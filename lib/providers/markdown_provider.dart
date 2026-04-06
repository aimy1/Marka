import 'dart:io' as io show Directory, File, Platform;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/doc_session.dart';
import '../models/workspace_item.dart';

class MarkdownProvider with ChangeNotifier {
  List<DocSession> _sessions = [];
  int _activeTabIndex = 0;
  String _previewContent = _welcomeMarkdown;
  List<String> _workspacePaths = [];
  Map<String, List<WorkspaceItem>> _workspaceFilesMap = {};
  
  // Settings v2.7.1 Consolidated
  String _fontFamily = 'JetBrains Mono';
  double _fontSize = 14.0;
  double _lineHeight = 1.5;
  bool _autoSave = false;
  bool _isSplitScreen = true;
  bool _isWrapped = true;
  bool _showToolbar = true;
  bool _isSyncScroll = true;
  bool _autoPairing = true;
  int _tabSize = 2;
  double _editorPadding = 32.0;
  String _locale = 'en';
  bool _showLineNumbers = true;
  bool _highlightActiveLine = true;
  bool _smoothScrolling = true;

  // Kate-style Cursor Tracking (Debounced)
  int _cursorLine = 1;
  int _cursorColumn = 1;
  int _selectionLength = 0;
  Timer? _cursorTimer;
  
  // Search & Replace State (Throttled)
  String _searchQuery = '';
  List<int> _searchMatches = [];
  int _currentMatchIndex = -1;
  bool _showSearchOverlay = false;
  static const int _maxSearchMatches = 5000;

  MarkdownProvider() {
    _loadSettings();
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    super.dispose();
  }

  // Getters
  List<DocSession> get sessions => _sessions;
  int get activeTabIndex => _activeTabIndex;
  DocSession? get activeSession => _sessions.isNotEmpty ? _sessions[_activeTabIndex] : null;
  String get content => activeSession?.content ?? '';
  String get previewContent => _previewContent;
  bool get isModified => activeSession?.isModified ?? false;
  List<String> get workspacePaths => _workspacePaths;
  Map<String, List<WorkspaceItem>> get workspaceFilesMap => _workspaceFilesMap;
  
  String get fontFamily => _fontFamily;
  double get fontSize => _fontSize;
  double get lineHeight => _lineHeight;
  bool get autoSave => _autoSave;
  bool get isSplitScreen => _isSplitScreen;
  bool get isWrapped => _isWrapped;
  bool get showToolbar => _showToolbar;
  bool get isSyncScroll => _isSyncScroll;
  bool get autoPairing => _autoPairing;
  int get tabSize => _tabSize;
  double get editorPadding => _editorPadding;
  String get locale => _locale;
  bool get showLineNumbers => _showLineNumbers;
  bool get highlightActiveLine => _highlightActiveLine;
  bool get smoothScrolling => _smoothScrolling;

  int get cursorLine => _cursorLine;
  int get cursorColumn => _cursorColumn;
  int get selectionLength => _selectionLength;
  int get selectionStart => activeSession?.selectionStart ?? 0;
  int get selectionEnd => activeSession?.selectionEnd ?? 0;

  int? _requestSelectionOffset;
  int? get requestSelectionOffset => _requestSelectionOffset;

  double get scrollPercentage => activeSession?.scrollPercentage ?? 0.0;
  int get wordCount => content.trim().isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
  String? get currentFilePath => activeSession?.path;
  String get pathSeparator => io.Platform.isWindows ? '\\' : '/';

  // ── Pro Settings v2.7.1 ──
  void updateFontSize(double v) { _fontSize = v.clamp(8, 32); _saveSettings(); notifyListeners(); }
  void updateLineHeight(double v) { _lineHeight = v.clamp(1.0, 3.0); _saveSettings(); notifyListeners(); }
  void updateFontFamily(String v) { _fontFamily = v; _saveSettings(); notifyListeners(); }
  void toggleWrap() { _isWrapped = !_isWrapped; _saveSettings(); notifyListeners(); }
  void toggleAutoSave() { _autoSave = !_autoSave; _saveSettings(); notifyListeners(); }
  void updateEditorPadding(double v) { _editorPadding = v.clamp(16, 96); _saveSettings(); notifyListeners(); }
  void toggleAutoPairing() { _autoPairing = !_autoPairing; _saveSettings(); notifyListeners(); }
  void updateTabSize(int v) { _tabSize = v == 4 ? 4 : 2; _saveSettings(); notifyListeners(); }
  void toggleLineNumbers() { _showLineNumbers = !_showLineNumbers; _saveSettings(); notifyListeners(); }
  void toggleHighlightActiveLine() { _highlightActiveLine = !_highlightActiveLine; _saveSettings(); notifyListeners(); }
  void toggleSmoothScrolling() { _smoothScrolling = !_smoothScrolling; _saveSettings(); notifyListeners(); }
  String? get currentFileDirectory => activeSession?.path?.contains(pathSeparator) == true 
      ? activeSession?.path?.substring(0, activeSession?.path?.lastIndexOf(pathSeparator)) 
      : null;

