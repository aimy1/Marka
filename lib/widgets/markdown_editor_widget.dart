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
  bool _isUpdatingProgrammatically = false;

  void _onControllerChange() {
    if (_isUpdatingProgrammatically) return;
    final provider = Provider.of<MarkdownProvider>(context, listen: false);
    if (_controller.text != provider.content) provider.updateContent(_controller.text);
    provider.updateSelection(_controller.selection.start, _controller.selection.end);
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
      final max = _scrollController.position.maxScrollExtent;
      if (max > 0) {
        Provider.of<MarkdownProvider>(context, listen: false).updateScroll(_scrollController.offset / max);
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

    return Column(
      children: [
        _buildEditorToolbar(provider, isDark),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Interactive Line Numbers
              Container(
                width: 45,
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF11111B) : const Color(0xFFE6E9EF),
                  border: Border(
                    right: BorderSide(
                      color: isDark ? const Color(0xFF313244) : const Color(0xFFDCE0E8),
                      width: 1,
                    ),
                  ),
                ),
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: ListView.builder(
                    controller: _lineNumbersController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: lineCount,
                    itemBuilder: (context, index) => Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _moveToLine(index),
                        child: SizedBox(
                          height: 24,
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF585B70) : const Color(0xFF9399B2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Editor
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
                  child: TextField(
                    controller: _controller,
                    scrollController: _scrollController,
                    focusNode: _focusNode,
                    maxLines: null,
                    expands: true,
                    autofocus: true,
                    cursorColor: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Start writing...'),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: provider.fontSize,
                      height: 1.6,
                      color: isDark ? const Color(0xFFCDD6F4) : const Color(0xFF4C4F69),
                    ),
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
            _toolBtn(Icons.format_bold_rounded, () => provider.insertSnippet('**', '**'), 'Bold'),
            _toolBtn(Icons.format_italic_rounded, () => provider.insertSnippet('*', '*'), 'Italic'),
            _toolBtn(Icons.title_rounded, () => provider.insertSnippet('# ', ''), 'Heading'),
            _toolBtn(Icons.format_strikethrough_rounded, () => provider.insertSnippet('~~', '~~'), 'Strikethrough'),
            const VerticalDivider(width: 20, indent: 8, endIndent: 8),
            _toolBtn(Icons.format_list_bulleted_rounded, () => provider.insertSnippet('- ', ''), 'List'),
            _toolBtn(Icons.format_list_numbered_rounded, () => provider.insertSnippet('1. ', ''), 'Numbered List'),
            _toolBtn(Icons.check_box_outlined, () => provider.insertSnippet('- [ ] ', ''), 'Task List'),
            const VerticalDivider(width: 20, indent: 8, endIndent: 8),
            _toolBtn(Icons.link_rounded, () => provider.insertSnippet('[', '](url)'), 'Link'),
            _toolBtn(Icons.image_outlined, () => provider.insertSnippet('![', '](url)'), 'Image'),
            _toolBtn(Icons.code_rounded, () => provider.insertSnippet('`', '`'), 'Inline Code'),
            _toolBtn(Icons.terminal_rounded, () => provider.insertSnippet('```\n', '\n```'), 'Code Block'),
            _toolBtn(Icons.format_quote_rounded, () => provider.insertSnippet('> ', ''), 'Quote'),
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

  void _moveToLine(int lineIndex) {
    final text = _controller.text;
    final lines = text.split('\n');
    if (lineIndex < 0 || lineIndex >= lines.length) return;
    int offset = 0;
    for (int i = 0; i < lineIndex; i++) offset += lines[i].length + 1;
    _controller.selection = TextSelection.collapsed(offset: offset.clamp(0, text.length));
    _focusNode.requestFocus();
    Provider.of<MarkdownProvider>(context, listen: false).updateSelection(_controller.selection.start, _controller.selection.end);
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

    // Simple RegEx-based Highlighter for common MD patterns
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
