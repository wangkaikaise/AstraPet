import Foundation
import UserNotifications

@MainActor
final class ReminderManager: ObservableObject {
    @Published var authorizationDenied = false

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            authorizationDenied = !granted
        } catch {
            authorizationDenied = true
        }
    }

    func synchronize(_ reminders: [PetReminder]) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for reminder in reminders where reminder.isEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Eva 提醒"
            content.body = reminder.title
            content.sound = .default

            let trigger: UNNotificationTrigger
            if reminder.schedule == .interval {
                trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: TimeInterval(max(15, reminder.intervalMinutes) * 60),
                    repeats: true
                )
            } else {
                var components = DateComponents()
                components.hour = reminder.hour
                components.minute = reminder.minute
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            }
            let request = UNNotificationRequest(
                identifier: reminder.id.uuidString,
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }
}