  // Search Getters
  String get searchQuery => _searchQuery;
  List<int> get searchMatches => _searchMatches;
  int get currentMatchIndex => _currentMatchIndex;
  bool get showSearchOverlay => _showSearchOverlay;

  // ── Advanced Search v2.8.0 ──
  bool _isCaseSensitive = false;
  bool get isCaseSensitive => _isCaseSensitive;
  void toggleCaseSensitive() { _isCaseSensitive = !_isCaseSensitive; _performSearch(); notifyListeners(); }

  bool _isRegex = false;
  bool get isRegex => _isRegex;
  void toggleRegex() { _isRegex = !_isRegex; _performSearch(); notifyListeners(); }

  String _replaceQuery = '';
  String get replaceQuery => _replaceQuery;
  void updateReplaceQuery(String v) { _replaceQuery = v; notifyListeners(); }


  // State Management
  void updateContent(String newContent) {
    final session = activeSession;
    if (session != null) {
      session.updateContent(newContent);
      _previewContent = newContent;
      if (_autoSave && !kIsWeb) saveFile();
      if (_searchQuery.isNotEmpty) _performSearch();
      notifyListeners();
    }
  }

  // Debounced Cursor Info Performance Optimization
  void updateCursorInfo(int line, int col, int selLength) {
    if (_cursorLine != line) {
      _cursorLine = line;
      _cursorColumn = col;
      _selectionLength = selLength;
      notifyListeners();
      return;
    }
    _cursorTimer?.cancel();
    _cursorTimer = Timer(const Duration(milliseconds: 50), () {
      if (_cursorColumn != col || _selectionLength != selLength) {
        _cursorColumn = col;
        _selectionLength = selLength;
        notifyListeners();
      }
    });
  }

  // Search Logic
  void toggleSearchOverlay() {
    _showSearchOverlay = !_showSearchOverlay;
    if (!_showSearchOverlay) {
      // Clear matches when closing, but keep the query for persistence
      _searchMatches = [];
      _currentMatchIndex = -1;
      _saveSettings(); // Save the query state
    } else {
      if (_searchQuery.isNotEmpty) _performSearch(jump: false);
    }
    notifyListeners();
  }

  void updateSearch(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _performSearch(jump: false);
    notifyListeners();
  }

  void _performSearch({bool jump = false}) {
    _searchMatches = [];
    if (_searchQuery.isEmpty) {
      _currentMatchIndex = -1;
      return;
    }
    
    try {
      final text = content;
      final q = _isRegex ? _searchQuery : RegExp.escape(_searchQuery);
      final regex = RegExp(q, caseSensitive: _isCaseSensitive, multiLine: true);
      
      final matches = regex.allMatches(text);
      for (final m in matches) {
        if (_searchMatches.length >= _maxSearchMatches) break;
        _searchMatches.add(m.start);
      }
    } catch (e) {
      debugPrint('Search Regex Error: $e');
    }
    
    if (_searchMatches.isNotEmpty) {
      // Logic: If we are jumping, go to the first match. 
      // If not, just update the match count but stay where we are.
      if (_currentMatchIndex < 0 || _currentMatchIndex >= _searchMatches.length) {
         _currentMatchIndex = 0;
      }
      if (jump) {
        _requestSelectionOffset = _searchMatches[_currentMatchIndex];
      }
    } else {
      _currentMatchIndex = -1;
    }
  }

  void findNext() {
    if (_searchMatches.isEmpty) return;
    _currentMatchIndex = (_currentMatchIndex + 1) % _searchMatches.length;
    _requestSelectionOffset = _searchMatches[_currentMatchIndex];
    notifyListeners();
  }

  void findPrev() {
    if (_searchMatches.isEmpty) return;
    _currentMatchIndex = (_currentMatchIndex - 1 + _searchMatches.length) % _searchMatches.length;
    _requestSelectionOffset = _searchMatches[_currentMatchIndex];
    notifyListeners();
  }

