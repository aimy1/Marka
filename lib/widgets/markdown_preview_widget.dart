import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../providers/markdown_provider.dart';
import '../utils/front_matter_parser.dart';
import 'markdown_metadata_header.dart';

/// Marka v2.6.0 - YAML Front Matter Hero Integration
/// Renders Title, Date, Categories, and Tags as a professional Hero Header.
/// Maintained 100% Scroll Sync compatibility from v2.3.0.
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
    if (!mounted) return;
    setState(() {});

    final provider = Provider.of<MarkdownProvider>(context, listen: false);
    if (!provider.isSyncScroll) return;
    
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

    // ── Parse Front Matter ──
    final result = FrontMatterParser.parse(provider.previewContent);

    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
        children: [
          // ── Hero Header ──
          MarkdownMetadataHeader(data: result.data, isDark: isDark),

          // ── Clean Markdown Body ──
          MarkdownBody(
            data: result.content,
            selectable: true,
            extensionSet: md.ExtensionSet.gitHubFlavored,
            imageDirectory: provider.currentFileDirectory,
            onTapLink: (text, href, title) {
              if (href != null) {
                Clipboard.setData(ClipboardData(text: href));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已复制链接到剪贴板: $href'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            styleSheet: _buildStyleSheet(provider, isDark),
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet _buildStyleSheet(MarkdownProvider provider, bool isDark) {
    final textColor = isDark ? const Color(0xFFCDD6F4) : const Color(0xFF4C4F69);
    final accentColor = isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF);
    final linkColor = isDark ? const Color(0xFF89B4FA) : const Color(0xFF1E66F5);
    final codeBg = isDark ? const Color(0xFF313244) : const Color(0xFFE6E9EF);
    final codeColor = isDark ? const Color(0xFFFAB387) : const Color(0xFFFE640B);
    final borderColor = isDark ? const Color(0xFF313244) : const Color(0xFFDCE0E8);

    return MarkdownStyleSheet(
      // ── Headings Typography Ladder ──
      h1: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.35, color: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5)),
      h1Padding: const EdgeInsets.only(top: 16, bottom: 12),
      h2: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.4, color: isDark ? const Color(0xFF89DCEB) : const Color(0xFF179299)),
      h2Padding: const EdgeInsets.only(top: 14, bottom: 10),
      h3: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.45, color: accentColor),
      h3Padding: const EdgeInsets.only(top: 12, bottom: 8),
      h4: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5, color: textColor),
      h5: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.5, color: textColor),
      h6: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.5, color: isDark ? Colors.white54 : Colors.black54),
      
      // ── Paragraph & Typography ──
      p: TextStyle(fontSize: 15, height: 1.68, color: textColor),
      pPadding: const EdgeInsets.only(bottom: 12),
      strong: const TextStyle(fontWeight: FontWeight.bold),
      em: const TextStyle(fontStyle: FontStyle.italic),
      a: TextStyle(color: linkColor, decoration: TextDecoration.underline, fontWeight: FontWeight.w500),

      // ── Blockquote (Catppuccin Accent Side Border) ──
      blockquote: TextStyle(
        fontSize: 15, 
        height: 1.65, 
        color: isDark ? const Color(0xFFA6ADC8) : const Color(0xFF5C5F77), 
        fontStyle: FontStyle.italic
      ),
      blockquoteDecoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.035) : Colors.black.withOpacity(0.025),
        border: Border(left: BorderSide(color: accentColor, width: 3.5)),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(18, 12, 16, 12),

      // ── Lists & Bullet ──
      listBullet: TextStyle(fontSize: 15, color: accentColor, fontWeight: FontWeight.bold),
      listIndent: 28.0,

      // ── Tables ──
      tableBody: TextStyle(fontSize: 14, height: 1.5, color: textColor),
      tableBorder: TableBorder.all(color: borderColor, width: 1.0, style: BorderStyle.solid),
      tableHead: TextStyle(fontWeight: FontWeight.w700, color: accentColor, fontSize: 13.5),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

      // ── Code & Codeblock ──
      code: TextStyle(
        fontSize: 13.0,
        backgroundColor: codeBg,
        color: codeColor,
      ),
      codeblockDecoration: BoxDecoration(
        color: isDark ? const Color(0xFF11111B) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      codeblockPadding: const EdgeInsets.all(16),

      // ── Horizontal Divider ──
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.black12, width: 1.5)),
      ),
    );
  }
}
