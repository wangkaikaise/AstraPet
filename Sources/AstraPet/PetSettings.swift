import Foundation
import SwiftUI

@MainActor
final class PetSettings: ObservableObject {
    private enum Key {
        static let size = "pet.size"
        static let opacity = "pet.opacity"
        static let theme = "pet.theme"
        static let speed = "pet.speed"
        static let keepOnTop = "pet.keepOnTop"
        static let reminders = "pet.reminders"
    }

    @Published var size: Double { didSet { save(size, for: Key.size) } }
    @Published var opacity: Double { didSet { save(opacity, for: Key.opacity) } }
    @Published var theme: GlowTheme { didSet { save(theme.rawValue, for: Key.theme) } }
    @Published var animationSpeed: Double { didSet { save(animationSpeed, for: Key.speed) } }
    @Published var keepOnTop: Bool { didSet { save(keepOnTop, for: Key.keepOnTop) } }
    @Published var reminders: [PetReminder] { didSet { saveReminders() } }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        size = defaults.object(forKey: Key.size) as? Double ?? 220
        opacity = defaults.object(forKey: Key.opacity) as? Double ?? 1
        animationSpeed = defaults.object(forKey: Key.speed) as? Double ?? 1
        keepOnTop = defaults.object(forKey: Key.keepOnTop) as? Bool ?? true
        theme = GlowTheme(rawValue: defaults.string(forKey: Key.theme) ?? "cyan") ?? .cyan
        if let data = defaults.data(forKey: Key.reminders),
           let decoded = try? JSONDecoder().decode([PetReminder].self, from: data) {
            reminders = decoded
        } else {
            reminders = []
        }
    }

    private func save(_ value: Any, for key: String) {
        defaults.set(value, forKey: key)
    }

    private func saveReminders() {
        if let data = try? JSONEncoder().encode(reminders) {
            defaults.set(data, forKey: Key.reminders)
        }
    }
}
