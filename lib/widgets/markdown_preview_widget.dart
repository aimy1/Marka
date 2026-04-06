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
            styleSheet: _buildStyleSheet(provider, isDark),
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet _buildStyleSheet(MarkdownProvider provider, bool isDark) {
    final textColor = isDark ? const Color(0xFFCDD6F4) : const Color(0xFF4C4F69);
    final accentColor = isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF);
    final borderColor = isDark ? const Color(0xFF1E1E2E).withOpacity(0.5) : const Color(0xFFDCE0E8);
    final lh = provider.lineHeight;

    return MarkdownStyleSheet(
      h1: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, height: 1.3, color: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5)),
      h2: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, height: 1.4, color: isDark ? const Color(0xFF89DCEB) : const Color(0xFF179299)),
      h3: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4, color: accentColor),
      p: GoogleFonts.inter(fontSize: 15, height: lh, color: textColor),
      strong: const TextStyle(fontWeight: FontWeight.bold),
      em: const TextStyle(fontStyle: FontStyle.italic),
      blockquote: GoogleFonts.inter(fontSize: 15, height: lh, color: isDark ? const Color(0xFF9399B2) : const Color(0xFF7C7F93), fontStyle: FontStyle.italic),
      listBullet: GoogleFonts.inter(fontSize: 15, color: accentColor),
      listIndent: 28.0,
      tableBody: GoogleFonts.inter(fontSize: 14, height: lh, color: textColor),
      tableBorder: TableBorder.all(color: Colors.transparent, width: 0),
      tableHead: GoogleFonts.inter(fontWeight: FontWeight.w800, color: accentColor, fontSize: 12),
      code: TextStyle(
        fontFamily: 'monospace', 
        fontSize: 13,
        backgroundColor: (isDark ? const Color(0xFFFAB387) : const Color(0xFFFE640B)).withOpacity(0.1),
        color: isDark ? const Color(0xFFFAB387) : const Color(0xFFFE640B)
      ),
      codeblockDecoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
    );
  }
}
