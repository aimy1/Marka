import 'dart:ui';
import 'package:flutter/material.dart';
import '../../providers/markdown_provider.dart';

/// Professional Editor Controller for Marka Engine 2.0
/// Handles Incremental Highlighting, Block Indent, and Auto-closing logic.
class MarkaEditorController extends TextEditingController {
  final MarkdownProvider provider;
  
  MarkaEditorController({required this.provider}) {
    text = provider.content;
  }

  static final RegExp _boldReg = RegExp(r'\*\*.*?\*\*');
  static final RegExp _italicReg = RegExp(r'\*.*?\*');
  static final RegExp _headingReg = RegExp(r'^#+ .*$', multiLine: true);
  static final RegExp _linkReg = RegExp(r'\[.*?\]\(.*?\)');
  static final RegExp _codeInlineReg = RegExp(r'`.*?`');
  static final RegExp _quoteReg = RegExp(r'^> .*$', multiLine: true);
  static final RegExp _codeBlockReg = RegExp(r'```[\s\S]*?```');

  static final RegExp _combinedSyntaxReg = RegExp(
    r'\*\*.*?\*\*|\*.*?\*|^#+ .*$|\[.*?\]\(.*?\)|`.*?`|^> .*$|```[\s\S]*?```',
    multiLine: true,
  );

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    // Return standard TextSpan for very large text if search is not active to maintain extreme high FPS (60fps+)
    final textLength = text.length;
    final hasSearch = provider.searchQuery.isNotEmpty;

    if (textLength > 50000 && !hasSearch) {
      return TextSpan(text: text, style: style);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<TextSpan> children = [];
    
    // Color mapping
    final Color boldItalicColor = isDark ? const Color(0xFFF9E2AF) : const Color(0xFFDF8E1D);
    final Color headingColor = isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF);
    final Color linkColor = isDark ? const Color(0xFF89B4FA) : const Color(0xFF1E66F5);
    final Color codeInlineColor = isDark ? const Color(0xFFFAB387) : const Color(0xFFFE640B);
    final Color quoteColor = isDark ? const Color(0xFFA6ADC8) : const Color(0xFF7C7F93);
    final Color codeBlockColor = isDark ? const Color(0xFF94E2D5) : const Color(0xFF179299);

    int currentTextOffset = 0;

    text.splitMapJoin(
      _combinedSyntaxReg,
      onMatch: (m) {
        final matchText = m[0]!;
        final matchStart = m.start;
        currentTextOffset = m.end;

        Color? matchColor;
        FontWeight weight = FontWeight.normal;

        if (_boldReg.hasMatch(matchText)) {
          matchColor = boldItalicColor;
          weight = FontWeight.bold;
        } else if (_italicReg.hasMatch(matchText)) {
          matchColor = boldItalicColor;
        } else if (_headingReg.hasMatch(matchText)) {
          matchColor = headingColor;
          weight = FontWeight.bold;
        } else if (_linkReg.hasMatch(matchText)) {
          matchColor = linkColor;
        } else if (_codeInlineReg.hasMatch(matchText)) {
          matchColor = codeInlineColor;
        } else if (_quoteReg.hasMatch(matchText)) {
          matchColor = quoteColor;
        } else if (_codeBlockReg.hasMatch(matchText)) {
          matchColor = codeBlockColor;
        }

        List<TextSpan> innerSpans = [];
        if (hasSearch) {
          int currentIdx = 0;
          final searchReg = RegExp(RegExp.escape(provider.searchQuery), caseSensitive: provider.isCaseSensitive);
          matchText.splitMapJoin(
            searchReg,
            onMatch: (sm) {
              final smStart = sm.start;
              final globalStart = matchStart + smStart;
              final isCurrent = provider.searchMatches.indexOf(globalStart) == provider.currentMatchIndex;
              
              if (smStart > currentIdx) {
                innerSpans.add(TextSpan(text: matchText.substring(currentIdx, smStart)));
              }
              innerSpans.add(TextSpan(
                text: sm[0],
                style: TextStyle(
                  backgroundColor: isCurrent 
                      ? Colors.orange.withOpacity(0.5) 
                      : Colors.yellow.withOpacity(0.3),
                  color: isDark ? Colors.white : Colors.black,
                ),
              ));
              currentIdx = sm.end;
              return '';
            },
            onNonMatch: (n) { return ''; }
          );
          if (currentIdx < matchText.length) {
            innerSpans.add(TextSpan(text: matchText.substring(currentIdx)));
          }
        }

        if (innerSpans.isEmpty) {
          children.add(TextSpan(text: matchText, style: style?.copyWith(color: matchColor, fontWeight: weight)));
        } else {
          children.add(TextSpan(
            children: innerSpans, 
            style: style?.copyWith(color: matchColor, fontWeight: weight)
          ));
        }
        return '';
      },
      onNonMatch: (n) {
        final matchStart = currentTextOffset;
        currentTextOffset += n.length;

        if (n.isEmpty) return '';

        if (hasSearch) {
          final searchReg = RegExp(RegExp.escape(provider.searchQuery), caseSensitive: provider.isCaseSensitive);
          int currentIdx = 0;
          n.splitMapJoin(
            searchReg,
            onMatch: (sm) {
              final globalStart = matchStart + sm.start;
              final isCurrent = provider.searchMatches.indexOf(globalStart) == provider.currentMatchIndex;
              if (sm.start > currentIdx) {
                children.add(TextSpan(text: n.substring(currentIdx, sm.start), style: style));
              }
              children.add(TextSpan(
                text: sm[0],
                style: style?.copyWith(
                  backgroundColor: isCurrent 
                      ? Colors.orange.withOpacity(0.5) 
                      : Colors.yellow.withOpacity(0.3),
                  color: isDark ? Colors.white : Colors.black,
                ),
              ));
              currentIdx = sm.end;
              return '';
            },
            onNonMatch: (nNonMatch) { return ''; }
          );
          if (currentIdx < n.length) {
            children.add(TextSpan(text: n.substring(currentIdx), style: style));
          }
        } else {
          children.add(TextSpan(text: n, style: style));
        }
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
