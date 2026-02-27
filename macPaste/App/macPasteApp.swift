import SwiftUI
import AppKit

/// 应用入口
class ApplicationDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        ClipboardMonitor.shared.startMonitoring()
        StatusBarManager.shared.setup()
        // 启动时一次性请求辅助功能权限，避免点击条目时反复弹窗
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            PasteService.requestAccessibilityIfNeeded()
        }
    }
}

@main
struct ClipperApp: App {
    @NSApplicationDelegateAdaptor(ApplicationDelegate.self) var appDelegate

    var body: some Scene {
        // 主界面由状态栏图标 + 全局快捷键 Cmd+Shift+V 唤起（StatusBarManager）
        WindowGroup {
            EmptyView()
                .frame(width: 0, height: 0)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 0, height: 0)
        .commandsRemoved()
    }
}
