# 🚀 Marka IDE

<p align="center">
  <a href="README.md"><b>English Documentation</b></a> | 
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Release-v3.3.8-CBA6F7?style=for-the-badge&logo=markdown&logoColor=white" alt="Marka Release" />
  <img src="https://img.shields.io/badge/Built_with-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Platforms-Linux_|_Windows_|_Web-313244?style=for-the-badge&logo=linux&logoColor=white" alt="Platforms" />
  <img src="https://img.shields.io/badge/Theme-Catppuccin-F38BA8?style=for-the-badge" alt="Theme" />
</p>

---

> **专为专业人士打造的精准 Markdown 创作空间。**
>
> Marka 是一款现代、高性能的 Markdown IDE，采用 Flutter 构建，专为对文字处理有工业级精度要求并追求禅意写作体验的作家和开发者设计。其完美融合了 **Kate** 编辑器的严谨排版布局标准与 **Catppuccin** 色彩体系的优雅工作室美学。

<p align="center">
  <img width="100%" alt="Marka IDE 截图" src="https://github.com/user-attachments/assets/95679915-229f-4091-b26b-9a7bf94d4394" style="border-radius: 12px; box-shadow: 0 8px 30px rgba(0,0,0,0.3);" />
</p>

---

## ✨ 核心特性

### 📐 Kate 风格的像素级对齐 (Engine 3.0)
* **零垂直抖动**：通过强力的 `StrutStyle` 限制，每一行都精确锁定在 21 像素的原子网格中。
* **像素级基线同步**：统一字体家族并引入 `TextLeadingDistribution.even`（均等行高分配），使得左侧行号与编辑器文本基线在水平像素层面绝对齐平。
* **纯净布局边界**：移除了输入框的 Material 填充背景及内部偏移，实现无干扰的极致书写边界。

### 🎛️ 动态自由拉伸工作区
* **可拖拽侧边栏**：鼠标左右滑动即可在 `180px ~ 450px` 之间自由调节左侧文件树宽度。
* **自由分栏占比**：拉伸编辑器与预览区中间的分割线，实时调整双栏的显示空间占比。
* **60FPS 极速重绘隔离**：拖动状态与宽度计算完全局部化隔离，避免引起整页重绘和高昂的 Markdown 解析开销，滑动如丝般顺滑。
* **智能过渡动画**：点击按钮收纳侧边栏时保持 `300ms` 优雅滑出，主动拖拽时切换为 `0ms` 即时响应，杜绝操作延迟。

### 🎨 工作室级美学与微交互
* **Catppuccin 全深度集成**：无论在明亮还是深色模式下，都能提供高对比度、低疲劳度的配色方案（**Latte** 与 **Macchiato** 调色板）。
* **精致动效反馈**：支持页签滑动切换、搜索面板弹性滑入、以及侧边栏激活项脉冲呼吸灯指示器。
* **定制版 themed 滚动条**：`6px` 极细胶囊状滚动条，闲置时融入背景，悬停或拖拽时激活渐变高亮主题色，提供极佳视觉暗示。
* **统一的选区设计**：重构文本选择高亮区（透明度提升至 `0.3`）与选择气泡指针，完全统一为 Catppuccin 标志性的 Mauve 紫。

### 🔍 工业级查找与替换
* **匹配焦点追踪**：全量文本实时高亮匹配，并在当前焦点项上提供橙色高对比度强调展示。
* **IDE 高级控制**：支持大小写敏感筛选、正则表达式（Regex）解析以及一键全局替换。

---

## 💻 技术栈

* **渲染引擎**: Flutter (Skia / Impeller 图形加速)
* **状态管理**: Provider 架构
* **系统字体**: Google Fonts / JetBrains Mono
* **打包编译**: 本地 `rpmbuild` 模块 & 免 FUSE 挂载权限的 `appimagetool`
* **安装包引擎**: Inno Setup Compiler (`.iss`)

