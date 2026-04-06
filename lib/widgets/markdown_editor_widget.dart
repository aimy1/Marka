import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../providers/markdown_provider.dart';
import 'search_overlay_widget.dart';

class MarkdownEditorWidget extends StatefulWidget {
  const MarkdownEditorWidget({super.key});

  @override
  State<MarkdownEditorWidget> createState() => _MarkdownEditorWidgetState();
}

class _MarkdownEditorWidgetState extends State<MarkdownEditorWidget> {
  late TextEditingController _controller;
  late ScrollController _scrollController;
  late ScrollController _lineNumbersController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<MarkdownProvider>(context, listen: false);
    _controller = MarkdownTextEditingController(provider: provider);
    _scrollController = ScrollController();
    _lineNumbersController = ScrollController();
    _focusNode = FocusNode();
    
    _scrollController.addListener(_onScroll);
    provider.addListener(_onProviderChange);
    _controller.addListener(_onControllerChange);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  int _lastActiveTabIndex = -1;
  int _activeLine = 0;
  bool _isUpdatingProgrammatically = false;

  void _onControllerChange() {
    if (_isUpdatingProgrammatically) return;
    final provider = Provider.of<MarkdownProvider>(context, listen: false);
    final text = _controller.text;
    final selection = _controller.selection;

    if (text != provider.content) provider.updateContent(text);
    
    if (selection.start >= 0) {
      final start = selection.start;
      final part = text.substring(0, start.clamp(0, text.length));
      final lines = part.split('\n');
      final line = lines.length;
      final col = lines.last.length + 1;
      final selLen = selection.end - selection.start;
      
      if (_activeLine != line - 1) setState(() => _activeLine = line - 1);
      
      // OPTIMIZED: Debounced update
      provider.updateCursorInfo(line, col, selLen);
      provider.updateSelection(selection.start, selection.end);
    }
  }

