import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject private var settings: PetSettings
    @EnvironmentObject private var reminders: ReminderManager
    @EnvironmentObject private var runtime: PetRuntime
    @EnvironmentObject private var systemMetrics: SystemMetricsMonitor
    @State private var title = ""
    @State private var time = Date()
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchAtLoginError: String?

    var body: some View {
        TabView {
            Form {
                Section("陪伴状态") {
                    Picker("动作预览", selection: $runtime.action) {
                        ForEach(PetAction.allCases) { action in
                            Label(action.title, systemImage: action.symbol).tag(action)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("当前情绪", selection: $settings.mood) {
                        ForEach(PetMood.allCases) { mood in
                            Label(mood.title, systemImage: mood.symbol).tag(mood)
                        }
                    }
                    Toggle("自动切换打工人情绪", isOn: $settings.autoMood)
                    Picker("切换间隔", selection: $settings.moodInterval) {
                        ForEach(MoodInterval.allCases) { interval in
                            Text(interval.title).tag(interval)
                        }
                    }
                    .disabled(!settings.autoMood)
                }

                Section("节奏与窗口") {
                    Slider(value: $settings.size, in: 140...340, step: 10) {
                        Text("伙伴尺寸")
                    } minimumValueLabel: { Text("小") } maximumValueLabel: { Text("大") }
                    Slider(value: $settings.opacity, in: 0.55...1) { Text("透明度") }
                    Slider(value: $settings.animationSpeed, in: 0.55...1.25, step: 0.05) {
                        Text("动作节奏")
                    } minimumValueLabel: { Text("舒缓") } maximumValueLabel: { Text("活泼") }
                    Toggle("始终置于其他窗口上方", isOn: $settings.keepOnTop)
                    Toggle("登录后自动启动", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { enabled in updateLaunchAtLogin(enabled) }
                    if let launchAtLoginError {
                        Text(launchAtLoginError)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("伙伴", systemImage: "face.smiling") }

            Form {
                Section("桌面底座") {
                    Slider(value: $settings.baseBrightness, in: 0.1...1, step: 0.05) {
                        Text("底座亮度")
                    } minimumValueLabel: { Image(systemName: "sun.min") } maximumValueLabel: { Image(systemName: "sun.max.fill") }
                    Picker("环境色", selection: $settings.theme) {
                        ForEach(GlowTheme.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("防护罩") {
                    Toggle("显示防护罩", isOn: $settings.shieldEnabled)
                    Picker("防护罩风格", selection: $settings.shieldStyle) {
                        ForEach(ShieldStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(!settings.shieldEnabled)
                    Text("防护罩采用低功耗矢量效果，不会额外加载图片素材。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("环境", systemImage: "lamp.desk.fill") }

            Form {
                Section("桌面性能卡片") {
                    Toggle("在宠物旁显示性能信息", isOn: $settings.showSystemMonitor)
                    Picker("刷新频率", selection: $settings.metricsRefreshInterval) {
                        ForEach(MetricsRefreshInterval.allCases) { interval in
                            Text(interval.title).tag(interval)
                        }
                    }
                    .disabled(!settings.showSystemMonitor)
                }

                Section("显示项目") {
                    Toggle("CPU 占用率", isOn: $settings.showCPUUsage)
                    Toggle("CPU 温度 / 热状态", isOn: $settings.showCPUTemperature)
                    Toggle("GPU 占用率", isOn: $settings.showGPUUsage)
                    Toggle("GPU 温度", isOn: $settings.showGPUTemperature)
                }
                .disabled(!settings.showSystemMonitor)

                Section("当前读数") {
                    LabeledContent("CPU 占用率", value: percentage(systemMetrics.snapshot.cpuUsage))
                    LabeledContent("CPU 热状态", value: systemMetrics.snapshot.thermalState)
                    LabeledContent("GPU 占用率", value: percentage(systemMetrics.snapshot.gpuUsage))
                    LabeledContent("精确芯片温度", value: "macOS 系统限制")
                    Text("CPU 占用率使用 Mach 系统计数器；GPU 占用率读取可用的 IORegistry 性能统计。macOS 不向普通应用提供统一、公开的 CPU/GPU 摄氏温度接口，因此本版以系统热状态安全降级，不会显示猜测数值。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("性能", systemImage: "gauge.with.dots.needle.67percent") }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    TextField("提醒内容，例如：起来走一走", text: $title)
                    DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    Button("添加") { addReminder() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if reminders.authorizationDenied {
                    Label("通知权限未开启，请在系统设置中允许 Eva Desktop Pet 通知。", systemImage: "exclamationmark.triangle")
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
                            Text("添加一个每日提醒，Eva 会准时通知你。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(20)
            .tabItem { Label("提醒", systemImage: "bell") }
        }
        .frame(width: 620, height: 470)
    }

    private func percentage(_ value: Double?) -> String {
        value.map { String(format: "%.0f%%", $0) } ?? "等待采样"
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
