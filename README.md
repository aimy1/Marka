# Marka IDE

<p align="center">
  <a href="README_ZH.md"><b>中文文档</b></a> | 
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Release-v3.3.8-CBA6F7?style=for-the-badge&logo=markdown&logoColor=white" alt="Marka Release" />
  <img src="https://img.shields.io/badge/Built_with-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Platforms-Linux_|_Windows_|_Web-313244?style=for-the-badge&logo=linux&logoColor=white" alt="Platforms" />
  <img src="https://img.shields.io/badge/Theme-Catppuccin-F38BA8?style=for-the-badge" alt="Theme" />
</p>

---

> **The Precision Markdown Workspace for Professionals.**
>
> Marka is a modern, high-performance Markdown IDE built with Flutter, designed for writers and developers who demand industrial-grade precision and a zen-like writing experience. It unites the strict layout standards of the **Kate** editor with the aesthetic elegance of the **Catppuccin** palette.

<p align="center">
  <img width="100%" alt="Marka IDE Screenshot" src="https://github.com/user-attachments/assets/211673ed-26c1-4f68-b400-d64baef3ed2d" style="border-radius: 12px; box-shadow: 0 8px 30px rgba(0,0,0,0.3);" />
</p>

---

## ✨ Key Features

### 📐 Kate-Style Typographic Grid (Engine 3.0)
* **Zero Vertical Jitter**: Every line is locked to an atomic 21-pixel grid using strict `StrutStyle` constraints.
* **Pixel-Perfect Baseline Sync**: By unifying font families and introducing `TextLeadingDistribution.even` (even layout padding), row numbers in the gutter and editor text align perfectly down to the pixel.
* **Pure Layout Boundaries**: Eliminates all internal decoration offsets by bypassing Flutter's default Material filled states.

### 🎛️ Dynamic Resizable Workspace
* **Draggable Sidebar**: Customize the width of the workspace file tree on the fly (drag from `180px` to `450px`).
* **Resizable Split Screen**: Drag the middle divider to partition the editor and live preview. 
* **60FPS High-Performance Rebuild Isolation**: Width state variables are fully localized in sub-state structures, bypassing expensive full-page builds and text reflows.
* **Instant Transition Logic**: Sidebar transitions slide dynamically at `300ms` when toggled, but collapse to `0ms` instantly while active dragging to ensure zero latency.

### 🎨 Studio-Grade Aesthetics & Theme
* **Catppuccin Integration**: High-contrast, low-fatigue color schemes featuring the **Macchiato** (Dark) and **Latte** (Light) palettes.
* **Micro-Animations & Feedback**: Features smooth tab switching, elastic search overlay entry, and a breathing pulse active indicator in the sidebar tree.
* **Themed Interactive Scrollbar**: Custom `6px` pill-shaped scrollbar that blends subtly with the background and lights up dynamically with the active theme color on hover or drag.
* **Unified Selection Colors**: Native-feeling selection highlights and handles aligned with Catppuccin Mauve accents.

### 🔍 Industrial Find & Replace
* **Focused Match Highlight**: Real-time match counting and highlight rendering across the entire document.
* **IDE Controls**: Supports case sensitivity, Regex pattern matching, and single-click global replacements.

---

## 💻 Tech Stack

* **Front-End Engine**: Flutter (Skia / Impeller rendering)
* **State Manager**: Provider Architecture
* **Typography**: Google Fonts / JetBrains Mono
* **Linux Compilers**: native `rpmbuild` & FUSE-free `appimagetool`
* **Installer Engine**: Inno Setup Compiler (`.iss`)

---

## 🛠️ Installation & Build Guide

### Running Locally
Ensure you have the Flutter SDK (Stable branch) installed:
```bash
git clone https://github.com/aimy1/Marka.git
cd Marka
flutter pub get
flutter run -d chrome # Or Windows / Linux
```

### Compiling Release Packages

#### 📦 Linux (RPM Package & AppImage)
We provide an automated compilation script that compiles the Flutter release bundle, builds an unzipped `AppImage` without requiring kernel-level FUSE mount rights, and packages an `RPM` binary:
```bash
chmod +x build_linux_packages.sh
./build_linux_packages.sh
```
The output packages will be located in the `dist/` directory:
- `dist/Marka-3.3.8-x86_64.AppImage`
- `dist/marka-3.3.8-1.x86_64.rpm`

#### 📦 Windows (Inno Setup Installer)
1. Build the Flutter release:
   ```bash
   flutter build windows --release
   ```
2. Compile the installer script located in `windows/runner/marka_installer.iss` using Inno Setup compiler to output `Marka_Setup_3.3.8.exe`.

---

## ⌨️ Keyboard Shortcuts

| Category | Shortcut | Description |
| :--- | :--- | :--- |
| **System** | `Ctrl + S` | Save current file |
| | `Ctrl + \` | Toggle Left Sidebar |
| **Formatting** | `Ctrl + B` | Format Bold (`**text**`) |
| | `Ctrl + I` | Format Italic (`*text*`) |
| | `Ctrl + L` | Insert Link (`[text](url)`) |
| | `Ctrl + Shift + I` | Insert Image (`![alt](url)`) |
| | `Ctrl + Shift + X` | Insert Strikethrough (`~~text~~`) |
| | `Ctrl + Q` | Insert Blockquote (`> `) |
| | `Ctrl + .` | Insert Inline Code (`` `code` ``) |
| | `Ctrl + Shift + C` | Insert Code Block (`` ```code``` ``) |
| | `Ctrl + 1 / 2 / 3` | Convert to H1 / H2 / H3 Header |
| **Editing** | `Ctrl + Z / Y` | Multi-history Undo / Redo |
| | `Alt + ↑ / ↓` | Move current line up / down |
| | `Ctrl + Shift + K` | Delete current line |
| | `Shift + Alt + ↓` | Duplicate current line below |
| | `Ctrl + /` | Toggle single line comment (`<!-- -->`) |
| | `Tab / Shift+Tab` | Indent / Outdent selected lines |
| **Navigation** | `Ctrl + F` | Toggle Search & Replace Overlay |
| | `Escape` | Close active overlays or dialogs |

---

## 🗺️ Release Roadmap

- [x] **v2.9.0**: Kate-style atomic grid alignment engine.
- [x] **v3.0.0**: Find & Replace overlay, selection metrics rewrite.
- [x] **v3.1.0**: Undo/Redo historical state controller integration.
- [x] **v3.3.0**: macOS sliding Segmented Tab controller, color normalizations.
- [x] **v3.3.8**: AppImage & RPM automated packing pipeline, resizable sidebar/split-screen layout with 60FPS isolation, custom themed scrollbars, pixel-perfect baseline sync.
- [ ] **v4.0.0**: Modular plug-in ecosystem & themes API (In development).

---

## 🤝 Credits & Licensing
Designed and maintained by the **Marka Team**.
Special thanks to the **Flutter** and **Catppuccin** developer communities.

*"Simplicity is the ultimate sophistication."*
