# 🚀 Marka IDE (v3.3.3)

[English Documentation](README.md)

> **专为专业人士打造的精准 Markdown 创作空间。**

Marka 是一款现代、高性能的 Markdown IDE，采用 Flutter 构建，专为对文字处理有工业级精度要求并追求禅意写作体验的作家和开发者设计。其设计灵感源自 **Kate** 编辑器的严谨布局标准与 **Catppuccin** 色彩体系的优雅美学。

![Marka Release](https://img.shields.io/badge/Release-v3.3.3-CBA6F7?style=for-the-badge&logo=markdown)
![Flutter](https://img.shields.io/badge/Built_with-Flutter-02569B?style=for-the-badge&logo=flutter)
---
<img width="1731" height="1097" alt="image" src="https://github.com/user-attachments/assets/d93449a3-9bfe-41d7-afb6-179fdafc75b9" />
<img width="1733" height="1099" alt="image" src="https://github.com/user-attachments/assets/ea7a5171-0a9e-4338-8544-245031e42b99" />
---

## ✨ 核心特性

### 📐 Kate 风格的像素级对齐 (Engine 3.0)
零垂直抖动。通过强力的 `StrutStyle` 限制，每一行都精确锁定在 21 像素的原子网格中。行号、文本基线即使在处理 100,000+ 行的大文件时也能保持完美同步。

### 🔍 工业级查找与替换
不止是基础查找。Marka 提供实时全量匹配高亮，并针对当前焦点匹配项提供橙色强调展示。支持正则表达式、大小写敏感匹配以及一键全局替换。

### 🎨 工作室级美学 (v3.3.3 进化)
- **高保真 UI 与动画**：全新的标签切换动效、搜索框弹性入场以及侧边栏激活项脉冲呼吸灯，提供极致的视觉反馈。
- **Catppuccin 全深度集成**：无论在明亮还是深色模式下，都能提供高对比度、低疲劳度的配色方案。
- **动态排版控制**：建议配合 `JetBrains Mono` 使用，支持行高、内边距动态调节。

### 🚀 开发者生产力工具
- **智能选区行为**：符合主流 IDE 逻辑的点击移动光标、拖拽选中文本行为。
- **Undo/Redo 支持**：全历史记录撤销与重做，哪怕是复杂的片段插入也能轻松回滚。
- **分屏同步滚动与 AnimatedSwitcher**：分屏切换平滑过渡，编辑器与预览窗口 1:1 物理锁定。
- **快捷键矩阵**：Ctrl+B / I / L 等常见 Markdown 快捷键，辅以 Alt+↑/↓ 移动行等高级指令。

---

## 💻 技术栈

- **核心引擎**: Flutter (Skia/Impeller)
- **状态管理**: Provider
- **精选字体**: Google Fonts / JetBrains Mono
- **编辑架构**: 高度模块化的 Engine 3.0 架构

---

## 🛠️ 快速开始

### 安装步骤
1. 克隆仓库到本地
2. 在根目录运行 `flutter pub get`
3. 启动应用：`flutter run -d windows` (或你偏好的平台)

### 常用快捷键
- `Ctrl + S`: 保存文档
- `Ctrl + F`: 开启查找/替换面板
- `Alt + ↑/↓`: 向上/下移动当前行
- `Ctrl + Z`: 撤销更改
- `Ctrl + Y`: 重做更改
- `Ctrl + \`: 切换侧边栏

---

## 🗺️ 路线图
- [x] v2.9.0: 原子级网格对齐逻辑
- [x] v3.0.0: 查找高亮与工业级选区修复
- [x] v3.1.0: 撤销/重做历史控制器
- [x] v3.3.3: UI 动画进化与品牌统一
- [ ] v4.0.0: 插件化扩展体系 (规划中)
- [ ] v4.0.0: 插件化扩展体系

---

## 🤝 致谢
由 Marka 团队倾力打造。特别感谢 Flutter 与 Catppuccin 社区提供的灵感与支持。

*"至简即是至繁。"*
