import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../providers/markdown_provider.dart';

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
    if (_controller.text != provider.content) provider.updateContent(_controller.text);
    provider.updateSelection(_controller.selection.start, _controller.selection.end);
    
    final text = _controller.text;
    final selectionStart = _controller.selection.start;
    if (selectionStart >= 0) {
      final lineIdx = '\n'.allMatches(text.substring(0, selectionStart.clamp(0, text.length))).length;
      if (_activeLine != lineIdx) setState(() => _activeLine = lineIdx);
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
      _controller.selection = TextSelection.collapsed(offset: offset);
      provider.consumeSelectionRequest();
      _focusNode.requestFocus();
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
    
    const double gutterWidth = 46.0;
    const double horizontalPadding = 20.0;
    final double lineHeightFactor = provider.lineHeight; // Reactive line height
    final double calculatedLineHeight = provider.fontSize * lineHeightFactor;

    return Column(
      children: [
        if (provider.showToolbar) _buildEditorToolbar(provider, isDark),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: gutterWidth,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF11111B) : const Color(0xFFE6E9EF),
                        border: Border(
                          right: BorderSide(
                            color: isDark ? const Color(0xFF313244) : const Color(0xFFDCE0E8),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                          child: ListView.builder(
                            controller: _lineNumbersController,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: lineCount,
                            itemBuilder: (context, index) {
                              final isActive = index == _activeLine;
                              return SizedBox(
                                height: calculatedLineHeight,
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                      color: isActive 
                                        ? (isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF))
                                        : (isDark ? const Color(0xFF585B70) : const Color(0xFF9399B2)),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: Container(color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5))),
                  ],
                ),
              ),
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
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Start writing...',
                    contentPadding: const EdgeInsets.fromLTRB(gutterWidth + horizontalPadding, 20, horizontalPadding, 20),
                  ),
                  strutStyle: StrutStyle(
                    forceStrutHeight: true,
                    height: lineHeightFactor,
                    fontSize: provider.fontSize,
                    fontFamily: 'JetBrains Mono',
                  ),
                  style: GoogleFonts.getFont(
                    provider.fontFamily,
                    fontSize: provider.fontSize,
                    height: lineHeightFactor,
                    color: isDark ? const Color(0xFFCDD6F4) : const Color(0xFF4C4F69),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditorToolbar(MarkdownProvider provider, bool isDark) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
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
          ],
        ),
      ),
    );
  }

  Widget _toolBtn(IconData icon, VoidCallback onTap, String tooltip) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Icon(
            icon, 
            size: 18, 
            color: isDark ? const Color(0xFFCDD6F4).withOpacity(0.7) : const Color(0xFF4C4F69).withOpacity(0.7)
          ),
        ),
      ),
    );
  }
}

class MarkdownTextEditingController extends TextEditingController {
  final MarkdownProvider provider;
  MarkdownTextEditingController({required this.provider}) {
    text = provider.content;
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<TextSpan> children = [];

    final patterns = {
      RegExp(r'\*\*.*?\*\*'): isDark ? const Color(0xFFF9E2AF) : const Color(0xFFDF8E1D), // Bold
      RegExp(r'\*.*?\*'): isDark ? const Color(0xFFF9E2AF) : const Color(0xFFDF8E1D), // Italic
      RegExp(r'^#+ .*$', multiLine: true): isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF), // Headings
      RegExp(r'\[.*?\]\(.*?\)'): isDark ? const Color(0xFF89B4FA) : const Color(0xFF1E66F5), // Links
      RegExp(r'`.*?`'): isDark ? const Color(0xFFFAB387) : const Color(0xFFFE640B), // Code
      RegExp(r'^> .*$', multiLine: true): isDark ? const Color(0xFFA6ADC8) : const Color(0xFF7C7F93), // Quotes
      RegExp(r'```[\s\S]*?```'): isDark ? const Color(0xFF94E2D5) : const Color(0xFF179299), // Code Block
    };

    text.splitMapJoin(
      RegExp(patterns.keys.map((r) => r.pattern).join('|'), multiLine: true),
      onMatch: (m) {
        final matchText = m[0]!;
        Color? matchColor;
        FontWeight weight = FontWeight.normal;

        for (final entry in patterns.entries) {
          if (entry.key.hasMatch(matchText)) {
            matchColor = entry.value;
            if (entry.key.pattern.contains(r'\*\*')) weight = FontWeight.bold;
            break;
          }
        }
        children.add(TextSpan(text: matchText, style: style?.copyWith(color: matchColor, fontWeight: weight)));
        return '';
      },
      onNonMatch: (n) {
        children.add(TextSpan(text: n, style: style));
        return '';
      },
    );

    return TextSpan(children: children, style: style);
  }
}
