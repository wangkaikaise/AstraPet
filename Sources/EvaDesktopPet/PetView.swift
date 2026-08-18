import SwiftUI

struct PetView: View {
    @EnvironmentObject private var settings: PetSettings
    @EnvironmentObject private var runtime: PetRuntime
    @EnvironmentObject private var systemMetrics: SystemMetricsMonitor
    @State private var isBlinking = false
    @State private var message: String?
    @State private var tapCount = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: 240)
            let phase = time * settings.animationSpeed

            ZStack(alignment: .top) {
                if settings.shieldEnabled {
                    ShieldView(style: settings.shieldStyle, phase: phase, color: settings.theme.color)
                        .frame(width: settings.size + 58, height: settings.size + 58)
                        .offset(y: 26)
                        .transition(.opacity)
                }

                GlassLightPool(phase: phase, brightness: settings.baseBrightness, color: settings.theme.color)
                    .frame(width: settings.size * 0.72, height: 46)
                    .offset(y: settings.size + 42)

                robot(phase: phase)

                if let message {
                    Text(message)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .background(Color.black.opacity(0.20), in: Capsule())
                        .foregroundStyle(.white)
                        .overlay(Capsule().stroke(.white.opacity(0.38)))
                        .shadow(color: settings.theme.color.opacity(0.25), radius: 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .offset(y: settings.showSystemMonitor ? settings.size + 8 : 2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .overlay(alignment: .topTrailing) {
                if settings.showSystemMonitor {
                    MetricsHUD(snapshot: systemMetrics.snapshot)
                        .padding(.top, 8)
                        .padding(.trailing, 4)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
        }
        .frame(width: settings.size + 140, height: settings.size + 140)
        .contentShape(Rectangle())
        .task { await blinkLoop() }
        .task(id: "\(settings.autoMood)-\(settings.moodInterval.rawValue)") { await moodLoop() }
        .task(id: "\(settings.showSystemMonitor)-\(settings.metricsRefreshInterval.rawValue)") {
            guard settings.showSystemMonitor else {
                systemMetrics.reset()
                return
            }
            await systemMetrics.run(every: settings.metricsRefreshInterval.rawValue)
        }
        .onChange(of: runtime.action) { newAction in
            isBlinking = false
            show(newAction == .sleep ? "晚安，我会安静陪着你" : "慢慢进入\(newAction.title)状态")
        }
        .onChange(of: settings.mood) { newMood in
            show("现在是：\(newMood.title)")
        }
        .animation(.easeInOut(duration: 2.0), value: settings.shieldEnabled)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("桌面伙伴 Eva，当前动作：\(runtime.action.title)，情绪：\(settings.mood.title)")
        .accessibilityAddTraits(.isButton)
    }

    private func robot(phase: Double) -> some View {
        let motion = motionValues(for: runtime.action, phase: phase)
        return Image(nsImage: RobotAsset.image(named: spriteName))
            .resizable()
            .scaledToFit()
            .frame(width: settings.size, height: settings.size)
            .id(spriteName)
            .transition(.opacity.combined(with: .scale(scale: 0.985)))
            .opacity(settings.opacity)
            .scaleEffect(motion.scale)
            .rotationEffect(.degrees(motion.rotation))
            .offset(x: motion.x, y: motion.y + 34)
            .onTapGesture { interact() }
            .contextMenu {
                ForEach(PetAction.allCases) { item in
                    Button { runtime.action = item } label: {
                        Label(item.title, systemImage: item.symbol)
                    }
                }
            }
            .help("点击和 Eva 互动；拖动可移动位置")
            .animation(.easeInOut(duration: 2.2), value: spriteName)
    }

    private var spriteName: String {
        if runtime.action == .sleep { return "eva-glass-v11-sleep" }
        if runtime.action == .cheer { return "eva-glass-v11-happy" }
        if settings.mood.usesGloomyExpression { return "eva-glass-v11-gloomy" }
        if isBlinking { return "eva-glass-v11-blink" }
        return "eva-glass-v11"
    }

    private func motionValues(for action: PetAction, phase: Double) -> MotionValues {
        switch action {
        case .idle:
            return MotionValues(
                x: sin(phase * 0.13) * 1.5,
                y: sin(phase * 0.20) * 4.2,
                rotation: sin(phase * 0.11) * 1.1,
                scale: 1 + sin(phase * 0.16) * 0.009
            )
        case .hover:
            return MotionValues(
                x: cos(phase * 0.18) * 4.5,
                y: sin(phase * 0.27) * 7,
                rotation: sin(phase * 0.16) * 2.1,
                scale: 1.01 + sin(phase * 0.23) * 0.012
            )
        case .cheer:
            return MotionValues(
                x: sin(phase * 0.25) * 2.8,
                y: -5 + sin(phase * 0.23) * 5,
                rotation: sin(phase * 0.21) * 2.5,
                scale: 1.025 + sin(phase * 0.20) * 0.014
            )
        case .sleep:
            return MotionValues(
                x: 0,
                y: 5 + sin(phase * 0.10) * 2,
                rotation: -1.5 + sin(phase * 0.08) * 0.6,
                scale: 0.98 + sin(phase * 0.09) * 0.006
            )
        }
    }

    @MainActor
    private func blinkLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 7_800_000_000)
            guard runtime.action == .idle, !settings.mood.usesGloomyExpression else { continue }
            withAnimation(.easeInOut(duration: 0.14)) { isBlinking = true }
            try? await Task.sleep(nanoseconds: 260_000_000)
            withAnimation(.easeInOut(duration: 0.16)) { isBlinking = false }
        }
    }

    @MainActor
    private func moodLoop() async {
        while settings.autoMood && !Task.isCancelled {
            let seconds = UInt64(settings.moodInterval.rawValue)
            try? await Task.sleep(nanoseconds: seconds * 1_000_000_000)
            guard settings.autoMood, !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 1.25)) { settings.advanceMood() }
        }
    }

    private func interact() {
        tapCount += 1
        runtime.action = .cheer
        let messages = messagesForCurrentMood
        show(messages[tapCount % messages.count])
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            if runtime.action == .cheer { runtime.action = .idle }
        }
    }

    private var messagesForCurrentMood: [String] {
        switch settings.mood {
        case .cheerful: ["今天也很棒呀", "你的好心情，我收到啦"]
        case .calm: ["慢一点也没关系", "陪你安静待一会儿"]
        case .tired: ["累了就伸个懒腰吧", "先喝口水，再继续"]
        case .frustrated: ["工作可以烦，别为难自己", "深呼吸，我陪着你"]
        case .blue: ["今天不开心也没关系", "不用马上振作，我在这里"]
        case .focused: ["专注模式，一起加油", "一步一步来就好"]
        }
    }

    private func show(_ text: String) {
        withAnimation(.easeInOut(duration: 0.65)) { message = text }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            if message == text {
                withAnimation(.easeOut(duration: 0.55)) { message = nil }
            }
        }
    }
}

