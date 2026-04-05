import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:provider/provider.dart';
import '../providers/markdown_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class ToolbarWidget extends StatelessWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<MarkdownProvider>(context);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF313244) : const Color(0xFFDCE0E8),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // File Operations
          _toolbarButton(context, Icons.note_add_outlined, 'New', () => provider.newFile()),
          _toolbarButton(context, Icons.file_open_outlined, 'Open', () => provider.openFile()),
          _toolbarButton(context, Icons.save_outlined, 'Save', () => provider.saveFile()),
          _toolbarButton(context, Icons.sync_rounded, 'Refresh Preview', () => provider.refreshPreview()),
          _divider(isDark),
          // Markdown Helpers
          _toolbarButton(context, Icons.format_bold_rounded, 'Bold', () => provider.insertSnippet('**', '**', provider.selectionStart, provider.selectionEnd)),
          _toolbarButton(context, Icons.format_italic_rounded, 'Italic', () => provider.insertSnippet('*', '*', provider.selectionStart, provider.selectionEnd)),
          _toolbarButton(context, Icons.link_rounded, 'Link', () => provider.insertSnippet('[', '](url)', provider.selectionStart, provider.selectionEnd)),
          _toolbarButton(context, Icons.image_outlined, 'Image', () => provider.insertSnippet('![alt](', ')', provider.selectionStart, provider.selectionEnd)),
          _toolbarButton(context, Icons.code_rounded, 'Code', () => provider.insertSnippet('```\n', '\n```', provider.selectionStart, provider.selectionEnd)),
          _toolbarButton(context, Icons.border_all_rounded, 'Table', () => provider.insertSnippet('| Col 1 | Col 2 |\n|---|---|\n| Cell | Cell |', '', provider.selectionStart, provider.selectionEnd)),
          _divider(isDark),
          // View Controls
          _toolbarButton(
            context, 
            provider.isSplitScreen ? Icons.view_agenda_outlined : Icons.view_sidebar_outlined, 
            'Toggle Split', 
            () => provider.toggleSplitScreen(),
          ),
          _toolbarButton(
            context, 
            provider.isWrapped ? Icons.wrap_text_rounded : Icons.format_align_left_rounded, 
            'Toggle Wrap', 
            () => provider.toggleWrap(),
          ),
          const Spacer(),
          // Theme Toggle
          Tooltip(
            message: 'Toggle Theme',
            child: IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 20,
              ),
              color: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5),
              onPressed: () => AdaptiveTheme.of(context).toggleThemeMode(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbarButton(BuildContext context, IconData icon, String tooltip, VoidCallback onPressed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        color: isDark ? const Color(0xFFCDD6F4) : const Color(0xFF4C4F69),
        splashRadius: 20,
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      height: 20,
      width: 1,
      color: isDark ? const Color(0xFF313244) : const Color(0xFFDCE0E8),
    );
  }
}
