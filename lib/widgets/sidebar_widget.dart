import 'dart:io' as io show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/markdown_provider.dart';
import '../models/workspace_item.dart';
import '../utils/path_utils.dart';
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
          // Header / Global Controls
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
            child: Row(
              children: [
                Icon(Icons.workspaces_outline, size: 18, color: isDark ? Colors.white38 : Colors.black45),
                const SizedBox(width: 10),
                Text(
                  provider.t('workspaces'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.add_rounded, size: 20, color: isDark ? Colors.white38 : Colors.black45),
                  onPressed: () => provider.loadWorkspace(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: kIsWeb ? provider.t('open_files') : provider.t('open_folder'),
                ),
                IconButton(
                  icon: Icon(Icons.refresh_rounded, size: 18, color: isDark ? Colors.white38 : Colors.black45),
                  onPressed: () => provider.refreshWorkspace(),
                  padding: const EdgeInsets.only(left: 8),
                  constraints: const BoxConstraints(),
                  tooltip: provider.t('refresh_all'),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, indent: 16, endIndent: 16),

          // Workspace List
          Expanded(
            child: provider.workspacePaths.isEmpty
                ? _buildEmptyWorkspace(context, isDark, provider)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: provider.workspacePaths.length,
                    itemBuilder: (context, index) {
                      final path = provider.workspacePaths[index];
                      final folderName = path.split(getPathSeparator()).last;
                      final files = provider.workspaceFilesMap[path] ?? [];
                      
                      return Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          visualDensity: VisualDensity.compact,
                          leading: Icon(Icons.folder_rounded, size: 18, color: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF)),
                          title: GestureDetector(
                            onSecondaryTapDown: (details) => _showFolderContextMenu(context, provider, path, details.globalPosition),
                            child: Text(
                              folderName,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: _buildFolderTrailing(context, provider, path, isDark),
                          children: files.isEmpty 
                            ? [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(provider.t('no_md_files'), style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                                )
                              ]
                            : files.map((fileItem) {
                                final isSelected = provider.currentFilePath == fileItem.path;
                                return _buildFileItem(context, provider, fileItem, isSelected, isDark);
                              }).toList(),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildEmptyWorkspace(BuildContext context, bool isDark, MarkdownProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            kIsWeb ? Icons.cloud_off_outlined : Icons.folder_off_outlined, 
            size: 48, 
            color: isDark ? Colors.white10 : Colors.black12
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              kIsWeb 
                ? 'Individual folders cannot be scanned in browsers. Select multiple files to create a virtual workspace!' 
                : provider.t('no_folders_open'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildActionButton(
            context, 
            provider.t('open_folder'), 
            Icons.create_new_folder_outlined, 
            () => provider.loadWorkspace(context), 
            isDark
          ),
        ],
      ),
    );
  }

  Widget _buildFolderTrailing(BuildContext context, MarkdownProvider provider, String path, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.add_box_outlined, size: 16, color: isDark ? Colors.white24 : Colors.black26),
          onPressed: () => _showCreateFileDialog(context, provider, path),
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
          tooltip: provider.t('new_file'),
        ),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? Colors.white24 : Colors.black26),
      ],
    );
  }

  void _showFolderContextMenu(BuildContext context, MarkdownProvider provider, String path, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
          onTap: () => provider.removeWorkspaceFolder(path),
          child: Row(
            children: [Icon(Icons.folder_delete_outlined, size: 18, color: Colors.red), SizedBox(width: 12), Text(provider.t('remove_folder'), style: const TextStyle(color: Colors.red))],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isDark ? Colors.white70 : Colors.black87),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, MarkdownProvider provider, WorkspaceItem item, bool isSelected, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 1.0),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? const Color(0xFF313244) : const Color(0xFFDCE0E8)) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: InkWell(
          onTap: () => provider.openFileDirectly(item.path),
          onSecondaryTapDown: (details) => _showFileContextMenu(context, provider, item, details.globalPosition),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 6.0, 12.0, 6.0),
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined, 
                  size: 14, 
                  color: isSelected ? const Color(0xFFCBA6F7) : (isDark ? Colors.white30 : Colors.black38),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.name,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isSelected 
                          ? (isDark ? Colors.white : Colors.black87)
                          : (isDark ? Colors.white60 : Colors.black54),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.circle, size: 4, color: Color(0xFFCBA6F7)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFileContextMenu(BuildContext context, MarkdownProvider provider, WorkspaceItem item, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
          onTap: () => Future.delayed(Duration.zero, () => _showRenameDialog(context, provider, item)),
          child: Row(
            children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 12), Text(provider.t('rename'))],
          ),
        ),
        PopupMenuItem(
          onTap: () => provider.deleteFile(item.path),
          child: Row(
            children: [Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red), SizedBox(width: 12), Text(provider.t('delete'), style: const TextStyle(color: Colors.red))],
          ),
        ),
      ],
    );
  }

  void _showCreateFileDialog(BuildContext context, MarkdownProvider provider, String folderPath) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('${provider.t('new_file_dialog_title')} ${folderPath.split(getPathSeparator()).last}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'filename (without .md)', border: const OutlineInputBorder()),
          autofocus: true,
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(provider.t('cancel'))),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.createFile(controller.text, folderPath);
                Navigator.pop(context);
              }
            },
            child: Text(provider.t('create')),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, MarkdownProvider provider, WorkspaceItem item) {
    final controller = TextEditingController(
      text: item.name.replaceAll('.md', ''),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(provider.t('rename_dialog_title'), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(controller: controller, autofocus: true, style: GoogleFonts.inter(fontSize: 13), decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(provider.t('cancel'))),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.renameFile(item.path, controller.text);
                Navigator.pop(context);
              }
            },
            child: Text(provider.t('rename')),
          ),
        ],
      ),
    );
  }
}
