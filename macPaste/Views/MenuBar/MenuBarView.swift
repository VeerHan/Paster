import SwiftUI
import AppKit

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

/// 菜单栏弹出视图
struct MenuBarView: View {
    @EnvironmentObject var viewModel: ClipboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSearch = false

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            HStack {
                Image(systemName: "doc.on.clipboard.fill")
                    .foregroundColor(.accentColor)
                Text("Paster")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Text("\(viewModel.history.items.count) 条")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                // 搜索按钮
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSearch.toggle()
                    }
                } label: {
                    Image(systemName: showSearch ? "magnifyingglass.circle.fill" : "magnifyingglass")
                        .foregroundColor(showSearch ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help(showSearch ? "关闭搜索" : "搜索")

                // 清空按钮
                Button {
                    ClipboardHistory.shared.clearHistory()
                    ClipboardHistory.shared.clearImageCache()
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
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
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()

            // 剪贴板列表
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if viewModel.filteredItems.isEmpty {
                        EmptyHistoryView()
                    } else {
                        ForEach(viewModel.filteredItems.prefix(100)) { item in
                            MenuBarItemRow(item: item)
                                .environmentObject(viewModel)
                                .onTapGesture {
                                    viewModel.copyItem(item)
                                    dismiss()
                                }
                        }
                    }
                }
            }
            .frame(height: 340)
        }
        .frame(width: 300)
        .background(.ultraThinMaterial)
        .animation(.easeInOut(duration: 0.2), value: showSearch)
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
                .foregroundColor(.gray.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 40)
        .padding(.leading, 20)
    }
}

/// 菜单栏条目行
struct MenuBarItemRow: View {
    let item: ClipboardItem
    @EnvironmentObject var viewModel: ClipboardViewModel
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // 类型图标
            TypeBadge(contentType: item.contentType)
                .frame(width: 28, height: 28)

            // 内容预览
            VStack(alignment: .leading, spacing: 2) {
                if item.contentType == .image, let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
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

            if isHovered {
                Button {
                    ClipboardHistory.shared.deleteItem(item)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("删除")
                .padding(.trailing, 8)
            } else if item.isPinned {
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
