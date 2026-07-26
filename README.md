<p align="center">
  <img src="markd.logo.jpg" width="120" height="120" style="border-radius: 24px;" alt="Marka Logo" />
</p>

<h1 align="center">Marka IDE</h1>

<p align="center">
  <b>Modern Cross-Platform Workspace Markdown Editor Built for Focused Writing & Industrial Aesthetics</b>
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
  <a href="#-key-features">Features</a> •
  <a href="#-downloads--installation">Download</a> •
  <a href="#-developer-guide">Developer Guide</a> •
  <a href="#-license">License</a>
</p>

---

## ✨ Key Features

### 📄 1. Single-File Open & System Association
- **Instant Launch**: Double-click `.md` / `.txt` files or use OS "Open With" / CLI arguments to directly open target documents.
- **Auto Workspace Context**: Parent directories are automatically mounted into the file explorer sidebar to ensure local relative images and resources render seamlessly.

### 🎨 2. Pixel-Perfect Line Highlight Alignment
- **Zero Cumulative Drift**: Engineered with measured `preferredLineHeight` and centered `StrutStyle` to guarantee 0px vertical drift between line numbers, cursor highlights, and text lines across 200+ lines.
- **Catppuccin Aesthetics**: Harmonious Morandi dark/light color palettes tailored with GFM heading ladders, code tags, and blockquote accents.

### 🐧 3. Comprehensive Linux Packaging (Fedora / Ubuntu / Universal)
- **Fedora 44 Native RPM**: Packed with full runtime dependencies (`gtk3`, `libayatana-appindicator3`), supports single-command `sudo dnf install`.
- **Ubuntu / Debian Native DEB**: Built with native `dpkg-deb` rules, fully compatible with `sudo apt install`.
- **Linux Universal AppImage**: Self-contained executable for all Linux distributions.

### 🍎 4. macOS & Windows First-Class Support
- **macOS Native DMG & ZIP**: Provides Retina-ready macOS `.dmg` disk images and `.zip` bundles.
- **Windows Graphical Installer**: 64-bit Inno Setup installer with desktop integration.

### 🌐 5. Full Bilingual i18n & Utility Suite
- **Complete Localization**: Full English & Chinese translations for all setting tiles and interface elements.
- **Sync-Scroll Preview**: Real-time GFM preview with synchronized scroll position.
- **Multi-Format Export**: Export to standalone HTML, copy HTML code snippets, or copy rich text formatting.

---

## 📦 Downloads & Installation

Get the latest binaries directly from the [**GitHub Releases v3.3.10**](https://github.com/aimy1/Marka/releases/tag/v3.3.10) page:

| OS / Distribution | Package Format | Binary File | Installation / Usage Command |
| :--- | :---: | :--- | :--- |
| **Fedora 44 / RHEL** | RPM | `Marka-Installer-Fedora.rpm` | `sudo dnf install ./Marka-Installer-Fedora.rpm` |
| **Ubuntu / Debian** | DEB | `Marka-Installer-Ubuntu.deb` | `sudo apt install ./Marka-Installer-Ubuntu.deb` |
| **Linux Universal** | AppImage | `Marka-Installer-AppImage.AppImage` | `chmod +x Marka-*.AppImage && ./Marka-*.AppImage` |
| **macOS (Apple / Intel)** | DMG Image | `Marka-Installer-macOS.dmg` | Drag to Applications folder |
| **macOS (ZIP Bundle)** | ZIP Archive | `Marka-Installer-macOS.zip` | Extract and run `Marka.app` |
| **Windows 64-bit** | EXE Installer | `Marka-Installer-Windows.exe` | Run installer wizard |

---

## 🛠️ Developer Guide

### Local Development

Prerequisites: [Flutter SDK](https://flutter.dev/) (>=3.0.0)

```bash
# 1. Clone the repository
git clone https://github.com/aimy1/Marka.git
cd Marka

# 2. Install dependencies
flutter pub get

# 3. Launch dev build
flutter run -d windows   # Windows
flutter run -d linux     # Linux
flutter run -d macos     # macOS
```

### Local Multi-Platform Build

To build Linux RPM, DEB, and AppImage packages locally:
```bash
flutter build linux --release
chmod +x ./build_linux_packages.sh
./build_linux_packages.sh
```
All generated packages will be placed in the `dist/` directory.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