  void replaceNext() {
    if (_searchMatches.isEmpty || _currentMatchIndex == -1) return;
    final start = _searchMatches[_currentMatchIndex];
    // Find length of current match
    final text = content;
    final q = _isRegex ? _searchQuery : RegExp.escape(_searchQuery);
    final regex = RegExp(q, caseSensitive: _isCaseSensitive);
    final match = regex.matchAsPrefix(text, start);
    if (match != null) {
      final newContent = text.replaceRange(match.start, match.end, _replaceQuery);
      updateContent(newContent);
    }
  }

  void replaceAll() {
    if (_searchQuery.isEmpty) return;
    final q = _isRegex ? _searchQuery : RegExp.escape(_searchQuery);
    final regex = RegExp(q, caseSensitive: _isCaseSensitive);
    final newContent = content.replaceAll(regex, _replaceQuery);
    updateContent(newContent);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fontFamily = prefs.getString('fontFamily') ?? 'Inter';
    _fontSize = prefs.getDouble('fontSize') ?? 14.0;
    _lineHeight = prefs.getDouble('lineHeight') ?? 1.6;
    _autoSave = prefs.getBool('autoSave') ?? false;
    _isSplitScreen = prefs.getBool('isSplitScreen') ?? true;
    _isWrapped = prefs.getBool('isWrapped') ?? true;
    _showToolbar = prefs.getBool('showToolbar') ?? true;
    _isSyncScroll = prefs.getBool('isSyncScroll') ?? true;
    _autoPairing = prefs.getBool('autoPairing') ?? true;
    _tabSize = prefs.getInt('tabSize') ?? 2;
    _editorPadding = prefs.getDouble('editorPadding') ?? 32.0;
    _locale = prefs.getString('locale') ?? 'en';
    _workspacePaths = prefs.getStringList('workspacePaths') ?? [];
    _showLineNumbers = prefs.getBool('showLineNumbers') ?? true;
    _highlightActiveLine = prefs.getBool('highlightActiveLine') ?? true;
    _smoothScrolling = prefs.getBool('smoothScrolling') ?? true;
    _searchQuery = prefs.getString('searchQuery') ?? '';
    _replaceQuery = prefs.getString('replaceQuery') ?? '';
    
    _previewContent = content;
    await refreshWorkspace();
    
    // Auto-init for new professional users (v3.3.4)
    if (!kIsWeb && _workspacePaths.isEmpty) {
      await initWorkspace();
    } else if (_sessions.isEmpty) {
      _sessions = [DocSession(name: 'Welcome.md', content: _welcomeMarkdown, originalContent: _welcomeMarkdown)];
    }
    notifyListeners();
  }

  Future<void> initWorkspace() async {
    if (kIsWeb) return;
    try {
      final root = io.Directory.current.path;
      final workspacePath = '$root${pathSeparator}Marka_Workspace';
      final dir = io.Directory(workspacePath);
      final welcomeFilePath = '$workspacePath${pathSeparator}Welcome.md';
      
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        final welcomeFile = io.File(welcomeFilePath);
        await welcomeFile.writeAsString(_welcomeMarkdown);
      }

      if (!_workspacePaths.contains(workspacePath)) {
        _workspacePaths.add(workspacePath);
        await _saveSettings();
        await refreshWorkspace();
      }

      // Automatically open the Welcome.md file for a great first impression
      await openFileDirectly(welcomeFilePath);
    } catch (e) {
      debugPrint('Error initializing Workspace: $e');
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontFamily', _fontFamily);
    await prefs.setDouble('fontSize', _fontSize);
    await prefs.setDouble('lineHeight', _lineHeight);
    await prefs.setBool('autoSave', _autoSave);
    await prefs.setBool('isSplitScreen', _isSplitScreen);
    await prefs.setBool('isWrapped', _isWrapped);
    await prefs.setBool('showToolbar', _showToolbar);
    await prefs.setBool('isSyncScroll', _isSyncScroll);
    await prefs.setBool('autoPairing', _autoPairing);
    await prefs.setInt('tabSize', _tabSize);
    await prefs.setDouble('editorPadding', _editorPadding);
    await prefs.setString('locale', _locale);
    await prefs.setStringList('workspacePaths', _workspacePaths);
    await prefs.setBool('showLineNumbers', _showLineNumbers);
    await prefs.setBool('highlightActiveLine', _highlightActiveLine);
    await prefs.setBool('smoothScrolling', _smoothScrolling);
    await prefs.setString('searchQuery', _searchQuery);
    await prefs.setString('replaceQuery', _replaceQuery);
  }