  void _onProviderChange() {
    final provider = Provider.of<MarkdownProvider>(context, listen: false);
    final session = provider.activeSession;
    if (session == null) return;

    bool sessionChanged = _lastActiveTabIndex != provider.activeTabIndex;
    bool contentOutOfSync = _controller.text != session.content;
    
    if (sessionChanged || contentOutOfSync) {
      _lastActiveTabIndex = provider.activeTabIndex;
      _controller.removeListener(_onControllerChange);
      
      final oldSelection = _controller.selection;
      final newSelection = (sessionChanged || !oldSelection.isValid) 
          ? TextSelection.collapsed(offset: 0)
          : oldSelection;

      _controller.value = TextEditingValue(
        text: session.content,
        selection: newSelection,
      );
      
      _controller.addListener(_onControllerChange);
      if (sessionChanged && _scrollController.hasClients) _scrollController.jumpTo(0);
    }

    if (provider.requestSelectionOffset != null) {
      final offset = provider.requestSelectionOffset!;
      final matchEnd = provider.searchQuery.isNotEmpty ? offset + provider.searchQuery.length : offset;

      _controller.selection = TextSelection(baseOffset: offset, extentOffset: matchEnd);
      provider.consumeSelectionRequest();
      _focusNode.requestFocus();

      if (_scrollController.hasClients) {
        final lineHeight = provider.fontSize * provider.lineHeight;
        final targetLine = '\n'.allMatches(_controller.text.substring(0, offset)).length;
        final targetOffset = targetLine * lineHeight;
        
        if (targetOffset < _scrollController.offset || targetOffset > _scrollController.offset + 400) {
           _scrollController.animateTo(targetOffset - 100, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      }
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients && _lineNumbersController.hasClients) {
      _lineNumbersController.jumpTo(_scrollController.offset);
      final provider = Provider.of<MarkdownProvider>(context, listen: false);
      if (provider.isSyncScroll) {
        final max = _scrollController.position.maxScrollExtent;
        if (max > 0) provider.updateScroll(_scrollController.offset / max);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _lineNumbersController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarkdownProvider>(context);
    final text = _controller.text;
    final lineCount = '\n'.allMatches(text).length + 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    const double gutterWidth = 52.0;
    const double horizontalPadding = 24.0;
    const double topPadding = 24.0;
    
    final double lineHeightFactor = provider.lineHeight;
    final double calculatedLineHeight = provider.fontSize * lineHeightFactor;
    final charWidth = provider.fontSize * 0.6; 

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.enter): const _IndentIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const _SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const _CloseSearchIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _IndentIntent: _IndentAction(this),
          _SearchIntent: _SearchAction(provider),
          _CloseSearchIntent: _CloseSearchAction(provider),
        },
        child: Column(
          children: [
            if (provider.showToolbar) _buildEditorToolbar(provider, isDark),
            Expanded(
              child: Stack(
                children: [
                  // 1. Optimized Gutter & Clipping Guides
                  Positioned.fill(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildGutter(gutterWidth, topPadding, calculatedLineHeight, lineCount, isDark),
                        Expanded(
                          child: Container(
                            color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
                            child: AnimatedBuilder(
                              animation: _scrollController,
                              builder: (context, _) {
                                return CustomPaint(
                                  painter: _IndentGuidesPainter(
                                    scrollController: _scrollController,
                                    charWidth: charWidth,
                                    horizontalOffset: horizontalPadding,
                                    topPadding: topPadding,
                                    lineHeight: calculatedLineHeight,
                                    guideColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.04),
                                  ),
                                );
                              }
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildLineHighlight(topPadding, calculatedLineHeight, isDark),
                  
                  Positioned.fill(
                    child: TextField(
                      controller: _controller,
                      scrollController: _scrollController,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
                      autofocus: true,
                      cursorColor: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF),
                      cursorWidth: 2,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        isDense: true, border: InputBorder.none, hintText: 'Start writing...',
                        contentPadding: const EdgeInsets.only(
                          left: gutterWidth + horizontalPadding, top: topPadding, bottom: topPadding, right: horizontalPadding
                        ),
                      ),
                      strutStyle: StrutStyle(forceStrutHeight: true, height: lineHeightFactor, fontSize: provider.fontSize, fontFamily: provider.fontFamily),
                      style: GoogleFonts.getFont(
                        provider.fontFamily, fontSize: provider.fontSize, height: lineHeightFactor,
                        letterSpacing: 0, fontFeatures: const [FontFeature.disable('liga')],
                        color: isDark ? const Color(0xFFCDD6F4) : const Color(0xFF4C4F69),
                      ),
                    ),
                  ),

                  if (provider.showSearchOverlay)
                    Positioned(top: 10, right: 20, child: SearchOverlayWidget(provider: provider)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGutter(double width, double top, double height, int count, bool isDark) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11111B) : const Color(0xFFE6E9EF),
        border: Border(right: BorderSide(color: isDark ? const Color(0xFF313244) : const Color(0xFFDCE0E8), width: 1)),
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.builder(
          controller: _lineNumbersController,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.only(top: top),
          itemCount: count,
          itemExtent: height,
          cacheExtent: 1000, // PERFORMANCE: Increase cache for smoother high-volume scrolling
          itemBuilder: (context, index) {
            final isActive = index == _activeLine;
            return Container(
              padding: const EdgeInsets.only(right: 12),
              alignment: Alignment.centerRight,
              child: Text(
                '${index + 1}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10, height: 1.0, fontWeight: isActive ? FontWeight.w800 : FontWeight.w400,
                  color: isActive ? (isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF)) : (isDark ? const Color(0xFF585B70) : const Color(0xFF9399B2)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLineHighlight(double topPadding, double lineHeight, bool isDark) {
    if (!_scrollController.hasClients) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        final offset = (topPadding + (_activeLine * lineHeight)) - _scrollController.offset;
        if (offset < -lineHeight || offset > 2000) return const SizedBox.shrink(); // PERFORMANCE: Aggressive clipping
        return Positioned(
          top: offset, left: 0, right: 0, height: lineHeight,
          child: Container(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
        );
      },
    );
  }

  Widget _buildEditorToolbar(MarkdownProvider provider, bool isDark) {
    return Container(
      height: 38, padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
        border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _toolBtn(Icons.format_bold_rounded, () => provider.insertSnippet('**', '**'), provider.t('bold')),
            _toolBtn(Icons.format_italic_rounded, () => provider.insertSnippet('*', '*'), provider.t('italic')),
            _toolBtn(Icons.title_rounded, () => provider.insertSnippet('# ', ''), provider.t('heading')),
            _toolBtn(Icons.format_strikethrough_rounded, () => provider.insertSnippet('~~', '~~'), provider.t('strikethrough')),
            const VerticalDivider(width: 20, indent: 8, endIndent: 8),
            _toolBtn(Icons.format_list_bulleted_rounded, () => provider.insertSnippet('- ', ''), provider.t('list')),
            _toolBtn(Icons.format_list_numbered_rounded, () => provider.insertSnippet('1. ', ''), provider.t('numbered_list')),
            _toolBtn(Icons.check_box_outlined, () => provider.insertSnippet('- [ ] ', ''), provider.t('task_list')),
            const VerticalDivider(width: 20, indent: 8, endIndent: 8),
            _toolBtn(Icons.link_rounded, () => provider.insertSnippet('[', '](url)'), provider.t('link')),
            _toolBtn(Icons.image_outlined, () => provider.insertSnippet('![', '](url)'), provider.t('image')),
            _toolBtn(Icons.code_rounded, () => provider.insertSnippet('`', '`'), provider.t('code')),
            _toolBtn(Icons.terminal_rounded, () => provider.insertSnippet('```\n', '\n```'), provider.t('terminal')),
            _toolBtn(Icons.format_quote_rounded, () => provider.insertSnippet('> ', ''), provider.t('quote')),
            const VerticalDivider(width: 20, indent: 8, endIndent: 8),
            _toolBtn(Icons.search_rounded, () => provider.toggleSearchOverlay(), provider.t('find')),
          ],
        ),
      ),
    );
  }

  Widget _toolBtn(IconData icon, VoidCallback onTap, String tooltip) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip, child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(4),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Icon(icon, size: 18, color: isDark ? const Color(0xFFCDD6F4).withOpacity(0.7) : const Color(0xFF4C4F69).withOpacity(0.7))),
      ),
    );
  }

  void _performIndentAction() {
    final text = _controller.text;
    final selection = _controller.selection;
    if (!selection.isCollapsed) return;

    final currentLineStart = text.lastIndexOf('\n', selection.start - 1) + 1;
    final currentLine = text.substring(currentLineStart, selection.start);
    final match = RegExp(r'^(\s*(?:[-*+]|(?:\d+\.)|>\s*)*\s*)').firstMatch(currentLine);
    
    if (match != null && match.group(1)!.isNotEmpty) {
      final prefix = match.group(1)!;
      String actualPrefix = prefix;
      if (RegExp(r'^\s*\d+\.').hasMatch(prefix)) {
        final currentNumMatch = RegExp(r'\d+').firstMatch(prefix);
        if (currentNumMatch != null) {
          final nextNum = int.parse(currentNumMatch.group(0)!) + 1;
          actualPrefix = prefix.replaceFirst(RegExp(r'\d+'), nextNum.toString());
        }
      }
      final newText = text.replaceRange(selection.start, selection.end, '\n$actualPrefix');
      _controller.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: selection.start + actualPrefix.length + 1));
    } else {
      final newText = text.replaceRange(selection.start, selection.end, '\n');
      _controller.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: selection.start + 1));
    }
  }
}

// 📐 Optimized Indentation Guide Painter (Viewport-Aware)
class _IndentGuidesPainter extends CustomPainter {
  final ScrollController scrollController;
  final double charWidth;
  final double horizontalOffset;
  final double topPadding;
  final double lineHeight;
  final Color guideColor;
  
