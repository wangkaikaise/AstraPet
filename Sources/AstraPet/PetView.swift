import SwiftUI

struct PetView: View {
    @EnvironmentObject private var settings: PetSettings
    @Binding var action: PetAction
    @State private var animated = false
    @State private var message: String?
    @State private var tapCount = 0

    private var duration: Double { max(0.45, 1.7 / settings.animationSpeed) }

    var body: some View {
        ZStack(alignment: .top) {
            if let message {
                Text(message)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(settings.theme.color.opacity(0.45)))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .offset(y: -2)
            }

            Image(nsImage: RobotAsset.image)
                .resizable()
                .scaledToFit()
                .frame(width: settings.size, height: settings.size)
                .opacity(settings.opacity)
                .shadow(color: settings.theme.color.opacity(animated ? 0.75 : 0.25), radius: animated ? 22 : 8)
                .scaleEffect(scale)
                .rotationEffect(rotation)
                .offset(x: xOffset, y: yOffset + 28)
                .saturation(action == .sleep ? 0.35 : 1)
                .onTapGesture { interact() }
                .contextMenu {
                    ForEach(PetAction.allCases) { item in
                        Button { action = item } label: {
                            Label(item.title, systemImage: item.symbol)
                        }
                    }
                }
                .help("点击和 Astra 互动；拖动可移动位置")
        }
        .frame(width: settings.size + 54, height: settings.size + 66)
        .contentShape(Rectangle())
        .onAppear { startAnimation() }
        .onChange(of: action) { _ in startAnimation() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("桌面宠物 Astra，当前动作：\(action.title)")
        .accessibilityAddTraits(.isButton)
    }

    private var scale: CGFloat {
        switch action {
        case .idle: animated ? 1.025 : 0.99
        case .hover: animated ? 1.04 : 0.98
        case .cheer: animated ? 1.12 : 0.94
        case .sleep: animated ? 0.97 : 0.93
        }
    }

    private var rotation: Angle {
        switch action {
        case .idle, .sleep: .degrees(animated ? 1.5 : -1.5)
        case .hover: .degrees(animated ? 5 : -5)
        case .cheer: .degrees(animated ? 8 : -8)
        }
    }

    private var xOffset: CGFloat { action == .cheer ? (animated ? 8 : -8) : 0 }
    private var yOffset: CGFloat {
        switch action {
        case .hover: animated ? -11 : 8
        case .cheer: animated ? -15 : 6
        case .idle: animated ? -4 : 4
        case .sleep: animated ? 5 : 9
        }
    }

    private func startAnimation() {
        animated = false
        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
            animated = true
        }
        show(action == .sleep ? "进入低功耗模式…" : "\(action.title)模式已启动")
    }

    private func interact() {
        tapCount += 1
        action = .cheer
        let messages = ["我在！", "今天也一起加油。", "收到你的信号啦。", "需要提醒时叫我。"]
        show(messages[tapCount % messages.count])
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if action == .cheer { action = .idle }
        }
    }

    private func show(_ text: String) {
        withAnimation { message = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if message == text { withAnimation { message = nil } }
        }
    }
}
