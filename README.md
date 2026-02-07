# Paster - macOS 剪贴板历史管理器

<p align="center">
  <img src="macPaste/Resources/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="128" alt="Paster Icon">
</p>

<p align="center">
  <strong>轻量、美观的 macOS 菜单栏剪贴板历史工具</strong>
</p>

<p align="center">
  <a href="#功能特性">功能特性</a> •
  <a href="#系统要求">系统要求</a> •
  <a href="#安装与使用">安装与使用</a> •
  <a href="#构建">构建</a> •
  <a href="#贡献">贡献</a>
</p>

---

## 功能特性

- **📋 剪贴板监控**：自动记录复制到剪贴板的内容
- **📝 多种类型支持**：纯文本、富文本、图片、链接、文件路径
- **🔍 搜索**：快速搜索历史记录
- **📌 固定**：重要内容可固定到顶部
- **⚙️ 可配置**：历史数量、图片上限、开机自启动等
- **🗑️ 缓存管理**：支持清理图片缓存，节省磁盘空间
- **🚀 菜单栏常驻**：轻量运行，不占用 Dock 空间

## 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Apple Silicon 或 Intel 芯片

## 安装与使用

### 从 Release 安装

1. 前往 [Releases](https://github.com/YOUR_USERNAME/mac-paste/releases) 页面（将 `YOUR_USERNAME` 替换为你的 GitHub 用户名）
2. 下载最新版本的 `Paster.app.zip`
3. 解压后将 `Paster.app` 拖入「应用程序」文件夹
4. 首次运行时，在「系统设置 > 隐私与安全性 > 辅助功能」中授权访问

### 首次使用

1. 点击菜单栏的剪贴板图标打开 Paster
2. 复制任意文本或图片，内容会自动出现在历史列表中
3. 点击历史项即可再次复制到剪贴板
4. 使用搜索图标进行筛选，使用固定图标保留重要内容

## 构建

### 使用 Xcode

```bash
# 克隆仓库
git clone https://github.com/YOUR_USERNAME/mac-paste.git
cd mac-paste

# 使用 Xcode 打开项目
open Paster.xcodeproj
# 或
open 剪剪.xcodeproj
```

在 Xcode 中选择目标设备为「My Mac」，点击运行 (⌘R) 即可构建并运行。

### 使用命令行

```bash
xcodebuild -project Paster.xcodeproj -scheme Paster -configuration Release build
```

构建产物位于 `build/Build/Products/Release/Paster.app`。

### 使用 XcodeGen（可选）

项目包含 `project.yml`，可使用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 生成 Xcode 项目：

```bash
xcodegen generate
```

## 项目结构

```
mac-paste/
├── macPaste/
│   ├── App/           # 应用入口
│   ├── Models/        # 数据模型
│   ├── Services/      # 剪贴板监控、存储服务
│   ├── ViewModels/    # 视图逻辑
│   ├── Views/         # UI 视图
│   └── Resources/     # 资源、图标、配置
├── Paster.xcodeproj   # Xcode 项目
└── project.yml        # XcodeGen 配置
```

## 技术栈

- **SwiftUI** + **AppKit**：原生 macOS 界面
- **Swift 5.9**：现代 Swift 语言特性
- **Combine**：响应式数据流
- **ServiceManagement**：开机自启动（macOS 13+）

## 贡献

欢迎提交 Issue 和 Pull Request！请参阅 [CONTRIBUTING.md](CONTRIBUTING.md) 了解贡献指南。

## 开源协议

本项目采用 [MIT License](LICENSE) 开源协议。

---

<p align="center">
  Made with ♥ for macOS
</p>
