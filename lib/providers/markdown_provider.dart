import 'dart:io' as io show Directory, File, Platform, Process;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;
import '../models/doc_session.dart';
import '../models/workspace_item.dart';
import '../models/outline_item.dart';
import '../utils/path_utils.dart';

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
  bool _smoothScrolling = true;
  List<String> _openedFilePaths = [];
  bool _showLineNumbers = true;
  bool _showGridLines = false;
  bool _showLineHighlight = true;
  Timer? _backupTimer;
  Timer? _previewTimer;

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

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _backupTimer?.cancel();
    _previewTimer?.cancel();
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
  void toggleSmoothScrolling() { _smoothScrolling = !_smoothScrolling; _saveSettings(); notifyListeners(); }

  bool get showLineNumbers => _showLineNumbers;
  void toggleLineNumbers() { _showLineNumbers = !_showLineNumbers; _saveSettings(); notifyListeners(); }

  bool get showGridLines => _showGridLines;
  void toggleGridLines() { _showGridLines = !_showGridLines; _saveSettings(); notifyListeners(); }

  bool get showLineHighlight => _showLineHighlight;
  void toggleLineHighlight() { _showLineHighlight = !_showLineHighlight; _saveSettings(); notifyListeners(); }

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
  void updateContent(String newContent, {bool immediatePreview = false}) {
    final session = activeSession;
    if (session != null) {
      session.updateContent(newContent);
    } else {
      final newSession = DocSession(
        path: null,
        name: 'Untitled.md',
        content: newContent,
      );
      _sessions.add(newSession);
      _activeTabIndex = 0;
    }

    if (_searchQuery.isNotEmpty) _performSearch();
    if (_autoSave && !kIsWeb) saveFile();

    if (immediatePreview || newContent.length < 2000) {
      _previewTimer?.cancel();
      _previewContent = newContent;
      notifyListeners();
    } else {
      // Debounce markdown preview rebuilding for large documents to keep typing silky smooth (150ms)
      _previewTimer?.cancel();
      _previewTimer = Timer(const Duration(milliseconds: 150), () {
        if (_previewContent != newContent) {
          _previewContent = newContent;
          notifyListeners();
        }
      });
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

  final String? initialSingleFilePath;

  MarkdownProvider({this.initialSingleFilePath}) {
    _loadSettings();
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
    _openedFilePaths = prefs.getStringList('openedFilePaths') ?? [];
    _smoothScrolling = prefs.getBool('smoothScrolling') ?? true;
    _searchQuery = prefs.getString('searchQuery') ?? '';
    _replaceQuery = prefs.getString('replaceQuery') ?? '';
    _showLineNumbers = prefs.getBool('showLineNumbers') ?? true;
    _showGridLines = prefs.getBool('showGridLines') ?? false;
    _showLineHighlight = prefs.getBool('showLineHighlight') ?? true;
    
    await refreshWorkspace();
    
    // Single File Direct Open Mode
    if (initialSingleFilePath != null && initialSingleFilePath!.isNotEmpty) {
      await openSingleFile(initialSingleFilePath!);
    } else if (_openedFilePaths.isNotEmpty) {
      for (final p in _openedFilePaths) {
        await openFileDirectly(p, notify: false);
      }
    }

    // Auto-init for new users
    if (!kIsWeb && _workspacePaths.isEmpty && _openedFilePaths.isEmpty && _sessions.isEmpty) {
      await initWorkspace();
    }

    // Start periodic backup timer
    _backupTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _backupDrafts();
    });

    notifyListeners();
  }

  Future<void> openSingleFile(String filePath) async {
    if (kIsWeb) return;
    try {
      final file = io.File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final fileName = p.basename(filePath);

        int existingIndex = _sessions.indexWhere((s) => s.path == filePath);
        if (existingIndex != -1) {
          _activeTabIndex = existingIndex;
          _previewContent = _sessions[existingIndex].content;
        } else {
          final session = DocSession(
            path: filePath,
            name: fileName,
            content: content,
            originalContent: content,
          );

          if (_sessions.length == 1 &&
              (_sessions[0].name == 'Untitled.md' || _sessions[0].name == 'Welcome.md') &&
              !_sessions[0].isModified) {
            _sessions[0] = session;
            _activeTabIndex = 0;
          } else {
            _sessions.add(session);
            _activeTabIndex = _sessions.length - 1;
          }
          _previewContent = content;
        }

        final parentPath = file.parent.path;
        if (!_workspacePaths.contains(parentPath)) {
          _workspacePaths.add(parentPath);
          await refreshWorkspace();
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error opening single file: $e');
    }
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

      // Automatically open the Welcome.md file ONLY on first init
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
    await prefs.setStringList('openedFilePaths', _sessions.where((s) => s.path != null).map((s) => s.path!).toList());
    await prefs.setBool('smoothScrolling', _smoothScrolling);
    await prefs.setString('searchQuery', _searchQuery);
    await prefs.setString('replaceQuery', _replaceQuery);
    await prefs.setBool('showLineNumbers', _showLineNumbers);
    await prefs.setBool('showGridLines', _showGridLines);
    await prefs.setBool('showLineHighlight', _showLineHighlight);
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

  Future<void> openInExplorer(String path) async {
    if (kIsWeb) return;
    try {
      if (io.Platform.isWindows) {
        // Windows: open explorer and select the file
        await io.Process.run('explorer.exe', ['/select,', path]);
      } else if (io.Platform.isMacOS) {
        // macOS: reveal in finder
        await io.Process.run('open', ['-R', path]);
      } else {
        // Linux: open the parent directory
        final dir = io.Directory(path).parent.path;
        await io.Process.run('xdg-open', [dir]);
      }
    } catch (e) {
      debugPrint('Error opening directory: $e');
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

  Future<void> openFileDirectly(String path, {bool notify = true}) async {
    try {
      int existingIndex = _sessions.indexWhere((s) => s.path == path);
      if (existingIndex != -1) {
        _activeTabIndex = existingIndex;
        _previewContent = _sessions[existingIndex].content;
      } else {
        if (kIsWeb) return;
        final file = io.File(path);
        if (await file.exists()) {
          String content = await file.readAsString();
          
          // Check for backup draft recovery
          final prefs = await SharedPreferences.getInstance();
          final backupsStr = prefs.getString('session_backups');
          String loadedContent = content;
          bool modified = false;
          if (backupsStr != null) {
            final Map<String, dynamic> backups = jsonDecode(backupsStr);
            if (backups.containsKey(path)) {
              loadedContent = backups[path]!;
              if (loadedContent != content) {
                modified = true;
              }
            }
          }

          final session = DocSession(
            path: path, 
            name: path.split(pathSeparator).last, 
            content: loadedContent, 
            originalContent: content,
            isModified: modified,
          );
          _sessions.add(session);
          _activeTabIndex = _sessions.length - 1;
          _previewContent = loadedContent;
        }
      }
      if (notify) {
        _saveSettings();
        notifyListeners();
      }
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

  // --- Document Outline ---
  List<OutlineItem> getOutline() {
    final text = content;
    final List<OutlineItem> outline = [];
    
    int frontMatterLinesCount = 0;
    int startIdx = 0;
    if (text.startsWith('---\n') || text.startsWith('---\r\n')) {
      final match = RegExp(r'^---\r?\n([\s\S]*?)\r?\n---\r?\n?').firstMatch(text);
      if (match != null) {
        startIdx = match.end;
        frontMatterLinesCount = text.substring(0, startIdx).split('\n').length - 1;
      }
    }
    
    final lines = text.substring(startIdx).split('\n');
    int currentOffset = startIdx;
    final headingReg = RegExp(r'^(#{1,6})\s+(.+)$');
    
    for (int i = 0; i < lines.length; i++) {
      final lineText = lines[i];
      final match = headingReg.firstMatch(lineText);
      if (match != null) {
        final hashes = match.group(1)!;
        final title = match.group(2)!.trim();
        outline.add(OutlineItem(
          title: title,
          level: hashes.length,
          offset: currentOffset,
          line: frontMatterLinesCount + i + 1,
        ));
      }
      currentOffset += lineText.length + 1;
    }
    return outline;
  }

  void jumpToOffset(int offset) {
    _requestSelectionOffset = offset;
    notifyListeners();
  }

  // --- HTML Exporter ---
  String _generateFullHtml(String title, String bodyHtml, bool isDark) {
    final themeBg = isDark ? '#1e1e2e' : '#ffffff';
    final themeText = isDark ? '#cdd6f4' : '#4c4f69';
    final accent = isDark ? '#cba6f7' : '#1e66f5';
    final blockquoteBg = isDark ? 'rgba(255,255,255,0.03)' : 'rgba(0,0,0,0.03)';
    final codeBg = isDark ? '#11111b' : '#f2f2f2';
    
    return '''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>$title</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono&family=Outfit:wght@600;700;800&display=swap" rel="stylesheet">
<style>
  body {
    font-family: 'Inter', sans-serif;
    background-color: $themeBg;
    color: $themeText;
    line-height: 1.7;
    max-width: 800px;
    margin: 40px auto;
    padding: 0 24px;
  }
  h1, h2, h3, h4, h5, h6 {
    font-family: 'Outfit', sans-serif;
    color: $accent;
    margin-top: 24px;
    margin-bottom: 16px;
  }
  h1 { font-size: 2em; border-bottom: 1px solid rgba(0,0,0,0.1); padding-bottom: 8px; }
  h2 { font-size: 1.5em; }
  h3 { font-size: 1.25em; }
  p { margin-top: 0; margin-bottom: 16px; }
  a { color: $accent; text-decoration: none; }
  a:hover { text-decoration: underline; }
  code {
    font-family: 'JetBrains Mono', monospace;
    background-color: $codeBg;
    padding: 2px 6px;
    border-radius: 4px;
    font-size: 0.9em;
  }
  pre {
    background-color: $codeBg;
    padding: 16px;
    border-radius: 8px;
    overflow-x: auto;
  }
  pre code {
    padding: 0;
    background-color: transparent;
    font-size: 0.85em;
  }
  blockquote {
    border-left: 4px solid $accent;
    background-color: $blockquoteBg;
    padding: 8px 16px;
    margin: 0 0 16px 0;
    border-radius: 0 8px 8px 0;
  }
  table {
    border-collapse: collapse;
    width: 100%;
    margin-bottom: 16px;
  }
  th, td {
    border: 1px solid rgba(0,0,0,0.1);
    padding: 8px 12px;
    text-align: left;
  }
  th {
    background-color: $blockquoteBg;
    font-weight: 600;
  }
</style>
</head>
<body>
$bodyHtml
</body>
</html>''';
  }

  Future<void> exportToHtml(BuildContext context) async {
    final session = activeSession;
    if (session == null) return;
    try {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final parsed = md.markdownToHtml(session.content, extensionSet: md.ExtensionSet.gitHubFlavored);
      final fullHtml = _generateFullHtml(session.name, parsed, isDark);
      
      if (kIsWeb) {
        await Clipboard.setData(ClipboardData(text: fullHtml));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('copied'))));
        }
        return;
      }
      
      String defaultName = session.name.replaceAll('.md', '.html');
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: t('export_html'),
        fileName: defaultName,
        allowedExtensions: ['html'],
      );
      
      if (outputPath != null) {
        final file = io.File(outputPath);
        await file.writeAsString(fullHtml);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported successfully to $outputPath')));
        }
      }
    } catch (e) {
      debugPrint('Error exporting HTML: $e');
    }
  }

  // --- Draft Backups ---
  Future<void> _backupDrafts() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, String> backups = {};
      for (final s in _sessions) {
        if (s.path != null && s.isModified) {
          backups[s.path!] = s.content;
        }
      }
      if (backups.isNotEmpty) {
        await prefs.setString('session_backups', jsonEncode(backups));
      } else {
        await prefs.remove('session_backups');
      }
    } catch (e) {
      debugPrint('Error backing up drafts: $e');
    }
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
      'show_line_numbers': 'Show Line Numbers',
      'show_grid_lines': 'Show Grid Reference Lines',
      'export': 'Export',
      'export_html': 'Export to HTML',
      'copy_html': 'Copy HTML Snippet',
      'copy_rich_text': 'Copy as Rich Text',
      'outline': 'Outline',
      'files': 'Explorer',
      'table_wizard': 'Insert Table...',
      'table_wizard_title': 'Table Generator',
      'rows': 'Rows',
      'cols': 'Columns',
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
      'replace_all': 'Replace All',
      'no_results': 'No matching results',
      'interface': 'Interface',

      'general': 'General',
      'editor': 'Editor',
      'appearance': 'Appearance',
      'advanced': 'Advanced',
      'about': 'About',
      'smooth_scrolling': 'Smooth Scrolling',
      'spaces': 'Spaces',
      'about_desc': 'Marka is a professional-grade Markdown editor designed for industrial writing and focus. [v3.3.10]',

      'about_version': 'Version',
      'about_github': 'GitHub Repository',
      'about_author': 'Author',
      'about_license': 'License',
      'find': 'Find',

      'open_location': 'Open File Location',
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
      'show_line_numbers': '显示行号',
      'show_grid_lines': '显示网格参考线',
      'line_highlight': '激活行高亮',
      'export': '分享与导出',
      'export_html': '导出为 HTML',
      'copy_html': '复制 HTML 代码',
      'copy_rich_text': '复制为富文本',
      'outline': '大纲',
      'files': '文件树',
      'table_wizard': '插入表格...',
      'table_wizard_title': '表格生成器',
      'rows': '行数',
      'cols': '列数',
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
      'auto_pairing': '自动补全括号符号',
      'editor_padding': '编辑器左右间距',
      'pro_features': '高级功能',

      'general': '常规',
      'editor': '编辑器',
      'appearance': '外观',
      'advanced': '高级',
      'about': '关于 Marka',
      'smooth_scrolling': '平滑滚动',
      'spaces': '个空格',
      'about_desc': 'Marka 是一款专注于高品质专注写作与极客排版的工业级 Markdown 编辑器。[v3.3.10]',
      'about_version': '软件版本',
      'about_github': 'GitHub 开源仓库',
      'about_author': '开发者',
      'about_license': '开源协议',
      'find': '查找文本',
      'replace_all': '全量替换',
      'no_results': '暂无匹配结果',
      'interface': '界面与交互',
      'open_location': '打开文件所在位置',
    },
  };

  static const String _welcomeMarkdown = r'''---
title: 🚀 Marka IDE: 极客写作与原子排版工作站
subtitle: 零垂直抖动、隔离重绘、高帧率拉伸
date: 2026-07-16
author: Marka Engine Core Team
version: v3.3.8
tags: [Kate排版, Catppuccin, 隔离重绘, 工作室美学]
---

# 🚀 欢迎开启您的专业创作旅程

> **“至简，即是至繁。”**
> 
> Marka 是一款为极客与专业创作者打造的精准排版 Markdown 写作工具。我们追求极致的排版精度、流畅的性能响应和纯净的视觉美感。本篇指南将作为您的第一篇交互式文档，带您探索 Marka 的独特魅力。

---

## 🎨 第一部分：Marka IDE 核心工业级特性 (The Geek Station)

### 📐 1.1 像素级基线对齐 (Kate 排版引擎)
* **零垂直抖动**: 通过 `StrutStyle` 物理锁定，将每行文本强制分配在 `21 像素` 的原子网格中。
* **正文-行号对齐**: 行号字体与正文字体实时同步，并应用 `TextLeadingDistribution.even`，确保即使处理 `100,000+` 行的长文，行号与正文基线也始终保持**像素级绝对齐平**。
* **纯净打字边界**: 剔除 Flutter 默认的 `filled` 偏移，还原最纯粹、精准的打字排版边界。

### 🎛️ 1.2 双维度自由伸缩工作区 (Fluid Resizing)
* **可拖拽侧边栏**: 鼠标移向左侧文件区右边界，指针变为 `↔`，支持在 `180px ~ 450px` 之间自由调节文件树宽度。
* **自由分栏占比**: 开启分屏后，拖拽中间的分割线即可调整编辑区与预览区的显示比例。
* **60FPS 渲染隔离**: 宽高计算采用局部状态隔离技术，拖拽时仅调整容器大小，不引发全局文件树重建及文本解析，滑动极其顺滑。
* **瞬时反馈**: 折叠动画优雅滑行 300ms，手动拖拽时瞬时 0ms 响应，真正实现零延迟跟手体验。

### 🔮 1.3 极简交互与美学反馈
* **定制版 themed 滚动条**: 极细 `6px` 圆角胶囊滚动条，在闲置时与背景融为一体，悬停或拖拽时优雅点亮为主调的 Catppuccin 标志性颜色。
* **微交互彩蛋**: 新版 tab bar 滑动切换动效、搜索面板弹性滑入、以及侧边栏激活项脉冲呼吸灯，让您的每次操作都伴随精致的视觉回馈。
* **高级选区主题**: 文本选区背景与指示气泡采用 Mauve 紫，高亮对比度提升至 `0.3`，选中文本更加醒目。

---

## ✍️ 第二部分：Markdown 排版演练 (The Writing Master)

请在右侧分栏中对照实时预览效果，体验 Markdown 带来的专注美感。

### 2.1 基础排版与装饰
* **加粗突出**: `**加粗文本**` -> **加粗文本**
* *斜体强调*: `*斜体文本*` -> *斜体文本*
* ~~误删划除~~: `~~删除线文本~~` -> ~~删除线文本~~
* `行内代码`: 包裹在反引号中，如 \`void main()\`

> [!NOTE]
> **排版贴士**：在 Marka 中，这些格式都有对应的快捷键，例如 `Ctrl + B` 加粗，`Ctrl + I` 斜体。你可以选中文字后直接按快捷键进行包装！

### 2.2 多级标题层级
在 Markdown 中使用不同数量的 `#` 号来控制标题级数：
# 一级大标题 (H1)
## 二级副标题 (H2)
### 三级小标题 (H3)

### 2.3 任务看板与列表
* **无序列表**: 使用 `-` 或 `*` 符号。
* **有序列表**: 使用 `1. `、`2. ` 符号。
* [x] **行号基线同步**：已完美对齐。
* [x] **双滚动条清理**：已隐藏原生滚动条，只保留定制滚动条。
* [ ] **侧边栏拉伸**：尝试拖拽左侧侧边栏。
* [ ] **分栏拉伸**：尝试拖拽中间分割线。
* [ ] **高亮选区**：双击选中文本，查看 Mauve 紫选区效果。
* [ ] **快捷键行操作**：尝试按下 `Alt + ↑/↓` 移动当前代码行。

### 2.4 扩展排版演示

#### 2.4.1 代码块 (Syntax Highlighting)
```dart
// 体验 JetBrains Mono 带来的清爽代码布局
void main() {
  const message = "Hello Marka IDE v3.3.8!";
  print(message);
}
```

#### 2.4.2 交互式表格 (Tables)
| 功能模块 | 支持情况 | 备注版本 |
| :--- | :---: | :--- |
| **Kate 原子网格** | 🟢 已上线 | Engine 3.0 像素级精度 |
| **工业级检索/替换** | 🟢 已上线 | 全量高亮 + 当前项强调 |
| **Undo/Redo 控制器**| 🟢 已上线 | 支持 Ctrl+Z/Y 事务级回滚 |
| **可拖动侧边栏/分栏** | 🟢 已上线 | 隔离重绘，60FPS 极速拉伸 |

#### 2.4.3 引用与警告块 (Alerts)
> [!TIP]
> **YAML Front Matter**: 文档最顶部的 `---` 区域定义了文档属性（如标题、日期、标签）。Marka 会智能解析它，并在预览区顶部生成一张卡片，十分适合用来写博客与学术记录！

> [!IMPORTANT]
> **实时同步滚动**: Marka 的编辑区 and 预览区是物理锁定的，当您滚动编辑区时，预览区会高精度按比例保持 1:1 对齐同步。

---

## ⚙️ 第三部分：专业级快捷键矩阵 (Productivity Flow)

| 分类 | 快捷键 | 功能描述 |
| :--- | :--- | :--- |
| **格式化** | `Ctrl + B` | **加粗** |
| | `Ctrl + I` | *斜体* |
| | `Ctrl + L` | 插入超链接 |
| | `Ctrl + Shift + I` | 插入图片 |
| | `Ctrl + 1 / 2 / 3` | 转换为 H1 / H2 / H3 标题 |
| **行编辑** | `Alt + ↑/↓` | **将当前行向上/下移动一行（极速排版）** |
| | `Ctrl + Shift + K` | **删除当前整行** |
| | `Shift + Alt + ↓` | **复制当前行到下一行** |
| | `Ctrl + /` | 开关单行 HTML 注释 |
| | `Tab / Shift+Tab` | 对选中行进行缩进 / 反向缩进 |
| **搜索** | `Ctrl + F` | 开启/关闭 查找与替换检索控制面板 |
| | `Escape` | 关闭浮窗、面板或设置对话框 |

---

由 **Marka 团队** 倾力设计与维护。愿它能成为您手中最犀利的创作武器。

*"至简即是至繁。"*
''';
}
