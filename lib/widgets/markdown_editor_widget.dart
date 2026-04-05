import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:highlight/highlight.dart' show highlight, Node;
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<MarkdownProvider>(context, listen: false);
    _controller = MarkdownTextEditingController(provider: provider);
    _scrollController = ScrollController();
    _lineNumbersController = ScrollController();
    
    _scrollController.addListener(_onScroll);
    provider.addListener(_onProviderChange);
  }

  void _onProviderChange() {
    final provider = Provider.of<MarkdownProvider>(context, listen: false);
    if (provider.requestSelectionOffset != null) {
      final offset = provider.requestSelectionOffset!;
      _controller.selection = TextSelection.collapsed(offset: offset);
      provider.consumeSelectionRequest();
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients && _lineNumbersController.hasClients) {
      // Sync line numbers scroll
      _lineNumbersController.jumpTo(_scrollController.offset);

      final max = _scrollController.position.maxScrollExtent;
      if (max > 0) {
        final percentage = _scrollController.offset / max;
        Provider.of<MarkdownProvider>(context, listen: false).updateScroll(percentage);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _lineNumbersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarkdownProvider>(context);
    final text = _controller.text;
    final lineCount = '\n'.allMatches(text).length + 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line Numbers Gutter
        RepaintBoundary(
          child: Container(
            width: 50,
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
            child: ListView.builder(
              controller: _lineNumbersController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lineCount,
              itemBuilder: (context, index) {
                return SizedBox(
                  height: 24,
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF585B70) : const Color(0xFF9399B2),
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
        ),
        // Editor
        Expanded(
          child: RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
              child: CallbackShortcuts(
                bindings: <ShortcutActivator, VoidCallback>{
                  // Smart Bulleting (Enter)
                  const SingleActivator(LogicalKeyboardKey.enter): () => _handleEnter(),
                  // Auto-pairing
                  const SingleActivator(LogicalKeyboardKey.bracketLeft): () => _handleAutoPair('[', ']'),
                  const SingleActivator(LogicalKeyboardKey.parenthesisLeft): () => _handleAutoPair('(', ')'),
                  const SingleActivator(LogicalKeyboardKey.quote): () => _handleAutoPair('"', '"'),
                  const SingleActivator(LogicalKeyboardKey.quoteSingle): () => _handleAutoPair("'", "'"),
                },
                child: TextField(
                  controller: _controller,
                  scrollController: _scrollController,
                  maxLines: null,
                  expands: true,
                  onChanged: (val) => setState(() {}),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Start writing...',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: provider.fontSize,
                    height: 1.6,
                    color: isDark ? const Color(0xFFCDD6F4) : const Color(0xFF4C4F69),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleEnter() {
    final text = _controller.text;
    final selection = _controller.selection;
    
    // Safety check for empty or invalid selection
    if (selection.start < 0) return;

    final lines = text.substring(0, selection.start).split('\n');
    final currentLine = lines.isNotEmpty ? lines.last : '';

    String prefix = '';
    // Bullet list detection
    if (currentLine.trimLeft().startsWith('- ')) {
      prefix = '- ';
    } 
    // Numbered list detection
    else if (RegExp(r'^\s*\d+\.\s+').hasMatch(currentLine)) {
      final match = RegExp(r'^\s*(\d+)\.\s+').firstMatch(currentLine);
      if (match != null) {
        final num = int.parse(match.group(1)!) + 1;
        prefix = '$num. ';
      }
    }

    if (prefix.isNotEmpty && currentLine.trim() != prefix.trim()) {
      final newText = text.replaceRange(selection.start, selection.end, '\n$prefix');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + 1 + prefix.length),
      );
    } else {
      // If current line only contains the prefix, clear it (standard IDE behavior)
      if (prefix.isNotEmpty && currentLine.trim() == prefix.trim()) {
         final startOfLine = selection.start - currentLine.length;
         final newText = text.replaceRange(startOfLine, selection.start, '');
         _controller.value = TextEditingValue(
           text: newText,
           selection: TextSelection.collapsed(offset: startOfLine),
         );
         return;
      }
      
      // Default enter behavior
      final newText = text.replaceRange(selection.start, selection.end, '\n');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + 1),
      );
    }
    setState(() {});
  }

  void _handleAutoPair(String opening, String closing) {
    final text = _controller.text;
    final selection = _controller.selection;
    if (selection.start < 0) return;

    final newText = text.replaceRange(selection.start, selection.end, '$opening$closing');
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + 1),
    );
    setState(() {});
  }
}

class MarkdownTextEditingController extends TextEditingController {
  final MarkdownProvider provider;

  MarkdownTextEditingController({required this.provider}) {
    text = provider.content;
    addListener(() {
      if (text != provider.content) {
        provider.updateContent(text);
      }
      provider.updateSelection(selection.start, selection.end);
    });
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Catppuccin Mocha (Dark) / Latte (Light) themed highlighting
    final Map<String, TextStyle> catppuccinTheme = isDark ? {
      'root': const TextStyle(color: Color(0xFFCDD6F4)),
      'section': const TextStyle(color: Color(0xFFCBA6F7), fontWeight: FontWeight.bold), // Mauve
      'strong': const TextStyle(color: Color(0xFFFAB387), fontWeight: FontWeight.bold), // Peach
      'emphasis': const TextStyle(color: Color(0xFFFAB387), fontStyle: FontStyle.italic),
      'string': const TextStyle(color: Color(0xFFA6DA95)), // Green
      'bullet': const TextStyle(color: Color(0xFFF5C2E7)), // Pink
      'code': const TextStyle(color: Color(0xFF94E2D5), backgroundColor: Color(0xFF313244)), // Teal
      'link': const TextStyle(color: Color(0xFF89B4FA), decoration: TextDecoration.underline), // Blue
      'quote': const TextStyle(color: Color(0xFF9399B2), fontStyle: FontStyle.italic),
      'comment': const TextStyle(color: Color(0xFF585B70)),
    } : {
      'root': const TextStyle(color: Color(0xFF4C4F69)),
      'section': const TextStyle(color: Color(0xFF7287FD), fontWeight: FontWeight.bold),
      'strong': const TextStyle(color: Color(0xFFFE640B), fontWeight: FontWeight.bold),
      'emphasis': const TextStyle(color: Color(0xFFFE640B), fontStyle: FontStyle.italic),
      'string': const TextStyle(color: Color(0xFF40A02B)),
      'bullet': const TextStyle(color: Color(0xFFEA76CB)),
      'code': const TextStyle(color: Color(0xFF179299), backgroundColor: Color(0xFFDCE0E8)),
      'link': const TextStyle(color: Color(0xFF1E66F5), decoration: TextDecoration.underline),
      'quote': const TextStyle(color: Color(0xFF7C7F93), fontStyle: FontStyle.italic),
      'comment': const TextStyle(color: Color(0xFF9CA0B0)),
    };

    final nodes = highlight.parse(text, language: 'markdown').nodes ?? [];

    return TextSpan(
      style: style,
      children: _buildNodes(nodes, catppuccinTheme, style),
    );
  }

  List<TextSpan> _buildNodes(List<Node> nodes, Map<String, TextStyle> theme, TextStyle? baseStyle) {
    List<TextSpan> spans = [];
    for (var node in nodes) {
      if (node.value != null) {
        spans.add(TextSpan(
          text: node.value,
          style: (theme[node.className] ?? theme['root'] ?? baseStyle)?.copyWith(
            fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
          ),
        ));
      } else if (node.children != null) {
        spans.add(TextSpan(
          children: _buildNodes(node.children!, theme, theme[node.className] ?? baseStyle),
        ));
      }
    }
    return spans;
  }
}
