import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/markdown_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusBarWidget extends StatelessWidget {
  const StatusBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<MarkdownProvider>(context);
    final text = provider.content;
    
    // Calculate stats
    final charCount = text.length;
    final wordCount = text.isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    final lineCount = '\n'.allMatches(text).length + 1;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11111B) : const Color(0xFFDCE0E8),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF313244) : const Color(0xFFC6D0F5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _statusBarItem(context, 'Markdown', Icons.article_outlined, isDark),
          _divider(isDark),
          _statusBarItem(context, '$lineCount Lines', Icons.format_list_numbered_rtl_rounded, isDark),
          _divider(isDark),
          _statusBarItem(context, '$wordCount Words', Icons.spellcheck_rounded, isDark),
          _divider(isDark),
          _statusBarItem(context, '$charCount Chars', Icons.text_fields_rounded, isDark),
          const Spacer(),
          Text(
            provider.currentFilePath ?? 'Untitled.md',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF9399B2) : const Color(0xFF7C7F93),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            provider.isModified ? Icons.edit_note_rounded : Icons.save_outlined,
            size: 14,
            color: provider.isModified ? const Color(0xFFFAB387) : const Color(0xFFA6DA95),
          ),
        ],
      ),
    );
  }

  Widget _statusBarItem(BuildContext context, String label, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? const Color(0xFF9399B2) : const Color(0xFF7C7F93),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF9399B2) : const Color(0xFF7C7F93),
          ),
        ),
      ],
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      height: 12,
      width: 1,
      color: isDark ? const Color(0xFF313244) : const Color(0xFFC6D0F5),
    );
  }
}
