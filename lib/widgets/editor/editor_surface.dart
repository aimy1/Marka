import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../providers/markdown_provider.dart';
import 'editor_controller.dart';
import 'editor_gutter.dart';

/// Professional Editor Surface for Marka Engine 2.0
/// Handles the Core Input, Keyboard Shortcuts, and Visual Selection state.
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

    return Expanded(
      child: Stack(
        children: [
          // 1. Background Grid & Guides
          Positioned.fill(
            child: Container(
              color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
              child: AnimatedBuilder(
                animation: scrollController,
                builder: (context, _) => CustomPaint(
                  painter: MarkaIndentGuidesLayer(
                    scrollController: scrollController,
                    charWidth: charWidth,
                    horizontalOffset: horizontalPadding,
                    topPadding: topPadding,
                    lineHeight: calculatedLineHeight,
                    guideColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.04),
                  ),
                ),
              ),
            ),
          ),

          // 2. Performance-Aware Current Line Highlight
          _buildLineHighlight(topPadding, calculatedLineHeight, isDark),

          // 3. Core Input Layer (Engine 2.0)
          Positioned.fill(
            child: RawKeyboardListener(
              focusNode: FocusNode(), // Temporary for key detection
              onKey: (event) => _handleKeyPress(event),
              child: TextField(
                controller: controller,
                scrollController: scrollController,
                focusNode: focusNode,
                maxLines: null,
                expands: true,
                cursorColor: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF),
                cursorWidth: 2,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: topPadding),
                ),
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
                  color: isDark ? const Color(0xFFCDD6F4) : const Color(0xFF4C4F69),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineHighlight(double topPadding, double lineHeight, bool isDark) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
         if (!scrollController.hasClients) return const SizedBox.shrink();
         final offset = (topPadding + (activeLine * lineHeight)) - scrollController.offset;
         // Aggressive clipping: Only render if reasonably close to viewport
         if (offset < -lineHeight || offset > 2000) return const SizedBox.shrink();
         return Positioned(
           top: offset, left: 0, right: 0, height: lineHeight,
           child: Container(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
         );
      },
    );
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;
    
    // Auto-Closing Hook
    if (event.character != null && event.character!.length == 1) {
       controller.handleAutoClosing(event.character!);
    }

    // Block Indent Hook (Tab / Shift+Tab)
    if (event.logicalKey == LogicalKeyboardKey.tab) {
       final isShift = HardwareKeyboard.instance.isShiftPressed;
       controller.performBlockIndent(isOutdent: isShift);
    }
  }
}
