import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import '../providers/markdown_provider.dart';
import '../widgets/markdown_editor_widget.dart';
import '../widgets/markdown_preview_widget.dart';
import '../utils/front_matter_parser.dart';

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
  double _sidebarWidth = 260.0;
  bool _isDraggingSidebar = false;

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
                    duration: Duration(milliseconds: _isDraggingSidebar ? 0 : 300),
                    curve: Curves.easeInOut,
                    width: _showSidebar ? _sidebarWidth : 0,
                    child: ClipRect(
                      child: OverflowBox(
                        minWidth: _sidebarWidth,
                        maxWidth: _sidebarWidth,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _showSidebar ? 1.0 : 0.0,
                          child: const SidebarWidget(),
                        ),
                      ),
                    ),
                  ),
                  if (_showSidebar)
                    _DraggableDivider(
                      isDark: isDark,
                      onDragStart: () => setState(() => _isDraggingSidebar = true),
                      onDragEnd: () => setState(() => _isDraggingSidebar = false),
                      onDragUpdate: (delta) {
                        setState(() {
                          _sidebarWidth = (_sidebarWidth + delta).clamp(180.0, 450.0);
                        });
                      },
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        _buildTabBarWrapper(provider, isDark),
                        Expanded(
                          child: (provider.sessions.length == 1 && provider.sessions.first.name == 'Welcome.md' && provider.workspacePaths.isEmpty)
                            ? _buildWelcomeScreen(context, provider, isDark)
                            : ResizableSplitView(
                                isDark: isDark,
                                isSplitScreen: provider.isSplitScreen,
                                provider: provider,
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
        height: 42, // Compact title bar height
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
              width: 1.0,
            ),
          ),
        ),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
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
                    icon: Icons.remove_rounded, // Centered horizontal line for minimize
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
    return _WindowControlButton(
      icon: icon,
      onTap: onTap,
      isDark: isDark,
      isClose: isClose,
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
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.ios_share_rounded, 
                  size: 20,
                ),
                tooltip: provider.t('export'),
                onSelected: (value) async {
                  if (value == 'export_html') {
                    await provider.exportToHtml(context);
                  } else if (value == 'copy_html') {
                    final parsed = FrontMatterParser.parse(provider.content);
                    final bodyHtml = md.markdownToHtml(parsed.content, extensionSet: md.ExtensionSet.gitHubFlavored);
                    await Clipboard.setData(ClipboardData(text: bodyHtml));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.t('copied'))));
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'export_html',
                    child: Row(
                      children: [
                        Icon(Icons.html_rounded, size: 16, color: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5)),
                        const SizedBox(width: 8),
                        Text(provider.t('export_html'), style: GoogleFonts.inter(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'copy_html',
                    child: Row(
                      children: [
                        Icon(Icons.copy_all_rounded, size: 16, color: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5)),
                        const SizedBox(width: 8),
                        Text(provider.t('copy_html'), style: GoogleFonts.inter(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
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
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Settings',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, anim1, anim2) => const SettingsDialog(),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
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
            borderRadius: BorderRadius.circular(6),
            boxShadow: _isHovered ? [BoxShadow(color: (widget.isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5)).withOpacity(0.3), blurRadius: 12)] : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset('markd.logo.jpg', width: 24, height: 24, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class _WindowControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final bool isClose;

  const _WindowControlButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.isClose = false,
  });

  @override
  State<_WindowControlButton> createState() => _WindowControlButtonState();
}

class _WindowControlButtonState extends State<_WindowControlButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    if (widget.isClose && _isHovered) {
      iconColor = Colors.white;
    } else {
      iconColor = widget.isDark ? Colors.white70 : Colors.black87;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: widget.isClose 
          ? const Color(0xFFE81123) 
          : (widget.isDark ? Colors.white10 : Colors.black12),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 28,
          width: 36,
          alignment: Alignment.center,
          child: Icon(
            widget.icon,
            size: 14,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

class _DraggableDivider extends StatefulWidget {
  final bool isDark;
  final ValueChanged<double> onDragUpdate;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  const _DraggableDivider({
    required this.isDark,
    required this.onDragUpdate,
    this.onDragStart,
    this.onDragEnd,
  });

  @override
  State<_DraggableDivider> createState() => _DraggableDividerState();
}

class _DraggableDividerState extends State<_DraggableDivider> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5);
    final active = _isHovered || _isDragging;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) {
          setState(() => _isDragging = true);
          widget.onDragStart?.call();
        },
        onHorizontalDragEnd: (_) {
          setState(() => _isDragging = false);
          widget.onDragEnd?.call();
        },
        onHorizontalDragCancel: () {
          setState(() => _isDragging = false);
          widget.onDragEnd?.call();
        },
        onHorizontalDragUpdate: (details) {
          widget.onDragUpdate(details.delta.dx);
        },
        child: Container(
          width: 8,
          color: active ? accentColor.withOpacity(0.05) : Colors.transparent,
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: active ? 2.0 : 1.0,
            color: active ? accentColor : (widget.isDark ? Colors.white10 : Colors.black12),
          ),
        ),
      ),
    );
  }
}

class ResizableSplitView extends StatefulWidget {
  final bool isDark;
  final bool isSplitScreen;
  final MarkdownProvider provider;

  const ResizableSplitView({
    super.key,
    required this.isDark,
    required this.isSplitScreen,
    required this.provider,
  });

  @override
  State<ResizableSplitView> createState() => _ResizableSplitViewState();
}

class _ResizableSplitViewState extends State<ResizableSplitView> {
  double _splitRatio = 0.5;

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
          color: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSplitScreen) {
      return Stack(
        children: [
          const MarkdownEditorWidget(),
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildEditorBadge(widget.provider),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const dividerWidth = 8.0;
        final availableWidth = totalWidth - dividerWidth;
        final editorWidth = availableWidth * _splitRatio;
        final previewWidth = availableWidth * (1.0 - _splitRatio);

        return Row(
          children: [
            SizedBox(
              width: editorWidth,
              child: Stack(
                children: [
                  const MarkdownEditorWidget(),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: _buildEditorBadge(widget.provider),
                  ),
                ],
              ),
            ),
            _DraggableDivider(
              isDark: widget.isDark,
              onDragUpdate: (delta) {
                setState(() {
                  _splitRatio = (_splitRatio + delta / availableWidth).clamp(0.15, 0.85);
                });
              },
            ),
            SizedBox(
              width: previewWidth,
              child: MarkdownPreviewWidget(),
            ),
          ],
        );
      },
    );
  }
}

