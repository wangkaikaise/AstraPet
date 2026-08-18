import Foundation
import SwiftUI

enum PetAction: String, CaseIterable, Codable, Identifiable {
    case idle, hover, cheer, sleep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .idle: "待机"
        case .hover: "巡航"
        case .cheer: "开心"
        case .sleep: "休眠"
        }
    }

    var symbol: String {
        switch self {
        case .idle: "sparkles"
        case .hover: "paperplane.fill"
        case .cheer: "hands.clap.fill"
        case .sleep: "moon.zzz.fill"
        }
    }
}

enum GlowTheme: String, CaseIterable, Codable, Identifiable {
    case amber, blush, sage

    var id: String { rawValue }
    var title: String {
        switch self {
        case .amber: "烛光琥珀"
        case .blush: "晚霞粉"
        case .sage: "鼠尾草绿"
        }
    }
    var color: Color {
        switch self {
        case .amber: Color(red: 1, green: 0.63, blue: 0.22)
        case .blush: Color(red: 0.96, green: 0.48, blue: 0.48)
        case .sage: Color(red: 0.42, green: 0.68, blue: 0.52)
        }
    }
}

enum ShieldStyle: String, CaseIterable, Codable, Identifiable {
    case halo, bubble, orbit

    var id: String { rawValue }
    var title: String {
        switch self {
        case .halo: "柔光环"
        case .bubble: "安心泡泡"
        case .orbit: "守护轨道"
        }
    }
}

enum PetMood: String, CaseIterable, Codable, Identifiable {
    case cheerful, calm, tired, frustrated, blue, focused

    var id: String { rawValue }
    var title: String {
        switch self {
        case .cheerful: "开心营业"
        case .calm: "平静摸鱼"
        case .tired: "有点疲惫"
        case .frustrated: "工作烦躁"
        case .blue: "今日郁闷"
        case .focused: "专注奋斗"
        }
    }
    var symbol: String {
        switch self {
        case .cheerful: "sun.max.fill"
        case .calm: "cup.and.saucer.fill"
        case .tired: "battery.25"
        case .frustrated: "exclamationmark.bubble.fill"
        case .blue: "cloud.drizzle.fill"
        case .focused: "scope"
        }
    }
    var usesGloomyExpression: Bool {
        self == .tired || self == .frustrated || self == .blue
    }
    var next: PetMood {
        let moods = Self.allCases
        guard let index = moods.firstIndex(of: self) else { return .calm }
        return moods[(index + 1) % moods.count]
    }
}

enum MoodInterval: Int, CaseIterable, Codable, Identifiable {
    case fifteenMinutes = 900
    case thirtyMinutes = 1800
    case oneHour = 3600

    var id: Int { rawValue }
    var title: String {
        switch self {
        case .fifteenMinutes: "15 分钟"
        case .thirtyMinutes: "30 分钟"
        case .oneHour: "1 小时"
        }
    }
}

struct PetReminder: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var hour: Int
    var minute: Int
    var isEnabled = true

    var timeText: String {
        String(format: "%02d:%02d", hour, minute)
    }
}

enum ReminderRules {
    static func isValid(title: String, hour: Int, minute: Int) -> Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (0...23).contains(hour) && (0...59).contains(minute)
    }
}

@MainActor
final class PetRuntime: ObservableObject {
    @Published var action: PetAction = .idle
}
