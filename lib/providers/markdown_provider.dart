import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class MarkdownProvider with ChangeNotifier {
  String _content = '''
# 🚀 Marka

A **modern**, workspace-centric Markdown editor.

## ✨ Features
- **Real-time Preview**: See changes instantly
- **Syntax Highlighting**: Beautiful code blocks
- **Dark Mode**: Eye-friendly interface

## 💻 Code Example
```dart
void main() {
  print("Line 1");
  print("Line 2");
  print("Line 3");
  print("Line 4");
  print("Line 5");
  print("Line 6");
  print("Line 7");
  print("Line 8");
  print("Line 9");
  print("Line 10");
  print("Line 11");
  print("Line 12");
  print("Line 13");
  print("Line 14");
  print("Line 15");
  print("Line 16");
  print("Line 17");
  print("Line 18");
  print("Line 19");
  print("Line 20");
}
```

> "Simplicity is the ultimate sophistication." — Leonardo da Vinci

---
### 🛠️ Built with
1. Flutter
2. Provider
3. Google Fonts
''';
  String _previewContent = '';
  Timer? _debounceTimer;
  Timer? _autoSaveTimer;
  String _originalContent = '';
  String _currentFilePath;
  bool _isModified = false;
  bool _isSplitScreen = true;
  bool _isWrapped = true;
  double _scrollPercentage = 0.0;
  int _selectionStart = 0;
  int _selectionEnd = 0;

  // Tab Management
  List<File> _openFiles = [];
  int _activeTabIndex = -1;

  List<File> get openFiles => _openFiles;
  int get activeTabIndex => _activeTabIndex;
  File? get activeFile => _activeTabIndex != -1 ? _openFiles[_activeTabIndex] : null;

  // Selection update request
  int? _requestSelectionOffset;
  int? get requestSelectionOffset => _requestSelectionOffset;

  void consumeSelectionRequest() {
    _requestSelectionOffset = null;
  }

  // Workspace & Settings
  String? _workspacePath;
  List<File> _workspaceFiles = [];
  double _fontSize = 14.0;
  bool _autoSave = false;

  MarkdownProvider() : _currentFilePath = '', _originalContent = '' {
    _originalContent = _content;
    _previewContent = _content;
  }

  String get content => _content;
  String get previewContent => _previewContent;
  String? get currentFilePath => _currentFilePath.isEmpty ? null : _currentFilePath;
  bool get isModified => _isModified;
  bool get isSplitScreen => _isSplitScreen;
  bool get isWrapped => _isWrapped;
  double get scrollPercentage => _scrollPercentage;
  int get selectionStart => _selectionStart;
  int get selectionEnd => _selectionEnd;
  
  // Workspace & Settings Getters
  String? get workspacePath => _workspacePath;
  List<File> get workspaceFiles => _workspaceFiles;
  double get fontSize => _fontSize;
  bool get autoSave => _autoSave;

  void updateContent(String newContent) {
    if (_content != newContent) {
      _content = newContent;
      _isModified = _content != _originalContent;
      
      // Update the active file's content in memory if needed (though we currently read from _content)
      
      // Debounce preview update (fast)
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 150), () {
        if (_previewContent != _content) {
          _previewContent = _content;
          notifyListeners();
        }
      });

      // Auto-save debounce (longer)
      if (_autoSave && _isModified) {
        _autoSaveTimer?.cancel();
        _autoSaveTimer = Timer(const Duration(seconds: 3), () {
          if (_isModified) saveFile();
        });
      }
      
      // Notify immediately for status bar/dirty indicators
      notifyListeners();
    }
  }

  // Settings Methods
  void updateFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  void toggleAutoSave() {
    _autoSave = !_autoSave;
    notifyListeners();
  }

  // Workspace Methods
  Future<void> loadWorkspace() async {
    String? selectedDirectory = await FilePicker.getDirectoryPath();
    if (selectedDirectory != null) {
      _workspacePath = selectedDirectory;
      await refreshWorkspace();
    }
  }

  Future<void> refreshWorkspace() async {
    if (_workspacePath == null) return;
    try {
      final dir = Directory(_workspacePath!);
      final entities = await dir.list().toList();
      _workspaceFiles = entities
          .whereType<File>()
          .where((f) => f.path.endsWith('.md') || f.path.endsWith('.markdown'))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing workspace: $e');
    }
  }

  Future<void> createFile(String name) async {
    if (_workspacePath == null) return;
    try {
      final path = '$_workspacePath${Platform.pathSeparator}$name.md';
      final file = File(path);
      await file.writeAsString('');
      await refreshWorkspace();
      await openFileDirectly(file);
    } catch (e) {
      debugPrint('Error creating file: $e');
    }
  }

  Future<void> deleteFile(File file) async {
    try {
      await file.delete();
      if (_currentFilePath == file.path) {
        newFile();
      }
      await refreshWorkspace();
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  Future<void> renameFile(File file, String newName) async {
    try {
      final newPath = '${file.parent.path}${Platform.pathSeparator}$newName.md';
      final renamed = await file.rename(newPath);
      if (_currentFilePath == file.path) {
        _currentFilePath = renamed.path;
      }
      await refreshWorkspace();
    } catch (e) {
      debugPrint('Error renaming file: $e');
    }
  }

  Future<void> openFileDirectly(File file) async {
    try {
      // Check if already open
      int existingIndex = _openFiles.indexWhere((f) => f.path == file.path);
      if (existingIndex != -1) {
        _activeTabIndex = existingIndex;
      } else {
        _openFiles.add(file);
        _activeTabIndex = _openFiles.length - 1;
      }

      _content = await file.readAsString();
      _currentFilePath = file.path;
      _originalContent = _content;
      _isModified = false;
      _previewContent = _content;
      notifyListeners();
    } catch (e) {
      debugPrint('Error opening file directly: $e');
    }
  }

  void closeTab(int index) {
    if (index >= 0 && index < _openFiles.length) {
      _openFiles.removeAt(index);
      if (_openFiles.isEmpty) {
        newFile();
      } else {
        if (_activeTabIndex >= _openFiles.length) {
          _activeTabIndex = _openFiles.length - 1;
        }
        openFileDirectly(_openFiles[_activeTabIndex]);
      }
      notifyListeners();
    }
  }

  void switchTab(int index) {
    if (index >= 0 && index < _openFiles.length) {
      _activeTabIndex = index;
      openFileDirectly(_openFiles[index]);
    }
  }

  void updateSelection(int start, int end) {
    _selectionStart = start;
    _selectionEnd = end;
  }

  void toggleSplitScreen() {
    _isSplitScreen = !_isSplitScreen;
    notifyListeners();
  }

  void toggleWrap() {
    _isWrapped = !_isWrapped;
    notifyListeners();
  }

  void refreshPreview() {
    notifyListeners();
  }

  void updateScroll(double percentage) {
    if ((_scrollPercentage - percentage).abs() > 0.01) {
      _scrollPercentage = percentage;
      notifyListeners();
    }
  }

  Future<void> openFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown', 'txt'],
      );

      if (result != null) {
        if (kIsWeb) {
          final fileBytes = result.files.first.bytes;
          if (fileBytes != null) {
            _content = utf8.decode(fileBytes);
            _currentFilePath = result.files.first.name;
          }
        } else {
          final file = File(result.files.single.path!);
          _content = await file.readAsString();
          _currentFilePath = file.path;
        }
        _originalContent = _content;
        _isModified = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
    }
  }

  Future<void> saveFile() async {
    if (_currentFilePath.isEmpty || kIsWeb) {
      await saveFileAs();
      return;
    }

    try {
      final file = File(_currentFilePath);
      await file.writeAsString(_content);
      _originalContent = _content;
      _isModified = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving file: $e');
    }
  }

  Future<void> saveFileAs() async {
    try {
      String? outputPath = await FilePicker.saveFile(
        dialogTitle: 'Save Markdown As',
        fileName: _currentFilePath.isEmpty ? 'Untitled.md' : _currentFilePath.split(Platform.pathSeparator).last,
        allowedExtensions: ['md'],
      );

      if (outputPath != null) {
        if (!kIsWeb) {
          final file = File(outputPath);
          await file.writeAsString(_content);
          _currentFilePath = outputPath;
        } else {
          // Web handling for saveFile usually requires different approach (blob download)
          // For now we simulate save for web
          _currentFilePath = outputPath;
        }
        _originalContent = _content;
        _isModified = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error saving file as: $e');
    }
  }

  void insertSnippet(String prefix, [String suffix = '', int? selectionStart, int? selectionEnd]) {
    final start = selectionStart ?? _content.length;
    final end = selectionEnd ?? _content.length;

    if (start >= 0 && end >= start) {
      final selectedText = _content.substring(start, end);
      final newText = _content.replaceRange(start, end, '$prefix$selectedText$suffix');
      
      _content = newText;
      _isModified = _content != _originalContent;
      _previewContent = _content;
      
      // Request selection update
      if (start == end) {
        _requestSelectionOffset = start + prefix.length;
      } else {
        _requestSelectionOffset = start + prefix.length + selectedText.length + suffix.length;
      }

      notifyListeners();
    }
  }

  void newFile() {
    _content = '';
    _originalContent = '';
    _currentFilePath = '';
    _isModified = false;
    notifyListeners();
  }
}
