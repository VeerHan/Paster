import SwiftUI

/// 预览卡片组件
struct PreviewCard<Content: View>: View {
    let title: String?
    let systemImage: String?
    @ViewBuilder let content: () -> Content

    init(title: String? = nil, systemImage: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                HStack {
                    if let image = systemImage {
                        Image(systemName: image)
                            .foregroundColor(.secondary)
                    }
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }

            content()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

/// 文本预览卡片
struct TextPreviewCard: View {
    let text: String
    let maxLines: Int

    init(_ text: String, maxLines: Int = 3) {
        self.text = text
        self.maxLines = maxLines
    }

    var body: some View {
        Text(text)
            .font(.body)
            .foregroundColor(.primary)
            .lineLimit(maxLines)
            .textSelection(.enabled)
    }
}

/// URL 预览卡片
struct URLPreviewCard: View {
    let url: URL

    var body: some View {
        HStack {
            Image(systemName: "link")
                .foregroundColor(.cyan)
            Text(url.absoluteString)
                .font(.body)
                .foregroundColor(.cyan)
                .lineLimit(1)
            Spacer()
        }
        .padding()
        .background(Color.cyan.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 16) {
        PreviewCard(title: "文本内容", systemImage: "doc.text") {
            TextPreviewCard("这是一段测试文本，用于展示预览卡片的效果。")
        }

        PreviewCard(systemImage: "link") {
            URLPreviewCard(url: URL(string: "https://www.apple.com/cn/")!)
        }

        PreviewCard(title: "图片") {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.purple.opacity(0.3))
                .frame(height: 100)
                .overlay {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.purple)
                }
        }
    }
    .padding()
}
