import SwiftUI
import AppKit

/// 应用入口
class ApplicationDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct ClipperApp: App {
    @NSApplicationDelegateAdaptor(ApplicationDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var clipboardMonitor = ClipboardMonitor.shared
    @StateObject private var viewModel = ClipboardViewModel.shared

    var body: some Scene {
        MenuBarExtra("Paster", systemImage: "doc.on.clipboard") {
            MenuBarView()
                .environmentObject(appState)
                .environmentObject(viewModel)
        }
        .menuBarExtraStyle(.window)

    }
}

class AppState: ObservableObject {
    @Published var showSettings = false
    @Published var isMonitoring = false

    init() {
        isMonitoring = true
        ClipboardMonitor.shared.startMonitoring()
    }
}
