import Foundation
import AppKit

/// 本地存储服务
class StorageService {
    private let fileManager = FileManager.default
    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    // 存储路径
    private var applicationSupportDirectory: URL {
        let paths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("macPaste", isDirectory: true)
    }

    private var historyFileURL: URL {
        applicationSupportDirectory.appendingPathComponent("history.json")
    }

    private var imagesDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("Images", isDirectory: true)
    }

    init() {
        createDirectoriesIfNeeded()
    }

    // MARK: - 历史记录存储

    /// 保存历史记录
    func saveHistory(_ items: [ClipboardItem]) {
        do {
            var historyItems: [ClipboardItem] = []
            for item in items {
                if item.contentType == .image, let imageData = item.imageData {
                    // 保存图片到磁盘
                    _ = saveImageToDisk(imageData, for: item.id)
                    // 保存不含图片数据的条目
                    let itemWithoutImage = ClipboardItem(
                        id: item.id,
                        contentType: .image,
                        textContent: item.textContent,
                        htmlContent: item.htmlContent,
                        imageData: nil,
                        url: item.url,
                        filePath: item.filePath,
                        createdAt: item.createdAt,
                        isPinned: item.isPinned
                    )
                    historyItems.append(itemWithoutImage)
                } else {
                    historyItems.append(item)
                }
            }

            let data = try encoder.encode(historyItems)
            try data.write(to: historyFileURL, options: .atomic)
        } catch {
            print("保存历史记录失败: \(error)")
        }
    }

    /// 加载历史记录
    func loadHistory() -> [ClipboardItem] {
        guard fileManager.fileExists(atPath: historyFileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: historyFileURL)
            var items = try decoder.decode([ClipboardItem].self, from: data)

            // 加载图片数据
            for i in items.indices where items[i].contentType == .image {
                if let imageData = loadImageFromDisk(for: items[i].id) {
                    items[i] = ClipboardItem(
                        id: items[i].id,
                        contentType: .image,
                        textContent: items[i].textContent,
                        htmlContent: items[i].htmlContent,
                        imageData: imageData,
                        url: items[i].url,
                        filePath: items[i].filePath,
                        createdAt: items[i].createdAt,
                        isPinned: items[i].isPinned
                    )
                }
            }

            return items
        } catch {
            print("加载历史记录失败: \(error)")
            return []
        }
    }

    // MARK: - 图片存储

    /// 保存图片到磁盘
    private func saveImageToDisk(_ data: Data, for itemId: UUID) -> Bool {
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            do {
                try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            } catch {
                print("创建图片目录失败: \(error)")
                return false
            }
        }

        let imageURL = imagesDirectory.appendingPathComponent(itemId.uuidString + ".png")

        do {
            try data.write(to: imageURL)
            return true
        } catch {
            print("保存图片失败: \(error)")
            return false
        }
    }

    /// 从磁盘加载图片
    private func loadImageFromDisk(for itemId: UUID) -> Data? {
        let imageURL = imagesDirectory.appendingPathComponent(itemId.uuidString + ".png")

        guard fileManager.fileExists(atPath: imageURL.path) else {
            return nil
        }

        return try? Data(contentsOf: imageURL)
    }

    /// 删除图片
    func deleteImage(for itemId: UUID) {
        let imageURL = imagesDirectory.appendingPathComponent(itemId.uuidString + ".png")

        if fileManager.fileExists(atPath: imageURL.path) {
            try? fileManager.removeItem(at: imageURL)
        }
    }

    /// 清空图片缓存
    func clearImageCache() {
        if fileManager.fileExists(atPath: imagesDirectory.path) {
            try? fileManager.removeItem(at: imagesDirectory)
        }
        try? fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
    }

    // MARK: - 私有方法

    private func createDirectoriesIfNeeded() {
        if !fileManager.fileExists(atPath: applicationSupportDirectory.path) {
            try? fileManager.createDirectory(at: applicationSupportDirectory, withIntermediateDirectories: true)
        }
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            try? fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        }
    }
}
