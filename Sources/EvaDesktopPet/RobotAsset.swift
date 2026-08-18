import AppKit
import Foundation

@MainActor
enum RobotAsset {
    private static let cache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 3
        return cache
    }()

    static func image(named name: String) -> NSImage {
        if let cached = cache.object(forKey: name as NSString) {
            return cached
        }

        let image: NSImage?
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let bundled = NSImage(contentsOf: url) {
            image = bundled
        } else {
            let sourceURL = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .appendingPathComponent("Resources/\(name).png")
            image = NSImage(contentsOf: sourceURL)
        }

        if let image {
            image.cacheMode = .always
            cache.setObject(image, forKey: name as NSString)
            return image
        }

        return NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Eva") ?? NSImage()
    }
}
