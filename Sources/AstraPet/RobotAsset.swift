import AppKit
import Foundation

enum RobotAsset {
    @MainActor
    static func image(named name: String) -> NSImage {
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }

        let sourceURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/\(name).png")
        if let image = NSImage(contentsOf: sourceURL) {
            return image
        }

        return NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Astra") ?? NSImage()
    }
}