  _IndentGuidesPainter({
    required this.scrollController, required this.charWidth, required this.horizontalOffset, 
    required this.topPadding, required this.lineHeight, required this.guideColor
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!scrollController.hasClients) return;
    
    final paint = Paint()..color = guideColor..strokeWidth = 1;
    final scrollOffset = scrollController.offset;
    
    // PERFORMANCE: Only draw guides currently within the viewport
    final startY = (scrollOffset - topPadding).clamp(0.0, double.infinity);
    final endY = (scrollOffset + size.height).clamp(0.0, double.infinity);

    // Draw vertical guides every 4 characters
    for (int i = 1; i < 15; i++) {
        final x = horizontalOffset + (i * 4 * charWidth);
        if (x > size.width) break;
        // Limit the line to the physical canvas height but logically represent the visible segment
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }
  @override bool shouldRepaint(covariant _IndentGuidesPainter oldDelegate) => 
    oldDelegate.scrollController.offset != scrollController.offset;
}

// Shortcut definitions
class _IndentIntent extends Intent { const _IndentIntent(); }
class _IndentAction extends Action<_IndentIntent> {
  final _MarkdownEditorWidgetState state; _IndentAction(this.state);
  @override Object? invoke(_IndentIntent intent) { state._performIndentAction(); return null; }
}
class _SearchIntent extends Intent { const _SearchIntent(); }
class _SearchAction extends Action<_SearchIntent> {
  final MarkdownProvider provider; _SearchAction(this.provider);
  @override Object? invoke(_SearchIntent intent) { provider.toggleSearchOverlay(); return null; }
}
class _CloseSearchIntent extends Intent { const _CloseSearchIntent(); }
class _CloseSearchAction extends Action<_CloseSearchIntent> {
  final MarkdownProvider provider; _CloseSearchAction(this.provider);
  @override Object? invoke(_CloseSearchIntent intent) { if (provider.showSearchOverlay) provider.toggleSearchOverlay(); return null; }
}

class MarkdownTextEditingController extends TextEditingController {
  final MarkdownProvider provider;
  MarkdownTextEditingController({required this.provider}) { text = provider.content; }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<TextSpan> children = [];
    final patterns = {
      RegExp(r'\*\*.*?\*\*'): isDark ? const Color(0xFFF9E2AF) : const Color(0xFFDF8E1D),
      RegExp(r'\*.*?\*'): isDark ? const Color(0xFFF9E2AF) : const Color(0xFFDF8E1D),
      RegExp(r'^#+ .*$', multiLine: true): isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF),
      RegExp(r'\[.*?\]\(.*?\)'): isDark ? const Color(0xFF89B4FA) : const Color(0xFF1E66F5),
      RegExp(r'`.*?`'): isDark ? const Color(0xFFFAB387) : const Color(0xFFFE640B),
      RegExp(r'^> .*$', multiLine: true): isDark ? const Color(0xFFA6ADC8) : const Color(0xFF7C7F93),
      RegExp(r'```[\s\S]*?```'): isDark ? const Color(0xFF94E2D5) : const Color(0xFF179299),
    };

    text.splitMapJoin(
      RegExp(patterns.keys.map((r) => r.pattern).join('|'), multiLine: true),
      onMatch: (m) {
        final matchText = m[0]!; Color? matchColor; FontWeight weight = FontWeight.normal;
        for (final entry in patterns.entries) { if (entry.key.hasMatch(matchText)) { matchColor = entry.value; if (entry.key.pattern.contains(r'\*\*')) weight = FontWeight.bold; break; } }
        children.add(TextSpan(text: matchText, style: style?.copyWith(color: matchColor, fontWeight: weight)));
        return '';
      },
      onNonMatch: (n) { children.add(TextSpan(text: n, style: style)); return ''; },
    );
    return TextSpan(children: children, style: style);
  }
}
