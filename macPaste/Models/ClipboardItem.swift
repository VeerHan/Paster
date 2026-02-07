import Foundation
import AppKit
import CryptoKit

/// 剪贴板内容类型
enum ClipboardContentType: String, Codable, CaseIterable {
    case plainText = "plain_text"
    case richText = "rich_text"
    case image = "image"
    case url = "url"
    case filePath = "file_path"

    var displayName: String {
        switch self {
        case .plainText: return "文本"
        case .richText: return "文本"
        case .image: return "图片"
        case .url: return "文本"
        case .filePath: return "文本"
        }
    }

    var systemImage: String {
        switch self {
        case .plainText: return "doc.text"
        case .richText: return "doc.text"
        case .image: return "photo"
        case .url: return "doc.text"
        case .filePath: return "doc.text"
        }
    }
}

/// 剪贴板条目模型
struct ClipboardItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let contentType: ClipboardContentType
    let textContent: String?
    let htmlContent: String?
    let imageData: Data?
    let url: URL?
    let filePath: String?
    let createdAt: Date
    var isPinned: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // 用于比较的哈希值
    var contentHash: String {
        switch contentType {
        case .plainText:
            return textContent ?? ""
        case .richText:
            return htmlContent ?? textContent ?? ""
        case .image:
            if let data = imageData {
                let digest = SHA256.hash(data: data)
                return digest.map { String(format: "%02x", $0) }.joined()
            }
            return ""
        case .url:
            return url?.absoluteString ?? ""
        case .filePath:
            return filePath ?? ""
        }
    }

    init(
        id: UUID = UUID(),
        contentType: ClipboardContentType,
        textContent: String? = nil,
        htmlContent: String? = nil,
        imageData: Data? = nil,
        url: URL? = nil,
        filePath: String? = nil,
        createdAt: Date = Date(),
        isPinned: Bool = false
    ) {
        self.id = id
        self.contentType = contentType
        self.textContent = textContent
        self.htmlContent = htmlContent
        self.imageData = imageData
        self.url = url
        self.filePath = filePath
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
        case .plainText, .richText, .url, .filePath:
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
        case .plainText, .richText, .url, .filePath:
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

/// HTML 标签去除扩展
extension String {
    func strippingHTMLTags() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        if let attributedString = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
        ) {
            return attributedString.string
        }
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}
