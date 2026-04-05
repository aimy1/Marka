import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/markdown_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_dialog.dart';

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<MarkdownProvider>(context);

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11111B) : const Color(0xFFE6E9EF),
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF313244) : const Color(0xFFDCE0E8),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.folder_copy_rounded, size: 18, color: isDark ? Colors.white38 : Colors.black45),
                const SizedBox(width: 12),
                Icon(Icons.description_outlined, size: 18, color: isDark ? Colors.white38 : Colors.black45),
                const Spacer(),
                Icon(Icons.chevron_left_rounded, size: 20, color: isDark ? Colors.white38 : Colors.black45),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildCategory(context, 'Documents', Icons.arrow_drop_down_rounded, [
                  _buildFileItem(context, provider, 'Welcome.md', const Color(0xFFCBA6F7), 'ma', true, isDark),
                  _buildFileItem(context, provider, 'Events.md', const Color(0xFF89B4FA), 'en', false, isDark),
                ], isDark),
                _buildCategory(context, 'Projects', Icons.arrow_drop_down_rounded, [
                  _buildFileItem(context, provider, 'Project_Notes.md', const Color(0xFFEED49F), 'ms', false, isDark),
                  _buildFileItem(context, provider, 'Projects.md', const Color(0xFF94E2D5), 'pr', false, isDark),
                  _buildFileItem(context, provider, 'Project_Notes.md', const Color(0xFFCBA6F7), 'ms', false, isDark),
                ], isDark),
                _buildCategory(context, 'Notes', Icons.arrow_drop_down_rounded, [
                  _buildFileItem(context, provider, 'Project_Notes.md', const Color(0xFFF5C2E7), 'ms', false, isDark),
                  _buildFileItem(context, provider, 'Welcome.md', const Color(0xFF94E2D5), 'ma', false, isDark),
                ], isDark),
              ],
            ),
          ),

          // Bottom Settings
          _buildSidebarAction(
            context,
            'Settings',
            Icons.settings_outlined,
            isDark,
            onTap: () => _showSettingsDialog(context, provider),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCategory(BuildContext context, String title, IconData icon, List<Widget> children, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isDark ? Colors.white38 : Colors.black45),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
        Column(children: children),
      ],
    );
  }

  Widget _buildFileItem(BuildContext context, MarkdownProvider provider, String title, Color color, String prefix, bool isSelected, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 1.0),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? const Color(0xFF313244) : const Color(0xFFDCE0E8)) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    prefix,
                    style: GoogleFonts.firaCode(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isSelected 
                          ? (isDark ? Colors.white : Colors.black87)
                          : (isDark ? Colors.white70 : Colors.black54),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateFileDialog(BuildContext context, MarkdownProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Markdown File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'filename'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.createFile(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, MarkdownProvider provider) {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
      ),
    );
  }


  void _showRenameDialog(BuildContext context, MarkdownProvider provider, File file) {
    final controller = TextEditingController(text: file.path.split(Platform.pathSeparator).last.replaceAll('.md', ''));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.renameFile(file, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarAction(BuildContext context, String title, IconData icon, bool isDark, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isDark ? Colors.white38 : Colors.black45),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
