import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject private var settings: PetSettings
    @EnvironmentObject private var reminders: ReminderManager
    @EnvironmentObject private var runtime: PetRuntime
    @EnvironmentObject private var systemMetrics: SystemMetricsMonitor
    @State private var title = ""
    @State private var time = Date()
    @State private var reminderSchedule = ReminderSchedule.interval
    @State private var intervalMinutes = 45
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
                    Slider(value: $settings.animationSpeed, in: 0.4...1.0, step: 0.05) {
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
                Section("玻璃光效") {
                    Slider(value: $settings.baseBrightness, in: 0.1...1, step: 0.05) {
                        Text("底部光效亮度")
                    } minimumValueLabel: { Image(systemName: "sun.min") } maximumValueLabel: { Image(systemName: "sun.max.fill") }
                    LabeledContent("统一配色", value: "白色 · 黑色 · 电光蓝")
                    Text("底部不再绘制实体底座，只保留透明玻璃折射和柔和蓝色光池。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                    Text("防护罩、光池和信息卡片使用统一的透明玻璃风格。")
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

                Section("玻璃卡片样式") {
                    Slider(value: $settings.metricsBackgroundOpacity, in: 0.05...0.7, step: 0.05) {
                        Text("背景深度")
                    } minimumValueLabel: { Text("通透") } maximumValueLabel: { Text("清晰") }
                    Picker("字体", selection: $settings.metricFontStyle) {
                        ForEach(MetricFontStyle.allCases) { style in Text(style.title).tag(style) }
                    }
                    .pickerStyle(.segmented)
                    Picker("文字颜色", selection: $settings.metricTextColor) {
                        ForEach(MetricTextColor.allCases) { color in Text(color.title).tag(color) }
                    }
                    .pickerStyle(.segmented)
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
                HStack(spacing: 10) {
                    Menu("快捷内容") {
                        Button("喝水") { title = "喝口水，照顾好自己" }
                        Button("站起来活动") { title = "起来走一走，放松肩颈" }
                        Button("查看任务和待办") { title = "看看任务清单，选择下一件小事" }
                        Button("休息眼睛") { title = "看看远处，让眼睛休息一下" }
                    }
                    TextField("提醒内容", text: $title)
                    Button("添加") { addReminder() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                HStack {
                    Picker("提醒方式", selection: $reminderSchedule) {
                        ForEach(ReminderSchedule.allCases) { schedule in Text(schedule.title).tag(schedule) }
                    }
                    .pickerStyle(.segmented)
                    if reminderSchedule == .daily {
                        DatePicker("时间", selection: $time, displayedComponents: .hourAndMinute)
                    } else {
                        Picker("间隔", selection: $intervalMinutes) {
                            ForEach([15, 30, 45, 60, 90, 120], id: \.self) { value in
                                Text("\(value) 分钟").tag(value)
                            }
                        }
                        .frame(width: 160)
                    }
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
                            Text("可按固定时间，或每隔一段时间温柔提醒你。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(20)
            .tabItem { Label("提醒", systemImage: "bell") }
        }
        .frame(width: 660, height: 520)
    }

    private func percentage(_ value: Double?) -> String {
        value.map { String(format: "%.0f%%", $0) } ?? "等待采样"
    }

    private func addReminder() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let hour = components.hour ?? 9
        let minute = components.minute ?? 0
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let isValid = reminderSchedule == .daily
            ? ReminderRules.isValid(title: trimmedTitle, hour: hour, minute: minute)
            : ReminderRules.isValidInterval(title: trimmedTitle, minutes: intervalMinutes)
        guard isValid else { return }
        settings.reminders.append(PetReminder(
            title: trimmedTitle,
            hour: hour,
            minute: minute,
            schedule: reminderSchedule,
            intervalMinutes: intervalMinutes
        ))
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
