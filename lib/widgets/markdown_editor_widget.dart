import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/markdown_provider.dart';
import 'search_overlay_widget.dart';
import 'editor/editor_controller.dart';
import 'editor/editor_gutter.dart';

/// Marka v2.6.3 - Selection Interaction Fix
/// Removed experimental gesture listeners that blocked mouse selection.
/// Enforced desktopTextSelectionControls for 100% reliable mouse dragging.
class MarkdownEditorWidget extends StatefulWidget {
  const MarkdownEditorWidget({super.key});

  @override
  State<MarkdownEditorWidget> createState() => _MarkdownEditorWidgetState();
}

class _MarkdownEditorWidgetState extends State<MarkdownEditorWidget> {
  late MarkaEditorController _controller;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  static const double _fontSize = 14.0;
  static const double _lineHeight = 1.5;
  static const EdgeInsets _textPadding = EdgeInsets.symmetric(horizontal: 32, vertical: 24);

  int _lastTabIndex = -1;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<MarkdownProvider>(context, listen: false);
    _controller = MarkaEditorController(provider: provider);
    _controller.addListener(_onTextChanged);
    provider.addListener(_onProviderChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _onTextChanged() {
    final provider = Provider.of<MarkdownProvider>(context, listen: false);
    final text = _controller.text;
    if (text != provider.content) provider.updateContent(text);

    final sel = _controller.selection;
    if (sel.start >= 0) {
      final before = text.substring(0, sel.start.clamp(0, text.length));
      final lines = before.split('\n');
      provider.updateCursorInfo(lines.length, lines.last.length + 1, sel.end - sel.start);
      provider.updateSelection(sel.start, sel.end);
    }
  }

  void _onProviderChanged() {
    final provider = Provider.of<MarkdownProvider>(context, listen: false);
    final session = provider.activeSession;
    if (session == null) return;

    final sessionChanged = _lastTabIndex != provider.activeTabIndex;
    if (sessionChanged || _controller.text != session.content) {
      _lastTabIndex = provider.activeTabIndex;
      _controller.removeListener(_onTextChanged);
      _controller.value = TextEditingValue(
        text: session.content,
        selection: sessionChanged ? const TextSelection.collapsed(offset: 0) : _controller.selection,
      );
      _controller.addListener(_onTextChanged);
      if (sessionChanged && _scrollController.hasClients) _scrollController.jumpTo(0);
    }

    if (provider.requestSelectionOffset != null) {
      final off = provider.requestSelectionOffset!;
      _controller.selection = TextSelection(
        baseOffset: off, 
        extentOffset: provider.searchQuery.isNotEmpty ? off + provider.searchQuery.length : off
      );
      provider.consumeSelectionRequest();
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarkdownProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const _SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const _CloseSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const _EnterIntent(),
        LogicalKeySet(LogicalKeyboardKey.tab): const _IndentIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.tab): const _OutdentIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowUp): const _MoveLineUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): const _MoveLineDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.slash): const _ToggleCommentIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyK): const _DeleteLineIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): const _DuplicateLineIntent(),
        // Markdown Formatting Shortcuts
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB): const _FormatBoldIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI): const _FormatItalicIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyL): const _FormatLinkIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyI): const _FormatImageIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyX): const _FormatStrikethroughIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyQ): const _FormatQuoteIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.period): const _FormatInlineCodeIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyC): const _FormatCodeBlockIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit1): const _FormatH1Intent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit2): const _FormatH2Intent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit3): const _FormatH3Intent(),
      },
      child: Actions(
        actions: {
          _SearchIntent: _SearchAction(provider),
          _CloseSearchIntent: _CloseSearchAction(provider),
          _EnterIntent: _EnterAction(this),
          _IndentIntent: _IndentAction(this),
          _OutdentIntent: _OutdentAction(this),
          _MoveLineUpIntent: _MoveLineUpAction(this),
          _MoveLineDownIntent: _MoveLineDownAction(this),
          _ToggleCommentIntent: _ToggleCommentAction(this),
          _DeleteLineIntent: _DeleteLineAction(this),
          _DuplicateLineIntent: _DuplicateLineAction(this),
          _FormatBoldIntent: _SnippetAction(provider, '**', '**'),
          _FormatItalicIntent: _SnippetAction(provider, '*', '*'),
          _FormatLinkIntent: _SnippetAction(provider, '[', '](url)'),
          _FormatImageIntent: _SnippetAction(provider, '![', '](url)'),
          _FormatStrikethroughIntent: _SnippetAction(provider, '~~', '~~'),
          _FormatQuoteIntent: _SnippetAction(provider, '> ', ''),
          _FormatInlineCodeIntent: _SnippetAction(provider, '`', '`'),
          _FormatCodeBlockIntent: _SnippetAction(provider, '```\n', '\n```'),
          _FormatH1Intent: _SnippetAction(provider, '# ', ''),
          _FormatH2Intent: _SnippetAction(provider, '## ', ''),
          _FormatH3Intent: _SnippetAction(provider, '### ', ''),
        },
        child: Column(
          children: [
            if (provider.showToolbar) _buildToolbar(provider, isDark),
            Expanded(
              child: Stack(
                children: [
                  NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollUpdateNotification && provider.isSyncScroll) {
                         final max = n.metrics.maxScrollExtent;
                         if (max > 0) provider.updateScroll(n.metrics.pixels / max);
                      }
                      return false;
                    },
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        textSelectionTheme: TextSelectionThemeData(
                          selectionColor: isDark ? const Color(0xFFCBA6F7).withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                          selectionHandleColor: isDark ? const Color(0xFFCBA6F7) : Colors.blue,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (provider.showLineNumbers)
                             MarkaEditorGutter(
                               scrollController: _scrollController,
                               lineCount: _controller.text.split('\n').length,
                               fontSize: provider.fontSize,
                               lineHeight: provider.lineHeight,
                             ),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              scrollController: _scrollController,
                              focusNode: _focusNode,
                              maxLines: null,
                              expands: true,
                              cursorColor: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF),
                              cursorWidth: 1.2,
                              textAlignVertical: TextAlignVertical.top,
                              selectionControls: desktopTextSelectionControls,
                              onChanged: (text) {
                                _handleAutoPairing(text);
                                if (provider.showLineNumbers) setState(() {});
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 32, 
                                  vertical: provider.lineHeight * 16
                                ),
                              ),
                              strutStyle: StrutStyle(
                                forceStrutHeight: true,
                                height: provider.lineHeight,
                                fontSize: provider.fontSize,
                              ),
                              style: GoogleFonts.getFont(
                                provider.fontFamily,
                                fontSize: provider.fontSize,
                                height: provider.lineHeight,
                                letterSpacing: 0,
                                color: isDark ? const Color(0xFFCDD6F4) : const Color(0xFF4C4F69),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (provider.showSearchOverlay)
                    Positioned(top: 8, right: 16, child: SearchOverlayWidget(provider: provider)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _moveLine({required bool up}) {
    final text = _controller.text;
    final sel = _controller.selection;
    if (sel.start == -1) return;

    final lineStart = text.lastIndexOf('\n', sel.start - 1) + 1;
    final lineEnd = text.indexOf('\n', sel.start);
    final actualEnd = lineEnd == -1 ? text.length : lineEnd;
    final currentLine = text.substring(lineStart, actualEnd);

    if (up) {
      if (lineStart == 0) return;
      final prevLineStart = text.lastIndexOf('\n', lineStart - 2) + 1;
      final prevLine = text.substring(prevLineStart, lineStart - 1);
      
      final newText = text.replaceRange(prevLineStart, actualEnd, '$currentLine\n$prevLine');
      final newOffset = prevLineStart + (sel.start - lineStart);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    } else {
      if (actualEnd == text.length) return;
      final nextLineEnd = text.indexOf('\n', actualEnd + 1);
      final actualNextEnd = nextLineEnd == -1 ? text.length : nextLineEnd;
      final nextLine = text.substring(actualEnd + 1, actualNextEnd);
      
      final newText = text.replaceRange(lineStart, actualNextEnd, '$nextLine\n$currentLine');
      final newOffset = lineStart + nextLine.length + 1 + (sel.start - lineStart);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    }
  }

  void _duplicateLine() {
    final text = _controller.text;
    final sel = _controller.selection;
    final lineStart = text.lastIndexOf('\n', sel.start - 1) + 1;
    final lineEnd = text.indexOf('\n', sel.start);
    final actualEnd = lineEnd == -1 ? text.length : lineEnd;
    final currentLine = text.substring(lineStart, actualEnd);

    final newText = text.replaceRange(actualEnd, actualEnd, '\n$currentLine');
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: sel.start + currentLine.length + 1);
  }

  void _deleteLine() {
     final text = _controller.text;
     final sel = _controller.selection;
     final lineStart = text.lastIndexOf('\n', sel.start - 1) + 1;
     final lineEnd = text.indexOf('\n', sel.start);
     final actualEnd = lineEnd == -1 ? text.length : lineEnd + 1;
     
     final newText = text.replaceRange(lineStart, actualEnd, '');
     _controller.text = newText;
     _controller.selection = TextSelection.collapsed(offset: lineStart.clamp(0, newText.length));
  }

  void _toggleComment() {
    final text = _controller.text;
    final sel = _controller.selection;
    final lineStart = text.lastIndexOf('\n', sel.start - 1) + 1;
    final lineEnd = text.indexOf('\n', sel.start);
    final actualEnd = lineEnd == -1 ? text.length : lineEnd;
    final currentLine = text.substring(lineStart, actualEnd);

    if (currentLine.trim().startsWith('<!--') && currentLine.trim().endsWith('-->')) {
      final uncomm = currentLine.trim().substring(4, currentLine.trim().length - 3).trim();
      _controller.value = TextEditingValue(
        text: text.replaceRange(lineStart, actualEnd, uncomm),
        selection: TextSelection.collapsed(offset: lineStart + uncomm.length),
      );
    } else {
      final comm = '<!-- $currentLine -->';
      _controller.value = TextEditingValue(
        text: text.replaceRange(lineStart, actualEnd, comm),
        selection: TextSelection.collapsed(offset: lineStart + comm.length),
      );
    }
  }

  void _handleAutoPairing(String text) {
    final sel = _controller.selection;
    if (!sel.isCollapsed || sel.start == 0) return;

    final char = text[sel.start - 1];
    final Map<String, String> pairs = {
      '(': ')', '[': ']', '{': '}', '"': '"', "'": "'", '《': '》',
    };

    if (pairs.containsKey(char)) {
      final closing = pairs[char]!;
      bool shouldPair = true;
      if (sel.start < text.length) {
        final nextChar = text[sel.start];
        if (RegExp(r'[^\s\w\d]').hasMatch(nextChar) == false && nextChar != ' ') {
          shouldPair = false;
        }
      }

      if (shouldPair) {
        final newText = text.replaceRange(sel.start, sel.start, closing);
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: sel.start),
        );
      }
    }
  }

  void _handleTab({bool isOutdent = false}) {
    final text = _controller.text;
    final sel = _controller.selection;
    
    // Find the current line start and end
    final lineStart = text.lastIndexOf('\n', sel.start - 1) + 1;
    final lineEnd = text.indexOf('\n', sel.start);
    final currentLine = text.substring(lineStart, lineEnd == -1 ? text.length : lineEnd);
    
    if (isOutdent) {
      // Logic for Shift + Tab: Remove 2 spaces if present
      if (currentLine.startsWith('  ')) {
        final newText = text.replaceRange(lineStart, lineStart + 2, '');
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: (sel.start - 2).clamp(0, newText.length)),
        );
      }
    } else {
      // Logic for Tab: Insert 2 spaces
      final newText = text.replaceRange(lineStart, lineStart, '  ');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: sel.start + 2),
      );
    }
  }

  void _handleEnter() {
    final text = _controller.text;
    final sel = _controller.selection;
    if (!sel.isCollapsed) return;

    final lineStart = text.lastIndexOf('\n', sel.start - 1) + 1;
    final currentLine = text.substring(lineStart, sel.start);
    final match = RegExp(r'^(\s*(?:[-*+])\s*)').firstMatch(currentLine);

    final prefix = (match != null && match.group(1)!.trim().isNotEmpty) ? match.group(1)! : '';
    final newText = text.replaceRange(sel.start, sel.end, '\n$prefix');
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + 1 + prefix.length),
    );
  }


  Widget _buildToolbar(MarkdownProvider p, bool isDark) {
    final iconCol = isDark ? const Color(0xFFCDD6F4).withOpacity(0.7) : const Color(0xFF4C4F69).withOpacity(0.7);
    return Container(
      height: 38, padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF2F2F2), border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12))),
      child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        _tool(Icons.format_bold_rounded, () => p.insertSnippet('**', '**'), p.t('bold'), iconCol),
        _tool(Icons.format_italic_rounded, () => p.insertSnippet('*', '*'), p.t('italic'), iconCol),
        _tool(Icons.title_rounded, () => p.insertSnippet('# ', ''), p.t('heading'), iconCol),
        _tool(Icons.strikethrough_s_rounded, () => p.insertSnippet('~~', '~~'), p.t('strikethrough'), iconCol),
        const VerticalDivider(width: 16, indent: 8, endIndent: 8),
        _tool(Icons.format_list_bulleted_rounded, () => p.insertSnippet('- ', ''), p.t('list'), iconCol),
        _tool(Icons.checklist_rtl_rounded, () => p.insertSnippet('- [ ] ', ''), p.t('task_list'), iconCol),
        _tool(Icons.format_quote_rounded, () => p.insertSnippet('> ', ''), p.t('quote'), iconCol),
        _tool(Icons.code_rounded, () => p.insertSnippet('`', '`'), p.t('code'), iconCol),
        _tool(Icons.terminal_rounded, () => p.insertSnippet('```\n', '\n```'), p.t('terminal'), iconCol),
        const VerticalDivider(width: 16, indent: 8, endIndent: 8),
        _tool(Icons.link_rounded, () => p.insertSnippet('[', '](url)'), p.t('link'), iconCol),
        _tool(Icons.image_outlined, () => p.insertSnippet('![', '](url)'), p.t('image'), iconCol),
        _tool(Icons.grid_on_rounded, () => p.insertSnippet('| Header | Header |\n| :--- | :--- |\n| Cell | Cell |', ''), p.t('table'), iconCol),
        _tool(Icons.horizontal_rule_rounded, () => p.insertSnippet('---\n', ''), p.t('hr'), iconCol),
        const VerticalDivider(width: 16, indent: 8, endIndent: 8),
        _tool(Icons.search_rounded, () => p.toggleSearchOverlay(), p.t('find'), iconCol),
      ])),
    );
  }

  Widget _tool(IconData icon, VoidCallback tap, String tip, Color col) => Tooltip(message: tip, child: InkWell(onTap: tap, borderRadius: BorderRadius.circular(4), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Icon(icon, size: 18, color: col))));
}

