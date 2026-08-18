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
    case cyan, violet, emerald

    var id: String { rawValue }
    var title: String {
        switch self {
        case .cyan: "量子蓝"
        case .violet: "星云紫"
        case .emerald: "极光绿"
        }
    }
    var color: Color {
        switch self {
        case .cyan: .cyan
        case .violet: .purple
        case .emerald: .mint
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
