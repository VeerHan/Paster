import SwiftUI

/// 内容类型徽章
struct TypeBadge: View {
    let contentType: ClipboardContentType

    var body: some View {
        Image(systemName: contentType.systemImage)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(iconColor)
            .frame(width: 24, height: 24)
            .background(backgroundColor)
            .cornerRadius(6)
    }

    private var iconColor: Color {
        switch contentType {
        case .plainText: return .blue
        case .richText: return .green
        case .image: return .purple
        case .url: return .cyan
        case .filePath: return .orange
        }
    }

    private var backgroundColor: Color {
        switch contentType {
        case .plainText: return .blue.opacity(0.15)
        case .richText: return .green.opacity(0.15)
        case .image: return .purple.opacity(0.15)
        case .url: return .cyan.opacity(0.15)
        case .filePath: return .orange.opacity(0.15)
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        ForEach(ClipboardContentType.allCases, id: \.self) { type in
            TypeBadge(contentType: type)
        }
    }
    .padding()
}