class _SearchIntent extends Intent { const _SearchIntent(); }
class _SearchAction extends Action<_SearchIntent> {
  final MarkdownProvider p; _SearchAction(this.p);
  @override Object? invoke(_SearchIntent i) { p.toggleSearchOverlay(); return null; }
}
class _CloseSearchIntent extends Intent { const _CloseSearchIntent(); }
class _CloseSearchAction extends Action<_CloseSearchIntent> {
  final MarkdownProvider p; _CloseSearchAction(this.p);
  @override Object? invoke(_CloseSearchIntent i) { if (p.showSearchOverlay) p.toggleSearchOverlay(); return null; }
}
class _EnterIntent extends Intent { const _EnterIntent(); }
class _EnterAction extends Action<_EnterIntent> {
  final _MarkdownEditorWidgetState s; _EnterAction(this.s);
  @override Object? invoke(_EnterIntent i) { s._handleEnter(); return null; }
}
class _IndentIntent extends Intent { const _IndentIntent(); }
class _IndentAction extends Action<_IndentIntent> {
  final _MarkdownEditorWidgetState s; _IndentAction(this.s);
  @override Object? invoke(_IndentIntent i) { s._handleTab(); return null; }
}
class _OutdentIntent extends Intent { const _OutdentIntent(); }
class _OutdentAction extends Action<_OutdentIntent> {
  final _MarkdownEditorWidgetState s; _OutdentAction(this.s);
  @override Object? invoke(_OutdentIntent i) { s._handleTab(isOutdent: true); return null; }
}

