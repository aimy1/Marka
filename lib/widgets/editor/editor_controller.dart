import 'dart:ui';
import 'package:flutter/material.dart';
import '../providers/markdown_provider.dart';

/// Professional Editor Controller for Marka Engine 2.0
/// Handles Incremental Highlighting, Block Indent, and Auto-closing logic.
class MarkaEditorController extends TextEditingController {
  final MarkdownProvider provider;
  
  MarkaEditorController({required this.provider}) {
    text = provider.content;
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<TextSpan> children = [];
    
    // Engine 2.0 optimized regex set
    final patterns = {
      RegExp(r'\*\*.*?\*\*'): isDark ? const Color(0xFFF9E2AF) : const Color(0xFFDF8E1D),
      RegExp(r'\*.*?\*'): isDark ? const Color(0xFFF9E2AF) : const Color(0xFFDF8E1D),
      RegExp(r'^#+ .*$', multiLine: true): isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF),
      RegExp(r'\[.*?\]\(.*?\)'): isDark ? const Color(0xFF89B4FA) : const Color(0xFF1E66F5),
      RegExp(r'`.*?`'): isDark ? const Color(0xFFFAB387) : const Color(0xFFFE640B),
      RegExp(r'^> .*$', multiLine: true): isDark ? const Color(0xFFA6ADC8) : const Color(0xFF7C7F93),
      RegExp(r'```[\s\S]*?```'): isDark ? const Color(0xFF94E2D5) : const Color(0xFF179299),
    };

    text.splitMapJoin(
      RegExp(patterns.keys.map((r) => r.pattern).join('|'), multiLine: true),
      onMatch: (m) {
        final matchText = m[0]!;
        Color? matchColor;
        FontWeight weight = FontWeight.normal;
        for (final entry in patterns.entries) {
          if (entry.key.hasMatch(matchText)) {
            matchColor = entry.value;
            if (entry.key.pattern.contains(r'\*\*')) weight = FontWeight.bold;
            break;
          }
        }
        children.add(TextSpan(text: matchText, style: style?.copyWith(color: matchColor, fontWeight: weight)));
        return '';
      },
      onNonMatch: (n) {
        children.add(TextSpan(text: n, style: style));
        return '';
      },
    );
    return TextSpan(children: children, style: style);
  }

  /// 📐 Professional Block Indentation Logic (Kate Style)
  /// Supports multi-line indent (Tab) and outdent (Shift+Tab)
  void performBlockIndent({required bool isOutdent}) {
    if (selection.isCollapsed) return;

    final start = selection.start;
    final end = selection.end;
    
    // Find the actual line boundaries for the selection
    final firstNewLineBefore = text.lastIndexOf('\n', start - 1);
    final actualStart = firstNewLineBefore == -1 ? 0 : firstNewLineBefore + 1;
    
    final lastNewLineBeforeEnd = text.lastIndexOf('\n', end - 1);
    final lastLineStart = lastNewLineBeforeEnd == -1 ? 0 : lastNewLineBeforeEnd + 1;
    final actualEnd = text.indexOf('\n', end) == -1 ? text.length : text.indexOf('\n', end);

    final selectedText = text.substring(actualStart, actualEnd);
    final lines = selectedText.split('\n');
    final processedLines = <String>[];

    int delta = 0;
    for (var line in lines) {
      if (isOutdent) {
        if (line.startsWith('  ')) {
          processedLines.add(line.substring(2));
          delta -= 2;
        } else if (line.startsWith(' ')) {
          processedLines.add(line.substring(1));
          delta -= 1;
        } else {
          processedLines.add(line);
        }
      } else {
        processedLines.add('  $line');
        delta += 2;
      }
    }

    final newContent = text.replaceRange(actualStart, actualEnd, processedLines.join('\n'));
    value = TextEditingValue(
      text: newContent,
      selection: TextSelection(
        baseOffset: start + (isOutdent ? (lines.first.startsWith(' ') ? -1 : 0) : 2),
        extentOffset: end + delta,
      ),
    );
    provider.updateContent(newContent);
  }

  /// 🤖 Auto-closing symbols logic
  void handleAutoClosing(String char) {
    const pairs = {'(': ')', '[': ']', '{': '}', '"': '"', "'": "'", '*': '*', '`': '`',};
    if (pairs.containsKey(char)) {
      final closing = pairs[char]!;
      final start = selection.start;
      final end = selection.end;
      
      final newText = text.replaceRange(start, end, '$char$closing');
      value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + 1),
      );
      provider.updateContent(newText);
    }
  }
}
