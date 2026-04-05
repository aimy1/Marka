import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/markdown_provider.dart';
import '../widgets/markdown_editor_widget.dart';
import '../widgets/markdown_preview_widget.dart';

import '../widgets/sidebar_widget.dart';
import '../widgets/toolbar_widget.dart';
import '../widgets/status_bar_widget.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  bool _showSidebar = true;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarkdownProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => provider.saveFile(),
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () => provider.saveFile(),
      },
      child: Scaffold(
        body: Column(
          children: [
          // Custom Title Bar (Pill)
          _buildCustomTitleBar(isDark),
          
          Expanded(
            child: Row(
              children: [
                // Fluid Animated Sidebar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: _showSidebar ? 260 : 0,
                  child: ClipRect(
                    child: OverflowBox(
                      minWidth: 260,
                      maxWidth: 260,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _showSidebar ? 1.0 : 0.0,
                        child: const SidebarWidget(),
                      ),
                    ),
                  ),
                ),
                
                // Main Content Area
                Expanded(
                  child: Column(
                    children: [
                      // Tab Bar Integrated with Toolbar
                      _buildTabBarWrapper(provider, isDark),
                      
                      // Editor & Preview Area
                      Expanded(
                        child: (provider.sessions.length == 1 && provider.sessions.first.name == 'Welcome.md' && provider.workspacePaths.isEmpty)
                          ? _buildWelcomeScreen(context, provider, isDark)
                          : Row(
                              children: [
                                // Editor Section with Floating Word Count
                                Expanded(
                                  child: Stack(
                                    children: [
                                      const MarkdownEditorWidget(),
                                      // Floating Word Count Badge
                                      Positioned(
                                        bottom: 20,
                                        right: 20,
                                        child: _buildEditorBadge(provider),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Split Divider
                                if (provider.isSplitScreen)
                                  Container(
                                    width: 1,
                                    color: Theme.of(context).dividerColor,
                                  ),
                                  
                                // Preview Section
                                if (provider.isSplitScreen)
                                  const Expanded(
                                    child: MarkdownPreviewWidget(),
                                  ),
                              ],
                            ),
                      ),
                      
                      // Bottom Status Bar
                      const StatusBarWidget(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTitleBar(bool isDark) {
    return GestureDetector(
      onPanStart: (details) {
        if (!kIsWeb) windowManager.startDragging();
      },
      child: Container(
        height: 48,
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
        child: Stack(
          children: [
            // Left Positioning for Branding (Pill)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black12,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(
                          'markd.logo.jpg',
                          width: 16,
                          height: 16,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Marka',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Window Controls (Right Positioned)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Row(
                children: [
                  _buildWindowControlButton(
                    icon: Icons.minimize_rounded,
                    onTap: () async {
                      if (!kIsWeb) await windowManager.minimize();
                    },
                    isDark: isDark,
                  ),
                  _buildWindowControlButton(
                    icon: Icons.crop_square_rounded,
                    onTap: () async {
                      if (!kIsWeb) {
                        if (await windowManager.isMaximized()) {
                          await windowManager.unmaximize();
                        } else {
                          await windowManager.maximize();
                        }
                      }
                    },
                    isDark: isDark,
                  ),
                  _buildWindowControlButton(
                    icon: Icons.close_rounded,
                    onTap: () async {
                      if (!kIsWeb) await windowManager.close();
                    },
                    isDark: isDark,
                    isClose: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    bool isClose = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 32,
        width: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isClose 
              ? Colors.red.withOpacity(0.7) 
              : (isDark ? Colors.white54 : Colors.black45),
        ),
      ),
    );
  }

  Widget _buildTabBarWrapper(MarkdownProvider provider, bool isDark) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Sidebar Toggle
          IconButton(
            icon: Icon(_showSidebar ? Icons.format_list_bulleted_outlined : Icons.menu_open_rounded, size: 20),
            onPressed: () => setState(() => _showSidebar = !_showSidebar),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          
          // Tabs
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: provider.sessions.length,
              itemBuilder: (context, index) {
                final session = provider.sessions[index];
                final isSelected = provider.activeTabIndex == index;
                
                return _buildTabItem(session.name, isSelected, isDark, () => provider.switchTab(index), () => provider.closeTab(index));
              },
            ),
          ),

          // Action Buttons
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.save_outlined, 
                  size: 20, 
                  color: provider.isModified ? const Color(0xFFCBA6F7) : null
                ), 
                onPressed: () => provider.saveFile(),
                tooltip: 'Save (Ctrl+S)',
              ),
              IconButton(icon: const Icon(Icons.add_rounded, size: 20), onPressed: () => provider.newFile()),
              IconButton(icon: const Icon(Icons.splitscreen_rounded, size: 20), onPressed: () => provider.toggleSplitScreen()),
              IconButton(icon: const Icon(Icons.settings_suggest_rounded, size: 20), onPressed: () => _showSettingsDialog(context, provider)),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    ),
  );
}

  void _showSettingsDialog(BuildContext context, MarkdownProvider provider) {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  Widget _buildTabItem(String name, bool isSelected, bool isDark, VoidCallback onTap, VoidCallback onClose) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? const Color(0xFF1E1E2E) : Colors.white)
              : Colors.transparent,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.description_outlined, size: 14, color: isSelected ? const Color(0xFFCBA6F7) : Colors.grey),
            const SizedBox(width: 8),
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isSelected ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClose,
              child: Icon(Icons.close_rounded, size: 14, color: isSelected ? Colors.grey : Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(BuildContext context, MarkdownProvider provider, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.folder_copy_rounded, size: 64, color: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF)),
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to Marka',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Open a folder to start managing your Markdown project.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () => provider.loadWorkspace(context),
            icon: const Icon(Icons.create_new_folder_outlined),
            label: const Text('Open Folder'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              backgroundColor: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF),
              foregroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => provider.openFile(),
            icon: const Icon(Icons.file_open_outlined, size: 18),
            label: const Text('Open Files'),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorBadge(MarkdownProvider provider) {
    final wordCount = provider.content.isEmpty ? 0 : provider.content.trim().split(RegExp(r'\s+')).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: provider.content.isNotEmpty ? 0.8 : 0.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF313244) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          '$wordCount Words',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5),
          ),
        ),
      ),
    );
  }
}
