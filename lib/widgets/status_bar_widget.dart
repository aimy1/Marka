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
    
    // Colors
    final textColor = isDark ? const Color(0xFF9399B2) : const Color(0xFF7C7F93);
    final iconColor = isDark ? const Color(0xFF585B70) : const Color(0xFF9399B2);
    final accentColor = isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF);

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
          // Editor Mode / Language
          _statusBarItem(context, 'Markdown', Icons.article_outlined, isDark),
          _divider(isDark),
          
          // Coordinate Info (Kate Style)
          _statusBarItem(
            context, 
            provider.t('ln_col').replaceAll('{0}', '${provider.cursorLine}').replaceAll('{1}', '${provider.cursorColumn}'), 
            Icons.location_searching_rounded, 
            isDark,
            color: accentColor
          ),
          
          // Selection Info
          if (provider.selectionLength > 0) ...[
            _divider(isDark),
            _statusBarItem(
              context, 
              provider.t('sel').replaceAll('{0}', '${provider.selectionLength}'), 
              Icons.select_all_rounded, 
              isDark,
              color: const Color(0xFFFAB387)
            ),
          ],
          
          _divider(isDark),
          
          // Text Stats
          _statusBarItem(context, '$wordCount Words', Icons.spellcheck_rounded, isDark),
          _divider(isDark),
          _statusBarItem(context, '$charCount Chars', Icons.text_fields_rounded, isDark),
          
          const Spacer(),
          
          // File Name & Save Status
          Text(
            provider.activeSession?.name ?? 'Untitled.md',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            provider.isModified ? Icons.pending_rounded : Icons.check_circle_outline_rounded,
            size: 14,
            color: provider.isModified ? const Color(0xFFFAB387) : const Color(0xFFA6DA95),
          ),
        ],
      ),
    );
  }

  Widget _statusBarItem(BuildContext context, String label, IconData icon, bool isDark, {Color? color}) {
    final defaultTextColor = isDark ? const Color(0xFF9399B2) : const Color(0xFF7C7F93);
    
    return Row(
      children: [
        Icon(
          icon,
          size: 13,
          color: color?.withOpacity(0.8) ?? (isDark ? const Color(0xFF585B70) : const Color(0xFF9399B2)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10.5,
            fontWeight: color != null ? FontWeight.w700 : FontWeight.w500,
            color: color ?? defaultTextColor,
          ),
        ),
      ],
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14.0),
      height: 12,
      width: 1,
      color: isDark ? const Color(0xFF313244) : const Color(0xFFC6D0F5).withOpacity(0.5),
    );
  }
}
