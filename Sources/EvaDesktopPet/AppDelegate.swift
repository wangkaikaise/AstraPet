import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = PetSettings()
    let reminderManager = ReminderManager()
    let runtime = PetRuntime()
    let systemMetrics = SystemMetricsMonitor()

    private var petPanel: NSPanel?
    private var settingsWindow: NSWindow?
    private var statusItem: NSStatusItem?
    private var settingsObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        createPetPanel()
        createStatusItem()
        Task { await reminderManager.synchronize(settings.reminders) }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let observer = settingsObserver { NotificationCenter.default.removeObserver(observer) }
    }

    private func createPetPanel() {
        let size = settings.size + 140
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1000, height: 700)
        let origin = NSPoint(x: screen.maxX - size - 24, y: screen.minY + 42)
        let panel = NSPanel(
            contentRect: NSRect(origin: origin, size: NSSize(width: size, height: size)),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.level = settings.keepOnTop ? .floating : .normal
        panel.hidesOnDeactivate = false
        panel.contentView = petHostingView()
        panel.orderFrontRegardless()
        petPanel = panel

        settings.$size.combineLatest(settings.$keepOnTop).sink { [weak self] size, keepOnTop in
            guard let panel = self?.petPanel else { return }
            let length = size + 140
            panel.setContentSize(NSSize(width: length, height: length))
            panel.level = keepOnTop ? .floating : .normal
        }.store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    private func petHostingView() -> NSView {
        let root = PetView()
            .environmentObject(settings)
            .environmentObject(runtime)
            .environmentObject(systemMetrics)
        let hostingView = NSHostingView(rootView: root)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        return hostingView
    }

    private func createStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Eva Desktop Pet")
        item.menu = buildMenu()
        statusItem = item
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(withTitle: "显示 / 隐藏 Eva", action: #selector(togglePet), keyEquivalent: "h").target = self
        let actions = NSMenuItem(title: "动作", action: nil, keyEquivalent: "")
        let actionMenu = NSMenu()
        for item in PetAction.allCases {
            let menuItem = NSMenuItem(title: item.title, action: #selector(selectAction(_:)), keyEquivalent: "")
            menuItem.representedObject = item.rawValue
            menuItem.target = self
            actionMenu.addItem(menuItem)
        }
        actions.submenu = actionMenu
        menu.addItem(actions)
        menu.addItem(.separator())
        menu.addItem(withTitle: "设置…", action: #selector(openSettings), keyEquivalent: ",").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出 Eva Desktop Pet", action: #selector(quit), keyEquivalent: "q").target = self
        return menu
    }

    @objc private func togglePet() {
        guard let panel = petPanel else { return }
        panel.isVisible ? panel.orderOut(nil) : panel.orderFrontRegardless()
    }

    @objc private func selectAction(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let selected = PetAction(rawValue: raw) else { return }
        runtime.action = selected
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let view = SettingsView()
                .environmentObject(settings)
                .environmentObject(reminderManager)
                .environmentObject(runtime)
                .environmentObject(systemMetrics)
            let window = NSWindow(contentViewController: NSHostingController(rootView: view))
            window.title = "Eva Desktop Pet 设置"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func quit() { NSApp.terminate(nil) }
}
