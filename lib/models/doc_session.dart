import 'package:flutter/material.dart';

class DocSession {
  String? path; // null if unsaved draft
  String content;
  String originalContent;
  String name;
  double scrollPercentage;
  int selectionStart;
  int selectionEnd;
  bool isModified;

  DocSession({
    this.path,
    required this.content,
    required this.name,
    this.originalContent = '',
    this.scrollPercentage = 0.0,
    this.selectionStart = 0,
    this.selectionEnd = 0,
    this.isModified = false,
  });

  void updateContent(String newContent) {
    content = newContent;
    isModified = content != originalContent;
  }

  void markSaved() {
    originalContent = content;
    isModified = false;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocSession &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          name == other.name;

  @override
  int get hashCode => path.hashCode ^ name.hashCode;
}
