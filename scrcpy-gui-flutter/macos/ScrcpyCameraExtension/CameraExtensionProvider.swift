import Foundation
import CoreMediaIO

@available(macOS 12.3, *)
class CameraExtensionProviderSource: NSObject, CMIOExtensionProviderSource {
    let provider: CMIOExtensionProvider
    private var deviceSource: CameraExtensionDeviceSource!
    
    // CMIOExtensionProviderSource protocol requirement:
    // This property returns the device identifiers available from this provider.
    // However, the CMIOExtensionProvider manages this internally via addDevice/removeDevice.
    // We just need to initialize the provider and add our device.
    
    init(clientQueue: DispatchQueue?) {
        // Create the provider object (passed back in startService in main.swift)
        // The source (self) is what the provider uses to get updates, but deeper integration 
        // usually happens by creating Devices and Streams and adding them to the Provider.
        
        self.provider = CMIOExtensionProvider(source: nil, clientQueue: clientQueue)
        super.init()
        
        self.provider.source = self
        
        // Initialize our virtual device
        self.deviceSource = CameraExtensionDeviceSource(localizedName: "Scrcpy Android Webcam")
        
        do {
            try self.provider.addDevice(self.deviceSource.device)
        } catch {
            print("Failed to add device: \(error)")
        }
    }
    
    func connect(to client: CMIOExtensionClient) throws {
        // Handle client connection if needed
    }
    
    func disconnect(from client: CMIOExtensionClient) {
        // Handle client disconnection if needed
    }
    
    var availableProperties: Set<CMIOExtensionProperty> {
        return [.providerManufacturer]
    }
    
    func providerProperties(for properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionProviderProperties {
        let providerProperties = CMIOExtensionProviderProperties(dictionary: [:])
        if properties.contains(.providerManufacturer) {
            providerProperties.manufacturer = "Scrcpy GUI"
        }
        return providerProperties
    }
    
    func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties) throws {
        // Handle property setting if needed
    }
}
