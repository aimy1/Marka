import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:provider/provider.dart';
import '../providers/markdown_provider.dart';

/// Marka IDE v3.5.0 - Strict Native System Settings (Micro-Radius Design)
/// Built according to strict Windows 11 Fluent (4px/8px micro-radii) & macOS Desktop System Preferences.
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarkdownProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Strict Native Color Palette
    final accentColor = isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5);
    final bgColor = isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF8F9FA);
    final sidebarBg = isDark ? const Color(0xFF181825) : const Color(0xFFF3F4F6);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8), // Strict 8px window radius
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 840,
            height: 600,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              children: [
                // ── Native Sidebar ──
                _buildNativeSidebar(provider, isDark, accentColor, sidebarBg, borderColor),
                
                // ── Hairline Divider ──
                Container(width: 1, color: borderColor),
                
                // ── Main Settings Panel ──
                Expanded(
                  child: Column(
                    children: [
                      _buildNativeHeader(provider, isDark, accentColor),
                      Container(height: 1, color: borderColor),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          child: _searchQuery.isNotEmpty 
                              ? _buildSearchResults(provider, isDark, accentColor)
                              : _buildCategoryContent(provider, isDark, accentColor),
                        ),
                      ),
                      _buildNativeFooter(context, isDark, provider, borderColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Native Sidebar ──
  Widget _buildNativeSidebar(MarkdownProvider p, bool isDark, Color accentColor, Color sidebarBg, Color borderColor) {
    return Container(
      width: 210,
      color: sidebarBg,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding Header
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 16, top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4), // Crisp 4px radius
                  ),
                  child: Icon(Icons.settings_suggest_rounded, size: 18, color: accentColor),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.t('settings'),
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Marka Preferences',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          _nativeNavItem(0, p.t('general'), Icons.tune_rounded, accentColor, isDark),
          _nativeNavItem(1, p.t('editor'), Icons.edit_note_rounded, accentColor, isDark),
          _nativeNavItem(2, p.t('appearance'), Icons.space_dashboard_rounded, accentColor, isDark),
          _nativeNavItem(3, p.t('advanced'), Icons.terminal_rounded, accentColor, isDark),
          const Spacer(),
          _nativeNavItem(4, p.t('about'), Icons.info_outline_rounded, accentColor, isDark),
        ],
      ),
    );
  }

  Widget _nativeNavItem(int index, String label, IconData icon, Color accent, bool isDark) {
    final isSelected = _selectedIndex == index && _searchQuery.isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
            _searchQuery = '';
            _searchController.clear();
          });
        },
        borderRadius: BorderRadius.circular(4), // Micro 4px
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
          decoration: BoxDecoration(
            color: isSelected 
                ? (isDark ? Colors.white.withOpacity(0.08) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: isSelected 
                ? Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 1)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: isSelected ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                icon, 
                size: 16, 
                color: isSelected ? accent : (isDark ? Colors.white54 : Colors.black54),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Native Header & Search Bar ──
  Widget _buildNativeHeader(MarkdownProvider p, bool isDark, Color accentColor) {
    final titles = [p.t('general'), p.t('editor'), p.t('appearance'), p.t('advanced'), p.t('about')];
    final titleText = _searchQuery.isNotEmpty ? '${p.t('find')}: "$_searchQuery"' : titles[_selectedIndex];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 16, 14),
      child: Row(
        children: [
          Text(
            titleText, 
            style: GoogleFonts.outfit(
              fontSize: 17, 
              fontWeight: FontWeight.w700, 
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          
          // Native Search Input Field
          Container(
            width: 210,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(4), // Micro 4px
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: '${p.t('find')}...',
                hintStyle: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
                prefixIcon: Icon(Icons.search_rounded, size: 15, color: isDark ? Colors.white38 : Colors.black38),
                suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 13),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 7),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          IconButton(
            onPressed: () => Navigator.pop(context), 
            icon: Icon(Icons.close_rounded, size: 18, color: isDark ? Colors.white54 : Colors.black54),
            tooltip: p.t('close'),
          ),
        ],
      ),
    );
  }

  // ── Native Category Content ──
  Widget _buildCategoryContent(MarkdownProvider p, bool isDark, Color accentColor) {
    switch (_selectedIndex) {
      case 0: // General
        return Column(
          children: [
            _buildNativeSection(
              title: p.t('general'),
              isDark: isDark,
              children: [
                _buildLanguageDropdown(p, isDark),
                _nativeDivider(isDark),
                _buildNativeTile(
                  title: p.t('theme'),
                  subtitle: isDark ? 'Dark mode active' : 'Light mode active',
                  icon: Icons.palette_outlined,
                  isDark: isDark,
                  action: _buildNativeSwitch(
                    value: isDark,
                    accentColor: accentColor,
                    onChanged: (v) => AdaptiveTheme.of(context).toggleThemeMode(),
                  ),
                ),
                _nativeDivider(isDark),
                _buildNativeTile(
                  title: p.t('auto_save'),
                  subtitle: 'Automatically save modified documents to disk',
                  icon: Icons.auto_awesome_rounded,
                  isDark: isDark,
                  action: _buildNativeSwitch(
                    value: p.autoSave,
                    accentColor: accentColor,
                    onChanged: (v) => p.toggleAutoSave(),
                  ),
                ),
              ],
            ),
          ],
        );

      case 1: // Editor Typography
        return Column(
          children: [
            _buildNativeSection(
              title: p.t('typography'),
              isDark: isDark,
              children: [
                _buildFontDropdown(p, isDark),
                _nativeDivider(isDark),
                _buildNativeTile(
                  title: p.t('font_size'),
                  subtitle: 'Adjust main editor typography font scale',
                  icon: Icons.format_size_rounded,
                  isDark: isDark,
                  action: _buildSizeControls(p, isDark, accentColor),
                ),
                _nativeDivider(isDark),
                _buildNativeTile(
                  title: p.t('line_height'),
                  subtitle: 'Set editor paragraph vertical line height ratio',
                  icon: Icons.format_line_spacing_rounded,
                  isDark: isDark,
                  action: _buildLineHeightSlider(p, accentColor, isDark),
                ),
              ],
            ),
          ],
        );

      case 2: // Appearance & View Options
        return Column(
          children: [
            _buildNativeSection(
              title: p.t('layout_options'),
              isDark: isDark,
              children: [
                _buildNativeTile(
                  title: p.t('editor_padding'),
                  subtitle: 'Horizontal padding around editor canvas',
                  icon: Icons.horizontal_distribute_rounded,
                  isDark: isDark,
                  action: _buildPaddingSlider(p, accentColor, isDark),
                ),
                _nativeDivider(isDark),
                _buildNativeTile(
                  title: p.t('word_wrap'),
                  subtitle: 'Soft wrap long lines to viewport bounds',
                  icon: Icons.wrap_text_rounded,
                  isDark: isDark,
                  action: _buildNativeSwitch(
                    value: p.isWrapped,
                    accentColor: accentColor,
                    onChanged: (v) => p.toggleWrap(),
                  ),
                ),
                _nativeDivider(isDark),
                _buildNativeTile(
                  title: p.t('split_screen'),
                  subtitle: 'Display side-by-side Markdown preview',
                  icon: Icons.splitscreen_rounded,
                  isDark: isDark,
                  action: _buildNativeSwitch(
                    value: p.isSplitScreen,
                    accentColor: accentColor,
                    onChanged: (v) => p.toggleSplitScreen(),
                  ),
                ),
                _nativeDivider(isDark),
                _buildNativeTile(
                  title: p.t('show_toolbar'),
                  subtitle: 'Display formatting shortcut toolbar',
                  icon: Icons.construction_rounded,
                  isDark: isDark,
                  action: _buildNativeSwitch(
                    value: p.showToolbar,
                    accentColor: accentColor,
                    onChanged: (v) => p.toggleToolbar(),
                  ),
                ),
                _nativeDivider(isDark),
                _buildNativeTile(
                  title: p.t('show_line_numbers'),
                  subtitle: 'Render vertical line numbers gutter',
                  icon: Icons.format_list_numbered_rounded,
                  isDark: isDark,
                  action: _buildNativeSwitch(
                    value: p.showLineNumbers,
                    accentColor: accentColor,
                    onChanged: (v) => p.toggleLineNumbers(),
                  ),
                ),
                _nativeDivider(isDark),
                _buildNativeTile(
                  title: p.t('show_grid_lines'),
                  subtitle: 'Display subtle background grid reference lines',
                  icon: Icons.grid_on_rounded,
                  isDark: isDark,
                  action: _buildNativeSwitch(
                    value: p.showGridLines,
                    accentColor: accentColor,
                    onChanged: (v) => p.toggleGridLines(),
                  ),
                ),
                _nativeDivider(isDark),
                _buildNativeTile(
                  title: p.t('line_highlight'),
                  subtitle: 'Highlight active focused line',
                  icon: Icons.border_horizontal_rounded,
                  isDark: isDark,
                  action: _buildNativeSwitch(
                    value: p.showLineHighlight,
                    accentColor: accentColor,
                    onChanged: (v) => p.toggleLineHighlight(),
                  ),
                ),
              ],
            ),
          ],
        );

      case 3: // Advanced & Keyboard Shortcuts
        return Column(
          children: [
            _buildNativeSection(
              title: p.t('editor_behavior'),
              isDark: isDark,
              children: [
                _buildNativeTile(
                  title: p.t('tab_size'),
                  subtitle: 'Spaces inserted for tab indentation',
                  icon: Icons.keyboard_tab_rounded,
                  isDark: isDark,
                  action: _buildTabDropdown(p, isDark),
                ),
                _nativeDivider(isDark),
                _buildNativeTile(
                  title: p.t('auto_pairing'),
                  subtitle: 'Automatically close brackets and quotes',
                  icon: Icons.code_rounded,
                  isDark: isDark,
                  action: _buildNativeSwitch(
                    value: p.autoPairing,
                    accentColor: accentColor,
                    onChanged: (v) => p.toggleAutoPairing(),
                  ),
                ),
                _nativeDivider(isDark),
                _buildNativeTile(
                  title: p.t('sync_scroll'),
                  subtitle: 'Synchronize editor and preview scroll positions',
                  icon: Icons.sync_rounded,
                  isDark: isDark,
                  action: _buildNativeSwitch(
                    value: p.isSyncScroll,
                    accentColor: accentColor,
                    onChanged: (v) => p.toggleSyncScroll(),
                  ),
                ),
                _nativeDivider(isDark),
                _buildNativeTile(
                  title: p.t('smooth_scrolling'),
                  subtitle: 'Enable GPU-accelerated smooth scrolling animation',
                  icon: Icons.mouse_rounded,
                  isDark: isDark,
                  action: _buildNativeSwitch(
                    value: p.smoothScrolling,
                    accentColor: accentColor,
                    onChanged: (v) => p.toggleSmoothScrolling(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildNativeSection(
              title: p.t('shortcuts'),
              isDark: isDark,
              children: [
                _buildNativeShortcutTile(p.t('shortcut_save'), 'Ctrl', 'S', isDark, accentColor),
                _nativeDivider(isDark),
                _buildNativeShortcutTile(p.t('shortcut_find'), 'Ctrl', 'F', isDark, accentColor),
                _nativeDivider(isDark),
                _buildNativeShortcutTile(p.t('shortcut_bold'), 'Ctrl', 'B', isDark, accentColor),
                _nativeDivider(isDark),
                _buildNativeShortcutTile(p.t('shortcut_italic'), 'Ctrl', 'I', isDark, accentColor),
                _nativeDivider(isDark),
                _buildNativeShortcutTile(p.t('shortcut_link'), 'Ctrl', 'L', isDark, accentColor),
                _nativeDivider(isDark),
                _buildNativeShortcutTile(p.t('shortcut_comment'), 'Ctrl', '/', isDark, accentColor),
              ],
            ),
          ],
        );

      default: // About Marka
        return Column(
          children: [
            _buildNativeSection(
              title: p.t('about'),
              isDark: isDark,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6), // Micro 6px
                      child: Image.asset('markd.logo.jpg', width: 52, height: 52, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Marka IDE',
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Industrial-Grade Markdown Workstation',
                          style: GoogleFonts.inter(fontSize: 11.5, color: isDark ? Colors.white54 : Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  p.t('about_desc'),
                  style: GoogleFonts.inter(fontSize: 12, height: 1.5, color: isDark ? Colors.white70 : Colors.black54),
                ),
                const SizedBox(height: 14),
                _nativeDivider(isDark),
                _buildNativeTile(
                  title: p.t('about_version'),
                  subtitle: 'Engine release version',
                  icon: Icons.info_outline_rounded,
                  isDark: isDark,
                  action: _nativeBadge('v3.5.0', accentColor, isDark),
                ),
                _nativeDivider(isDark),
                _buildNativeTile(
                  title: p.t('about_author'),
                  subtitle: 'Core developer',
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                  action: Text('Asniya', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
                ),
                _nativeDivider(isDark),
                _buildNativeTile(
                  title: p.t('about_license'),
                  subtitle: 'Software license terms',
                  icon: Icons.description_outlined,
                  isDark: isDark,
                  action: Text('MIT License', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
                ),
                _nativeDivider(isDark),
                _buildNativeTile(
                  title: p.t('about_github'),
                  subtitle: 'Repository URL',
                  icon: Icons.link_rounded,
                  isDark: isDark,
                  action: SelectableText('github.com/aimy1/Marka', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: accentColor)),
                ),
              ],
            ),
          ],
        );
    }
  }

  // ── Search View ──
  Widget _buildSearchResults(MarkdownProvider p, bool isDark, Color accentColor) {
    final List<Widget> results = [];
    final q = _searchQuery.toLowerCase();

    void addResult(String title, String subtitle, IconData icon, Widget action) {
      if (title.toLowerCase().contains(q) || subtitle.toLowerCase().contains(q)) {
        if (results.isNotEmpty) results.add(_nativeDivider(isDark));
        results.add(_buildNativeTile(title: title, subtitle: subtitle, icon: icon, isDark: isDark, action: action));
      }
    }

    addResult(p.t('theme'), 'Dark / Light UI theme toggle', Icons.palette_outlined, _buildNativeSwitch(value: isDark, accentColor: accentColor, onChanged: (v) => AdaptiveTheme.of(context).toggleThemeMode()));
    addResult(p.t('auto_save'), 'Automatically save modified documents to disk', Icons.auto_awesome_rounded, _buildNativeSwitch(value: p.autoSave, accentColor: accentColor, onChanged: (v) => p.toggleAutoSave()));
    addResult(p.t('font_family'), 'Editor typography font family', Icons.font_download_outlined, _buildFontDropdown(p, isDark));
    addResult(p.t('font_size'), 'Adjust main editor typography font scale', Icons.format_size_rounded, _buildSizeControls(p, isDark, accentColor));
    addResult(p.t('line_height'), 'Set editor paragraph vertical line height ratio', Icons.format_line_spacing_rounded, _buildLineHeightSlider(p, accentColor, isDark));
    addResult(p.t('editor_padding'), 'Horizontal padding around editor canvas', Icons.horizontal_distribute_rounded, _buildPaddingSlider(p, accentColor, isDark));
    addResult(p.t('word_wrap'), 'Soft wrap long lines to viewport bounds', Icons.wrap_text_rounded, _buildNativeSwitch(value: p.isWrapped, accentColor: accentColor, onChanged: (v) => p.toggleWrap()));
    addResult(p.t('split_screen'), 'Display side-by-side Markdown preview', Icons.splitscreen_rounded, _buildNativeSwitch(value: p.isSplitScreen, accentColor: accentColor, onChanged: (v) => p.toggleSplitScreen()));
    addResult(p.t('show_line_numbers'), 'Render vertical line numbers gutter', Icons.format_list_numbered_rounded, _buildNativeSwitch(value: p.showLineNumbers, accentColor: accentColor, onChanged: (v) => p.toggleLineNumbers()));
    addResult(p.t('tab_size'), 'Spaces inserted for tab indentation', Icons.keyboard_tab_rounded, _buildTabDropdown(p, isDark));
    addResult(p.t('auto_pairing'), 'Automatically close brackets and quotes', Icons.code_rounded, _buildNativeSwitch(value: p.autoPairing, accentColor: accentColor, onChanged: (v) => p.toggleAutoPairing()));
    addResult(p.t('sync_scroll'), 'Synchronize editor and preview scroll positions', Icons.sync_rounded, _buildNativeSwitch(value: p.isSyncScroll, accentColor: accentColor, onChanged: (v) => p.toggleSyncScroll()));

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 40, color: isDark ? Colors.white24 : Colors.black26),
              const SizedBox(height: 10),
              Text(
                '${p.t('no_results')}: "$_searchQuery"',
                style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return _buildNativeSection(
      title: '${p.t('find')} (${results.whereType<InkWell>().length})',
      isDark: isDark,
      children: results,
    );
  }

  // ── Micro-Radius Section Card ──
  Widget _buildNativeSection({required String title, required bool isDark, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.025) : Colors.white,
        borderRadius: BorderRadius.circular(6), // Strict 6px section radius
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.08),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _nativeDivider(bool isDark) {
    return Divider(
      height: 12, 
      thickness: 1, 
      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
    );
  }

  // ── Native Tile Component ──
  Widget _buildNativeTile({
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required bool isDark, 
    required Widget action
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(4), // Micro 4px
            ),
            child: Icon(icon, size: 15, color: isDark ? Colors.white70 : Colors.black87),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: GoogleFonts.inter(
                    fontSize: 13, 
                    fontWeight: FontWeight.w600, 
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  subtitle, 
                  style: GoogleFonts.inter(
                    fontSize: 11, 
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          action,
        ],
      ),
    );
  }

  // ── Native Keyboard Key Cap Component ──
  Widget _buildNativeShortcutTile(String label, String modifierKey, String mainKey, bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildKeyCap(modifierKey, isDark, accent),
              const SizedBox(width: 4),
              Text('+', style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
              const SizedBox(width: 4),
              _buildKeyCap(mainKey, isDark, accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyCap(String text, bool isDark, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(4), // Micro 4px
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10.5, 
          fontWeight: FontWeight.bold, 
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  // ── Micro Controls ──
  Widget _buildNativeSwitch({required bool value, required Color accentColor, required ValueChanged<bool> onChanged}) {
    return Transform.scale(
      scale: 0.8,
      child: Switch(
        value: value,
        activeTrackColor: accentColor.withOpacity(0.4),
        activeThumbColor: accentColor,
        inactiveThumbColor: Colors.grey.shade400,
        inactiveTrackColor: Colors.grey.withOpacity(0.2),
        onChanged: onChanged,
      ),
    );
  }

  Widget _nativeBadge(String text, Color accent, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4), // Micro 4px
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold, color: accent),
      ),
    );
  }

  Widget _buildNativeFooter(BuildContext context, bool isDark, MarkdownProvider provider, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context), 
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // Micro 4px
              side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
            ),
            child: Text(
              provider.t('close'), 
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown(MarkdownProvider provider, bool isDark) {
    return _buildNativeTile(
      title: provider.t('language'),
      subtitle: 'Select interface display language',
      icon: Icons.translate_rounded,
      isDark: isDark,
      action: DropdownButton<String>(
        value: provider.locale,
        underline: const SizedBox(),
        dropdownColor: isDark ? const Color(0xFF181825) : Colors.white,
        onChanged: (v) => v != null ? provider.updateLocale(v) : null,
        items: [
          {'code': 'en', 'label': '🇺🇸 English'},
          {'code': 'zh', 'label': '🇨🇳 简体中文'},
        ].map((l) => DropdownMenuItem(
          value: l['code'],
          child: Text(l['label']!, style: GoogleFonts.inter(fontSize: 12)),
        )).toList(),
      ),
    );
  }

  Widget _buildFontDropdown(MarkdownProvider provider, bool isDark) {
    final availableFonts = ['Inter', 'Fira Code', 'JetBrains Mono', 'Roboto Mono', 'Source Code Pro'];
    final currentFont = availableFonts.contains(provider.fontFamily) ? provider.fontFamily : 'Inter';
    return _buildNativeTile(
      title: provider.t('font_family'),
      subtitle: 'Choose preferred typography font family for editor',
      icon: Icons.font_download_outlined,
      isDark: isDark,
      action: DropdownButton<String>(
        value: currentFont,
        underline: const SizedBox(),
        dropdownColor: isDark ? const Color(0xFF181825) : Colors.white,
        onChanged: (v) => v != null ? provider.updateFontFamily(v) : null,
        items: availableFonts
            .map((f) => DropdownMenuItem(
          value: f,
          child: Text(f, style: GoogleFonts.getFont(f, fontSize: 12)),
        )).toList(),
      ),
    );
  }

  Widget _buildSizeControls(MarkdownProvider provider, bool isDark, Color accent) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniBtn(Icons.remove_rounded, () => provider.updateFontSize(provider.fontSize - 1), isDark),
        const SizedBox(width: 6),
        _nativeBadge('${provider.fontSize.toInt()} px', accent, isDark),
        const SizedBox(width: 6),
        _miniBtn(Icons.add_rounded, () => provider.updateFontSize(provider.fontSize + 1), isDark),
      ],
    );
  }

  Widget _buildLineHeightSlider(MarkdownProvider p, Color accent, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 85, 
          child: SliderTheme(
            data: const SliderThemeData(
              trackHeight: 2.5,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
            ),
            child: Slider(
              value: p.lineHeight, 
              min: 1.0, 
              max: 2.5, 
              divisions: 15, 
              activeColor: accent, 
              onChanged: (v) => p.updateLineHeight(v),
            ),
          ),
        ),
        const SizedBox(width: 4),
        _nativeBadge('${p.lineHeight.toStringAsFixed(2)}x', accent, isDark),
      ],
    );
  }

  Widget _buildPaddingSlider(MarkdownProvider p, Color accent, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 85, 
          child: SliderTheme(
            data: const SliderThemeData(
              trackHeight: 2.5,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
            ),
            child: Slider(
              value: p.editorPadding, 
              min: 16.0, 
              max: 96.0, 
              divisions: 20, 
              activeColor: accent, 
              onChanged: (v) => p.updateEditorPadding(v),
            ),
          ),
        ),
        const SizedBox(width: 4),
        _nativeBadge('${p.editorPadding.toInt()} px', accent, isDark),
      ],
    );
  }

  Widget _buildTabDropdown(MarkdownProvider p, bool isDark) {
    return DropdownButton<int>(
      value: p.tabSize,
      underline: const SizedBox(),
      dropdownColor: isDark ? const Color(0xFF181825) : Colors.white,
      onChanged: (v) => v != null ? p.updateTabSize(v) : null,
      items: [2, 4].map((s) => DropdownMenuItem(value: s, child: Text('$s ${p.t('spaces')}', style: GoogleFonts.inter(fontSize: 12)))).toList(),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback tap, bool isDark) {
    return InkWell(
      onTap: tap, 
      borderRadius: BorderRadius.circular(4), // Micro 4px
      child: Container(
        padding: const EdgeInsets.all(3), 
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), 
          borderRadius: BorderRadius.circular(4),
        ), 
        child: Icon(icon, size: 13),
      ),
    );
  }
}
