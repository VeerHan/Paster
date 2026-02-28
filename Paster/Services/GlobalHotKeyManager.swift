import Foundation
import AppKit
import Carbon
import Carbon.HIToolbox

private func hotKeyEventHandler(_: EventHandlerCallRef?, _: EventRef?, _: UnsafeMutableRawPointer?) -> OSStatus {
    DispatchQueue.main.async {
        GlobalHotKeyManager.shared.onHotKey?()
    }
    return noErr
}

/// 全局快捷键管理器（Carbon API，无需辅助功能权限）
final class GlobalHotKeyManager {
    static let shared = GlobalHotKeyManager()

    /// 默认快捷键：Cmd+Shift+V
    private let keyCode: UInt32 = UInt32(kVK_ANSI_V)
    private let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
    private var hotKeyRef: EventHotKeyRef?
    private let signature: OSType = 0x50535452 // "PSTR"

    var onHotKey: (() -> Void)?

    private init() {}

    func register() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyEventHandler,
            1,
            &eventType,
            nil,
            nil
        )

        var hotKeyID = EventHotKeyID(signature: signature, id: 1)
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        if status != noErr {
            print("全局快捷键注册失败: \(status)")
        }
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
}