---

## 🛠️ 快速开始

### 本地运行
确保本地已安装 Flutter SDK（Stable 分支）：
```bash
git clone https://github.com/aimy1/Marka.git
cd Marka
flutter pub get
flutter run -d chrome # 或 windows / linux
```

### 编译发布包

#### 📦 Linux (RPM 软件包与 AppImage)
我们提供了一键自动化打包脚本，可以编译 Flutter release 产物，提取无 FUSE 权限依赖的打包工具并直接生成 RPM 包及 AppImage：
```bash
chmod +x build_linux_packages.sh
./build_linux_packages.sh
```
编译成功后的包会统一放置在根目录下的 `dist/` 文件夹中：
- `dist/Marka-3.3.8-x86_64.AppImage`
- `dist/marka-3.3.8-1.x86_64.rpm`

#### 📦 Windows (Inno Setup 安装器)
1. 编译 Flutter Windows release 包：
   ```bash
   flutter build windows --release
   ```
2. 使用 Inno Setup 编译器编译 `windows/runner/marka_installer.iss` 脚本，输出 `Marka_Setup_3.3.8.exe`。

---

## ⌨️ 常用快捷键

| 分类 | 快捷键 | 功能描述 |
| :--- | :--- | :--- |
| **系统交互**| `Ctrl + S` | 保存当前文档 |
| | `Ctrl + \` | 切换左侧侧边栏折叠/展开 |
| **Markdown 格式化** | `Ctrl + B` | 粗体快捷键 (`**加粗**`) |
| | `Ctrl + I` | 斜体快捷键 (`*斜体*`) |
| | `Ctrl + L` | 插入超链接 (`[文本](链接)`) |
| | `Ctrl + Shift + I` | 插入图片 (`![描述](链接)`) |
| | `Ctrl + Shift + X` | 插入删除线 (`~~删除~~`) |
| | `Ctrl + Q` | 插入引用区块 (`> `) |
| | `Ctrl + .` | 插入行内代码 (`` `代码` ``) |
| | `Ctrl + Shift + C` | 插入多行代码块 (`` ```代码块``` ``) |
| | `Ctrl + 1 / 2 / 3` | 转换为 一级 / 二级 / 三级 标题 |
| **编辑器行操作** | `Ctrl + Z / Y` | 撤销 / 重做（多历史记录栈） |
| | `Alt + ↑ / ↓` | 将当前行向上 / 向下移动一行 |
| | `Ctrl + Shift + K` | 删除当前整行 |
| | `Shift + Alt + ↓` | 复制当前行到下一行 |
| | `Ctrl + /` | 开关单行 HTML 注释 (`<!-- 注释 -->`) |
| | `Tab / Shift+Tab` | 对选中行进行缩进 / 反向缩进 |
| **查找定位** | `Ctrl + F` | 开启/关闭 查找与替换控制面板 |
| | `Escape` | 退出浮窗、检索面板或设置对话框 |

---

## 🗺️ 版本路线图

- [x] **v2.9.0**: Kate 风格原子级垂直网格对齐引擎。
- [x] **v3.0.0**: 检索与替换面板，智能文本选区重构。
- [x] **v3.1.0**: Undo/Redo 历史状态控制器深度集成。
- [x] **v3.3.0**: macOS 原生滑动 Segmented Tab 控制器，全局配色调和。
- [x] **v3.3.8**: AppImage & RPM 一键自动化构建脚本及 CI 流水线、支持 60FPS 隔离的侧边栏与分栏拖拽、定制主题滚动条、行号与正文基线无偏差对齐。
- [ ] **v4.0.0**: 模块化插件扩展体系与自定义主题 API (正在开发中)。

---

## 🤝 致谢与授权
由 **Marka 团队** 倾力设计与维护。
特别感谢 **Flutter** 与 **Catppuccin** 开发者社区提供的无限灵感。

*"至简即是至繁。"*
