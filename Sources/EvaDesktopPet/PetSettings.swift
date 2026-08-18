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
        static let shieldEnabled = "pet.shieldEnabled"
        static let shieldStyle = "pet.shieldStyle"
        static let baseBrightness = "pet.baseBrightness"
        static let mood = "pet.mood"
        static let autoMood = "pet.autoMood"
        static let moodInterval = "pet.moodInterval"
        static let showSystemMonitor = "monitor.enabled"
        static let showCPUUsage = "monitor.cpuUsage"
        static let showCPUTemperature = "monitor.cpuTemperature"
        static let showGPUUsage = "monitor.gpuUsage"
        static let showGPUTemperature = "monitor.gpuTemperature"
        static let metricsRefreshInterval = "monitor.refreshInterval"
        static let metricsBackgroundOpacity = "monitor.backgroundOpacity"
        static let metricTextColor = "monitor.textColor"
        static let metricFontStyle = "monitor.fontStyle"
    }

    @Published var size: Double { didSet { save(size, for: Key.size) } }
    @Published var opacity: Double { didSet { save(opacity, for: Key.opacity) } }
    @Published var theme: GlowTheme { didSet { save(theme.rawValue, for: Key.theme) } }
    @Published var animationSpeed: Double { didSet { save(animationSpeed, for: Key.speed) } }
    @Published var keepOnTop: Bool { didSet { save(keepOnTop, for: Key.keepOnTop) } }
    @Published var shieldEnabled: Bool { didSet { save(shieldEnabled, for: Key.shieldEnabled) } }
    @Published var shieldStyle: ShieldStyle { didSet { save(shieldStyle.rawValue, for: Key.shieldStyle) } }
    @Published var baseBrightness: Double { didSet { save(baseBrightness, for: Key.baseBrightness) } }
    @Published var mood: PetMood { didSet { save(mood.rawValue, for: Key.mood) } }
    @Published var autoMood: Bool { didSet { save(autoMood, for: Key.autoMood) } }
    @Published var moodInterval: MoodInterval { didSet { save(moodInterval.rawValue, for: Key.moodInterval) } }
    @Published var showSystemMonitor: Bool { didSet { save(showSystemMonitor, for: Key.showSystemMonitor) } }
    @Published var showCPUUsage: Bool { didSet { save(showCPUUsage, for: Key.showCPUUsage) } }
    @Published var showCPUTemperature: Bool { didSet { save(showCPUTemperature, for: Key.showCPUTemperature) } }
    @Published var showGPUUsage: Bool { didSet { save(showGPUUsage, for: Key.showGPUUsage) } }
    @Published var showGPUTemperature: Bool { didSet { save(showGPUTemperature, for: Key.showGPUTemperature) } }
    @Published var metricsRefreshInterval: MetricsRefreshInterval { didSet { save(metricsRefreshInterval.rawValue, for: Key.metricsRefreshInterval) } }
    @Published var metricsBackgroundOpacity: Double { didSet { save(metricsBackgroundOpacity, for: Key.metricsBackgroundOpacity) } }
    @Published var metricTextColor: MetricTextColor { didSet { save(metricTextColor.rawValue, for: Key.metricTextColor) } }
    @Published var metricFontStyle: MetricFontStyle { didSet { save(metricFontStyle.rawValue, for: Key.metricFontStyle) } }
    @Published var reminders: [PetReminder] { didSet { saveReminders() } }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        size = defaults.object(forKey: Key.size) as? Double ?? 220
        opacity = defaults.object(forKey: Key.opacity) as? Double ?? 1
        animationSpeed = min(defaults.object(forKey: Key.speed) as? Double ?? 0.8, 1.25)
        keepOnTop = defaults.object(forKey: Key.keepOnTop) as? Bool ?? true
        theme = GlowTheme(rawValue: defaults.string(forKey: Key.theme) ?? "cyan") ?? .cyan
        shieldEnabled = defaults.object(forKey: Key.shieldEnabled) as? Bool ?? false
        shieldStyle = ShieldStyle(rawValue: defaults.string(forKey: Key.shieldStyle) ?? "halo") ?? .halo
        baseBrightness = defaults.object(forKey: Key.baseBrightness) as? Double ?? 0.72
        mood = PetMood(rawValue: defaults.string(forKey: Key.mood) ?? "calm") ?? .calm
        autoMood = defaults.object(forKey: Key.autoMood) as? Bool ?? true
        let storedInterval = defaults.integer(forKey: Key.moodInterval)
        moodInterval = MoodInterval(rawValue: storedInterval) ?? .thirtyMinutes
        showSystemMonitor = defaults.object(forKey: Key.showSystemMonitor) as? Bool ?? false
        showCPUUsage = defaults.object(forKey: Key.showCPUUsage) as? Bool ?? true
        showCPUTemperature = defaults.object(forKey: Key.showCPUTemperature) as? Bool ?? true
        showGPUUsage = defaults.object(forKey: Key.showGPUUsage) as? Bool ?? true
        showGPUTemperature = defaults.object(forKey: Key.showGPUTemperature) as? Bool ?? true
        let storedRefreshInterval = defaults.integer(forKey: Key.metricsRefreshInterval)
        metricsRefreshInterval = MetricsRefreshInterval(rawValue: storedRefreshInterval) ?? .fiveSeconds
        metricsBackgroundOpacity = defaults.object(forKey: Key.metricsBackgroundOpacity) as? Double ?? 0.28
        metricTextColor = MetricTextColor(rawValue: defaults.string(forKey: Key.metricTextColor) ?? "white") ?? .white
        metricFontStyle = MetricFontStyle(rawValue: defaults.string(forKey: Key.metricFontStyle) ?? "rounded") ?? .rounded
        if let data = defaults.data(forKey: Key.reminders),
           let decoded = try? JSONDecoder().decode([PetReminder].self, from: data) {
            reminders = decoded
        } else {
            reminders = []
        }
    }

    func advanceMood() {
        mood = mood.next
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
