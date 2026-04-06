import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../providers/markdown_provider.dart';
import 'search_overlay_widget.dart';
import 'editor/editor_controller.dart';

/// Marka v2.2.0 — Kate-Style Editor
/// Strict Row layout: Gutter (left) + TextField (right)
/// Single ScrollController drives both sides.
class MarkdownEditorWidget extends StatefulWidget {
  const MarkdownEditorWidget({super.key});

  @override
  State<MarkdownEditorWidget> createState() => _MarkdownEditorWidgetState();
}

class _MarkdownEditorWidgetState extends State<MarkdownEditorWidget> {
  late MarkaEditorController _controller;
  final ScrollController _sharedScroll = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Typography constants — shared by gutter and TextField
  static const double _fontSize = 14.0;
  static const double _lineHeight = 1.5;
  static const double _lineHeightPx = _fontSize * _lineHeight; // 21.0 px
  static const double _gutterWidth = 56.0;
  static const EdgeInsets _textPadding = EdgeInsets.only(
    left: 16, right: 16, top: 8, bottom: 8,
  );

  int _lineCount = 1;
  int _activeLine = 0;
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
      final line = lines.length;
      final col = lines.last.length + 1;
      final selLen = sel.end - sel.start;
      provider.updateCursorInfo(line, col, selLen);
      provider.updateSelection(sel.start, sel.end);

