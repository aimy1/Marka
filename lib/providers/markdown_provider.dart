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
    // Start with a Welcome session
    _sessions.add(DocSession(
      name: 'Welcome.md',
      content: _welcomeMarkdown,
      originalContent: _welcomeMarkdown,
    ));
    _activeTabIndex = 0;
    _previewContent = _welcomeMarkdown;
    
    // Load persisted workspaces safely after construction
    Future.microtask(() => _loadPersistedWorkspaces());
  }

  Future<void> _loadPersistedWorkspaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPaths = prefs.getStringList('workspace_paths');
      if (savedPaths != null && savedPaths.isNotEmpty) {
        for (var path in savedPaths) {
          if (!_workspacePaths.contains(path)) {
            _workspacePaths.add(path);
          }
        }
        await refreshWorkspace();
      }
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
      
      // Debounce preview update
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 150), () {
        if (_previewContent != session.content) {
          _previewContent = session.content;
          notifyListeners();
        }
      });

      // Auto-save debounce
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
              debugPrint('Web File Read Success: ${platformFile.name}, bytes: ${platformFile.bytes!.length}');
            } else {
              content = "--- ERROR: READ FAILED ---\n\nThe file '${platformFile.name}' was selected, but the browser returned zero bytes.\n\nPossible reasons:\n1. Browser security restrictions.\n2. The file is being used by another process.\n3. Memory limits on Web.\n\nPlease try saving the file locally and dragging it again, or use a different browser.";
              debugPrint('Web File Read Failure: ${platformFile.name}');
            }
            path = "web://${platformFile.name}";
          } else {
            path = platformFile.path;
            if (path != null) {
              content = await io.File(path).readAsString();
              
              // Auto-add folder to workspaces if not already there
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
            
            // Replace initial welcome/untitled file if it's the only one and not modified
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

          // On Web, simulate a workspace for these files
          if (kIsWeb && virtualWebWorkspace != null) {
            if (!_workspacePaths.contains(virtualWebWorkspace)) {
              _workspacePaths.add(virtualWebWorkspace);
            }
            
            _workspaceFilesMap.putIfAbsent(virtualWebWorkspace, () => []);
            if (!_workspaceFilesMap[virtualWebWorkspace]!.any((f) => f.path == (path ?? platformFile.name))) {
              _workspaceFilesMap[virtualWebWorkspace]!.add(
                WorkspaceItem(path: path ?? "web://${platformFile.name}", name: platformFile.name)
              );
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

      String? outputPath = await FilePicker.saveFile(
        dialogTitle: 'Save Markdown As',
        fileName: session.name,
        allowedExtensions: ['md'],
      );

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


  // Workspace Methods (Multiple Folders)
  Future<void> loadWorkspace([BuildContext? context]) async {
    if (kIsWeb) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Working directories restricted. Select multiple files to populate your project!'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
      openFile(); // This now supports multiple files and virtual workspace
      return;
    }
    
    try {
      String? selectedDirectory = await FilePicker.getDirectoryPath();
      if (selectedDirectory != null) {
        if (!_workspacePaths.contains(selectedDirectory)) {
          _workspacePaths.add(selectedDirectory);
          await _saveWorkspaces();
          await refreshWorkspace();
        }
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
    try {
      for (final path in _workspacePaths) {
        final dir = io.Directory(path);
        if (await dir.exists()) {
          final entities = await dir.list().toList();
          _workspaceFilesMap[path] = entities
              .whereType<io.File>()
              .where((f) => f.path.endsWith('.md') || f.path.endsWith('.markdown'))
              .map((f) => WorkspaceItem(path: f.path, name: f.path.split(pathSeparator).last))
              .toList();
        } else {
          // Folder removed/moved externally
          _workspaceFilesMap.remove(path);
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
        String content = '';
        if (kIsWeb) {
          // Web items are handled via initial open, direct open from sidebar should re-use existing session
          // or error out if not loaded correctly. Usually not reachable unless path is known.
          return; 
        } else {
          content = await io.File(path).readAsString();
        }
        
        final session = DocSession(
          path: path,
          name: path.split(pathSeparator).last,
          content: content,
          originalContent: content,
        );
        _sessions.add(session);
        _activeTabIndex = _sessions.length - 1;
        _previewContent = content;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error opening file directly: $e');
    }
  }

  // View Controls
  void toggleSplitScreen() {
    _isSplitScreen = !_isSplitScreen;
    notifyListeners();
  }

  void toggleWrap() {
    _isWrapped = !_isWrapped;
    notifyListeners();
  }

  void updateFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  void updateLineHeight(double height) {
    _lineHeight = height;
    notifyListeners();
  }

  void updateFontFamily(String family) {
    _fontFamily = family;
    notifyListeners();
  }

  void updateFontSize(double size) {
    _fontSize = size.clamp(8, 32);
    notifyListeners();
  }

  void updateLineHeight(double height) {
    _lineHeight = height.clamp(1.0, 3.0);
    notifyListeners();
  }

  void updateSelection(int start, int end) {
    _requestSelectionOffset = start;
    notifyListeners();
  }

  void toggleAutoSave() {
    _autoSave = !_autoSave;
    notifyListeners();
  }

  void updateScroll(double percentage) {
    final session = activeSession;
    if (session != null && (session.scrollPercentage - percentage).abs() > 0.01) {
      session.scrollPercentage = percentage;
      notifyListeners();
    }
  }

  void updateSelection(int start, int end) {
    final session = activeSession;
    if (session != null) {
      session.selectionStart = start;
      session.selectionEnd = end;
    }
  }

  void consumeSelectionRequest() {
    _requestSelectionOffset = null;
  }

  void refreshPreview() {
    notifyListeners();
  }

  Future<void> renameFile(String oldPath, String newName) async {
    try {
      final separator = getPathSeparator();
      String newPath;
      
      if (kIsWeb) {
        // Virtual rename for Web
        final parts = oldPath.split('/');
        parts.removeLast();
        newPath = parts.isEmpty ? "web://$newName" : "${parts.join('/')}/$newName.md";
      } else {
        // Ensure .md extension
        final cleanName = newName.toLowerCase().endsWith('.md') ? newName : '$newName.md';
        final lastSeparator = oldPath.lastIndexOf(separator);
        final directory = lastSeparator != -1 ? oldPath.substring(0, lastSeparator) : '';
        newPath = directory.isEmpty ? cleanName : "$directory$separator$cleanName";
        
        // Physical rename
        final file = io.File(oldPath);
        if (await file.exists()) {
          await file.rename(newPath);
        }
      }

      // 1. Update Sessions
      for (var session in _sessions) {
        if (session.path == oldPath) {
          session.path = newPath;
          session.name = newName.toLowerCase().endsWith('.md') ? newName : '$newName.md';
        }
      }

      // 2. Update Workspace Map
      for (var workspacePath in _workspacePaths) {
        final files = _workspaceFilesMap[workspacePath];
        if (files != null) {
          for (var i = 0; i < files.length; i++) {
            if (files[i].path == oldPath) {
              final newCleanName = newName.toLowerCase().endsWith('.md') ? newName : '$newName.md';
              files[i] = WorkspaceItem(path: newPath, name: newCleanName);
            }
          }
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error renaming file: $e');
    }
  }

  Future<void> createFile(String name, String folderPath) async {
    try {
      final cleanName = name.toLowerCase().endsWith('.md') ? name : '$name.md';
      final separator = getPathSeparator();
      final path = folderPath == 'Web Workspace' ? "web://$cleanName" : "$folderPath$separator$cleanName";
      
      if (!kIsWeb) {
        final file = io.File(path);
        if (!await file.exists()) {
          await file.writeAsString('');
        }
      }

      final session = DocSession(
        path: path,
        name: cleanName,
        content: '',
        originalContent: '',
      );
      _sessions.add(session);
      _activeTabIndex = _sessions.length - 1;
      _previewContent = '';
      
      // Update Workspace Map
      if (!_workspaceFilesMap.containsKey(folderPath)) {
        _workspaceFilesMap[folderPath] = [];
      }
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
        if (await file.exists()) {
          await file.delete();
        }
      }

      // 1. Close session if open
      _sessions.removeWhere((s) => s.path == path);
      if (_sessions.isEmpty) {
        newFile();
      } else {
        if (_activeTabIndex >= _sessions.length) {
          _activeTabIndex = _sessions.length - 1;
        }
        _previewContent = _sessions[_activeTabIndex].content;
      }

      // 2. Remove from Workspace Map
      for (var workspacePath in _workspacePaths) {
        _workspaceFilesMap[workspacePath]?.removeWhere((f) => f.path == path);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  void insertSnippet(String prefix, [String suffix = '', int? selectionStart, int? selectionEnd]) {
    final session = activeSession;
    if (session == null) return;

    final start = selectionStart ?? session.content.length;
    final end = selectionEnd ?? session.content.length;

    if (start >= 0 && end >= start) {
      final selectedText = session.content.substring(start, end);
      final newText = session.content.replaceRange(start, end, '$prefix$selectedText$suffix');
      
      session.updateContent(newText);
      _previewContent = newText;
      
      if (start == end) {
        _requestSelectionOffset = start + prefix.length;
      } else {
        _requestSelectionOffset = start + prefix.length + selectedText.length + suffix.length;
      }

      notifyListeners();
    }
  }

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
