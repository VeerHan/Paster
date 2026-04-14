import Foundation

/// 剪贴板历史记录管理
class ClipboardHistory: ObservableObject {
    static let shared = ClipboardHistory()
    private enum Limits {
        static let maxHistoryCount = 500
        static let maxImageCount = 50
    }

    @Published private(set) var items: [ClipboardItem] = []
    @Published var pinnedItems: [ClipboardItem] = []
    private var imageCount = 0

    private let storageService: StorageService

    private init() {
        self.storageService = StorageService()
        loadHistory()
        applyLimitsAndSaveIfNeeded()
    }

    // MARK: - 公开方法

    /// 添加剪贴板条目
    func addItem(_ item: ClipboardItem) {
        // 检查是否重复
        if isDuplicate(item) {
            return
        }

        // 检查图片数量限制
        if item.contentType == .image {
            imageCount += 1
            if imageCount > Limits.maxImageCount {
                removeOldestImage()
            }
        }

        items.insert(item, at: 0)

        applyLimitsAndSaveIfNeeded()
    }

    /// 删除单个条目
    func deleteItem(_ item: ClipboardItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            if items[index].contentType == .image {
                imageCount -= 1
                storageService.deleteImage(for: items[index].id)
            }
            items.remove(at: index)
            saveHistory()
        }
    }

    /// 删除多个条目
    func deleteItems(_ itemsToDelete: [ClipboardItem]) {
        for item in itemsToDelete {
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                if items[index].contentType == .image {
                    imageCount -= 1
                    storageService.deleteImage(for: items[index].id)
                }
            }
        }
        items.removeAll { item in
            itemsToDelete.contains { $0.id == item.id }
        }
        saveHistory()
    }

    /// 清空历史记录（保留固定条目）
    func clearHistory() {
        let unpinnedItems = items.filter { !$0.isPinned }
        for item in unpinnedItems {
            if item.contentType == .image {
                imageCount -= 1
                storageService.deleteImage(for: item.id)
            }
        }
        items.removeAll { !$0.isPinned }
        saveHistory()
    }

    /// 清空图片缓存
    func clearImageCache() {
        storageService.clearImageCache()
    }

    /// 切换固定状态
    func togglePin(for item: ClipboardItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isPinned.toggle()
            saveHistory()
        }
    }

    /// 搜索条目
    func searchItems(_ query: String, typeFilter: ClipboardContentType? = nil) -> [ClipboardItem] {
        let filtered = typeFilter != nil ? items.filter { $0.contentType == typeFilter! } : items

        if query.isEmpty {
            let pinned = filtered.filter { $0.isPinned }
            let normal = filtered.filter { !$0.isPinned }
            return pinned + normal
        }

        let searched = filtered.filter { item in
            item.previewText.localizedCaseInsensitiveContains(query) ||
            item.contentType.displayName.localizedCaseInsensitiveContains(query)
        }
        let pinned = searched.filter { $0.isPinned }
        let normal = searched.filter { !$0.isPinned }
        return pinned + normal
    }

    /// 获取按类型分组的条目
    func groupedItems() -> [(type: ClipboardContentType, items: [ClipboardItem])] {
        return Dictionary(grouping: items, by: { $0.contentType })
            .map { (type: $0.key, items: $0.value) }
            .sorted { $0.type.rawValue < $1.type.rawValue }
    }

    // MARK: - 私有方法

    private func isDuplicate(_ item: ClipboardItem) -> Bool {
        return items.contains { $0.contentHash == item.contentHash }
    }

    private func removeOldestImage() {
        if let index = items.lastIndex(where: { $0.contentType == .image }) {
            let removed = items.remove(at: index)
            imageCount -= 1
            storageService.deleteImage(for: removed.id)
        }
    }

    private func applyLimitsAndSaveIfNeeded() {
        let originalItemCount = items.count
        let originalImageCount = imageCount

        while items.count > Limits.maxHistoryCount {
            let removed = items.removeLast()
            if removed.contentType == .image {
                imageCount -= 1
                storageService.deleteImage(for: removed.id)
            }
        }

        while imageCount > Limits.maxImageCount {
            removeOldestImage()
        }

        if items.count != originalItemCount || imageCount != originalImageCount {
            saveHistory()
        } else if originalItemCount > 0 {
            saveHistory()
        }
    }

    private func saveHistory() {
        storageService.saveHistory(items)
    }

    private func loadHistory() {
        items = storageService.loadHistory()
        imageCount = items.filter { $0.contentType == .image }.count
    }
}