      final newActiveLine = line - 1;
      final newLineCount = '\n'.allMatches(text).length + 1;
      if (_activeLine != newActiveLine || _lineCount != newLineCount) {
        setState(() {
          _activeLine = newActiveLine;
          _lineCount = newLineCount;
        });
      }
    }
  }

  void _onProviderChanged() {
    final provider = Provider.of<MarkdownProvider>(context, listen: false);
    final session = provider.activeSession;
    if (session == null) return;

    final sessionChanged = _lastTabIndex != provider.activeTabIndex;
    final outOfSync = _controller.text != session.content;

    if (sessionChanged || outOfSync) {
      _lastTabIndex = provider.activeTabIndex;
      _controller.removeListener(_onTextChanged);
      _controller.value = TextEditingValue(
        text: session.content,
        selection: sessionChanged
            ? const TextSelection.collapsed(offset: 0)
            : _controller.selection,
      );
      _controller.addListener(_onTextChanged);
      if (sessionChanged && _sharedScroll.hasClients) {
        _sharedScroll.jumpTo(0);
      }
      setState(() {
        _lineCount = '\n'.allMatches(session.content).length + 1;
      });
    }

    // Jump to search result
    if (provider.requestSelectionOffset != null) {
      final off = provider.requestSelectionOffset!;
      final end = provider.searchQuery.isNotEmpty
          ? off + provider.searchQuery.length
          : off;
      _controller.selection = TextSelection(baseOffset: off, extentOffset: end);
      provider.consumeSelectionRequest();
      _focusNode.requestFocus();

      if (_sharedScroll.hasClients) {
        final targetLine = '\n'.allMatches(_controller.text.substring(0, off)).length;
        final targetPx = _textPadding.top + targetLine * _lineHeightPx;
        _sharedScroll.animateTo(
          (targetPx - 100).clamp(0, _sharedScroll.position.maxScrollExtent),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _sharedScroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarkdownProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Studio palette
    final Color gutterBg    = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFEAEAEA);
    final Color gutterBorder = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFCCCCCC);
    final Color numColor    = isDark ? const Color(0xFF5A5A5E) : const Color(0xFF8A8A8A);
    final Color numActive   = isDark ? const Color(0xFFD4D4D4) : const Color(0xFF222222);
    final Color surfaceBg   = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final Color textColor   = isDark ? const Color(0xFFD4D4D4) : const Color(0xFF1A1A1A);
    final Color caretColor  = isDark ? const Color(0xFFAEAFAD) : const Color(0xFF000000);

    final monoStyle = GoogleFonts.jetBrainsMono(
      fontSize: _fontSize,
      height: _lineHeight,
      letterSpacing: 0,
      fontFeatures: const [FontFeature.disable('liga')],
      color: textColor,
      decoration: TextDecoration.none,
    );

    final strutStyle = const StrutStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: _fontSize,
      height: _lineHeight,
      forceStrutHeight: true,
      leading: 0,
    );

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
            const _SearchIntent(),
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
                  // ── Core Row: Gutter | TextField ──────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      // ── LEFT: Gutter ────────────────────────────────────
                      Container(
                        width: _gutterWidth,
                        decoration: BoxDecoration(
                          color: gutterBg,
                          border: Border(
                            right: BorderSide(color: gutterBorder, width: 1),
                          ),
                        ),
                        child: LayoutBuilder(builder: (ctx, constraints) {
                          return ListView.builder(
                            controller: _sharedScroll,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.only(top: _textPadding.top),
                            itemCount: _lineCount,
                            itemExtent: _lineHeightPx,
                            cacheExtent: 2000,
                            itemBuilder: (_, i) {
                              final active = i == _activeLine;
                              return Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Text(
                                    '${i + 1}',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      height: 1.0,
                                      color: active ? numActive : numColor,
                                      fontWeight: active
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      ),

                      // ── RIGHT: TextField ────────────────────────────────
                      Expanded(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            // Sync gutter scroll from TextField scroll
                            if (n is ScrollUpdateNotification) {
                              if (_sharedScroll.hasClients) {
                                _sharedScroll.jumpTo(
                                  n.metrics.pixels.clamp(
                                    0.0,
                                    _sharedScroll.position.maxScrollExtent,
                                  ),
                                );
                              }
                            }
                            return false;
                          },
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              textSelectionTheme: TextSelectionThemeData(
                                selectionColor: isDark
                                    ? Colors.white.withOpacity(0.15)
                                    : Colors.blue.withOpacity(0.25),
                                selectionHandleColor: Colors.transparent,
                              ),
                            ),
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              maxLines: null,
                              expands: true,
                              autofocus: true,
                              cursorColor: caretColor,
                              cursorWidth: 1.5,
                              textAlignVertical: TextAlignVertical.top,
                              style: monoStyle,
                              strutStyle: strutStyle,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: surfaceBg,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: _textPadding,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Floating Search Overlay ─────────────────────────────
                  if (provider.showSearchOverlay)
                    Positioned(
                      top: 8,
                      right: 16,
                      child: SearchOverlayWidget(provider: provider),
                    ),
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

    final prefix = (match != null && match.group(1)!.trim().isNotEmpty)
        ? _nextPrefix(match.group(1)!)
        : '';

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
    final iconColor = isDark
        ? const Color(0xFFD4D4D4).withOpacity(0.7)
        : const Color(0xFF444444).withOpacity(0.7);
    final bg = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFEAEAEA);
    final border = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.06);

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _tb(Icons.format_bold_rounded,        () => p.insertSnippet('**', '**'),    p.t('bold'),          iconColor),
          _tb(Icons.format_italic_rounded,      () => p.insertSnippet('*', '*'),      p.t('italic'),        iconColor),
          _tb(Icons.title_rounded,              () => p.insertSnippet('# ', ''),      p.t('heading'),       iconColor),
          _tb(Icons.format_strikethrough_rounded,() => p.insertSnippet('~~', '~~'),  p.t('strikethrough'), iconColor),
          const VerticalDivider(width: 16, indent: 8, endIndent: 8),
          _tb(Icons.format_list_bulleted_rounded,() => p.insertSnippet('- ', ''),    p.t('list'),          iconColor),
          _tb(Icons.format_list_numbered_rounded,() => p.insertSnippet('1. ', ''),   p.t('numbered_list'), iconColor),
          _tb(Icons.check_box_outlined,         () => p.insertSnippet('- [ ] ', ''), p.t('task_list'),     iconColor),
          const VerticalDivider(width: 16, indent: 8, endIndent: 8),
          _tb(Icons.link_rounded,               () => p.insertSnippet('[', '](url)'),p.t('link'),          iconColor),
          _tb(Icons.image_outlined,             () => p.insertSnippet('![', '](url)'),p.t('image'),        iconColor),
          _tb(Icons.code_rounded,               () => p.insertSnippet('`', '`'),     p.t('code'),          iconColor),
          _tb(Icons.terminal_rounded,           () => p.insertSnippet('```\n', '\n```'), p.t('terminal'),  iconColor),
          _tb(Icons.format_quote_rounded,      () => p.insertSnippet('> ', ''),      p.t('quote'),         iconColor),
          const VerticalDivider(width: 16, indent: 8, endIndent: 8),
          _tb(Icons.search_rounded,             () => p.toggleSearchOverlay(),        p.t('find'),          iconColor),
        ]),
      ),
    );
  }

  Widget _tb(IconData icon, VoidCallback tap, String tip, Color col) =>
      Tooltip(
        message: tip,
        child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Icon(icon, size: 17, color: col),
          ),
        ),
      );
}

// ── Intents & Actions ──────────────────────────────────────────────────────

class _SearchIntent extends Intent { const _SearchIntent(); }
class _SearchAction extends Action<_SearchIntent> {
  final MarkdownProvider p; _SearchAction(this.p);
  @override Object? invoke(_SearchIntent i) { p.toggleSearchOverlay(); return null; }
}

class _CloseSearchIntent extends Intent { const _CloseSearchIntent(); }
class _CloseSearchAction extends Action<_CloseSearchIntent> {
  final MarkdownProvider p; _CloseSearchAction(this.p);
  @override Object? invoke(_CloseSearchIntent i) {
    if (p.showSearchOverlay) p.toggleSearchOverlay(); return null;
  }
}

class _EnterIntent extends Intent { const _EnterIntent(); }
class _EnterAction extends Action<_EnterIntent> {
  final _MarkdownEditorWidgetState s; _EnterAction(this.s);
  @override Object? invoke(_EnterIntent i) { s._handleEnter(); return null; }
}
