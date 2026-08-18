import SwiftUI

struct PetView: View {
    @EnvironmentObject private var settings: PetSettings
    @EnvironmentObject private var runtime: PetRuntime
    @State private var isBlinking = false
    @State private var message: String?
    @State private var tapCount = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let normalizedTime = timeline.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: 120)
            let phase = normalizedTime * settings.animationSpeed
            ZStack(alignment: .top) {
                ActionEffects(action: runtime.action, phase: phase, color: settings.theme.color)
                    .frame(width: settings.size + 110, height: settings.size + 110)
                robot(phase: phase)
                if let message {
                    Text(message)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(settings.theme.color.opacity(0.55)))
                        .shadow(color: settings.theme.color.opacity(0.25), radius: 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .frame(width: settings.size + 110, height: settings.size + 110)
        .contentShape(Rectangle())
        .task { await blinkLoop() }
        .onChange(of: runtime.action) { newAction in
            isBlinking = false
            show(newAction == .sleep ? "嘘…进入低功耗模式" : "\(newAction.title)模式启动")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("桌面宠物 Astra，当前动作：\(runtime.action.title)")
        .accessibilityAddTraits(.isButton)
    }

    private func robot(phase: Double) -> some View {
        let motion = motionValues(for: runtime.action, phase: phase)
        return Image(nsImage: RobotAsset.image(named: spriteName))
            .resizable()
            .scaledToFit()
            .frame(width: settings.size, height: settings.size)
            .id(spriteName)
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
            .opacity(settings.opacity)
            .scaleEffect(motion.scale)
            .rotationEffect(.degrees(motion.rotation))
            .offset(x: motion.x, y: motion.y + 38)
            .saturation(runtime.action == .sleep ? 0.55 : 1)
            .onTapGesture { interact() }
            .contextMenu {
                ForEach(PetAction.allCases) { item in
                    Button { runtime.action = item } label: {
                        Label(item.title, systemImage: item.symbol)
                    }
                }
            }
            .help("点击和 Astra 互动；拖动可移动位置")
            .animation(.easeInOut(duration: 0.22), value: spriteName)
    }

    private var spriteName: String {
        switch runtime.action {
        case .idle: isBlinking ? "robot-blink" : "robot"
        case .hover: "robot"
        case .cheer: "robot-cheer"
        case .sleep: "robot-sleep"
        }
    }

    private func motionValues(for action: PetAction, phase: Double) -> MotionValues {
        switch action {
        case .idle:
            return MotionValues(x: sin(phase * 0.65) * 2.5, y: sin(phase * 1.25) * 7,
                rotation: sin(phase * 0.7) * 2.2, scale: 1 + sin(phase * 1.1) * 0.018,
                glow: 0.42 + sin(phase * 1.5) * 0.12, glowRadius: 15 + sin(phase * 1.5) * 5)
        case .hover:
            return MotionValues(x: cos(phase * 1.2) * 9, y: sin(phase * 2.1) * 15,
                rotation: sin(phase * 1.2) * 5, scale: 1.03 + sin(phase * 2.1) * 0.025,
                glow: 0.72, glowRadius: 25)
        case .cheer:
            return MotionValues(x: sin(phase * 4.5) * 7, y: -abs(sin(phase * 3.1)) * 20,
                rotation: sin(phase * 4.5) * 7, scale: 1.04 + abs(sin(phase * 3.1)) * 0.07,
                glow: 0.82, glowRadius: 28)
        case .sleep:
            return MotionValues(x: 0, y: 8 + sin(phase * 0.7) * 3,
                rotation: -3 + sin(phase * 0.55) * 1.2, scale: 0.96 + sin(phase * 0.7) * 0.01,
                glow: 0.24, glowRadius: 10)
        }
    }

    @MainActor
    private func blinkLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 2_700_000_000)
            guard runtime.action == .idle else { continue }
            withAnimation(.easeInOut(duration: 0.06)) { isBlinking = true }
            try? await Task.sleep(nanoseconds: 150_000_000)
            withAnimation(.easeInOut(duration: 0.06)) { isBlinking = false }
        }
    }

    private func interact() {
        tapCount += 1
        runtime.action = .cheer
        let messages = ["收到！", "今天也一起加油。", "信号连接成功！", "嘿，我一直在。"]
        show(messages[tapCount % messages.count])
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_100_000_000)
            if runtime.action == .cheer { runtime.action = .idle }
        }
    }

    private func show(_ text: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { message = text }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_300_000_000)
            if message == text {
                withAnimation(.easeOut(duration: 0.2)) { message = nil }
            }
        }
    }
}

private struct MotionValues {
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let scale: CGFloat
    let glow: Double
    let glowRadius: CGFloat
}

private struct ActionEffects: View {
    let action: PetAction
    let phase: Double
    let color: Color

    var body: some View {
        ZStack {
            energyRings
            switch action {
            case .idle: idleOrbit
            case .hover: scanner
            case .cheer: celebration
            case .sleep: sleepSymbols
            }
        }
        .allowsHitTesting(false)
    }

    private var energyRings: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                let wave = (phase * 0.7 + Double(index) * 0.33).truncatingRemainder(dividingBy: 1)
                Ellipse()
                    .stroke(color.opacity((1 - wave) * (action == .sleep ? 0.16 : 0.42)), lineWidth: 1.5)
                    .frame(width: 44 + wave * 75, height: 14 + wave * 22)
                    .offset(y: 88)
            }
        }
    }

    private var idleOrbit: some View {
        Circle()
            .trim(from: 0.05, to: 0.28)
            .stroke(color.opacity(0.38), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
            .frame(width: 210, height: 210)
            .rotationEffect(.degrees(phase * 28))
    }

    private var scanner: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.34)
                .stroke(color.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 228, height: 228)
                .rotationEffect(.degrees(phase * 80))
            Circle()
                .stroke(color.opacity(0.16), lineWidth: 1)
                .frame(width: 245, height: 245)
                .scaleEffect(0.96 + sin(phase * 2) * 0.04)
        }
    }

    private var celebration: some View {
        ForEach(0..<8, id: \.self) { index in
            let angle = Double(index) * .pi / 4 + phase * 0.35
            Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "star.fill")
                .font(.system(size: index.isMultiple(of: 2) ? 14 : 9, weight: .bold))
                .foregroundStyle(color)
                .shadow(color: color, radius: 5)
                .offset(x: cos(angle) * 132, y: sin(angle) * 105)
                .scaleEffect(0.75 + abs(sin(phase * 3 + Double(index))) * 0.65)
                .opacity(0.45 + abs(sin(phase * 2.4 + Double(index))) * 0.55)
        }
    }

    private var sleepSymbols: some View {
        ForEach(0..<3, id: \.self) { index in
            let drift = (phase * 0.22 + Double(index) * 0.34).truncatingRemainder(dividingBy: 1)
            Text("Z")
                .font(.system(size: 12 + CGFloat(index) * 3, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.7), radius: 4)
                .offset(x: 78 + drift * 28, y: 24 - drift * 100)
                .opacity(1 - drift)
        }
    }
}
