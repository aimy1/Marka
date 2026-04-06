import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../providers/markdown_provider.dart';
import 'search_overlay_widget.dart';
import 'editor/editor_controller.dart';

/// Marka v2.4.0 - Selection & Drag-Drop Refactor
/// Implemented professional mouse selection and "IDE-style" drag-to-move foundations.
/// Optimized hit-testing for the Full-width Zen surface.
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
      },
      child: Actions(
        actions: {
          _SearchIntent: _SearchAction(provider),
          _CloseSearchIntent: _CloseSearchAction(provider),
          _EnterIntent: _EnterAction(this),
        },
        child: Column(
          children: [
            if (provider.showToolbar) _buildToolbar(provider, isDark),
            Expanded(
              child: Stack(
                children: [
                  // ── Full-Width Selection & Drag ──
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
                          // High-Fidelity Professional Selection Color
                          selectionColor: isDark ? const Color(0xFFCBA6F7).withOpacity(0.18) : Colors.blue.withOpacity(0.18),
                          selectionHandleColor: Colors.transparent,
                        ),
                      ),
                      child: Listener(
                        onPointerDown: (event) {
                           // Future Hook for Drag-to-Move Detection
                        },
                        child: TextField(
                          controller: _controller,
                          scrollController: _scrollController,
                          focusNode: _focusNode,
                          maxLines: null,
                          expands: true,
                          cursorColor: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF),
                          cursorWidth: 1.2,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
                            border: InputBorder.none,
                            contentPadding: _textPadding,
                          ),
                          strutStyle: const StrutStyle(
                            forceStrutHeight: true,
                            height: _lineHeight,
                            fontSize: _fontSize,
                          ),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: _fontSize,
                            height: _lineHeight,
                            letterSpacing: 0,
                            color: isDark ? const Color(0xFFCDD6F4) : const Color(0xFF4C4F69),
                          ),
                        ),
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

  void _handleEnter() {
    final text = _controller.text;
    final sel = _controller.selection;
    if (!sel.isCollapsed) return;

    final lineStart = text.lastIndexOf('\n', sel.start - 1) + 1;
    final currentLine = text.substring(lineStart, sel.start);
    final match = RegExp(r'^(\s*(?:[-*+]|\d+\.)\s*)').firstMatch(currentLine);

    final prefix = (match != null && match.group(1)!.trim().isNotEmpty) ? _nextPrefix(match.group(1)!) : '';
    final newText = text.replaceRange(sel.start, sel.end, '\n$prefix');
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + 1 + prefix.length),
    );
  }

  String _nextPrefix(String prefix) {
    final numMatch = RegExp(r'^(\s*)(\d+)(\.\s+)').firstMatch(prefix);
    if (numMatch != null) {
       final n = int.parse(numMatch.group(2)!) + 1;
       return '${numMatch.group(1)}$n${numMatch.group(3)}';
    }
    return prefix;
  }

  Widget _buildToolbar(MarkdownProvider p, bool isDark) {
    final iconCol = isDark ? const Color(0xFFCDD6F4).withOpacity(0.7) : const Color(0xFF4C4F69).withOpacity(0.7);
    return Container(
      height: 38, padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF2F2F2), border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black10))),
      child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        _tool(Icons.format_bold_rounded, () => p.insertSnippet('**', '**'), p.t('bold'), iconCol),
        _tool(Icons.format_italic_rounded, () => p.insertSnippet('*', '*'), p.t('italic'), iconCol),
        _tool(Icons.title_rounded, () => p.insertSnippet('# ', ''), p.t('heading'), iconCol),
        const VerticalDivider(width: 16, indent: 8, endIndent: 8),
        _tool(Icons.format_list_bulleted_rounded, () => p.insertSnippet('- ', ''), p.t('list'), iconCol),
        _tool(Icons.format_list_numbered_rounded, () => p.insertSnippet('1. ', ''), p.t('numbered_list'), iconCol),
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
