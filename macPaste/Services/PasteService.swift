import Foundation
import AppKit
import ApplicationServices

/// 辅助功能权限 + 粘贴工具
enum PasteService {
    /// 启动时调用：未授权则弹系统提示并打开设置页面
    static func requestAccessibilityIfNeeded() {
        if AXIsProcessTrusted() { return }
        // 触发系统弹窗
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
        // 同时直接打开系统设置的辅助功能页面，方便用户操作
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// 将条目粘贴到当前焦点应用的光标处（由 StatusBarManager 调用）
    static func pasteItemAtCursor(_ item: ClipboardItem) {
        item.copyToPasteboard()
        guard AXIsProcessTrusted() else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            simulateCmdV()
        }
    }

    private static func simulateCmdV() {
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
