import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/markdown_provider.dart';

/// Professional Editor Gutter for Marka v2.1.0 (Kate Refactor)
/// Strictly Right-Aligned, Fixed Width, and Studio Grey Aesthetics.
class MarkaEditorGutter extends StatelessWidget {
  final ScrollController scrollController;
  final ScrollController lineNumbersController;
  final int activeLine;
  final int lineCount;
  final MarkdownProvider provider;

  const MarkaEditorGutter({
    super.key,
    required this.scrollController,
    required this.lineNumbersController,
    required this.activeLine,
    required this.lineCount,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Core Studio Colors (Minimalism)
    final Color gutterBg = isDark ? const Color(0xFF18181A) : const Color(0xFFE8E8E8);
    final Color gutterBorder = isDark ? const Color(0xFF2D2D2D) : const Color(0xFFCCCCCC);
    final Color numberColor = isDark ? const Color(0xFF858585) : const Color(0xFF6E6E6E);
    final Color activeNumberColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

    final double lineHeight = provider.fontSize * provider.lineHeight;
    const double topPadding = 24.0;
    const double gutterWidth = 60.0; // Fixed Width per User Request

    return Container(
      width: gutterWidth,
      decoration: BoxDecoration(
        color: gutterBg,
        border: Border(
          right: BorderSide(color: gutterBorder, width: 1),
        ),
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: RepaintBoundary(
          child: ListView.builder(
            controller: lineNumbersController,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: topPadding),
            itemCount: lineCount,
            itemExtent: lineHeight,
            cacheExtent: 1500, // Increased for stability
            itemBuilder: (context, index) {
              final isActive = index == activeLine;
              return Container(
                padding: const EdgeInsets.only(right: 12),
                alignment: Alignment.centerRight, // RIGHT-ALIGNED Gutter
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    height: 1.0,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive ? activeNumberColor : numberColor,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Viewport-Aware Indentation Guides Layer (Studio Grade)
class MarkaIndentGuidesLayer extends CustomPainter {
  final ScrollController scrollController;
  final double charWidth;
  final double horizontalOffset;
  final double topPadding;
  final double lineHeight;
  final Color guideColor;
  
  MarkaIndentGuidesLayer({
    required this.scrollController,
    required this.charWidth,
    required this.horizontalOffset,
    required this.topPadding,
    required this.lineHeight,
    required this.guideColor
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!scrollController.hasClients) return;
    
    final paint = Paint()..color = guideColor..strokeWidth = 1;
    
    // Draw vertical guides every 4 characters with strict grid logic
    for (int i = 1; i < 20; i++) {
        final x = horizontalOffset + (i * 4 * charWidth);
        if (x > size.width) break;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant MarkaIndentGuidesLayer oldDelegate) => 
    oldDelegate.scrollController.offset != scrollController.offset;
}
