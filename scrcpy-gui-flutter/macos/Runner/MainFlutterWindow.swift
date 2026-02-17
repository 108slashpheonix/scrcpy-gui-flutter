import Cocoa
import FlutterMacOS
import ScreenCaptureKit
import CoreMedia
import VideoToolbox

class MainFlutterWindow: NSWindow {
  private var stream: Any? // SCStream is 12.3+
  private var streamHandler: Any? // Holds the SCStreamOutput delegate
  private var virtualCameraChannel: FlutterMethodChannel?
  private var tcpClient: Client?
    
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
      
    // Setup Method Channel
    virtualCameraChannel = FlutterMethodChannel(
        name: "com.scrcpy.gui/virtual_camera",
        binaryMessenger: flutterViewController.engine.binaryMessenger
    )
      
    virtualCameraChannel?.setMethodCallHandler { [weak self] (call, result) in
        guard let self = self else { return }
        switch call.method {
        case "start":
            if let args = call.arguments as? [String: Any],
               let windowTitle = args["windowTitle"] as? String {
                self.startVirtualCamera(windowTitle: windowTitle, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Window title missing", details: nil))
            }
        case "stop":
            self.stopVirtualCamera(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    super.awakeFromNib()
  }
    
  private func startVirtualCamera(windowTitle: String, result: @escaping FlutterResult) {
      if #available(macOS 12.3, *) {
          Task {
              do {
                  let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                  
                  // Find window by title (partial match)
                  guard let window = content.windows.first(where: {
                      $0.title?.contains(windowTitle) == true && $0.isOnScreen
                  }) else {
                      DispatchQueue.main.async {
                          result(FlutterError(code: "WINDOW_NOT_FOUND", message: "Could not find window: \(windowTitle)", details: nil))
                      }
                      return
                  }
                  
                  // Start capture on main thread if needed, or just call it (startCapture handles its own dispatch if needed, but SCStream usually requires main thread or specific queue?)
                  // config init is main thread safe. 
                  
                  await MainActor.run {
                      self.startCapture(window: window, result: result)
                  }
              } catch {
                  DispatchQueue.main.async {
                      result(FlutterError(code: "SC_ERROR", message: "Failed to get shareable content", details: error.localizedDescription))
                  }
              }
          }
      } else {
          result(FlutterError(code: "UNSUPPORTED_OS", message: "macOS 12.3 or later required for Virtual Camera", details: nil))
      }
  }
    
  private func stopVirtualCamera(result: FlutterResult?) {
      if #available(macOS 12.3, *) {
          if let stream = stream as? SCStream {
              stream.stopCapture()
          }
      }
      stream = nil
      streamHandler = nil
      
      tcpClient?.stop()
      tcpClient = nil
      result?(true)
  }
    
  @available(macOS 12.3, *)
  private func startCapture(window: SCWindow, result: @escaping FlutterResult) {
      let filter = SCContentFilter(desktopIndependentWindow: window)
      let config = SCStreamConfiguration()
      config.width = 1920
      config.height = 1080
      config.minimumFrameInterval = CMTime(value: 1, timescale: 30)
      config.queueDepth = 5
      
      // Initialize TCP Client
      tcpClient = Client(host: "127.0.0.1", port: 49152)
      tcpClient?.start()
      
      do {
          let stream = SCStream(filter: filter, configuration: config, delegate: nil)
          self.stream = stream
          
          let handler = StreamOutputHandler(tcpClient: tcpClient)
          self.streamHandler = handler
          
          try stream.addStreamOutput(handler, type: .screen, sampleHandlerQueue: DispatchQueue(label: "com.scrcpy.gui.frame-queue"))
          
          stream.startCapture { error in
              if let error = error {
                  result(FlutterError(code: "CAPTURE_ERROR", message: "Failed to start capture", details: error.localizedDescription))
              } else {
                  result(true)
              }
          }
      } catch {
          result(FlutterError(code: "CAPTURE_INIT_ERROR", message: "Failed to init capture", details: error.localizedDescription))
      }
  }
}

@available(macOS 12.3, *)
class StreamOutputHandler: NSObject, SCStreamOutput {
    weak var tcpClient: Client?
    
    init(tcpClient: Client?) {
        self.tcpClient = tcpClient
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        guard let imageBuffer = sampleBuffer.imageBuffer else { return }
        
        // Convert to needed format (if not already BGRA) and send
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly) }
        
        if let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) {
            _ = CVPixelBufferGetWidth(imageBuffer)
            let height = CVPixelBufferGetHeight(imageBuffer)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
            let dataSize = height * bytesPerRow
            
            let data = Data(bytes: baseAddress, count: dataSize)
            tcpClient?.send(data: data)
        }
    }
}

// Simple TCP Client
import Network

class Client {
    let connection: NWConnection
    let queue = DispatchQueue(label: "TCP Client Queue")

    init(host: String, port: UInt16) {
        self.connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: .tcp)
    }

    func start() {
        connection.stateUpdateHandler = { state in
            print("Client connection state: \(state)")
        }
        connection.start(queue: queue)
    }

    func send(data: Data) {
        // Send size header first
        var size = UInt32(data.count).bigEndian
        let header = Data(bytes: &size, count: 4)
        
        connection.send(content: header, completion: .contentProcessed { _ in
            // Then send body
            self.connection.send(content: data, completion: .contentProcessed { _ in })
        })
    }

    func stop() {
        connection.cancel()
    }
}