private struct MetricsHUD: View {
    let snapshot: SystemMetricsSnapshot

    @EnvironmentObject private var settings: PetSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if settings.showCPUUsage { metric("CPU", value: percentage(snapshot.cpuUsage), symbol: "cpu") }
            if settings.showCPUTemperature {
                metric("CPU 温度", value: temperature(snapshot.cpuTemperature, fallback: snapshot.thermalState), symbol: "thermometer.medium")
            }
            if settings.showGPUUsage { metric("GPU", value: percentage(snapshot.gpuUsage), symbol: "display") }
            if settings.showGPUTemperature {
                metric("GPU 温度", value: temperature(snapshot.gpuTemperature, fallback: "系统限制"), symbol: "thermometer.medium")
            }
        }
        .font(.system(size: 10, weight: .semibold, design: settings.metricFontStyle.design))
        .monospacedDigit()
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .background(Color.black.opacity(settings.metricsBackgroundOpacity), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(LinearGradient(colors: [.white.opacity(0.58), settings.theme.color.opacity(0.30)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .shadow(color: settings.theme.color.opacity(0.08), radius: 4, y: 2)
        .foregroundStyle(settings.metricTextColor.color.opacity(0.94))
        .allowsHitTesting(false)
    }

    private func metric(_ label: String, value: String, symbol: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol).frame(width: 11)
            Text(label)
            Spacer(minLength: 5)
            Text(value).fontWeight(.bold)
        }
        .frame(width: 112)
    }

    private func percentage(_ value: Double?) -> String {
        value.map { String(format: "%.0f%%", $0) } ?? "读取中"
    }

    private func temperature(_ value: Double?, fallback: String) -> String {
        value.map { String(format: "%.0f°C", $0) } ?? fallback
    }
}

private struct MotionValues {
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let scale: CGFloat
}

private struct GlassLightPool: View {
    let phase: Double
    let brightness: Double
    let color: Color

    var body: some View {
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(brightness * 0.55), color.opacity(brightness * 0.48), color.opacity(brightness * 0.08), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 70
                    )
                )
                .blur(radius: 8)
                .scaleEffect(0.98 + sin(phase * 0.15) * 0.020)
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(brightness * 0.20), color.opacity(brightness * 0.22), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 5)
                .blur(radius: 3)
        }
        .opacity(0.18 + brightness * 0.42)
        .allowsHitTesting(false)
    }
}

private struct ShieldView: View {
    let style: ShieldStyle
    let phase: Double
    let color: Color

    var body: some View {
        switch style {
        case .halo:
            Circle()
                .stroke(color.opacity(0.13), lineWidth: 10)
                .overlay(Circle().stroke(.white.opacity(0.28), lineWidth: 1.2))
                .scaleEffect(0.965 + sin(phase * 0.20) * 0.012)
        case .bubble:
            Circle()
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.52), color.opacity(0.35), .white.opacity(0.10)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1.5
                )
                .overlay(alignment: .topLeading) {
                    Capsule()
                        .fill(.white.opacity(0.18))
                        .frame(width: 32, height: 2)
                        .rotationEffect(.degrees(-35))
                        .offset(x: 38, y: 52)
                        .blur(radius: 1)
                }
                .scaleEffect(0.97 + sin(phase * 0.16) * 0.010)
        case .orbit:
            ZStack {
                Circle()
                    .trim(from: 0.08, to: 0.44)
                    .stroke(color.opacity(0.34), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(phase * 3.5))
                Circle()
                    .trim(from: 0.56, to: 0.84)
                    .stroke(color.opacity(0.20), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                    .rotationEffect(.degrees(-phase * 2.3))
            }
        }
    }
}
