import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject private var settings: PetSettings
    @EnvironmentObject private var reminders: ReminderManager
    @EnvironmentObject private var runtime: PetRuntime
    @State private var title = ""
    @State private var time = Date()
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchAtLoginError: String?

    var body: some View {
        TabView {
            Form {
                Picker("动作预览", selection: $runtime.action) {
                    ForEach(PetAction.allCases) { action in
                        Label(action.title, systemImage: action.symbol).tag(action)
                    }
                }
                .pickerStyle(.segmented)
                Picker("光效主题", selection: $settings.theme) {
                    ForEach(GlowTheme.allCases) { Text($0.title).tag($0) }
                }
                Slider(value: $settings.size, in: 140...340, step: 10) {
                    Text("宠物尺寸")
                } minimumValueLabel: { Text("小") } maximumValueLabel: { Text("大") }
                Slider(value: $settings.opacity, in: 0.45...1) { Text("透明度") }
                Slider(value: $settings.animationSpeed, in: 0.5...2, step: 0.1) { Text("动作速度") }
                Toggle("始终置于其他窗口上方", isOn: $settings.keepOnTop)
                Toggle("登录后自动启动", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { enabled in updateLaunchAtLogin(enabled) }
                if let launchAtLoginError {
                    Text(launchAtLoginError)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding(20)
            .tabItem { Label("外观", systemImage: "paintpalette") }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    TextField("提醒内容，例如：起来走一走", text: $title)
                    DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    Button("添加") { addReminder() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if reminders.authorizationDenied {
                    Label("通知权限未开启，请在系统设置中允许 AstraPet 通知。", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }

                List {
                    ForEach($settings.reminders) { $reminder in
                        HStack {
                            Toggle("", isOn: $reminder.isEnabled).labelsHidden()
                            Text(reminder.timeText).monospacedDigit().foregroundStyle(.secondary)
                            Text(reminder.title)
                            Spacer()
                            Button(role: .destructive) {
                                settings.reminders.removeAll { $0.id == reminder.id }
                                syncReminders()
                            } label: { Image(systemName: "trash") }
                                .buttonStyle(.borderless)
                        }
                        .onChange(of: reminder.isEnabled) { _ in syncReminders() }
                    }
                }
                .overlay {
                    if settings.reminders.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "bell")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                            Text("还没有提醒").font(.headline)
                            Text("添加一个每日提醒，Astra 会准时通知你。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(20)
            .tabItem { Label("提醒", systemImage: "bell") }
        }
        .frame(width: 520, height: 360)
    }

    private func addReminder() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let hour = components.hour ?? 9
        let minute = components.minute ?? 0
        guard ReminderRules.isValid(title: title, hour: hour, minute: minute) else { return }
        settings.reminders.append(PetReminder(title: title.trimmingCharacters(in: .whitespacesAndNewlines), hour: hour, minute: minute))
        title = ""
        syncReminders()
    }

    private func syncReminders() {
        Task {
            await reminders.requestPermission()
            await reminders.synchronize(settings.reminders)
        }
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = "无法更新开机启动：\(error.localizedDescription)"
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
