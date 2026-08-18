import Foundation
import SwiftUI

enum PetAction: String, CaseIterable, Codable, Identifiable {
    case idle, hover, cheer, play, sleep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .idle: "待机"
        case .hover: "巡航"
        case .cheer: "开心"
        case .play: "玩耍"
        case .sleep: "休眠"
        }
    }

    var symbol: String {
        switch self {
        case .idle: "sparkles"
        case .hover: "paperplane.fill"
        case .cheer: "hands.clap.fill"
        case .play: "wand.and.stars"
        case .sleep: "moon.zzz.fill"
        }
    }

    static func interactionCandidates(excluding current: PetAction) -> [PetAction] {
        allCases.filter { $0 != current }
    }
}

enum PetMotionSpec {
    static let chestCoreNormalizedX: CGFloat = 0
    static let chestCoreNormalizedY: CGFloat = 0.045
    static let idleHorizontalTravel: CGFloat = 4
    static let hoverHorizontalTravel: CGFloat = 32
}

enum PetInteractionSpec {
    // Non-zero alpha prevents transparent NSPanel hit testing from passing
    // pointer events through the visible rocket on macOS.
    static let hitLayerOpacity = 0.001
}

enum PetLayoutSpec {
    static let panelExtraWidth: CGFloat = 300
    static let panelExtraHeight: CGFloat = 220
    static let metricsHUDWidth: CGFloat = 130
    static let metricsHUDHeight: CGFloat = 82
    static let topMetricsPetOffset: CGFloat = 96

    static func metricsCenter(
        for position: MetricsPosition,
        petSize: CGFloat,
        containerSize: CGSize
    ) -> CGPoint {
        let horizontalCenter = containerSize.width / 2
        let sideCenter = panelExtraWidth / 4
        let sideVerticalCenter = 34 + petSize * 0.30

        switch position {
        case .top:
            return CGPoint(x: horizontalCenter, y: metricsHUDHeight / 2 + 8)
        case .bottom:
            return CGPoint(x: horizontalCenter, y: petSize + 142)
        case .left:
            return CGPoint(x: sideCenter, y: sideVerticalCenter)
        case .right:
            return CGPoint(x: containerSize.width - sideCenter, y: sideVerticalCenter)
        }
    }
}

enum GlowTheme: String, CaseIterable, Codable, Identifiable {
    case cyan

    var id: String { rawValue }
    var title: String {
        "电光蓝"
    }
    var color: Color {
        Color(red: 0.12, green: 0.76, blue: 1.0)
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

enum MetricsRefreshInterval: Int, CaseIterable, Codable, Identifiable {
    case twoSeconds = 2
    case fiveSeconds = 5
    case tenSeconds = 10

    var id: Int { rawValue }
    var title: String { "\(rawValue) 秒" }
}

enum MetricsPosition: String, CaseIterable, Identifiable {
    case top, bottom, left, right

    var id: String { rawValue }
    var title: String {
        switch self {
        case .top: "上方"
        case .bottom: "下方"
        case .left: "左侧"
        case .right: "右侧"
        }
    }

    var symbol: String {
        switch self {
        case .top: "arrow.up"
        case .bottom: "arrow.down"
        case .left: "arrow.left"
        case .right: "arrow.right"
        }
    }

}

enum MetricTextColor: String, CaseIterable, Identifiable {
    case white, blue, black

    var id: String { rawValue }
    var title: String {
        switch self {
        case .white: "白色"
        case .blue: "蓝色"
        case .black: "黑色"
        }
    }
    var color: Color {
        switch self {
        case .white: .white
        case .blue: GlowTheme.cyan.color
        case .black: .black
        }
    }
}

enum MetricFontStyle: String, CaseIterable, Identifiable {
    case rounded, system, monospaced

    var id: String { rawValue }
    var title: String {
        switch self {
        case .rounded: "圆体"
        case .system: "系统"
        case .monospaced: "等宽"
        }
    }
    var design: Font.Design {
        switch self {
        case .rounded: .rounded
        case .system: .default
        case .monospaced: .monospaced
        }
    }
}

enum ReminderSchedule: String, Codable, CaseIterable, Identifiable {
    case daily, interval

    var id: String { rawValue }
    var title: String { self == .daily ? "每天定时" : "间隔重复" }
}

struct PetReminder: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var hour: Int
    var minute: Int
    var isEnabled = true
    var schedule: ReminderSchedule = .daily
    var intervalMinutes = 60

    var timeText: String {
        schedule == .daily ? String(format: "%02d:%02d", hour, minute) : "每 \(intervalMinutes) 分钟"
    }

    init(
        id: UUID = UUID(), title: String, hour: Int, minute: Int,
        isEnabled: Bool = true, schedule: ReminderSchedule = .daily, intervalMinutes: Int = 60
    ) {
        self.id = id
        self.title = title
        self.hour = hour
        self.minute = minute
        self.isEnabled = isEnabled
        self.schedule = schedule
        self.intervalMinutes = intervalMinutes
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, hour, minute, isEnabled, schedule, intervalMinutes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        hour = try container.decodeIfPresent(Int.self, forKey: .hour) ?? 9
        minute = try container.decodeIfPresent(Int.self, forKey: .minute) ?? 0
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        schedule = try container.decodeIfPresent(ReminderSchedule.self, forKey: .schedule) ?? .daily
        intervalMinutes = try container.decodeIfPresent(Int.self, forKey: .intervalMinutes) ?? 60
    }
}

enum ReminderRules {
    static func isValid(title: String, hour: Int, minute: Int) -> Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (0...23).contains(hour) && (0...59).contains(minute)
    }


    static func isValidInterval(title: String, minutes: Int) -> Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && minutes >= 15
    }
}

@MainActor
final class PetRuntime: ObservableObject {
    @Published var action: PetAction = .idle
}
