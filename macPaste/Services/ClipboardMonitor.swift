import Foundation
import AppKit

/// 剪贴板监控服务
class ClipboardMonitor: ObservableObject {
    static let shared = ClipboardMonitor()

    private(set) var isMonitoring = false

    private let pasteboard = NSPasteboard.general
    private var timer: DispatchSourceTimer?
    private var changeCount: Int = 0
    private let queue = DispatchQueue(label: "com.paster.clipboard", qos: .utility)
    private let idleInterval: TimeInterval = 2.0
    private let activeInterval: TimeInterval = 0.5
    private let idleAfterSeconds: TimeInterval = 8.0
    private var lastChangeAt: Date = Date()
    private var currentInterval: TimeInterval = 1.0

    private init() {
        self.changeCount = pasteboard.changeCount
        self.lastChangeAt = Date()
        self.currentInterval = idleInterval
    }

    // MARK: - 公开方法

    /// 开始监控剪贴板
    func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        changeCount = pasteboard.changeCount
        lastChangeAt = Date()
        currentInterval = activeInterval

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.setEventHandler { [weak self] in
            self?.checkForChanges()
        }
        timer.schedule(deadline: .now(), repeating: currentInterval, leeway: .milliseconds(150))
        timer.resume()
        self.timer = timer
    }

    /// 停止监控剪贴板
    func stopMonitoring() {
        timer?.cancel()
        timer = nil
        isMonitoring = false
    }

    // MARK: - 私有方法

    private func checkForChanges() {
        let currentChangeCount = pasteboard.changeCount

        if currentChangeCount != changeCount {
            changeCount = currentChangeCount
            lastChangeAt = Date()
            updateTimerIntervalIfNeeded()
            handlePasteboardChange()
        } else {
            updateTimerIntervalIfNeeded()
        }
    }

    private func updateTimerIntervalIfNeeded() {
        guard let timer else { return }

        let timeSinceChange = Date().timeIntervalSince(lastChangeAt)
        let targetInterval: TimeInterval = timeSinceChange >= idleAfterSeconds ? idleInterval : activeInterval

        guard targetInterval != currentInterval else { return }
        currentInterval = targetInterval
        timer.schedule(deadline: .now() + currentInterval, repeating: currentInterval, leeway: .milliseconds(250))
    }

    private func handlePasteboardChange() {
        let pb = pasteboard
        DispatchQueue.main.async {
            guard let item = ClipboardItem.fromPasteboard(pb) else { return }
            ClipboardHistory.shared.addItem(item)
        }
    }
}
