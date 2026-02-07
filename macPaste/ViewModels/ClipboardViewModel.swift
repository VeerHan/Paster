import Foundation
import Combine

/// 剪贴板视图模型
class ClipboardViewModel: ObservableObject {
    static let shared = ClipboardViewModel()

    @Published var searchText = ""
    @Published var selectedType: ClipboardContentType? = nil
    @Published var selectedItem: ClipboardItem? = nil
    @Published var isMenuBarVisible = false

    let history: ClipboardHistory

    private var cancellables = Set<AnyCancellable>()

    private init() {
        self.history = ClipboardHistory.shared
        setupNotifications()
        bindHistoryChanges()
    }

    // MARK: - 公开方法

    /// 过滤后的条目
    var filteredItems: [ClipboardItem] {
        history.searchItems(searchText, typeFilter: selectedType)
    }

    /// 按类型分组的条目
    var groupedItems: [(type: ClipboardContentType, items: [ClipboardItem])] {
        history.groupedItems()
    }

    /// 切换类型筛选
    func toggleTypeFilter(_ type: ClipboardContentType) {
        if selectedType == type {
            selectedType = nil
        } else {
            selectedType = type
        }
    }

    /// 复制条目到剪贴板
    func copyItem(_ item: ClipboardItem) {
        item.copyToPasteboard()
    }

    /// 删除条目
    func deleteItem(_ item: ClipboardItem) {
        history.deleteItem(item)
    }

    /// 删除多个条目
    func deleteItems(_ items: [ClipboardItem]) {
        history.deleteItems(items)
    }

    /// 清空历史记录
    func clearHistory() {
        history.clearHistory()
    }

    /// 切换固定状态
    func togglePin(for item: ClipboardItem) {
        history.togglePin(for: item)
    }

    /// 切换菜单栏可见性
    func toggleMenuBar() {
        isMenuBarVisible.toggle()
    }

    // MARK: - 私有方法

    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .clipboardDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    private func bindHistoryChanges() {
        history.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
