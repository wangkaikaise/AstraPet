import SwiftUI

struct PetView: View {
    @EnvironmentObject private var settings: PetSettings
    @EnvironmentObject private var runtime: PetRuntime
    @State private var isBlinking = false
    @State private var message: String?
    @State private var tapCount = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 12.0)) { timeline in
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

                CompanionBase(phase: phase, brightness: settings.baseBrightness, color: settings.theme.color)
                    .frame(width: settings.size * 0.66, height: 52)
                    .offset(y: settings.size + 48)

                robot(phase: phase)

                if let message {
                    Text(message)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.25, green: 0.16, blue: 0.12).opacity(0.88), in: Capsule())
                        .foregroundStyle(Color(red: 1, green: 0.91, blue: 0.72))
                        .overlay(Capsule().stroke(settings.theme.color.opacity(0.5)))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .offset(y: 2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(width: settings.size + 140, height: settings.size + 140)
        .contentShape(Rectangle())
        .task { await blinkLoop() }
        .task(id: "\(settings.autoMood)-\(settings.moodInterval.rawValue)") { await moodLoop() }
        .onChange(of: runtime.action) { newAction in
            isBlinking = false
            show(newAction == .sleep ? "晚安，我会安静陪着你" : "慢慢进入\(newAction.title)状态")
        }
        .onChange(of: settings.mood) { newMood in
            show("现在是：\(newMood.title)")
        }
        .animation(.easeInOut(duration: 1.2), value: settings.shieldEnabled)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("桌面伙伴 Astra，当前动作：\(runtime.action.title)，情绪：\(settings.mood.title)")
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
            .help("点击和 Astra 互动；拖动可移动位置")
            .animation(.easeInOut(duration: 1.15), value: spriteName)
    }

    private var spriteName: String {
        if runtime.action == .sleep { return "robot-warm-sleep" }
        if runtime.action == .cheer { return "robot-warm-happy" }
        if settings.mood.usesGloomyExpression { return "robot-warm-gloomy" }
        if isBlinking { return "robot-warm-blink" }
        return "robot-warm"
    }

    private func motionValues(for action: PetAction, phase: Double) -> MotionValues {
        switch action {
        case .idle:
            return MotionValues(
                x: sin(phase * 0.30) * 1.8,
                y: sin(phase * 0.52) * 4.5,
                rotation: sin(phase * 0.24) * 1.3,
                scale: 1 + sin(phase * 0.42) * 0.010
            )
        case .hover:
            return MotionValues(
                x: cos(phase * 0.46) * 5,
                y: sin(phase * 0.72) * 8,
                rotation: sin(phase * 0.40) * 2.5,
                scale: 1.01 + sin(phase * 0.62) * 0.014
            )
        case .cheer:
            return MotionValues(
                x: sin(phase * 0.72) * 3,
                y: -5 + sin(phase * 0.64) * 5,
                rotation: sin(phase * 0.58) * 2.8,
                scale: 1.025 + sin(phase * 0.54) * 0.016
            )
        case .sleep:
            return MotionValues(
                x: 0,
                y: 5 + sin(phase * 0.23) * 2,
                rotation: -1.5 + sin(phase * 0.18) * 0.7,
                scale: 0.98 + sin(phase * 0.24) * 0.006
            )
        }
    }

    @MainActor
    private func blinkLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 5_400_000_000)
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
            try? await Task.sleep(nanoseconds: 15_000_000_000)
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
            try? await Task.sleep(nanoseconds: 5_500_000_000)
            if message == text {
                withAnimation(.easeOut(duration: 0.55)) { message = nil }
            }
        }
    }
}

private struct MotionValues {
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let scale: CGFloat
}

private struct CompanionBase: View {
    let phase: Double
    let brightness: Double
    let color: Color

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color(red: 0.20, green: 0.13, blue: 0.10).opacity(0.82))
                .frame(height: 32)
            Ellipse()
                .stroke(Color(red: 0.78, green: 0.60, blue: 0.42).opacity(0.9), lineWidth: 2)
                .frame(height: 30)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(brightness), color.opacity(brightness * 0.12), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 58
                    )
                )
                .frame(width: 116, height: 24)
                .scaleEffect(0.98 + sin(phase * 0.38) * 0.025)
            Capsule()
                .fill(Color(red: 0.96, green: 0.83, blue: 0.65).opacity(0.82))
                .frame(width: 54, height: 5)
        }
        .opacity(0.45 + brightness * 0.55)
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
                .stroke(color.opacity(0.18), lineWidth: 10)
                .overlay(Circle().stroke(color.opacity(0.28), lineWidth: 1.5))
                .scaleEffect(0.965 + sin(phase * 0.20) * 0.012)
        case .bubble:
            Circle()
                .fill(color.opacity(0.035))
                .overlay(
                    Circle().stroke(
                        LinearGradient(colors: [color.opacity(0.40), .white.opacity(0.12), color.opacity(0.16)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.5
                    )
                )
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
