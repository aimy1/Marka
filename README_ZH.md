<p align="center">
  <img src="markd.logo.jpg" width="120" height="120" style="border-radius: 24px;" alt="Marka Logo" />
</p>

<h1 align="center">Marka IDE</h1>

<p align="center">
  <b>专注于工业级专注写作与极客排版的现代跨平台 Markdown 工作空间</b>
</p>

<p align="center">
  <a href="https://github.com/aimy1/Marka/releases/tag/v3.3.10">
    <img src="https://img.shields.io/badge/Release-v3.3.10-CBA6F7?style=for-the-badge&logo=markdown&logoColor=white" alt="Marka Release" />
  </a>
  <img src="https://img.shields.io/badge/Built_with-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Platforms-Linux_|_macOS_|_Windows_|_Web-313244?style=for-the-badge&logo=linux&logoColor=white" alt="Platforms" />
  <img src="https://img.shields.io/badge/Theme-Catppuccin-F38BA8?style=for-the-badge" alt="Theme" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License" />
</p>

<p align="center">
  <a href="#-核心功能亮点">功能亮点</a> •
  <a href="#-全平台下载与安装">下载安装</a> •
  <a href="#-开发者指南">开发者指南</a> •
  <a href="#-开源协议">开源协议</a>
</p>

---

## ✨ 核心功能亮点

### 📄 1. 单文件关联与直开模式 (Single-File Association)
- **零延迟打开**：支持操作系统右键“打开方式”、双击 `.md` / `.txt` 文件或终端命令行直接打开文档。
- **智能工作区关联**：自动挂载当前文件所在的父目录至侧边栏，保障相对路径图片与本地资源顺畅渲染。

### 🎨 2. 极致排版与原子级对齐 (Pixel-Perfect Alignment)
- **0 像素累积偏移**：采用精确度量的 `preferredLineHeight` 与居中 `StrutStyle`，彻底消除 200+ 行长文本下的行高与背景高亮偏移。
- **Catppuccin 优雅美学**：精心调配的莫兰迪暗色与亮色调主题，配合 GFM 优雅标题梯队与优雅代码块。

### 🐧 3. 全 Linux 发行版打包支持 (Fedora / Ubuntu / Universal)
- **Fedora 44 原生 RPM**：包含完整依赖规范（`gtk3`, `libayatana-appindicator3`），支持 `sudo dnf install` 一键安装。
- **Ubuntu / Debian 原生 DEB**：零第三方依赖的原生 `dpkg-deb` 规则包，兼容 `sudo apt install`。
- **Linux 通用 AppImage**：适用于所有 Linux 发行版的免安装单文件绿色程序。

### 🍎 4. macOS 与 Windows 完美适配
- **macOS 原生 DMG & ZIP**：提供全系 Mac (.dmg / .zip) 镜像文件与 Retina 高清屏渲染。
- **Windows Inno Setup 安装包**：标准 64 位图形化安装程序与桌面快捷方式。

### 🌐 5. 完整双语国际化 (i18n) 与极客工具箱
- **偏好设置全量中英切换**：包含常规、编辑器、外观、高级与软件关于全量界面。
- **双屏同步滚动预览**：打字实时渲染，滚动自动对齐。
- **一键快捷导出**：支持导出为独立 HTML 文件、复制 HTML 代码片段或富文本剪贴板。

---

## 📦 全平台下载与安装

您可以直接前往 [**GitHub Releases v3.3.10**](https://github.com/aimy1/Marka/releases/tag/v3.3.10) 页面获取对应操作系统的最新安装包：

| 操作系统 / 发行版 | 安装包类型 | 文件名 | 安装命令 / 使用方式 |
| :--- | :---: | :--- | :--- |
| **Fedora 44 / RHEL** | RPM 包 | `Marka-Installer-Fedora.rpm` | `sudo dnf install ./Marka-Installer-Fedora.rpm` |
| **Ubuntu / Debian** | DEB 包 | `Marka-Installer-Ubuntu.deb` | `sudo apt install ./Marka-Installer-Ubuntu.deb` |
| **Linux 通用** | AppImage 包 | `Marka-Installer-AppImage.AppImage` | `chmod +x Marka-*.AppImage && ./Marka-*.AppImage` |
| **macOS (Apple / Intel)** | DMG 镜像 | `Marka-Installer-macOS.dmg` | 拖拽至 Application 文件夹 |
| **macOS (ZIP 包)** | ZIP 压缩包 | `Marka-Installer-macOS.zip` | 解压直接运行 `Marka.app` |
| **Windows 64位** | EXE 安装包 | `Marka-Installer-Windows.exe` | 双击运行图形化安装向导 |

---

## 🛠️ 开发者指南

### 本地运行与调试

依赖要求: [Flutter SDK](https://flutter.dev/) (>=3.0.0)

```bash
# 1. 克隆代码仓库
git clone https://github.com/aimy1/Marka.git
cd Marka

# 2. 获取依赖包
flutter pub get

# 3. 启动本地开发
flutter run -d windows   # Windows 平台
flutter run -d linux     # Linux 平台
flutter run -d macos     # macOS 平台
```

### 全平台本地打包

Linux 系统下一键构建 RPM、DEB 与 AppImage：
```bash
flutter build linux --release
chmod +x ./build_linux_packages.sh
./build_linux_packages.sh
```
打包产物将自动收集并输出至项目根目录下的 `dist/` 文件夹。

---

## 📄 开源协议

本项目采用 [MIT License](LICENSE) 协议开源。欢迎提交 Issue 与 Pull Request 共建！
