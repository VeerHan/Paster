import SwiftUI
import AppKit

/// 状态栏图标 + 面板管理（支持点击图标与全局快捷键唤起）
final class StatusBarManager: NSObject {
    static let shared = StatusBarManager()

    private var statusItem: NSStatusItem?
    private var panel: NSPanel?
    private var eventMonitor: Any?
    private let viewModel = ClipboardViewModel.shared
    private var previousApp: NSRunningApplication?

    private var isShown: Bool { panel?.isVisible == true }

    private override init() {
        super.init()
    }

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Paster")
        button.action = #selector(togglePopover)
        button.target = self

        let hostingView = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(viewModel)
                .environment(\.closePopover) { [weak self] in
                    self?.closePopover()
                }
                .environment(\.pasteAndClose) { [weak self] item in
                    self?.handleItemSelected(item)
                }
        )

        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 420),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        p.isFloatingPanel = true
        p.level = .popUpMenu
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.contentViewController = hostingView
        p.isMovableByWindowBackground = false
        p.hidesOnDeactivate = false

        // 毛玻璃背景 + 圆角
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .popover
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 12
        visualEffect.layer?.masksToBounds = true
        p.contentView = visualEffect

        hostingView.view.translatesAutoresizingMaskIntoConstraints = false
        visualEffect.addSubview(hostingView.view)
        NSLayoutConstraint.activate([
            hostingView.view.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hostingView.view.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            hostingView.view.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hostingView.view.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
        ])

        self.panel = p

        GlobalHotKeyManager.shared.onHotKey = { [weak self] in
            self?.togglePopover()
        }
        GlobalHotKeyManager.shared.register()
    }

    @objc private func togglePopover() {
        if isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem?.button, let panel = panel else { return }
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           frontmost.bundleIdentifier != Bundle.main.bundleIdentifier {
            previousApp = frontmost
        }

        // 计算面板位置：紧贴状态栏按钮下方居中
        let buttonRect = button.window!.convertToScreen(button.convert(button.bounds, to: nil))
        let panelWidth: CGFloat = 300
        let panelHeight: CGFloat = 420
        let x = buttonRect.minX
        let y = buttonRect.minY - panelHeight - 4
        panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        startEventMonitor()
    }

    private func closePopover() {
        panel?.orderOut(nil)
        stopEventMonitor()
        restoreFocus()
    }

    /// 点击面板外部时自动关闭
    private func startEventMonitor() {
        stopEventMonitor()
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.isShown else { return }
            self.closePopover()
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    /// 选中条目后的完整流程：关面板 → 恢复焦点 → 写剪贴板 → 模拟粘贴
    private func handleItemSelected(_ item: ClipboardItem) {
        panel?.orderOut(nil)
        stopEventMonitor()

        // 暂停剪贴板监控，避免我们自己写入剪贴板被当成新条目
        ClipboardMonitor.shared.stopMonitoring()

        let targetApp = previousApp
        previousApp = nil

        // 先恢复焦点到原应用
        if let app = targetApp {
            app.activate(options: [.activateIgnoringOtherApps])
        }

        // 等焦点切换完成后再写剪贴板并模拟粘贴
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            item.copyToPasteboard()

            if AXIsProcessTrusted() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    Self.simulatePaste()
                    // 恢复剪贴板监控
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        ClipboardMonitor.shared.startMonitoring()
                    }
                }
            } else {
                ClipboardMonitor.shared.startMonitoring()
            }
        }
    }

    private func restoreFocus() {
        if let app = previousApp {
            app.activate(options: [.activateIgnoringOtherApps])
        }
        previousApp = nil
    }

    private static func simulatePaste() {
        guard let src = CGEventSource(stateID: .hidSystemState) else { return }
        let vDown = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true)
        let vUp = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false)
        vDown?.flags = .maskCommand
        vUp?.flags = .maskCommand
        let loc = CGEventTapLocation.cghidEventTap
        vDown?.post(tap: loc)
        vUp?.post(tap: loc)
    }
}
