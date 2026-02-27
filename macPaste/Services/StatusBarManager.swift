import SwiftUI
import AppKit

/// 状态栏图标 + Popover 管理（支持点击图标与全局快捷键唤起）
final class StatusBarManager: NSObject {
    static let shared = StatusBarManager()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let viewModel = ClipboardViewModel.shared
    private var previousApp: NSRunningApplication?

    private override init() {
        super.init()
    }

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Paster")
        button.action = #selector(togglePopover)
        button.target = self

        let pop = NSPopover()
        pop.contentSize = NSSize(width: 300, height: 420)
        pop.behavior = .transient
        pop.animates = true
        pop.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(viewModel)
                .environment(\.closePopover) { [weak self] in
                    self?.closePopover()
                }
                .environment(\.pasteAndClose) { [weak self] item in
                    self?.handleItemSelected(item)
                }
        )
        self.popover = pop

        GlobalHotKeyManager.shared.onHotKey = { [weak self] in
            self?.togglePopover()
        }
        GlobalHotKeyManager.shared.register()
    }

    @objc private func togglePopover() {
        if popover?.isShown == true {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           frontmost.bundleIdentifier != Bundle.main.bundleIdentifier {
            previousApp = frontmost
        }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func closePopover() {
        popover?.close()
        restoreFocus()
    }

    /// 选中条目后的完整流程：关面板 → 恢复焦点 → 写剪贴板 → 模拟粘贴
    private func handleItemSelected(_ item: ClipboardItem) {
        popover?.close()

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
