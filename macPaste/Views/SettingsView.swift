import SwiftUI
import ServiceManagement

/// 设置视图
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("maxHistoryCount") private var maxHistoryCount = 500
    @AppStorage("maxImageCount") private var maxImageCount = 50
    @AppStorage("autoStart") private var autoStart = true

    @State private var cacheSize: String = "计算中..."
    @State private var isClearingCache = false

    var body: some View {
        Form {
            Section("支持的类型") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach([
                        ("纯文本", "doc.text", "任意文本内容"),
                        ("图片", "photo", "PNG/JPEG/GIF 等"),
                        ("链接", "link", "URL 网址"),
                        ("文件路径", "folder", "本地文件路径")
                    ], id: \.0) { item in
                        HStack {
                            Image(systemName: item.1)
                                .foregroundColor(.accentColor)
                                .frame(width: 24)
                            Text(item.0)
                                .font(.body)
                            Spacer()
                            Text(item.2)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section("常规") {
                Stepper("历史记录上限: \(maxHistoryCount)", value: $maxHistoryCount, in: 100...2000, step: 100)
                Stepper("图片保存上限: \(maxImageCount)", value: $maxImageCount, in: 10...200, step: 10)
                Toggle("开机自启动", isOn: $autoStart)
            }

            Section("缓存管理") {
                HStack {
                    Text("图片缓存大小")
                    Spacer()
                    Text(cacheSize)
                        .foregroundColor(.secondary)
                }

                Button {
                    clearImageCache()
                } label: {
                    HStack {
                        if isClearingCache {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("清除图片缓存")
                    }
                }
                .disabled(isClearingCache || cacheSize == "0 B")
            }

            Section("数据") {
                Button("清空历史记录", role: .destructive) {
                    ClipboardHistory.shared.clearHistory()
                    ClipboardHistory.shared.clearImageCache()
                }
            }

            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 420, height: 480)
        .onAppear {
            calculateCacheSize()
            syncAutoStartState()
        }
        .onChange(of: autoStart) { newValue in
            applyAutoStart(newValue)
        }
    }

    private func calculateCacheSize() {
        DispatchQueue.global(qos: .userInitiated).async {
            let imagesDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("macPaste/Images")

            if let enumerator = FileManager.default.enumerator(at: imagesDir, includingPropertiesForKeys: [.fileSizeKey]) {
                var totalSize: Int64 = 0
                for case let fileURL as URL in enumerator {
                    if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        totalSize += Int64(fileSize)
                    }
                }

                DispatchQueue.main.async {
                    cacheSize = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
                }
            } else {
                DispatchQueue.main.async {
                    cacheSize = "0 B"
                }
            }
        }
    }

    private func clearImageCache() {
        isClearingCache = true

        DispatchQueue.global(qos: .userInitiated).async {
            let imagesDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("macPaste/Images")

            try? FileManager.default.removeItem(at: imagesDir)
            try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)

            DispatchQueue.main.async {
                isClearingCache = false
                cacheSize = "0 B"
            }
        }
    }

    private func syncAutoStartState() {
        guard #available(macOS 13.0, *) else { return }
        let isEnabled = SMAppService.mainApp.status == .enabled
        if isEnabled != autoStart {
            autoStart = isEnabled
        }
    }

    private func applyAutoStart(_ enabled: Bool) {
        guard #available(macOS 13.0, *) else { return }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            autoStart.toggle()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
