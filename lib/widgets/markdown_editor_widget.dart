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
    
    // Add the listener separately so we can remove it during sync
    _controller.addListener(_onControllerChange);
    
    // Auto-focus on init or file switch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  int _lastActiveTabIndex = -1;
  bool _isUpdatingProgrammatically = false;

  void _onControllerChange() {
    if (_isUpdatingProgrammatically) return;
    
    final provider = Provider.of<MarkdownProvider>(context, listen: false);
    if (_controller.text != provider.content) {
      provider.updateContent(_controller.text);
    }
    provider.updateSelection(_controller.selection.start, _controller.selection.end);
  }

  void _onProviderChange() {
    final provider = Provider.of<MarkdownProvider>(context, listen: false);
    final session = provider.activeSession;
    
    if (session == null) return;

    // Detect if we switched segments (sessions)
    bool sessionChanged = _lastActiveTabIndex != provider.activeTabIndex;
    bool contentOutOfSync = _controller.text != session.content;
    
    if (sessionChanged || contentOutOfSync) {
      _lastActiveTabIndex = provider.activeTabIndex;
      
      // Temporarily remove listener to avoid sync loop
      _controller.removeListener(_onControllerChange);
      
      final oldSelection = _controller.selection;
      final newSelection = (sessionChanged || !oldSelection.isValid) 
          ? TextSelection.collapsed(offset: 0)
          : oldSelection;

      _controller.value = TextEditingValue(
        text: session.content,
        selection: newSelection,
      );
      
      // Re-add listener after value is set
      _controller.addListener(_onControllerChange);

      // Sync scroll for new sessions
      if (sessionChanged && _scrollController.hasClients) {
        _scrollController.jumpTo(0); // Reset scroll to top for new file
      } else if (_scrollController.hasClients) {
        // Subtle sync if needed
        final max = _scrollController.position.maxScrollExtent;
        if (max > 0) {
          final target = session.scrollPercentage * max;
          if ((_scrollController.offset - target).abs() > 50) {
            _scrollController.jumpTo(target);
          }
        }
      }
      
      // Re-focus whenever significant change occurs (especially after file picker)
      debugPrint('Syncing MarkdownEditorWidget: ${session.name}, content length: ${session.content.length}');
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      });
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
    _focusNode.dispose();
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
                        fontSize: 12,
                        color: isDark ? const Color(0xFF585B70) : const Color(0xFF9399B2),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
            child: TextField(
              controller: _controller,
              scrollController: _scrollController,
              focusNode: _focusNode,
              maxLines: null,
              expands: true,
              autofocus: true,
              onTap: () {
                _focusNode.requestFocus();
              },
              cursorColor: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Start writing...',
              ),
              style: GoogleFonts.jetBrainsMono(
                fontSize: provider.fontSize,
                height: 1.5,
                color: isDark ? const Color(0xFFCDD6F4) : const Color(0xFF4C4F69),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _moveToLine(int lineIndex) {
    final text = _controller.text;
    final lines = text.split('\n');
    if (lineIndex < 0 || lineIndex >= lines.length) return;
    
    int offset = 0;
    for (int i = 0; i < lineIndex; i++) {
       offset += lines[i].length + 1; // +1 for newline
    }
    
    // Safety check for offset
    final finalOffset = offset.clamp(0, text.length);
    
    _controller.selection = TextSelection.collapsed(offset: finalOffset);
    _focusNode.requestFocus();
    
    // On Web, explicitly request focus and update provider
    final provider = Provider.of<MarkdownProvider>(context, listen: false);
    provider.updateSelection(finalOffset, finalOffset);
  }

  void _handleEnter() {
    final text = _controller.text;
    final selection = _controller.selection;
    if (selection.start < 0) return;

    final lines = text.substring(0, selection.start).split('\n');
    final currentLine = lines.isNotEmpty ? lines.last : '';

    String prefix = '';
    if (currentLine.trimLeft().startsWith('- ')) {
      prefix = '- ';
    } else if (RegExp(r'^\s*\d+\.\s+').hasMatch(currentLine)) {
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
      if (prefix.isNotEmpty && currentLine.trim() == prefix.trim()) {
         final startOfLine = selection.start - currentLine.length;
         final newText = text.replaceRange(startOfLine, selection.start, '');
         _controller.value = TextEditingValue(
           text: newText,
           selection: TextSelection.collapsed(offset: startOfLine),
         );
         return;
      }
      
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
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return TextSpan(text: text, style: style);
  }
}
