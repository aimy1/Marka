import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Professional Hero Header for Markdown Front Matter v2.6.0
class MarkdownMetadataHeader extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;

  const MarkdownMetadataHeader({super.key, required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final title = data['title'] ?? '';
    final date = data['date'] ?? '';
    final categories = data['categories'] as List<String>? ?? [];
    final tags = data['tags'] as List<String>? ?? [];

    final accentCol = isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF);
    final subTextCol = isDark ? const Color(0xFF9399B2) : const Color(0xFF7C7F93);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title Hero ──
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.2,
                color: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5),
              ),
            ),
          ),

        // ── Meta Info (Date) ──
        if (date.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: subTextCol.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  date,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: subTextCol,
                  ),
                ),
              ],
            ),
          ),

        // ── Categories & Tags ──
        if (categories.isNotEmpty || tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Wrap(
              spacing: 8,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...categories.map((c) => _buildPill(c, accentCol.withOpacity(0.12), accentCol, true)),
                ...tags.map((t) => _buildPill('#$t', Colors.transparent, subTextCol.withOpacity(0.8), false)),
              ],
            ),
          ),

        // ── Final Gradiant Divider ──
        Container(
          height: 1,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentCol.withOpacity(0.2),
                accentCol.withOpacity(0.01),
              ],
            ),
          ),
          margin: const EdgeInsets.only(bottom: 40),
        ),
      ],
    );
  }

  Widget _buildPill(String label, Color bg, Color textCol, bool border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: border ? Border.all(color: textCol.withOpacity(0.2), width: 0.5) : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textCol,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
