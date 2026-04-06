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
import '../widgets/settings_dialog.dart';

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
            _buildCustomTitleBar(isDark),
            Expanded(
              child: Row(
                children: [
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
                  Expanded(
                    child: Column(
                      children: [
                        _buildTabBarWrapper(provider, isDark),
                        Expanded(
                          child: (provider.sessions.length == 1 && provider.sessions.first.name == 'Welcome.md' && provider.workspacePaths.isEmpty)
                            ? _buildWelcomeScreen(context, provider, isDark)
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                                child: Row(
                                  key: ValueKey(provider.isSplitScreen),
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          const MarkdownEditorWidget(),
                                          Positioned(
                                            bottom: 20,
                                            right: 20,
                                            child: _buildEditorBadge(provider),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (provider.isSplitScreen)
                                      Container(
                                        width: 1,
                                        color: Theme.of(context).dividerColor,
                                      ),
                                    if (provider.isSplitScreen)
                                      const Expanded(
                                        child: MarkdownPreviewWidget(),
                                      ),
                                  ],
                                ),
                              ),
                        ),
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
      onPanStart: (details) {
        if (!kIsWeb) windowManager.startDragging();
      },
      child: Container(
        height: 60, // Increased title bar height for larger logo
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
        child: Stack(
          children: [
            // Left Positioning for Branding (Floating Style)
            Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CustomLogo(isDark: isDark),
                  const SizedBox(width: 12),
                  Text(
                    'Marka',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _VersionBadge(isDark: isDark),
                ],
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
      hoverColor: isClose ? Colors.red : (isDark ? Colors.white10 : Colors.black12),
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
          color: isDark ? Colors.white54 : Colors.black45,
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
                tooltip: provider.t('save_tooltip'),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 20), 
                onPressed: () => provider.newFile(),
                tooltip: provider.t('new_file_tooltip'),
              ),
              IconButton(
                icon: const Icon(Icons.splitscreen_rounded, size: 20), 
                onPressed: () => provider.toggleSplitScreen(),
                tooltip: provider.t('split_tooltip'),
              ),
              IconButton(
                icon: const Icon(Icons.settings_suggest_rounded, size: 20), 
                onPressed: () => _showSettingsDialog(context, provider),
                tooltip: provider.t('settings_tooltip'),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, MarkdownProvider provider) {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(),
    );
  }

  Widget _buildTabItem(String name, bool isSelected, bool isDark, VoidCallback onTap, VoidCallback onClose) {
    return _AnimatedTab(
      name: name,
      isSelected: isSelected,
      isDark: isDark,
      onTap: onTap,
      onClose: onClose,
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
            provider.t('welcome_title'),
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            provider.t('welcome_desc'),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
          const SizedBox(height: 48),
          _buildBigButton(
            context,
            provider.t('open_folder'),
            Icons.create_new_folder_outlined,
            () => provider.loadWorkspace(context),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildBigButton(BuildContext context, String label, IconData icon, VoidCallback onTap, bool isDark) {
    return Material(
      color: isDark ? const Color(0xFFCBA6F7).withOpacity(0.1) : const Color(0xFF1E66F5).withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5)),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditorBadge(MarkdownProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wordCount = provider.content.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E).withOpacity(0.8) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Text(
        '$wordCount ${provider.t('words')}',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
      ),
    );
  }
}

class _AnimatedTab extends StatefulWidget {
  final String name;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _AnimatedTab({
    required this.name,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_AnimatedTab> createState() => _AnimatedTabState();
}

class _AnimatedTabState extends State<_AnimatedTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(top: 6, left: 4, right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? (widget.isDark ? const Color(0xFF1E1E2E) : Colors.white)
                : (_isHovered ? (widget.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)) : Colors.transparent),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            boxShadow: widget.isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2))] : [],
          ),
          child: Row(
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 300),
                scale: widget.isSelected ? 1.0 : (_isHovered ? 1.1 : 1.0),
                child: Icon(
                  Icons.description_outlined, 
                  size: 14, 
                  color: widget.isSelected ? accentColor : Colors.grey
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.name,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: widget.isSelected 
                      ? (widget.isDark ? Colors.white : Colors.black87) 
                      : Colors.grey,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onClose,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: widget.isSelected || _isHovered ? 1.0 : 0.0,
                  child: Icon(
                    Icons.close_rounded, 
                    size: 14, 
                    color: widget.isSelected ? Colors.grey : Colors.grey.withOpacity(0.5)
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _CustomLogo extends StatefulWidget {
  final bool isDark;
  const _CustomLogo({required this.isDark});

  @override
  State<_CustomLogo> createState() => _CustomLogoState();
}

class _CustomLogoState extends State<_CustomLogo> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 300),
        scale: _isHovered ? 1.15 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: _isHovered ? [BoxShadow(color: (widget.isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5)).withOpacity(0.3), blurRadius: 12)] : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset('markd.logo.jpg', width: 34, height: 34, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class _VersionBadge extends StatelessWidget {
  final bool isDark;
  const _VersionBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [accentColor.withOpacity(0.15), accentColor.withOpacity(0.05)]
              : [accentColor.withOpacity(0.1), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Text(
        'v3.3.4',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: accentColor.withOpacity(0.8),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