/// Marka v2.9.0 Industrial Intents
class _MoveLineUpIntent extends Intent { const _MoveLineUpIntent(); }
class _MoveLineUpAction extends Action<_MoveLineUpIntent> {
  final _MarkdownEditorWidgetState s; _MoveLineUpAction(this.s);
  @override Object? invoke(_MoveLineUpIntent i) { s._moveLine(up: true); return null; }
}
class _MoveLineDownIntent extends Intent { const _MoveLineDownIntent(); }
class _MoveLineDownAction extends Action<_MoveLineDownIntent> {
  final _MarkdownEditorWidgetState s; _MoveLineDownAction(this.s);
  @override Object? invoke(_MoveLineDownIntent i) { s._moveLine(up: false); return null; }
}
class _DuplicateLineIntent extends Intent { const _DuplicateLineIntent(); }
class _DuplicateLineAction extends Action<_DuplicateLineIntent> {
  final _MarkdownEditorWidgetState s; _DuplicateLineAction(this.s);
  @override Object? invoke(_DuplicateLineIntent i) { s._duplicateLine(); return null; }
}
class _ToggleCommentIntent extends Intent { const _ToggleCommentIntent(); }
class _ToggleCommentAction extends Action<_ToggleCommentIntent> {
  final _MarkdownEditorWidgetState s; _ToggleCommentAction(this.s);
  @override Object? invoke(_ToggleCommentIntent i) { s._toggleComment(); return null; }
}
class _DeleteLineIntent extends Intent { const _DeleteLineIntent(); }
class _DeleteLineAction extends Action<_DeleteLineIntent> {
  final _MarkdownEditorWidgetState s; _DeleteLineAction(this.s);
  @override Object? invoke(_DeleteLineIntent i) { s._deleteLine(); return null; }
}

