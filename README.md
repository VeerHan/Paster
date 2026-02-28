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
- **📝 文本与图片**：仅支持纯文本和图片，界面与逻辑更专注
- **🖱️ 一键粘贴到光标**：点击历史条目后，自动关闭面板、恢复焦点，并在**当前应用光标处粘贴**，无需再按 Cmd+V
- **⌘⇧V 全局快捷键**：任意界面按 **Cmd+Shift+V** 唤起/关闭 Popover，再按一次即关闭
- **🔍 搜索**：快速搜索历史记录
- **📌 固定**：常用条目可固定，清空时保留
- **🗑️ 清空历史**：清空时自动清理图片缓存，节省磁盘空间
- **🚀 菜单栏常驻**：状态栏图标 + NSPopover，不占用 Dock 空间

## 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Apple Silicon 或 Intel 芯片

## 安装与使用

### 从 Release 安装

1. 前往 [Releases](https://github.com/VeerHan/Paster/releases) 页面（将 `VeerHan` 替换为你的 GitHub 用户名）
2. 下载最新版本的 `Paster-*.dmg` 或 `Paster.app.zip`
3. 打开 DMG 后将 `Paster.app` 拖入「应用程序」文件夹（或解压 zip 后拖入）
4. **首次运行**：若需「点击条目自动粘贴」功能，请在「系统设置 > 隐私与安全性 > 辅助功能」中为 Paster **开启**授权（应用启动时会提示并打开该页面）

### 使用方式

1. **唤起面板**：点击菜单栏的剪贴板图标，或按 **⌘⇧V**
2. **关闭面板**：再次按 **⌘⇧V**，或点击面板外区域
3. **选择并粘贴**：点击某条历史 → 面板关闭、焦点回到原应用 → 内容自动粘贴到光标处
4. **搜索**：点击顶部搜索图标，输入关键词筛选
5. **固定/删除**：鼠标悬停条目可固定或删除

## 构建

### 使用 Xcode

```bash
# 克隆仓库
git clone https://github.com/VeerHan/Paster.git
cd Paster

# 使用 Xcode 打开项目
open Paster.xcodeproj
```

在 Xcode 中选择目标设备为「My Mac」，点击运行 (⌘R) 即可构建并运行。

### 使用命令行

```bash
xcodebuild -scheme macPaste -configuration Release -derivedDataPath build build
```

构建产物位于 `build/Build/Products/Release/Paster.app`。

### 打包分发（DMG）

在项目根目录执行：

```bash
./scripts/build-release.sh
```

会在 `dist/` 下生成：
- **Paster-1.0.0.dmg**：标准 macOS 安装镜像，双击后把 Paster 拖到 Applications 即可

支持 **macOS 13.0 (Ventura) 及以上**，同时兼容 **Apple Silicon (M1/M2/M3/M4)** 和 **Intel** 芯片。

对方首次运行若提示「无法打开」或「来自未识别的开发者」，在「系统设置 > 隐私与安全性」中点击「仍要打开」即可（未公证的应用会如此提示）。

### 使用 XcodeGen（可选）

项目包含 `project.yml`，可使用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 生成 Xcode 项目：

```bash
xcodegen generate
```

## 项目结构

```
Paster/
├── macPaste/
│   ├── App/           # 应用入口
│   ├── Models/        # 数据模型（ClipboardItem、ClipboardHistory）
│   ├── Services/      # 剪贴板监控、存储、粘贴服务、状态栏与全局热键
│   ├── ViewModels/    # 视图逻辑
│   ├── Views/         # UI 视图（Popover 内容、组件）
│   └── Resources/     # 资源、图标、配置
├── Paster.xcodeproj   # Xcode 项目
└── project.yml        # XcodeGen 配置
```

## 技术栈

- **SwiftUI** + **AppKit**：原生 macOS 界面，状态栏 Popover（NSPopover）
- **Carbon**：全局快捷键 ⌘⇧V（RegisterEventHotKey）
- **CGEvent**：模拟 Cmd+V 实现「粘贴到光标」
- **Combine**：响应式数据流
- **辅助功能 (Accessibility)**：自动粘贴需在系统设置中授权一次

## 常见问题

### 覆盖安装后为何又弹出「辅助功能访问」？自动粘贴失效怎么办？

**原因**：macOS 的辅助功能权限是按**应用的身份（代码签名）**记录的。当前项目若未设置 **Development Team**（`DEVELOPMENT_TEAM` 为空），每次构建会使用「临时签名」，**每次编译出的可执行文件签名都不同**。覆盖安装后，系统会认为这是「另一个应用」，之前授予的权限不会套用，所以会再次弹窗，且自动粘贴会失效。

**解决办法**：

1. **开发/自用构建（推荐）**：在 Xcode 中为项目设置 **Signing & Capabilities → Team**（选你的 Apple ID 或开发团队）。用同一团队证书签名后，多次构建会被系统视为同一应用，覆盖安装后辅助功能权限可保留。
2. **已覆盖安装、当前自动粘贴失效时**：  
   - 打开「系统设置 → 隐私与安全性 → 辅助功能」，在列表中找到 **Paster**，**先关闭其开关（或移除列表中的 Paster）**，再**重新打开** Paster 应用，在弹窗中点击「打开系统设置」并重新勾选 Paster。  
   - 若仍无效，可**彻底删除** `/Applications/Paster.app` 后重新安装，再在辅助功能中授权一次。

## 贡献

欢迎提交 Issue 和 Pull Request！请参阅 [CONTRIBUTING.md](CONTRIBUTING.md) 了解贡献指南。

## 开源协议

本项目采用 [MIT License](LICENSE) 开源协议。

---

<p align="center">
  Made with ♥ for macOS
</p>
