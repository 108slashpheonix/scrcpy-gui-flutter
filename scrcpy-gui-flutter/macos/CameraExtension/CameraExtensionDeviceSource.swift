import Foundation
import CoreMediaIO
import CoreAudio

@available(macOS 12.3, *)
class CameraExtensionDeviceSource: NSObject, CMIOExtensionDeviceSource {
    private(set) var device: CMIOExtensionDevice!
    private var streamSource: CameraExtensionStreamSource!
    
    init(localizedName: String) {
        super.init()
        
        let deviceID = UUID() // Generate a unique ID for the device instance
        self.device = CMIOExtensionDevice(localizedName: localizedName, deviceID: deviceID, legacyDeviceID: nil, source: self)
        
        self.streamSource = CameraExtensionStreamSource(localizedName: "Scrcpy Video", streamID: UUID())
        
        do {
            try self.device.addStream(self.streamSource.stream)
        } catch {
            print("Failed to add stream: \(error)")
        }
    }
    
    var availableProperties: Set<CMIOExtensionProperty> {
        return [.deviceTransportType, .deviceModel]
    }
    
    func deviceProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionDeviceProperties {
        let deviceProperties = CMIOExtensionDeviceProperties(dictionary: [:])
        if properties.contains(.deviceTransportType) {
            deviceProperties.transportType = kIOAudioDeviceTransportTypeVirtual
        }
        if properties.contains(.deviceModel) {
            deviceProperties.model = "Scrcpy Virtual Camera"
        }
        return deviceProperties
    }
    
    func setDeviceProperties(_ deviceProperties: CMIOExtensionDeviceProperties) throws {
        // Handle property setting if needed
    }
}
