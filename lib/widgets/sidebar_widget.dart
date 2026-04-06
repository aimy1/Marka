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
                _buildHeaderIcon(
                  Icons.add_rounded, 
                  () => provider.loadWorkspace(context), 
                  kIsWeb ? provider.t('open_files') : provider.t('open_folder'),
                  isDark
                ),
                _buildHeaderIcon(
                  Icons.refresh_rounded, 
                  () => provider.refreshWorkspace(), 
                  provider.t('refresh_all'),
                  isDark
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
                      
                      return _FolderExpansionTile(
                        path: path,
                        folderName: folderName,
                        files: files,
                        provider: provider,
                        isDark: isDark,
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap, String tooltip, bool isDark) {
    return IconButton(
      icon: Icon(icon, size: 18, color: isDark ? Colors.white38 : Colors.black45),
      onPressed: onTap,
      padding: const EdgeInsets.only(left: 8),
      constraints: const BoxConstraints(),
      tooltip: tooltip,
      hoverColor: isDark ? Colors.white12 : Colors.black12,
      splashRadius: 16,
    );
  }

  Widget _buildEmptyWorkspace(BuildContext context, bool isDark, MarkdownProvider provider) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
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
                  ? 'Individual folders cannot be scanned in browsers. Select multiple files!' 
                  : provider.t('no_folders_open'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildActionButton(
              context, 
              provider.t('open_folder'), 
              Icons.create_new_folder_outlined, 
              () => provider.loadWorkspace(context), 
              isDark
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isDark ? Colors.white70 : Colors.black87),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderExpansionTile extends StatefulWidget {
  final String path;
  final String folderName;
  final List<WorkspaceItem> files;
  final MarkdownProvider provider;
  final bool isDark;

  const _FolderExpansionTile({
    required this.path,
    required this.folderName,
    required this.files,
    required this.provider,
    required this.isDark,
  });

  @override
  State<_FolderExpansionTile> createState() => _FolderExpansionTileState();
}

class _FolderExpansionTileState extends State<_FolderExpansionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovered ? (widget.isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)) : Colors.transparent,
          ),
          child: ExpansionTile(
            initiallyExpanded: true,
            visualDensity: VisualDensity.compact,
            leading: AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: _isHovered ? 0.02 : 0,
              child: Icon(Icons.folder_rounded, size: 18, color: widget.isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF)),
            ),
            title: GestureDetector(
              onSecondaryTapDown: (details) => _showFolderContextMenu(context, widget.provider, widget.path, details.globalPosition),
              child: Text(
                widget.folderName,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white70 : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: _buildFolderTrailing(context, widget.provider, widget.path, widget.isDark, _isHovered),
            children: widget.files.isEmpty 
              ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(widget.provider.t('no_md_files'), style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                  )
                ]
              : widget.files.map((fileItem) {
                  final isSelected = widget.provider.currentFilePath == fileItem.path;
                  return _FileListItem(
                    item: fileItem,
                    isSelected: isSelected,
                    isDark: widget.isDark,
                    onTap: () => widget.provider.openFileDirectly(fileItem.path),
                    onSecondaryTap: (pos) => _showFileContextMenu(context, widget.provider, fileItem, pos),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFolderTrailing(BuildContext context, MarkdownProvider provider, String path, bool isDark, bool isVisible) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isVisible ? 1.0 : 0.2,
      child: Row(
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
          Icon(Icons.expand_more_rounded, size: 18, color: isDark ? Colors.white24 : Colors.black26),
        ],
      ),
    );
  }
}

class _FileListItem extends StatefulWidget {
  final WorkspaceItem item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final Function(Offset) onSecondaryTap;

  const _FileListItem({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.onSecondaryTap,
  });

  @override
  State<_FileListItem> createState() => _FileListItemState();
}

class _FileListItemState extends State<_FileListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? (widget.isDark ? const Color(0xFF313244) : accentColor.withOpacity(0.1)) 
                : (_isHovered ? (widget.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: widget.isSelected 
                ? Border.all(color: accentColor.withOpacity(0.3), width: 0.5)
                : Border.all(color: Colors.transparent, width: 0.5),
          ),
          child: InkWell(
            onTap: widget.onTap,
            onSecondaryTapDown: (details) => widget.onSecondaryTap(details.globalPosition),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 10.0),
              child: Row(
                children: [
                  if (widget.isSelected)
                    _ActivePulseIcon(isDark: widget.isDark, accentColor: accentColor)
                  else
                    AnimatedScale(
                      duration: const Duration(milliseconds: 300),
                      scale: _isHovered ? 1.15 : 1.0,
                      child: Icon(
                        Icons.description_outlined, 
                        size: 14, 
                        color: (widget.isDark ? Colors.white30 : Colors.black38),
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.item.name,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: widget.isSelected 
                            ? (widget.isDark ? Colors.white : accentColor)
                            : (widget.isDark ? Colors.white60 : Colors.black54),
                        fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isSelected)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivePulseIcon extends StatefulWidget {
  final bool isDark;
  final Color accentColor;
  const _ActivePulseIcon({required this.isDark, required this.accentColor});

  @override
  State<_ActivePulseIcon> createState() => _ActivePulseIconState();
}

class _ActivePulseIconState extends State<_ActivePulseIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Icon(Icons.description_rounded, size: 16, color: widget.accentColor),
    );
  }
}

// Dialog functions move outside or keep as private methods in SidebarWidget
void _showFolderContextMenu(BuildContext context, MarkdownProvider provider, String path, Offset position) {
  showMenu(
    context: context,
    position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
    items: [
      PopupMenuItem(
        onTap: () => provider.openInExplorer(path),
        child: Row(
          children: [Icon(Icons.folder_open_rounded, size: 18), SizedBox(width: 12), Text(provider.t('open_location'))],
        ),
      ),
      PopupMenuItem(
        onTap: () => provider.removeWorkspaceFolder(path),
        child: Row(
          children: [Icon(Icons.folder_delete_outlined, size: 18, color: Colors.cyan), SizedBox(width: 12), Text(provider.t('remove_folder'))],
        ),
      ),

    ],
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
        onTap: () => provider.openInExplorer(item.path),
        child: Row(
          children: [Icon(Icons.folder_open_rounded, size: 18), SizedBox(width: 12), Text(provider.t('open_location'))],
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