  void switchTab(int index) {
    if (index >= 0 && index < _sessions.length) {
      _activeTabIndex = index;
      _previewContent = _sessions[index].content;
      notifyListeners();
    }
  }

  void closeTab(int index) {
    if (_sessions.length > 1) {
      _sessions.removeAt(index);
      if (_activeTabIndex >= _sessions.length) _activeTabIndex = _sessions.length - 1;
      _previewContent = _sessions[_activeTabIndex].content;
    } else {
      _sessions = [DocSession(name: 'Untitled.md', content: '', originalContent: '')];
      _activeTabIndex = 0;
      _previewContent = '';
    }
    notifyListeners();
  }

  void newFile() {
    final session = DocSession(name: 'Untitled.md', content: '', originalContent: '');
    _sessions.add(session);
    _activeTabIndex = _sessions.length - 1;
    _previewContent = '';
    notifyListeners();
  }

  // File Operations
  Future<void> openFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown', 'txt'],
        allowMultiple: true,
      );

      if (result != null) {
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
      String? outputPath = await FilePicker.platform.saveFile(dialogTitle: 'Save Markdown As', fileName: session.name, allowedExtensions: ['md']);
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
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null && !_workspacePaths.contains(selectedDirectory)) {
        _workspacePaths.add(selectedDirectory);
        await _saveSettings();
        await refreshWorkspace();
      }
    } catch (e) {
      debugPrint('Error loading workspace: $e');
    }
  }

  void removeWorkspaceFolder(String path) {
    _workspacePaths.remove(path);
    _workspaceFilesMap.remove(path);
    _saveSettings();
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
  void toggleSplitScreen() { _isSplitScreen = !_isSplitScreen; _saveSettings(); notifyListeners(); }
  void toggleToolbar() { _showToolbar = !_showToolbar; _saveSettings(); notifyListeners(); }
  void toggleSyncScroll() { _isSyncScroll = !_isSyncScroll; _saveSettings(); notifyListeners(); }
  
  void updateSelection(int start, int end) {
    final s = activeSession;
    if (s != null) { s.selectionStart = start; s.selectionEnd = end; }
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
  }
  
  void updateLocale(String langCode) {
    _locale = langCode;
    _saveSettings();
    notifyListeners();
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
      'sync_scroll': 'Sync Scroll',
      'show_toolbar': 'Show Editor Toolbar',
      'copied': 'Copied to clipboard',
      'bold': 'Bold',
      'italic': 'Italic',
      'heading': 'Heading',
      'strikethrough': 'Strikethrough',
      'list': 'Bullet List',
      'ordered_list': 'Numbered List',
      'task_list': 'Task List',
      'link': 'Link',
      'image': 'Image',
      'code': 'Inline Code',
      'terminal': 'Code Block',
      'quote': 'Quote',
      'hr': 'Horizontal Line',
      'tab_size': 'Tab Size',
      'auto_pairing': 'Auto Pair Brackets',
      'editor_padding': 'Horizontal Padding',
      'line_highlight': 'Highlight Active Line',
      'pro_features': 'ADVANCED FEATURES',
      'appearance': 'INTERFACE APPEARANCE',
      'typography': 'FONT & SPACING',
      'ln_col': 'Ln {0}, Col {1}',
      'sel': 'Sel {0}',
      'search': 'Find...',
      'replace': 'Replace...',
      'replace_all': 'Replace All',
      'no_results': 'No matching results',
      'find': 'Find',
    },
    'zh': {
      'settings': '设置',
      'font_family': '字体',
      'font_size': '字号',
      'line_height': '行高',
      'auto_save': '自动保存',
      'theme': '主题模式',
      'language': '语言',
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
      'welcome_desc': '打开一个文件夹，开启您的 Markdown 创作之旅。',
      'open_files': '打开文件',
      'words': '字数统计',
      'save_tooltip': '立即保存 (Ctrl+S)',
      'new_file_tooltip': '新建文件',
      'split_tooltip': '切换分屏模式',
      'settings_tooltip': '偏好设置',
      'no_folders_open': '未打开任何工作目录',
      'remove_folder': '移除目录',
      'no_md_files': '暂无 .md 文件',
      'sync_scroll': '同步滚动预览',
      'show_toolbar': '显示编辑器工具栏',
      'copied': '已复制到剪贴板',
      'bold': '加粗',
      'italic': '斜体',
      'heading': '标题',
      'strikethrough': '删除线',
      'list': '无序列表',
      'ordered_list': '数字列表',
      'task_list': '任务列表',
      'link': '插入链接',
      'image': '插入图片',
      'code': '行内代码',
      'terminal': '代码块',
      'quote': '引用',
      'hr': '分割线',
      'tab_size': 'Tab 缩进大小',
      'auto_pairing': '自动补全括符号',
      'editor_padding': '编辑器左右间距',
      'line_highlight': '高亮当前行',
      'pro_features': '高级功能',
      'appearance': '界面外观',
      'typography': '字体排版',
      'ln_col': '行 {0}, 列 {1}',
      'sel': '已选 {0}',
      'search': '查找内容...',
      'replace': '替换为...',
      'replace_all': '全部替换',
      'no_results': '未找到结果',
      'find': '查找',
    },
  };



  static const String _welcomeMarkdown = r'''---
title: 🚀 Marka IDE: 您的专业创作空间
date: 2026-04-06
categories: [IDE, 教程, 效率]
tags: [Marka, Markdown, 精准对齐, 查找替换]
---

# 🚀 欢迎进入 Marka IDE

> **Marka: 专为专业人士打造的像素级对齐 Markdown 创作空间。**

本文档将作为您的第一篇交互式指南，带您快速掌握 **Marka** 的独家生产力特性与 **Markdown** 的标准排版方案。

---

## 🎨 第一部分：Marka IDE 特色功能 (The Power User)

Marka 不止是一个文本编辑器，它是一个基于工业级标准构建的创作工作站：

### 1.1 像素级对齐 (Kate 引擎)
- **视觉稳定性**: 通过 `StrutStyle` 强力锁定，无论字体大小，每一行都精确分布在原子网格中。
- **行号基线同步**: 行号与文本基线始终完美同步，即使是大规模文档也能保持视觉连贯。

### 1.2 工业级查找与替换
- **智能选区**: 完善的选区交互，点击移动光标、拖动快速选中文本。
- **高亮查找**: `Ctrl + F` 开启。全量颜色匹配高亮，当前匹配项橙色强调，按 `Enter` 快速跳转。

### 1.3 深度定制化
- **编辑器布局**: 在“设置 > 字数与排版”中调节左右间距，在极简居中与全宽录入间自由切换。
- **撤销/重做**: 专业的 `Undo/Redo` 控制器，全场景支持快捷键（Ctrl + Z / Y）操作。
- **分屏同步滚动**: 点击右上角分屏按钮，实现编辑器与预览窗口 1:1 物理百分比锁定。

---

## ✍️ 第二部分：Markdown 实战教程 (The Writing Master)

Markdown 旨在让您专注于内容而非格式。

### 2.1 文本样式与排版
- **粗体**: `**加粗文本**` -> **加粗文本**
- *斜体*: `*斜体文本*` -> *斜体文本*
- ~~删除线~~: `~~删除线文本~~` -> ~~删除线文本~~
- `行内代码`: 使用反引号 \`void main()\`

### 2.2 多级标题 (H1 - H3)
# 一级标题 (H1)
## 二级标题 (H2)
### 三级标题 (H3)

### 2.3 列表与任务管理
- **无序列表**: 使用 `-` 或 `*` 符号。
- **有序列表**: 使用 `1. ` 符号。
- [x] 已掌握 Marka 特色功能
- [ ] 完成这篇 Markdown 实战教程
- [ ] 尝试按下 `Tab` 调节缩进层级

### 2.4 代码块与表格
```dart
void main() {
  print("Hello Marka IDE!");
}
```

| 特性 | 支持情况 | 版本备注 |
| :--- | :--- | :--- |
| 查找高亮 | ✅ 已上线 | Engine 3.0+ |
| 原子网格 | ✅ 已上线 | Kate 级精度 |
| 撤销控制器 | ✅ 已上线 | 生产力套件 |

> "至简即是至繁。" —— 达芬奇

---

## ⚙️ 快捷键矩阵 (Productivity Flow)
- `Ctrl + B`: **加粗** / `Ctrl + I`: *斜体*
- `Ctrl + F`: **查找与替换** 面板
- `Alt + ↑/↓`: **向上/下快速移动整行**
- `Ctrl + Z`: **撤销** / `Ctrl + Y`: **重做**
- `Ctrl + \ `: **侧边栏开关**

---

### 💡 小贴士
**Hero Headers**: 在文档最顶部加入 YAML 属性（如上方的 `title`），Marka 会自动渲染为精美的文章卡片。
''';
}
