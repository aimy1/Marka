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
    final provider = Provider.of<MarkdownProvider>(context, listen: false);
    provider.addListener(_onProviderChange);
  }

  void _onProviderChange() {
    final provider = Provider.of<MarkdownProvider>(context, listen: false);
    if (_scrollController.hasClients) {
      final max = _scrollController.position.maxScrollExtent;
      final target = provider.scrollPercentage * max;
      if ((_scrollController.offset - target).abs() > 5.0) {
        _scrollController.jumpTo(target);
      }
    }
  }

  @override
  void dispose() {
    try {
      final provider = Provider.of<MarkdownProvider>(context, listen: false);
      provider.removeListener(_onProviderChange);
    } catch (_) {}
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewContent = context.select((MarkdownProvider p) => p.previewContent);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
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
          imageDirectory: context.select((MarkdownProvider p) => p.currentFileDirectory),
          styleSheet: _buildStyleSheet(isDark),
        ),
      ),
    );
  }

  MarkdownStyleSheet _buildStyleSheet(bool isDark) {
    final textColor = isDark ? const Color(0xFFCDD6F4) : const Color(0xFF4C4F69);
    final accentColor = isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF);
    final borderColor = isDark ? const Color(0xFF313244) : const Color(0xFFDCE0E8);

    return MarkdownStyleSheet(
      h1: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, height: 1.4, color: isDark ? const Color(0xFFCDD6F4) : const Color(0xFF1E66F5)),
      h2: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, height: 1.4, color: accentColor),
      h3: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4, color: isDark ? const Color(0xFF94E2D5) : const Color(0xFF179299)),
      p: GoogleFonts.inter(fontSize: 15, height: 1.8, color: textColor),
      strong: const TextStyle(fontWeight: FontWeight.bold),
      em: const TextStyle(fontStyle: FontStyle.italic),
      blockquote: GoogleFonts.inter(fontSize: 15, color: isDark ? const Color(0xFF9399B2) : const Color(0xFF7C7F93), fontStyle: FontStyle.italic),
      blockquoteDecoration: BoxDecoration(
        color: isDark ? const Color(0xFF313244).withOpacity(0.3) : const Color(0xFFEFF1F5).withAlpha(150),
        border: Border(left: BorderSide(color: isDark ? const Color(0xFF89DCEB) : const Color(0xFF179299), width: 4)),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
      ),
      listBullet: GoogleFonts.inter(fontSize: 15, color: accentColor),
      listIndent: 24.0,
      tableBody: GoogleFonts.inter(fontSize: 14, color: textColor),
      tableBorder: TableBorder.all(color: borderColor, width: 1),
      tableHead: GoogleFonts.inter(fontWeight: FontWeight.bold, color: accentColor),
      tableHeadDecoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      horizontalRuleDecoration: BoxDecoration(border: Border(top: BorderSide(color: borderColor, width: 2))),
      code: TextStyle(fontFamily: 'monospace', backgroundColor: Colors.transparent, color: isDark ? const Color(0xFFFAB387) : const Color(0xFFFE640B)),
      codeblockDecoration: BoxDecoration(
        color: isDark ? const Color(0xFF11111B) : const Color(0xFFE6E9EF),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class BlockquoteElementBuilder extends MarkdownElementBuilder {
  final bool isDark;
  BlockquoteElementBuilder({required this.isDark});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF313244).withOpacity(0.2) : const Color(0xFFEFF1F5).withOpacity(0.5),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
        border: Border(left: BorderSide(color: isDark ? const Color(0xFF89DCEB) : const Color(0xFF179299), width: 4)),
      ),
      child: Text(element.textContent, style: preferredStyle),
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
    if (textContent.contains('\n')) {
      return CodeBlockWidget(textContent: textContent.trim(), language: language, isDark: isDark);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
      child: Text(textContent, style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: isDark ? const Color(0xFFFAB387) : const Color(0xFFFE640B))),
    );
  }
}

class CodeBlockWidget extends StatefulWidget {
  final String textContent;
  final String language;
  final bool isDark;
  const CodeBlockWidget({super.key, required this.textContent, required this.language, required this.isDark});

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  bool _copied = false;

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: widget.textContent));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _copied = false); });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF11111B) : const Color(0xFFE6E9EF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.isDark ? const Color(0xFF313244) : const Color(0xFFDCE0E8), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: widget.isDark ? Colors.black26 : Colors.white24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _dot(const Color(0xFFED8796)), const SizedBox(width: 6),
                    _dot(const Color(0xFFEED49F)), const SizedBox(width: 6),
                    _dot(const Color(0xFFA6DA95)), const SizedBox(width: 12),
                    Text(
                      widget.language.isEmpty ? 'CODE' : widget.language.toUpperCase(),
                      style: GoogleFonts.firaCode(fontSize: 10, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white30 : Colors.black30),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _handleCopy,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, key: ValueKey(_copied), size: 16, color: _copied ? Colors.green : (widget.isDark ? Colors.white30 : Colors.black30)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: HighlightView(
              widget.textContent,
              language: widget.language.isEmpty ? 'plaintext' : widget.language,
              theme: widget.isDark ? atomOneDarkTheme : atomOneLightTheme,
              textStyle: GoogleFonts.jetBrainsMono(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