/// Dynamic Snippet Action
class _SnippetAction extends Action<Intent> {
  final MarkdownProvider p; 
  final String prefix; 
  final String suffix;
  _SnippetAction(this.p, this.prefix, this.suffix);
  @override Object? invoke(Intent i) { p.insertSnippet(prefix, suffix); return null; }
}

/// Marka v2.9.1 Productivity Intents
class _FormatBoldIntent extends Intent { const _FormatBoldIntent(); }
class _FormatItalicIntent extends Intent { const _FormatItalicIntent(); }
class _FormatLinkIntent extends Intent { const _FormatLinkIntent(); }
class _FormatImageIntent extends Intent { const _FormatImageIntent(); }
class _FormatStrikethroughIntent extends Intent { const _FormatStrikethroughIntent(); }
class _FormatQuoteIntent extends Intent { const _FormatQuoteIntent(); }
class _FormatInlineCodeIntent extends Intent { const _FormatInlineCodeIntent(); }
class _FormatCodeBlockIntent extends Intent { const _FormatCodeBlockIntent(); }
class _FormatH1Intent extends Intent { const _FormatH1Intent(); }
class _FormatH2Intent extends Intent { const _FormatH2Intent(); }
class _FormatH3Intent extends Intent { const _FormatH3Intent(); }
