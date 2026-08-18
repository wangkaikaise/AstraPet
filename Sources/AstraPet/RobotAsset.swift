import AppKit
import Foundation

enum RobotAsset {
    static let image: NSImage = {
        if let url = Bundle.main.url(forResource: "robot", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }

        let sourceURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/robot.png")
        if let image = NSImage(contentsOf: sourceURL) {
            return image
        }

        return NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Astra") ?? NSImage()
    }()
}
