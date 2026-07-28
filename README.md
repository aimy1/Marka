<p align="center">
  <img src="markd.logo.jpg" width="120" height="120" style="border-radius: 24px;" alt="Marka Logo" />
</p>

<h1 align="center">Marka IDE v3.3.12-RC</h1>

<p align="center">
  <b>Modern Cross-Platform Workspace Markdown Editor Built for Focused Writing & Industrial Aesthetics</b>
</p>

<p align="center">
  <a href="https://github.com/aimy1/Marka/releases/tag/v3.3.12-RC">
    <img src="https://img.shields.io/badge/Release-v3.3.12--RC-CBA6F7?style=for-the-badge&logo=markdown&logoColor=white" alt="Marka Release" />
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

## ✨ Key Features (v3.3.12-RC)

### 🎨 1. VS Code Settings Editor Architecture & Purified Theme Purple
- **VS Code Preferences Structure**: Tree category sidebar (`Commonly Used`, `Text Editor`, `Workbench`, `Shortcuts & About`), search filtering, and Setting ID code tags (`files.autoSave`, `editor.fontSize`).
- **Restored Language Selector**: Directly switch between 🇨🇳 简体中文 and 🇺🇸 English at the very top of `Commonly Used` settings.
- **Catppuccin Purple Aesthetic**: Tailored with Marka's signature Catppuccin Theme Purple (`#CBA6F7` / `#8839EF`), Outfit typography, and glassmorphic backdrop blur.

### 📄 2. Single-File Open & Workspace Association
- **Instant Launch**: Double-click `.md` / `.txt` files or use OS "Open With" / CLI arguments to directly open target documents.
- **Auto Workspace Context**: Parent directories are automatically mounted into the file explorer sidebar to ensure local relative images and resources render seamlessly.

### ⚡ 3. Large-Text Performance Optimization
- **Pre-Compiled Regex Engine**: Zero O(N²) scanning bottlenecks for 50,000+ character documents.
- **Debounced Live Preview**: 150ms AST update debouncing ensuring ultra-responsive typing.

### 🐧 4. Comprehensive Linux Packaging (Fedora RPM, AppImage, Ubuntu DEB)
- **Fedora 44 Native RPM**: Packed with full runtime dependencies (`gtk3`, `libayatana-appindicator3`), supports single-command `sudo dnf install`.
- **Linux Universal AppImage**: Self-contained standalone executable for all Linux distributions.
- **Ubuntu / Debian Native DEB**: Built with native `dpkg-deb` rules, fully compatible with `sudo apt install`.

### 🍎 5. macOS & Windows First-Class Support
- **macOS Native DMG & ZIP**: Provides Retina-ready macOS `.dmg` disk images and `.zip` bundles.
- **Windows Graphical Installer**: 64-bit Inno Setup installer with desktop integration.

---

## 📦 Downloads & Installation (v3.3.12-RC)

Get the latest binaries directly from the [**GitHub Releases v3.3.12-RC**](https://github.com/aimy1/Marka/releases/tag/v3.3.12-RC) page:

| OS / Distribution | Package Format | Binary File | Installation / Usage Command |
| :--- | :---: | :--- | :--- |
| **Fedora 44 / RHEL** | RPM | `Marka-Installer-Fedora.rpm` | `sudo dnf install ./Marka-Installer-Fedora.rpm` |
| **Linux Universal** | AppImage | `Marka-Installer-AppImage.AppImage` | `chmod +x Marka-*.AppImage && ./Marka-*.AppImage` |
| **Ubuntu / Debian** | DEB | `Marka-Installer-Ubuntu.deb` | `sudo apt install ./Marka-Installer-Ubuntu.deb` |
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
flutter run -d chrome    # Web Browser
```

### Local Multi-Platform Build

To build Linux RPM, AppImage, and DEB packages locally:
```bash
flutter build linux --release
chmod +x ./build_linux_packages.sh
./build_linux_packages.sh
```
All generated packages will be placed in the `dist/` directory.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
