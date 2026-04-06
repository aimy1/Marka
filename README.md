# 🚀 Marka IDE

[中文文档](README_ZH.md)

> **The Precision Markdown Workspace for Professionals.**

Marka is a modern, high-performance Markdown IDE built with Flutter, designed for writers and developers who demand industrial-grade precision and a zen-like writing experience. Inspired by the strict layout standards of the **Kate** editor and the aesthetic elegance of the **Catppuccin** palette.

![Marka Release](https://img.shields.io/badge/Release-v3.3.4-CBA6F7?style=for-the-badge&logo=markdown)
![Flutter](https://img.shields.io/badge/Built_with-Flutter-02569B?style=for-the-badge&logo=flutter)
---
<img width="2273" height="1206" alt="image" src="https://github.com/user-attachments/assets/211673ed-26c1-4f68-b400-d64baef3ed2d" />


---

## ✨ Key Features

### 📐 Kate-Style Atomic Grid (Engine 3.0)
Zero vertical jitter. Every line is locked to an atomic 21-pixel grid using `StrutStyle` forcing. Row numbers and text baselines stay perfectly synchronized, even in documents with 100,000+ lines.

### 🔍 Industrial Find & Replace
Beyond basic search. Marka provides real-time match highlighting across the entire document, with a distinct emphasis on the current focus. Supports Regex, case-sensitivity, and one-click global replacement.

### 🎨 Studio Aesthetics
- **Catppuccin Integration**: High-contrast, low-fatigue color schemes for both Light and Dark modes.
- **Dynamic Layout**: Adjustable horizontal editor padding, custom font families (default `JetBrains Mono`), and line height controls.

### 🚀 Developer Productivity Suite
- **Standard Selection Behavior**: Reliable click-to-focus and drag-to-select logic that matches professional IDEs.
- **Undo/Redo History**: Full support for `UndoHistoryController`, ensuring every snippet insertion or format change is reversible.
- **Real-time Sync Scroll**: 1:1 visual anchoring between the editor and preview for instant visual feedback.
- **Shortcut Matrix**: Standard Markdown shortcuts (Ctrl+B/I/L) plus advanced line manipulation (Alt+↑/↓).

---

## 💻 Tech Stack

- **Core Engine**: Flutter (Skia/Impeller)
- **State Management**: Provider
- **Typography**: Google Fonts / JetBrains Mono
- **Editing**: Modular Engine 3.0 Architecture

---

## 🛠️ Getting Started

### Installation
1. Clone the repository
2. Run `flutter pub get`
3. Launch with `flutter run -d windows` (or your preferred platform)

### Keyboard Shortcuts
- `Ctrl + S`: Save Document
- `Ctrl + F`: Toggle Search/Replace Overlay
- `Alt + ↑/↓`: Move Current Line Up/Down
- `Ctrl + Z`: Undo Changes
- `Ctrl + Y`: Redo Changes
- `Ctrl + \ `: Toggle Sidebar

---

## 🗺️ Roadmap
- [x] v2.9.0: Atomic Grid Alignment logic
- [x] v3.0.0: Find Highlighting & Industrial Selection Fixes
- [x] v3.1.0: Undo/Redo History Controller
- [ ] v3.2.0: Multi-session Cloud Sync (In Progress)
- [ ] v4.0.0: Plugin & Plugin Architecture

---

## 🤝 Credits
Built with ❤️ by the Marka Team. Special thanks to the Flutter and Catppuccin communities.

*"Simplicity is the ultimate sophistication."*
