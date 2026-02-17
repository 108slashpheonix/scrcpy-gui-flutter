import Foundation
import CoreMediaIO

// Entry point for the Camera Extension
// main.swift is implicitly the entry point, so we do not use @main here.

if #available(macOS 12.3, *) {
    let providerSource = CameraExtensionProviderSource(clientQueue: nil)
    CMIOExtensionProvider.startService(provider: providerSource.provider)
} else {
    // This extension requires macOS 12.3 or newer.
    NSLog("Error: ScrcpyCameraExtension requires macOS 12.3+")
}

CFRunLoopRun()
