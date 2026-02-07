import Foundation
import AppKit

/// 剪贴板监控服务
class ClipboardMonitor: ObservableObject {
    static let shared = ClipboardMonitor()

    @Published private(set) var isMonitoring = false
    @Published private(set) var lastChangeCount: Int = 0

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
        lastChangeCount = changeCount
        lastChangeAt = Date()
        currentInterval = activeInterval

        // 使用 GCD 定时器：更省电，允许系统合并唤醒
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.setEventHandler { [weak self] in
            self?.checkForChanges()
        }
        timer.schedule(deadline: .now(), repeating: currentInterval, leeway: .milliseconds(150))
        timer.resume()
        self.timer = timer

        // 立即检查一次
        checkForChanges()
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
            lastChangeCount = currentChangeCount
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
        guard let item = ClipboardItem.fromPasteboard(pasteboard) else {
            return
        }

        ClipboardHistory.shared.addItem(item)

        // 发送通知（用于 UI 更新）
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .clipboardDidChange,
                object: item
            )
        }
    }
}

// MARK: - 通知名称

extension Notification.Name {
    static let clipboardDidChange = Notification.Name("clipboardDidChange")
}
