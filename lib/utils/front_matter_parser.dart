import 'package:flutter/material.dart';

/// Professional Front Matter Parser for Marka IDE v2.6.0
class FrontMatterResult {
  final Map<String, dynamic> data;
  final String content;
  final bool hasFrontMatter;

  FrontMatterResult({required this.data, required this.content, this.hasFrontMatter = false});
}

class FrontMatterParser {
  static FrontMatterResult parse(String rawText) {
    // Regex to match YAML block between --- delimiters at the start of string
    final regex = RegExp(r'^---\r?\n([\s\S]*?)\r?\n---\r?\n?', multiLine: false);
    final match = regex.firstMatch(rawText);

    if (match == null) {
      return FrontMatterResult(data: {}, content: rawText, hasFrontMatter: false);
    }

    final yamlString = match.group(1) ?? '';
    final contentBody = rawText.substring(match.end);
    final data = <String, dynamic>{};

    // Simple line-by-line YAML parser for common fields
    final lines = yamlString.split('\n');
    for (var line in lines) {
      if (!line.contains(':')) continue;
      final parts = line.split(':');
      final key = parts[0].trim().toLowerCase();
      final valuePart = parts.sublist(1).join(':').trim();

      if (key == 'title' || key == 'date') {
        data[key] = _cleanValue(valuePart);
      } else if (key == 'categories' || key == 'tags') {
        data[key] = _parseYamlList(valuePart);
      }
    }

    return FrontMatterResult(data: data, content: contentBody, hasFrontMatter: true);
  }

  static String _cleanValue(String v) {
    String res = v.trim();
    if (res.startsWith('"') || res.startsWith("'")) res = res.substring(1);
    if (res.endsWith('"') || res.endsWith("'")) res = res.substring(0, res.length - 1);
    return res;
  }

  static List<String> _parseYamlList(String v) {
    if (v.startsWith('[') && v.endsWith(']')) {
      return v.substring(1, v.length - 1)
          .split(',')
          .map((e) => _cleanValue(e))
          .where((e) => e.isNotEmpty)
          .toList();
    }
    // Simple fallback for single value
    if (v.isNotEmpty) return [_cleanValue(v)];
    return [];
  }
}
