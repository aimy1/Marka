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
    if (!provider.isSyncScroll) return; // Respect sync scroll setting
    
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
    final provider = Provider.of<MarkdownProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: RepaintBoundary(
        child: Markdown(
          controller: _scrollController,
          data: provider.previewContent,
          selectable: true,
          extensionSet: md.ExtensionSet.gitHubFlavored,
          builders: {
            'code': CodeElementBuilder(isDark: isDark),
            'blockquote': BlockquoteElementBuilder(isDark: isDark),
            'hr': HorizontalRuleBuilder(isDark: isDark),
          },
          imageDirectory: provider.currentFileDirectory,
          styleSheet: _buildStyleSheet(provider, isDark),
        ),
      ),
    );
  }

  MarkdownStyleSheet _buildStyleSheet(MarkdownProvider provider, bool isDark) {
    final textColor = isDark ? const Color(0xFFCDD6F4) : const Color(0xFF4C4F69);
    final accentColor = isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF);
    final borderColor = isDark ? const Color(0xFF313244) : const Color(0xFFDCE0E8);
    final lh = provider.lineHeight;

    return MarkdownStyleSheet(
      h1: GoogleFonts.outfit(
        fontSize: 34, 
        fontWeight: FontWeight.w800, 
        height: 1.3, 
        letterSpacing: -0.5,
        color: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5)
      ),
      h2: GoogleFonts.outfit(
        fontSize: 26, 
        fontWeight: FontWeight.w700, 
        height: 1.4, 
        color: isDark ? const Color(0xFF89DCEB) : const Color(0xFF179299)
      ),
      h3: GoogleFonts.outfit(fontSize: 21, fontWeight: FontWeight.w600, height: 1.4, color: accentColor),
      p: GoogleFonts.inter(fontSize: 16, height: lh, color: textColor, letterSpacing: 0.2),
      strong: const TextStyle(fontWeight: FontWeight.bold),
      em: const TextStyle(fontStyle: FontStyle.italic),
      blockquote: GoogleFonts.inter(fontSize: 16, height: lh, color: isDark ? const Color(0xFF9399B2) : const Color(0xFF7C7F93), fontStyle: FontStyle.italic),
      listBullet: GoogleFonts.inter(fontSize: 16, color: accentColor),
      listIndent: 28.0,
      tableBody: GoogleFonts.inter(fontSize: 15, height: lh, color: textColor),
      tableBorder: TableBorder.all(color: Colors.transparent, width: 0),
      tableHead: GoogleFonts.inter(fontWeight: FontWeight.w800, color: accentColor, fontSize: 13, letterSpacing: 1.0),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      tableCellsDecoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      code: TextStyle(
        fontFamily: 'monospace', 
        fontSize: 14,
        backgroundColor: Colors.transparent, 
        color: isDark ? const Color(0xFFFAB387) : const Color(0xFFFE640B)
      ),
    );
  }
}

class HorizontalRuleBuilder extends MarkdownElementBuilder {
  final bool isDark;
  HorizontalRuleBuilder({required this.isDark});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 32),
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            (isDark ? const Color(0xFF313244) : const Color(0xFFDCE0E8)).withOpacity(0.8),
            Colors.transparent,
          ],
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.fromLTRB(24, 16, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF313244).withOpacity(0.15) : const Color(0xFFEFF1F5).withOpacity(0.4),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
        border: Border(
          left: BorderSide(
            color: isDark ? const Color(0xFFCBA6F7).withOpacity(0.8) : const Color(0xFF8839EF).withOpacity(0.8), 
            width: 5
          )
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFFFAB387) : const Color(0xFFFE640B)).withOpacity(0.12), 
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: (isDark ? const Color(0xFFFAB387) : const Color(0xFFFE640B)).withOpacity(0.2), width: 0.5),
      ),
      child: Text(
        textContent, 
        style: TextStyle(
          fontFamily: 'monospace', 
          fontSize: 13.5, 
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFFAB387) : const Color(0xFFD65D0E)
        )
      ),
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
    final provider = Provider.of<MarkdownProvider>(context);
    final bgColor = widget.isDark ? const Color(0xFF11111B) : const Color(0xFFE6E9EF);
    final borderColor = widget.isDark ? const Color(0xFF313244) : const Color(0xFFDCE0E8);
    final accentColor = widget.isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.3 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(color: borderColor.withOpacity(0.6), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
              border: Border(bottom: BorderSide(color: borderColor.withOpacity(0.5), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _dot(const Color(0xFFED8796)), const SizedBox(width: 8),
                    _dot(const Color(0xFFEED49F)), const SizedBox(width: 8),
                    _dot(const Color(0xFFA6DA95)), const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accentColor.withOpacity(0.2), width: 0.5),
                      ),
                      child: Text(
                        widget.language.isEmpty ? 'TEXT' : widget.language.toUpperCase(),
                        style: GoogleFonts.firaCode(
                          fontSize: 10, 
                          fontWeight: FontWeight.w800, 
                          letterSpacing: 1.1,
                          color: accentColor.withOpacity(0.9)
                        ),
                      ),
                    ),
                  ],
                ),
                Tooltip(
                  message: provider.t('copied'),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleCopy,
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(8),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            _copied ? Icons.check_circle_rounded : Icons.copy_all_rounded, 
                            key: ValueKey(_copied), 
                            size: 18, 
                            color: _copied ? const Color(0xFFA6DA95) : (widget.isDark ? Colors.white24 : Colors.black26)
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Theme(
              data: Theme.of(context).copyWith(
                scrollbarTheme: ScrollbarThemeData(
                  thumbColor: MaterialStateProperty.all(accentColor.withOpacity(0.2)),
                  radius: const Radius.circular(10),
                )
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: HighlightView(
                  widget.textContent,
                  language: widget.language.isEmpty ? 'plaintext' : widget.language,
                  theme: widget.isDark ? atomOneDarkTheme : atomOneLightTheme,
                  textStyle: GoogleFonts.jetBrainsMono(fontSize: 14.5, height: provider.lineHeight, letterSpacing: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 10, 
    height: 10, 
    decoration: BoxDecoration(
      color: color, 
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, spreadRadius: 1)]
    )
  );
}
