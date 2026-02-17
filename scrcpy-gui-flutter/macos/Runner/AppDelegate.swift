import Cocoa
import FlutterMacOS
import SystemExtensions

@main
class AppDelegate: FlutterAppDelegate, OSSystemExtensionRequestDelegate {
    
    override func applicationDidFinishLaunching(_ notification: Notification) {
        // Request System Extension Activation
        // Replace "com.imAdityaSharma.scrcpy-gui.ScrcpyCameraExtension" with your actual Bundle ID from Xcode if different
        // It is usually $(PRODUCT_BUNDLE_IDENTIFIER) of the extension target.
        let extensionIdentifier = "com.imAdityaSharma.scrcpy-gui.ScrcpyCameraExtension"
        
        // Create an activation request
        let request = OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: extensionIdentifier, queue: .main)
        request.delegate = self
        OSSystemExtensionManager.shared.submitRequest(request)
        
        super.applicationDidFinishLaunching(notification)
    }

    func request(_ request: OSSystemExtensionRequest, actionForReplacingExtension existing: OSSystemExtensionProperties, withExtension ext: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {
        print("Replacing existing system extension")
        return .replace
    }
    
    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        print("System Extension requires user approval")
    }
    
    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        print("System Extension ACTIVATED successfully")
    }
    
    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        print("System Extension FAILED to activate: \(error.localizedDescription)")
    }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
