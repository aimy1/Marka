import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../providers/markdown_provider.dart';
import 'editor_controller.dart';
import 'editor_gutter.dart';

/// Professional Editor Surface for Marka v2.1.0 (Kate Refactor)
/// Strictly Aligned with Atomic Line-Heights and Unified Grid Architecture.
class MarkaEditorSurface extends StatelessWidget {
  final MarkaEditorController controller;
  final ScrollController scrollController;
  final FocusNode focusNode;
  final int activeLine;
  final MarkdownProvider provider;

  const MarkaEditorSurface({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.focusNode,
    required this.activeLine,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double lineHeightFactor = provider.lineHeight;
    final double calculatedLineHeight = provider.fontSize * lineHeightFactor;
    final double charWidth = provider.fontSize * 0.6;
    const double horizontalPadding = 24.0;
    const double topPadding = 24.0;

    // Studio Theme Palette (Minimalist)
    final Color surfaceBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final Color textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A1A);
    final Color cursorColor = isDark ? const Color(0xFFFFFFFF).withOpacity(0.9) : const Color(0xFF000000);
    final Color selectionColor = isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08);

    return Expanded(
      child: Stack(
        children: [
          // 1. Studio Backdrop (Row Continer Simulation & Grid)
          Positioned.fill(
            child: Container(
              color: surfaceBg,
              child: AnimatedBuilder(
                animation: scrollController,
                builder: (context, _) => CustomPaint(
                  painter: EditorRowBackgroundPainter(
                    scrollController: scrollController,
                    charWidth: charWidth,
                    horizontalOffset: horizontalPadding,
                    topPadding: topPadding,
                    lineHeight: calculatedLineHeight,
                    gridColor: isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.02),
                  ),
                ),
              ),
            ),
          ),

          // 2. Performance Highlight - Focused Line Slot
          _buildActiveLineSlot(topPadding, calculatedLineHeight, isDark),

          // 3. Kate-Style Strict Input Layer
          Positioned.fill(
            child: RawKeyboardListener(
              focusNode: FocusNode(), // Intercept for key hooks
              onKey: (event) => _handleKeyPress(event),
              child: Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: TextSelectionThemeData(
                    selectionColor: selectionColor,
                    selectionHandleColor: Colors.transparent, // Disable handles for IDE feel
                  ),
                ),
                child: TextField(
                  controller: controller,
                  scrollController: scrollController,
                  focusNode: focusNode,
                  maxLines: null,
                  expands: true,
                  cursorColor: cursorColor,
                  cursorWidth: 1.5, // Industrial thin caret
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: '', // No hint for professional studio look
                    contentPadding: const EdgeInsets.only(
                      left: horizontalPadding, 
                      top: topPadding, 
                      bottom: topPadding, 
                      right: horizontalPadding
                    ),
                  ),
                  // STRUT STYLE LOCK: Ensures 100% vertical predictability
                  strutStyle: StrutStyle(
                    forceStrutHeight: true,
                    height: lineHeightFactor,
                    fontSize: provider.fontSize,
                    fontFamily: provider.fontFamily,
                  ),
                  style: GoogleFonts.getFont(
                    provider.fontFamily,
                    fontSize: provider.fontSize,
                    height: lineHeightFactor,
                    letterSpacing: 0,
                    fontFeatures: const [FontFeature.disable('liga')],
                    color: textColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLineSlot(double topPadding, double lineHeight, bool isDark) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
         if (!scrollController.hasClients) return const SizedBox.shrink();
         final offset = (topPadding + (activeLine * lineHeight)) - scrollController.offset;
         if (offset < -lineHeight || offset > 2000) return const SizedBox.shrink();
         return Positioned(
           top: offset, left: 0, right: 0, height: lineHeight,
           child: Container(
             decoration: BoxDecoration(
               color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.025),
               border: Border.symmetric(vertical: BorderSide.none, horizontal: BorderSide(color: isDark ? Colors.white12 : Colors.black12, width: 0.5)),
             ),
           ),
         );
      },
    );
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;
    if (event.character != null && event.character!.length == 1) {
       controller.handleAutoClosing(event.character!);
    }
    if (event.logicalKey == LogicalKeyboardKey.tab) {
       final isShift = HardwareKeyboard.instance.isShiftPressed;
       controller.performBlockIndent(isOutdent: isShift);
    }
  }
}

/// Simulation of "Individual Row Containers" via background rendering
class EditorRowBackgroundPainter extends CustomPainter {
  final ScrollController scrollController;
  final double charWidth;
  final double horizontalOffset;
  final double topPadding;
  final double lineHeight;
  final Color gridColor;
  
  EditorRowBackgroundPainter({
    required this.scrollController, required this.charWidth, required this.horizontalOffset, 
    required this.topPadding, required this.lineHeight, required this.gridColor
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!scrollController.hasClients) return;
    final paint = Paint()..color = gridColor..strokeWidth = 0.5;
    
    // Draw vertical guides every 4 characters
    for (int i = 1; i < 20; i++) {
        final x = horizontalOffset + (i * 4 * charWidth);
        if (x > size.width) break;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Optional: Draw subtle horizontal separators to reinforce "Row Container" feel
    // These lines help bridge the visual gap between gutter and text area
    for (double y = 0; y < size.height; y += lineHeight) {
       // Only drawing vertical reference for now to avoid visual clutter, 
       // horizontal separation is handled by active line and strict metrics.
    }
  }

  @override bool shouldRepaint(covariant EditorRowBackgroundPainter oldDelegate) => 
    oldDelegate.scrollController.offset != scrollController.offset;
}
