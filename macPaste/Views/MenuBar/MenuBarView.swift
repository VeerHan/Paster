import SwiftUI
import AppKit

/// 缩略图缓存，避免滚动时反复解码大图
private final class ThumbnailCache {
    static let shared = ThumbnailCache()
    private let cache = NSCache<NSString, NSImage>()

    private init() {
        cache.countLimit = 100
    }

    func thumbnail(for itemId: UUID, imageData: Data, maxSize: CGFloat = 160) -> NSImage? {
        let key = itemId.uuidString as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let source = NSImage(data: imageData) else { return nil }
        let originalSize = source.size
        guard originalSize.width > 0, originalSize.height > 0 else { return nil }

        let scale = min(maxSize / originalSize.width, maxSize / originalSize.height, 1.0)
        let targetSize = NSSize(width: originalSize.width * scale, height: originalSize.height * scale)

        let thumb = NSImage(size: targetSize)
        thumb.lockFocus()
        source.draw(in: NSRect(origin: .zero, size: targetSize),
                    from: NSRect(origin: .zero, size: originalSize),
                    operation: .copy, fraction: 1.0)
        thumb.unlockFocus()

        cache.setObject(thumb, forKey: key)
        return thumb
    }

    func evict(_ itemId: UUID) {
        cache.removeObject(forKey: itemId.uuidString as NSString)
    }

    func evictAll() {
        cache.removeAllObjects()
    }
}

/// 手势识别器包装器
struct SwipeGestureView: NSViewRepresentable {
    let onSwipeLeft: () -> Void
    let onSwipeProgress: (CGFloat) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        
        let panGesture = NSPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.allowedTouchTypes = .direct
        view.addGestureRecognizer(panGesture)
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onSwipeLeft = onSwipeLeft
        context.coordinator.onSwipeProgress = onSwipeProgress
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSwipeLeft: onSwipeLeft, onSwipeProgress: onSwipeProgress)
    }
    
    class Coordinator: NSObject {
        var onSwipeLeft: () -> Void
        var onSwipeProgress: (CGFloat) -> Void
        private var startLocation: NSPoint = .zero
        
        init(onSwipeLeft: @escaping () -> Void, onSwipeProgress: @escaping (CGFloat) -> Void) {
            self.onSwipeLeft = onSwipeLeft
            self.onSwipeProgress = onSwipeProgress
        }
        
        @objc func handlePan(_ gesture: NSPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)
            let velocity = gesture.velocity(in: gesture.view)
            
            switch gesture.state {
            case .began:
                startLocation = gesture.location(in: gesture.view)
            case .changed:
                // 只处理向左滑动
                if translation.x < 0 {
                    let horizontalDistance = abs(translation.x)
                    let verticalDistance = abs(translation.y)
                    
                    // 如果水平滑动占主导
                    if horizontalDistance > verticalDistance * 1.5 {
                        let progress = min(abs(translation.x) / 100.0, 1.0)
                        onSwipeProgress(-abs(translation.x))
                    }
                }
            case .ended, .cancelled:
                let horizontalDistance = abs(translation.x)
                let verticalDistance = abs(translation.y)
                
                // 如果向左滑动超过80像素且水平滑动占主导
                if translation.x < -80 && horizontalDistance > verticalDistance * 1.5 {
                    onSwipeLeft()
                } else {
                    onSwipeProgress(0)
                }
            default:
                break
            }
        }
    }
}

extension Notification.Name {
    static let panelDidShow = Notification.Name("panelDidShow")
}

/// 从外部关闭 Popover 的 Environment Key
private struct ClosePopoverKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

/// 选中条目后由外部统一处理（关面板+恢复焦点+粘贴）
private struct PasteAndCloseKey: EnvironmentKey {
    static let defaultValue: ((ClipboardItem) -> Void)? = nil
}

extension EnvironmentValues {
    var closePopover: (() -> Void)? {
        get { self[ClosePopoverKey.self] }
        set { self[ClosePopoverKey.self] = newValue }
    }
    var pasteAndClose: ((ClipboardItem) -> Void)? {
        get { self[PasteAndCloseKey.self] }
        set { self[PasteAndCloseKey.self] = newValue }
    }
}

