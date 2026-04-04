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
        color: isDark ? const Color(0xFF181825) : const Color(0xFFE6E9EF),
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
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'markd.logo.jpg',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.auto_awesome_mosaic_rounded, color: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5), size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Marka',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                if (provider.workspacePath != null)
                  IconButton(
                    icon: const Icon(Icons.add_rounded, size: 20),
                    onPressed: () => _showCreateFileDialog(context, provider),
                    tooltip: 'New File',
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Workspace Section
          if (provider.workspacePath == null)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    'No workspace loaded',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => provider.loadWorkspace(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF313244) : const Color(0xFFDCE0E8),
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      elevation: 0,
                    ),
                    child: const Text('Open Folder'),
                  ),
                ],
              ),
            )
          else ...[
            _buildSectionHeader(context, 'WORKSPACE', isDark),
            Expanded(
              child: ListView.builder(
                itemCount: provider.workspaceFiles.length,
                itemBuilder: (context, index) {
                  final file = provider.workspaceFiles[index];
                  final fileName = file.path.split(Platform.pathSeparator).last;
                  final isSelected = provider.currentFilePath == file.path;
                  
                  return _buildFileItem(context, provider, file, fileName, isSelected, isDark);
                },
              ),
            ),
          ],
          
          const Divider(height: 1, indent: 24, endIndent: 24),
          const SizedBox(height: 8),
          
          // Bottom Actions
          _buildSidebarAction(
            context,
            'Settings',
            Icons.settings_outlined,
            isDark,
            onTap: () => _showSettingsDialog(context, provider),
          ),
          const SizedBox(height: 16),
        ],
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

  Widget _buildFileItem(BuildContext context, MarkdownProvider provider, File file, String title, bool isSelected, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 1.0),
      child: InkWell(
        onTap: () => provider.openFileDirectly(file),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected 
                ? (isDark ? const Color(0xFF313244) : const Color(0xFFDCE0E8)) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Image.asset(
                'markd.png',
                width: 16,
                height: 16,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.description_outlined, size: 16, color: isSelected ? Colors.blue : null),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected 
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      onPressed: () => _showRenameDialog(context, provider, file),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                      onPressed: () => provider.deleteFile(file),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
            ],
          ),
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
