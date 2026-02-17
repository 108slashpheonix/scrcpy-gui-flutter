@available(macOS 12.3, *)
class CameraExtensionProviderSource: NSObject, CMIOExtensionProviderSource {
    private(set) var provider: CMIOExtensionProvider!
    private var deviceSource: CameraExtensionDeviceSource!
    
    init(clientQueue: DispatchQueue?) {
        super.init()
        
        self.provider = CMIOExtensionProvider(source: self, clientQueue: clientQueue)
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
    
    func providerProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionProviderProperties {
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