/// 菜单栏弹出视图
struct MenuBarView: View {
    @EnvironmentObject var viewModel: ClipboardViewModel
    @Environment(\.closePopover) private var closePopover
    @Environment(\.pasteAndClose) private var pasteAndClose
    @Environment(\.colorScheme) private var colorScheme
    @State private var showSearch = false
    @State private var scrollToTopTrigger = UUID()
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            HStack {
                Text("Paster")
                    .font(.system(size: 15, weight: .semibold))
                Text("⌘⇧V")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(viewModel.history.items.count) 条")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                let hasItems = !viewModel.history.items.isEmpty

                // 搜索按钮
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if showSearch {
                            viewModel.searchText = ""
                        }
                        showSearch.toggle()
                    }
                } label: {
                    Image(systemName: showSearch ? "magnifyingglass.circle.fill" : "magnifyingglass")
                        .foregroundColor(hasItems ? (showSearch ? .accentColor : .secondary) : .secondary.opacity(0.4))
                }
                .buttonStyle(.plain)
                .disabled(!hasItems)
                .help(showSearch ? "关闭搜索" : "搜索")

                // 清空按钮
                Button {
                    ClipboardHistory.shared.clearHistory()
                    ClipboardHistory.shared.clearImageCache()
                    ThumbnailCache.shared.evictAll()
                    viewModel.searchText = ""
                    withAnimation(.easeInOut(duration: 0.2)) { showSearch = false }
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(hasItems ? .secondary : .secondary.opacity(0.4))
                }
                .buttonStyle(.plain)
                .disabled(!hasItems)
                .help("清空")

                // 退出按钮
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("退出")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            // 搜索框
            if showSearch {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("搜索...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .focused($isSearchFocused)

                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(colorScheme == .dark ? Color(white: 0.22) : Color(white: 0.90))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isSearchFocused = true
                    }
                }
            }

            Divider()

            // 剪贴板列表
            if viewModel.filteredItems.isEmpty {
                EmptyHistoryView()
                    .frame(height: 340)
            } else {
                ScrollViewReader { proxy in
                    let items = Array(viewModel.filteredItems.prefix(50))
                    List(items.indices, id: \.self) { index in
                        let item = items[index]
                        MenuBarItemRow(item: item) { itemToDelete in
                            ClipboardHistory.shared.deleteItem(itemToDelete)
                        }
                        .onTapGesture {
                            pasteAndClose?(item)
                        }
                        .padding(.top, index == 0 ? 4 : 0)
                        .padding(.bottom, index == items.count - 1 ? 4 : 0)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .id(item.id)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .frame(height: 340)
                    .onChange(of: scrollToTopTrigger) { _ in
                        if let firstId = items.first?.id {
                            proxy.scrollTo(firstId, anchor: .top)
                        }
                    }
                    .onChange(of: viewModel.filteredItems.first?.id) { _ in
                        if let firstId = items.first?.id {
                            withAnimation(.easeOut(duration: 0.15)) {
                                proxy.scrollTo(firstId, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 300)
        .background(.clear)
        .animation(.easeInOut(duration: 0.2), value: showSearch)
        .onReceive(NotificationCenter.default.publisher(for: .panelDidShow)) { _ in
            scrollToTopTrigger = UUID()
        }
    }

}

/// 空状态视图
struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text("暂无剪贴板历史")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("复制文本或图片即可开始")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 340)
        .contentShape(Rectangle())
    }
}

/// 菜单栏条目行 — 独立于 ViewModel，hover 不会触发列表重绘
struct MenuBarItemRow: View {
    let item: ClipboardItem
    let onDelete: (ClipboardItem) -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            TypeBadge(contentType: item.contentType)

            VStack(alignment: .leading, spacing: 2) {
                if item.contentType == .image, let imageData = item.imageData,
                   let thumb = ThumbnailCache.shared.thumbnail(for: item.id, imageData: imageData) {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 160, maxHeight: 80, alignment: .leading)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Text(item.previewText)
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                        .lineLimit(3, reservesSpace: false)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer()

            if !isHovered && item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .help("已固定")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .overlay(alignment: .topTrailing) {
            if isHovered {
                Button {
                    onDelete(item)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("删除")
                .padding(.top, 6)
                .padding(.trailing, 4)
            }
        }
        .background(isHovered ? Color(NSColor.selectedContentBackgroundColor).opacity(0.3) : (item.isPinned ? Color.orange.opacity(0.05) : Color.clear))
        .cornerRadius(6)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    MenuBarView()
        .environmentObject(ClipboardViewModel.shared)
        .frame(width: 320, height: 450)
}
