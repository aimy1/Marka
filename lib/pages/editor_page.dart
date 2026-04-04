import 'package:flutter/material.dart';
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

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => provider.saveFile(),
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): () => provider.openFile(),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () => provider.newFile(),
      },
      child: Scaffold(
        body: Stack(
          children: [
            Row(
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
                      // Top Toolbar
                      const ToolbarWidget(),
                      
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
            // Floating toggle for sidebar if hidden (Alternative position or method)
            if (!_showSidebar)
              Positioned(
                left: 16,
                bottom: 44, // Just above status bar
                child: FloatingActionButton.small(
                  onPressed: () => setState(() => _showSidebar = true),
                  tooltip: 'Show Sidebar',
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
                  child: const Icon(Icons.menu_open_rounded, color: Colors.white),
                ),
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
