import Foundation
import AppKit
import CryptoKit

/// 剪贴板内容类型（仅支持文本与图片）
enum ClipboardContentType: String, Codable, CaseIterable {
    case plainText = "plain_text"
    case image = "image"

    var displayName: String {
        switch self {
        case .plainText: return "文本"
        case .image: return "图片"
        }
    }

    var systemImage: String {
        switch self {
        case .plainText: return "doc.text"
        case .image: return "photo"
        }
    }
}

/// 剪贴板条目模型
struct ClipboardItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let contentType: ClipboardContentType
    let textContent: String?
    let imageData: Data?
    let createdAt: Date
    var isPinned: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var contentHash: String {
        switch contentType {
        case .plainText:
            return textContent ?? ""
        case .image:
            if let data = imageData {
                let digest = SHA256.hash(data: data)
                return digest.map { String(format: "%02x", $0) }.joined()
            }
            return ""
        }
    }

    init(
        id: UUID = UUID(),
        contentType: ClipboardContentType,
        textContent: String? = nil,
        imageData: Data? = nil,
        createdAt: Date = Date(),
        isPinned: Bool = false
    ) {
        self.id = id
        self.contentType = contentType
        self.textContent = textContent
        self.imageData = imageData
        self.createdAt = createdAt
        self.isPinned = isPinned
    }

    /// 从 NSPasteboard 创建剪贴板条目（仅文本和图片）
    static func fromPasteboard(_ pasteboard: NSPasteboard) -> ClipboardItem? {
        guard pasteboard.changeCount > 0 else { return nil }

        // 1. 检测图片
        if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage,
           let tiffData = image.tiffRepresentation,
           let pngData = NSBitmapImageRep(data: tiffData)?.representation(using: .png, properties: [:]) {
            return ClipboardItem(
                contentType: .image,
                imageData: pngData
            )
        }

        // 2. 检测文本（纯文本）
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            return ClipboardItem(
                contentType: .plainText,
                textContent: text
            )
        }

        return nil
    }

    /// 复制到剪贴板
    func copyToPasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch contentType {
        case .plainText:
            if let text = textContent {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let data = imageData,
               let image = NSImage(data: data) {
                pasteboard.writeObjects([image])
            }
        }
    }

    /// 获取预览文本
    var previewText: String {
        switch contentType {
        case .plainText:
            if let text = textContent {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                let normalized = trimmed.replacingOccurrences(of: "\r\n", with: "\n")
                let collapsed = normalized.replacingOccurrences(
                    of: "\n{2,}",
                    with: "\n",
                    options: .regularExpression
                )
                return String(collapsed.prefix(200))
            }
            return "(无文本)"
        case .image:
            return "[图片]"
        }
    }
}
