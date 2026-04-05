import 'dart:io' as io show Directory, File, Platform;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/doc_session.dart';
import '../models/workspace_item.dart';
import '../utils/path_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarkdownProvider with ChangeNotifier {
  String get pathSeparator => getPathSeparator();
  
  // Session Management
  final List<DocSession> _sessions = [];
  int _activeTabIndex = -1;

  // Global Settings/State
  bool _isSplitScreen = true;
  bool _isWrapped = true;
  double _fontSize = 14.0;
  double _lineHeight = 1.5;
  String _fontFamily = 'Inter';
  bool _autoSave = false;
  String _locale = 'en'; // 'en' or 'zh'
  
  // Workspace State (Multiple Folders)
  final List<String> _workspacePaths = [];
  final Map<String, List<WorkspaceItem>> _workspaceFilesMap = {};

  // Preview Debounce
  String _previewContent = '';
  Timer? _debounceTimer;
  Timer? _autoSaveTimer;

  // Selection update request
  int? _requestSelectionOffset;

  MarkdownProvider() {
    _sessions.add(DocSession(
      name: 'Welcome.md',
      content: _welcomeMarkdown,
      originalContent: _welcomeMarkdown,
    ));
    _activeTabIndex = 0;
    _previewContent = _welcomeMarkdown;
    
    Future.microtask(() => _loadPersistedWorkspaces());
  }

        await refreshWorkspace();
      }
      
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString('locale');
      if (savedLocale != null) {
        _locale = savedLocale;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading persisted workspaces: $e');
    }
  }

  Future<void> _saveWorkspaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('workspace_paths', _workspacePaths);
    } catch (e) {
      debugPrint('Error saving workspaces: $e');
    }
  }

  // Getters
  List<DocSession> get sessions => _sessions;
  int get activeTabIndex => _activeTabIndex;
  DocSession? get activeSession => _activeTabIndex != -1 ? _sessions[_activeTabIndex] : null;
  
  String get content => activeSession?.content ?? '';
  String get previewContent => _previewContent;
  String? get currentFilePath => activeSession?.path;
  bool get isModified => activeSession?.isModified ?? false;
  bool get isSplitScreen => _isSplitScreen;
  bool get isWrapped => _isWrapped;
  double get fontSize => _fontSize;
  double get lineHeight => _lineHeight;
  String get fontFamily => _fontFamily;
  bool get autoSave => _autoSave;
  String get locale => _locale;
  
  List<String> get workspacePaths => _workspacePaths;
  Map<String, List<WorkspaceItem>> get workspaceFilesMap => _workspaceFilesMap;
  
  int? get requestSelectionOffset => _requestSelectionOffset;
  int get selectionStart => activeSession?.selectionStart ?? 0;
  int get selectionEnd => activeSession?.selectionEnd ?? 0;
  double get scrollPercentage => activeSession?.scrollPercentage ?? 0.0;

  String? get currentFileDirectory {
    final path = activeSession?.path;
    if (path == null || kIsWeb) return null;
    return io.File(path).parent.path;
  }

  // Session Methods
  void updateContent(String newContent) {
    final session = activeSession;
    if (session != null && session.content != newContent) {
      session.updateContent(newContent);
      
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 150), () {
        if (_previewContent != session.content) {
          _previewContent = session.content;
          notifyListeners();
        }
      });

      if (_autoSave && session.isModified && session.path != null) {
        _autoSaveTimer?.cancel();
        _autoSaveTimer = Timer(const Duration(seconds: 3), () {
          if (session.isModified) saveFile();
        });
      }
      
      notifyListeners();
    }
  }

  void switchTab(int index) {
    if (index >= 0 && index < _sessions.length) {
      _activeTabIndex = index;
      _previewContent = _sessions[index].content;
      notifyListeners();
    }
  }

  void closeTab(int index) {
    if (index >= 0 && index < _sessions.length) {
      _sessions.removeAt(index);
      if (_sessions.isEmpty) {
        newFile();
      } else {
        if (_activeTabIndex >= _sessions.length) {
          _activeTabIndex = _sessions.length - 1;
        }
        _previewContent = _sessions[_activeTabIndex].content;
      }
      notifyListeners();
    }
  }

  void newFile() {
    final session = DocSession(
      name: 'Untitled.md',
      content: '',
      originalContent: '',
    );
    _sessions.add(session);
    _activeTabIndex = _sessions.length - 1;
    _previewContent = '';
    notifyListeners();
  }

  // File Operations
  Future<void> openFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown', 'txt'],
        allowMultiple: true,
      );

      if (result != null) {
        String? virtualWebWorkspace = kIsWeb ? "Web Workspace" : null;
        
        for (var platformFile in result.files) {
          String content = '';
          String? path;
          
          if (kIsWeb) {
            if (platformFile.bytes != null && platformFile.bytes!.isNotEmpty) {
              content = utf8.decode(platformFile.bytes!);
            } else {
              content = "--- ERROR: READ FAILED ---";
            }
            path = "web://${platformFile.name}";
          } else {
            path = platformFile.path;
            if (path != null) {
              content = await io.File(path).readAsString();
              final parentPath = io.File(path).parent.path;
              if (!_workspacePaths.contains(parentPath)) {
                _workspacePaths.add(parentPath);
                await refreshWorkspace();
              }
            }
          }

          int existingIndex = _sessions.indexWhere((s) => s.path == path && path != null);
          if (existingIndex == -1) {
            final session = DocSession(
              path: path,
              name: platformFile.name,
              content: content,
              originalContent: content,
            );
            
            if (_sessions.length == 1 && (_sessions[0].name == 'Untitled.md' || _sessions[0].name == 'Welcome.md') && !_sessions[0].isModified) {
              _sessions[0] = session;
              _activeTabIndex = 0;
            } else {
              _sessions.add(session);
              _activeTabIndex = _sessions.length - 1;
            }
            _previewContent = content;
          } else {
            _activeTabIndex = existingIndex;
            _previewContent = _sessions[existingIndex].content;
          }

          if (kIsWeb && virtualWebWorkspace != null) {
            if (!_workspacePaths.contains(virtualWebWorkspace)) {
              _workspacePaths.add(virtualWebWorkspace);
            }
            _workspaceFilesMap.putIfAbsent(virtualWebWorkspace, () => []);
            if (!_workspaceFilesMap[virtualWebWorkspace]!.any((f) => f.path == (path ?? platformFile.name))) {
              _workspaceFilesMap[virtualWebWorkspace]!.add(WorkspaceItem(path: path ?? "web://${platformFile.name}", name: platformFile.name));
            }
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error opening file(s): $e');
    }
  }

  Future<void> saveFile() async {
    final session = activeSession;
    if (session == null) return;
    if (session.path == null || kIsWeb) {
      await saveFileAs();
      return;
    }
    try {
      final file = io.File(session.path!);
      await file.writeAsString(session.content);
      session.markSaved();
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving file: $e');
    }
  }

  Future<void> saveFileAs() async {
    final session = activeSession;
    if (session == null) return;
    try {
      if (kIsWeb) {
        session.markSaved();
        notifyListeners();
        return;
      }
      String? outputPath = await FilePicker.saveFile(dialogTitle: 'Save Markdown As', fileName: session.name, allowedExtensions: ['md']);
      if (outputPath != null) {
        final file = io.File(outputPath);
        await file.writeAsString(session.content);
        session.path = outputPath;
        session.name = outputPath.split(pathSeparator).last;
        session.markSaved();
        await refreshWorkspace();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error saving file as: $e');
    }
  }

  // Workspace Methods
  Future<void> loadWorkspace([BuildContext? context]) async {
    if (kIsWeb) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Working directories restricted. Select multiple files!')));
      }
      openFile();
      return;
    }
    try {
      String? selectedDirectory = await FilePicker.getDirectoryPath();
      if (selectedDirectory != null && !_workspacePaths.contains(selectedDirectory)) {
        _workspacePaths.add(selectedDirectory);
        await _saveWorkspaces();
        await refreshWorkspace();
      }
    } catch (e) {
      debugPrint('Error loading workspace: $e');
    }
  }

  void removeWorkspaceFolder(String path) {
    _workspacePaths.remove(path);
    _workspaceFilesMap.remove(path);
    notifyListeners();
  }

  Future<void> refreshWorkspace() async {
    if (kIsWeb) return;
    _workspaceFilesMap.clear();
    try {
      for (final path in _workspacePaths) {
        final dir = io.Directory(path);
        if (await dir.exists()) {
          final entities = await dir.list().toList();
          _workspaceFilesMap[path] = entities.whereType<io.File>()
              .where((f) => f.path.endsWith('.md') || f.path.endsWith('.markdown'))
              .map((f) => WorkspaceItem(path: f.path, name: f.path.split(pathSeparator).last))
              .toList();
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing workspace: $e');
    }
  }

  Future<void> openFileDirectly(String path) async {
    try {
      int existingIndex = _sessions.indexWhere((s) => s.path == path);
      if (existingIndex != -1) {
        _activeTabIndex = existingIndex;
        _previewContent = _sessions[existingIndex].content;
      } else {
        if (kIsWeb) return;
        String content = await io.File(path).readAsString();
        final session = DocSession(path: path, name: path.split(pathSeparator).last, content: content, originalContent: content);
        _sessions.add(session);
        _activeTabIndex = _sessions.length - 1;
        _previewContent = content;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error opening file directly: $e');
    }
  }

  Future<void> createFile(String name, String folderPath) async {
    try {
      final cleanName = name.toLowerCase().endsWith('.md') ? name : '$name.md';
      final path = "$folderPath$pathSeparator$cleanName";
      if (!kIsWeb) {
        final file = io.File(path);
        if (!await file.exists()) await file.writeAsString('');
      }
      final session = DocSession(path: path, name: cleanName, content: '', originalContent: '');
      _sessions.add(session);
      _activeTabIndex = _sessions.length - 1;
      _previewContent = '';
      if (!_workspaceFilesMap.containsKey(folderPath)) _workspaceFilesMap[folderPath] = [];
      _workspaceFilesMap[folderPath]!.add(WorkspaceItem(path: path, name: cleanName));
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating file: $e');
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      if (!kIsWeb) {
        final file = io.File(path);
        if (await file.exists()) await file.delete();
      }
      _sessions.removeWhere((s) => s.path == path);
      if (_sessions.isEmpty) { newFile(); }
      else {
        if (_activeTabIndex >= _sessions.length) _activeTabIndex = _sessions.length - 1;
        _previewContent = _sessions[_activeTabIndex].content;
      }
      for (var ws in _workspacePaths) { _workspaceFilesMap[ws]?.removeWhere((f) => f.path == path); }
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  Future<void> renameFile(String oldPath, String newName) async {
    try {
      final cleanName = newName.toLowerCase().endsWith('.md') ? newName : '$newName.md';
      final directory = oldPath.substring(0, oldPath.lastIndexOf(pathSeparator));
      final newPath = "$directory$pathSeparator$cleanName";
      if (!kIsWeb) {
        final file = io.File(oldPath);
        if (await file.exists()) await file.rename(newPath);
      }
      for (var s in _sessions) { if (s.path == oldPath) { s.path = newPath; s.name = cleanName; } }
      for (var ws in _workspacePaths) {
        final fs = _workspaceFilesMap[ws];
        if (fs != null) {
          for (var i = 0; i < fs.length; i++) { if (fs[i].path == oldPath) fs[i] = WorkspaceItem(path: newPath, name: cleanName); }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error renaming file: $e');
    }
  }

  // View Controls
  void refreshPreview() { final s = activeSession; if (s != null) { _previewContent = s.content; notifyListeners(); } }
  void toggleSplitScreen() { _isSplitScreen = !_isSplitScreen; notifyListeners(); }
  void toggleWrap() { _isWrapped = !_isWrapped; notifyListeners(); }
  void toggleAutoSave() { _autoSave = !_autoSave; notifyListeners(); }
  void updateFontFamily(String family) { _fontFamily = family; notifyListeners(); }
  void updateFontSize(double size) { _fontSize = size.clamp(8, 32); notifyListeners(); }
  void updateLineHeight(double height) { _lineHeight = height.clamp(1.0, 3.0); notifyListeners(); }
  
  void updateSelection(int start, int end) {
    final s = activeSession;
    if (s != null) { s.selectionStart = start; s.selectionEnd = end; }
    _requestSelectionOffset = start;
    notifyListeners();
  }

  void consumeSelectionRequest() { _requestSelectionOffset = null; }
  
  void updateScroll(double percentage) {
    final s = activeSession;
    if (s != null && (s.scrollPercentage - percentage).abs() > 0.01) { s.scrollPercentage = percentage; notifyListeners(); }
  }

  void insertSnippet(String prefix, [String suffix = '', int? selectionStart, int? selectionEnd]) {
    final s = activeSession; if (s == null) return;
    final start = selectionStart ?? s.content.length;
    final end = selectionEnd ?? s.content.length;
    if (start >= 0 && end >= start) {
      final selectedText = s.content.substring(start, end);
      final newText = s.content.replaceRange(start, end, '$prefix$selectedText$suffix');
      s.updateContent(newText);
      _previewContent = newText;
      _requestSelectionOffset = start + prefix.length + (start == end ? 0 : selectedText.length + suffix.length);
      notifyListeners();
    }
  void updateLocale(String langCode) async {
    _locale = langCode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', langCode);
  }

  String t(String key) {
    return _translations[_locale]?[key] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'settings': 'Settings',
      'font_family': 'Font Family',
      'font_size': 'Font Size',
      'line_height': 'Line Height',
      'auto_save': 'Auto Save',
      'theme': 'Theme',
      'language': 'Language',
      'split_screen': 'Split Screen',
      'word_wrap': 'Word Wrap',
      'close': 'Close',
      'workspaces': 'WORKSPACES',
      'open_folder': 'Open Folder',
      'refresh_all': 'Refresh All',
      'new_file': 'New File',
      'rename_dialog_title': 'Rename File',
      'new_file_dialog_title': 'New File in',
      'rename': 'Rename',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'create': 'Create',
      'welcome_title': 'Welcome to Marka',
      'welcome_desc': 'Open a folder to start managing your Markdown project.',
      'open_files': 'Open Files',
      'words': 'Words',
      'save_tooltip': 'Save (Ctrl+S)',
      'new_file_tooltip': 'New File',
      'split_tooltip': 'Toggle Split Screen',
      'settings_tooltip': 'Settings',
      'no_folders_open': 'No Folders Open',
      'remove_folder': 'Remove Folder',
      'no_md_files': 'No .md files',
    },
    'zh': {
      'settings': '设置',
      'font_family': '字体',
      'font_size': '字号',
      'line_height': '行高',
      'auto_save': '自动保存',
      'theme': '主题模式',
      'language': '软件语言',
      'split_screen': '分屏预览',
      'word_wrap': '自动换行',
      'close': '关闭',
      'workspaces': '工作空间',
      'open_folder': '打开文件夹',
      'refresh_all': '刷新全部',
      'new_file': '新建文件',
      'rename_dialog_title': '重命名文件',
      'new_file_dialog_title': '新建文件于',
      'rename': '重命名',
      'delete': '删除',
      'cancel': '取消',
      'create': '创建',
      'welcome_title': '欢迎使用 Marka',
      'welcome_desc': '打开一个项目目录来启动您的 Markdown 工作流。',
      'open_files': '打开文件',
      'words': '字数统计',
      'save_tooltip': '保存 (Ctrl+S)',
      'new_file_tooltip': '新建文件',
      'split_tooltip': '切换分屏',
      'settings_tooltip': '设置中心',
      'no_folders_open': '暂未打开工作目录',
      'remove_folder': '移除目录',
      'no_md_files': '无 Markdown 文件',
    },
  };

  static const String _welcomeMarkdown = '''
# 🚀 Marka

A **modern**, workspace-centric Markdown editor.

## ✨ Features
- **Real-time Preview**: See changes instantly
- **Syntax Highlighting**: Beautiful code blocks
- **Dark Mode**: Eye-friendly interface

## 💻 Code Example
```dart
void main() {
  print("Hello Marka!");
}
```

> "Simplicity is the ultimate sophistication." — Leonardo da Vinci

---
### 🛠️ Built with
1. Flutter
2. Provider
3. Google Fonts
''';
}
