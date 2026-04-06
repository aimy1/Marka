import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/markdown_provider.dart';

/// Professional Editor Gutter for Marka Engine 2.0
/// Handles Line Numbers, Active Line Highlighting, and Indentation Guides.
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
    final double lineHeight = provider.fontSize * provider.lineHeight;
    const double topPadding = 24.0;
    const double gutterWidth = 52.0;

    return Container(
      width: gutterWidth,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11111B) : const Color(0xFFE6E9EF),
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF313244) : const Color(0xFFDCE0E8),
            width: 1,
          ),
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
            cacheExtent: 1000,
            itemBuilder: (context, index) {
              final isActive = index == activeLine;
              return Container(
                padding: const EdgeInsets.only(right: 12),
                alignment: Alignment.centerRight,
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    height: 1.0,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w400,
                    color: isActive 
                      ? (isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF))
                      : (isDark ? const Color(0xFF585B70) : const Color(0xFF9399B2)),
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

/// Viewport-Aware Indentation Guides Layer
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
    final scrollOffset = scrollController.offset;
    
    // Performance: Only draw within the physical viewport
    for (int i = 1; i < 15; i++) {
        final x = horizontalOffset + (i * 4 * charWidth);
        if (x > size.width) break;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant MarkaIndentGuidesLayer oldDelegate) => 
    oldDelegate.scrollController.offset != scrollController.offset;
}
