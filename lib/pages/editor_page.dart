import 'dart:io';
import 'package:flutter/material.dart';
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
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => provider.saveFile(),
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): () => provider.openFile(),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () => provider.newFile(),
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): () => provider.insertSnippet('**', '**', provider.selectionStart, provider.selectionEnd),
        const SingleActivator(LogicalKeyboardKey.keyI, control: true): () => provider.insertSnippet('*', '*', provider.selectionStart, provider.selectionEnd),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () => provider.insertSnippet('[', '](url)', provider.selectionStart, provider.selectionEnd),
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
                          child: Row(
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
      ),
    );
  }

  Widget _buildCustomTitleBar(bool isDark) {
    return GestureDetector(
      onPanStart: (details) => windowManager.startDragging(),
      child: Container(
        height: 48,
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
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
              itemCount: provider.openFiles.length,
              itemBuilder: (context, index) {
                final file = provider.openFiles[index];
                final isSelected = provider.activeTabIndex == index;
                final fileName = file.path.split(Platform.pathSeparator).last;
                
                return _buildTabItem(fileName, isSelected, isDark, () => provider.switchTab(index), () => provider.closeTab(index));
              },
            ),
          ),

          // Action Buttons
          Row(
            children: [
              IconButton(icon: const Icon(Icons.add_rounded, size: 20), onPressed: () => provider.newFile()),
              IconButton(icon: const Icon(Icons.splitscreen_rounded, size: 20), onPressed: () => provider.toggleSplitScreen()),
              IconButton(icon: const Icon(Icons.fullscreen_rounded, size: 20), onPressed: () => windowManager.maximize()),
              IconButton(icon: const Icon(Icons.more_horiz_rounded, size: 20), onPressed: () {}),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
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
