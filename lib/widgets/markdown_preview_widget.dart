import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import '../providers/markdown_provider.dart';

class MarkdownPreviewWidget extends StatefulWidget {
  const MarkdownPreviewWidget({super.key});

  @override
  State<MarkdownPreviewWidget> createState() => _MarkdownPreviewWidgetState();
}

class _MarkdownPreviewWidgetState extends State<MarkdownPreviewWidget> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Add scroll sync listener
    final provider = Provider.of<MarkdownProvider>(context, listen: false);
    provider.addListener(_onProviderChange);
  }

  void _onProviderChange() {
    final provider = Provider.of<MarkdownProvider>(context, listen: false);
    if (_scrollController.hasClients) {
      final max = _scrollController.position.maxScrollExtent;
      final target = provider.scrollPercentage * max;
      
      // Check difference to avoid infinite loop or jerky motion
      if ((_scrollController.offset - target).abs() > 5.0) {
        _scrollController.jumpTo(target);
      }
    }
  }

  @override
  void dispose() {
    Provider.of<MarkdownProvider>(context, listen: false).removeListener(_onProviderChange);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewContent = context.select((MarkdownProvider p) => p.previewContent);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: RepaintBoundary(
        child: Markdown(
          controller: _scrollController,
          data: previewContent,
          selectable: true,
          extensionSet: md.ExtensionSet.gitHubFlavored,
          builders: {
            'code': CodeElementBuilder(isDark: isDark),
            'blockquote': BlockquoteElementBuilder(isDark: isDark),
          },
          imageDirectory: 'C:\\',
          styleSheet: MarkdownStyleSheet(
            h1: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.4,
              color: isDark ? const Color(0xFFCDD6F4) : const Color(0xFF1E66F5),
            ),
            h2: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF),
            ),
            h3: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: isDark ? const Color(0xFF94E2D5) : const Color(0xFF179299),
            ),
            p: GoogleFonts.inter(
              fontSize: 15,
              height: 1.7,
              color: isDark ? const Color(0xFFCDD6F4) : const Color(0xFF4C4F69),
            ),
            blockquote: GoogleFonts.inter(
              fontSize: 15,
              color: isDark ? const Color(0xFF9399B2) : const Color(0xFF7C7F93),
              fontStyle: FontStyle.italic,
            ),
            blockquoteDecoration: BoxDecoration(
              color: isDark ? const Color(0xFF313244).withOpacity(0.3) : const Color(0xFFEFF1F5).withAlpha(150),
              border: Border(
                left: BorderSide(
                  color: isDark ? const Color(0xFF89DCEB) : const Color(0xFF179299),
                  width: 4,
                ),
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            listBullet: GoogleFonts.inter(
              fontSize: 15,
              color: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF),
            ),
            listIndent: 24.0,
            tableBody: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? const Color(0xFFCDD6F4) : const Color(0xFF4C4F69),
            ),
            tableBorder: TableBorder.all(
              color: isDark ? const Color(0xFF313244) : const Color(0xFFDCE0E8),
              width: 1,
            ),
            tableHead: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF),
            ),
            code: const TextStyle(
              fontFamily: 'monospace',
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

class BlockquoteElementBuilder extends MarkdownElementBuilder {
  final bool isDark;

  BlockquoteElementBuilder({required this.isDark});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        children: [
          Positioned(
            left: 12,
            top: 0,
            child: Icon(
              Icons.format_quote_rounded,
              size: 28,
              color: (isDark ? const Color(0xFF89DCEB) : const Color(0xFF179299)).withOpacity(0.4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 16, 16, 16),
            child: Text(
              element.textContent,
              style: preferredStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  final bool isDark;

  CodeElementBuilder({required this.isDark});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var language = '';

    if (element.attributes['class'] != null) {
      String lg = element.attributes['class'] as String;
      language = lg.split('-').last;
    }

    final String textContent = element.textContent;

    // Is it a block of code (multiline)?
    if (textContent.contains('\n')) {
      return CodeBlockWidget(
        textContent: textContent.trim(),
        language: language,
        isDark: isDark,
      );
    }

    // Inline code
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        textContent,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: isDark ? Colors.orangeAccent : Colors.deepOrange,
        ),
      ),
    );
  }
}

class CodeBlockWidget extends StatefulWidget {
  final String textContent;
  final String language;
  final bool isDark;

  const CodeBlockWidget({
    super.key,
    required this.textContent,
    required this.language,
    required this.isDark,
  });

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  bool _isExpanded = false;
  bool _copied = false;

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: widget.textContent));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 200,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageColor = _getLanguageColor(widget.language);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isDark 
            ? [const Color(0xFF1E1E2E), const Color(0xFF181825)]
            : [const Color(0xFFEFF1F5), const Color(0xFFE6E9EF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDark ? const Color(0xFF313244).withOpacity(0.5) : const Color(0xFFDCE0E8),
          width: 1,
        ),
        boxShadow: widget.isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.black26 : Colors.white24,
              border: Border(
                bottom: BorderSide(
                  color: widget.isDark ? const Color(0xFF313244) : const Color(0xFFDCE0E8),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      widget.language.isEmpty ? '#plaintext' : '#import ${widget.language}',
                      style: GoogleFonts.firaCode(
                        fontSize: 11,
                        color: const Color(0xFFA6DA95),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Consumer<MarkdownProvider>(
                      builder: (context, provider, _) => _actionButton(
                        icon: provider.isWrapped ? Icons.wrap_text_rounded : Icons.format_align_left_rounded,
                        color: provider.isWrapped ? const Color(0xFFCBA6F7) : null,
                        onPressed: () => provider.toggleWrap(),
                        tooltip: 'Toggle Wrap',
                      ),
                    ),
                    _actionButton(
                      icon: _copied ? Icons.check_circle_outline_rounded : Icons.copy_all_rounded,
                      color: _copied ? const Color(0xFF27C93F) : null,
                      onPressed: _handleCopy,
                      tooltip: 'Copy',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Code Area
          Consumer<MarkdownProvider>(
            builder: (context, provider, _) => SingleChildScrollView(
              scrollDirection: provider.isWrapped ? Axis.vertical : Axis.horizontal,
              padding: const EdgeInsets.all(24.0),
              child: HighlightView(
                widget.textContent,
                language: widget.language.isEmpty ? 'plaintext' : widget.language,
                theme: widget.isDark ? atomOneDarkTheme : atomOneLightTheme,
                padding: EdgeInsets.zero,
                textStyle: GoogleFonts.firaCode(
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLanguageColor(String lang) {
    switch (lang.toLowerCase()) {
      case 'dart': return const Color(0xFF00B4AB);
      case 'flutter': return const Color(0xFF02569B);
      case 'js':
      case 'javascript': return const Color(0xFFF7DF1E);
      case 'ts':
      case 'typescript': return const Color(0xFF3178C6);
      case 'html': return const Color(0xFFE34F26);
      case 'css': return const Color(0xFF1572B6);
      case 'py':
      case 'python': return const Color(0xFF3776AB);
      default: return const Color(0xFFED8796); // Default Mocha Red
    }
  }

  Widget _dot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _actionButton({required IconData icon, required VoidCallback onPressed, String? tooltip, Color? color}) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 16, color: color ?? (widget.isDark ? Colors.white38 : Colors.black38)),
        ),
      ),
    );
  }
}
