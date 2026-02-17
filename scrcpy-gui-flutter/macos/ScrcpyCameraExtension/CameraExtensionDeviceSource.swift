import Foundation
import CoreMediaIO

@available(macOS 12.3, *)
class CameraExtensionDeviceSource: NSObject, CMIOExtensionDeviceSource {
    let device: CMIOExtensionDevice
    private let streamSource: CameraExtensionStreamSource
    
    init(localizedName: String) {
        let deviceID = UUID() // Generate a unique ID for the device instance
        self.device = CMIOExtensionDevice(localizedName: localizedName, deviceID: deviceID, legacyDeviceID: nil, source: nil)
        
        self.streamSource = CameraExtensionStreamSource(localizedName: "Scrcpy Video", streamID: UUID())
        super.init()
        
        self.device.source = self
        
        do {
            try self.device.addStream(self.streamSource.stream)
        } catch {
            print("Failed to add stream: \(error)")
        }
    }
    
    var availableProperties: Set<CMIOExtensionProperty> {
        return [.deviceTransportType, .deviceModel]
    }
    
    func deviceProperties(for properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionDeviceProperties {
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
