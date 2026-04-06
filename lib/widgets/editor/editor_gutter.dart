import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/markdown_provider.dart';

/// Marka v2.8.0 - Professional Line Number Gutter
/// Enforces pixel-perfect vertical alignment with the main editor surface.
class MarkaEditorGutter extends StatelessWidget {
  final ScrollController scrollController;
  final int lineCount;
  final double fontSize;
  final double lineHeight;

  const MarkaEditorGutter({
    super.key,
    required this.scrollController,
    required this.lineCount,
    required this.fontSize,
    required this.lineHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = Provider.of<MarkdownProvider>(context);

    if (!p.showLineNumbers) return const SizedBox.shrink();

    // Calculate width based on line count digits
    final double width = lineCount.toString().length * (fontSize * 0.6) + 32;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181825) : const Color(0xFFF9F9F9),
        border: Border(right: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
      ),
      child: ListView.builder(
        controller: scrollController,
        physics: const NeverScrollableScrollPhysics(), // Synced by external source
        itemCount: lineCount,
        padding: EdgeInsets.symmetric(vertical: p.lineHeight * 16),
        itemBuilder: (context, index) {
          final isCurrent = p.cursorLine == index + 1;
          return Container(
            height: fontSize * lineHeight,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              '${index + 1}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: fontSize * 0.82,
                height: lineHeight,
                color: isCurrent 
                  ? (isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF))
                  : (isDark ? Colors.white10 : Colors.black12),
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }
}
