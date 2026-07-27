import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:provider/provider.dart';
import '../providers/markdown_provider.dart';

/// Marka IDE v3.3.11 - Purified & Beautified Settings Canvas
/// Features purified native language labels, deleted scope bar, exquisite About Hero Card,
/// and full Catppuccin Theme Purple color system (#CBA6F7 / #8839EF).
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  String _selectedCategory = 'commonly_used';
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

    // Signature Marka Catppuccin Theme Purple System
    final bgColor = isDark ? const Color(0xFF1E1E2E) : const Color(0xFFFAFAFA);
    final headerBg = isDark ? const Color(0xFF181825) : const Color(0xFFF3F4F6);
    final sidebarBg = isDark ? const Color(0xFF181825) : const Color(0xFFF3F4F6);
    final contentBg = isDark ? const Color(0xFF1E1E2E) : const Color(0xFFFFFFFF);
    
    // Theme Purple Tokens
    final accentPurple = isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF);
    final titlePurple = isDark ? const Color(0xFFDDB6F6) : const Color(0xFF7287FD);
    
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final textMuted = isDark ? const Color(0xFFA6ADC8) : const Color(0xFF6C757D);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 920,
            height: 650,
            decoration: BoxDecoration(
              color: bgColor.withOpacity(isDark ? 0.95 : 0.98),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              children: [
                // ── Purified Header Bar (Scope Bar Removed) ──
                _buildMarkaHeader(provider, isDark, accentPurple, headerBg, borderColor, textMuted),
                
                Container(height: 1, color: borderColor),
                
                // ── Main Body (Sidebar + Settings Canvas) ──
                Expanded(
                  child: Row(
                    children: [
                      // Left Category Tree Navigation
                      _buildCategoryTree(provider, isDark, accentPurple, sidebarBg, borderColor, textMuted),
                      
                      Container(width: 1, color: borderColor),
                      
                      // Right Settings Canvas
                      Expanded(
                        child: Container(
                          color: contentBg,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                            child: _searchQuery.isNotEmpty
                                ? _buildMarkaSearchResults(provider, isDark, accentPurple, titlePurple, textMuted)
                                : _buildMarkaCategoryContent(provider, isDark, accentPurple, titlePurple, textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Footer Bar ──
                _buildMarkaFooter(context, isDark, provider, headerBg, borderColor, accentPurple),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header Bar ──
  Widget _buildMarkaHeader(MarkdownProvider p, bool isDark, Color accentPurple, Color headerBg, Color borderColor, Color textMuted) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 16, 14),
      color: headerBg,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentPurple.withOpacity(0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.settings_suggest_rounded, size: 18, color: accentPurple),
          ),
          const SizedBox(width: 12),
          Text(
            p.t('settings'),
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 24),
          
          // Search Input Box
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? accentPurple.withOpacity(0.3) : accentPurple.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                style: GoogleFonts.inter(fontSize: 12.5, color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: '${p.t('find')} (e.g. general.language, editor.fontSize)...',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
                  prefixIcon: Icon(Icons.search_rounded, size: 16, color: accentPurple),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 14),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, size: 20, color: textMuted),
            tooltip: p.t('close'),
          ),
        ],
      ),
    );
  }

  // ── Category Navigation Tree Sidebar ──
  Widget _buildCategoryTree(MarkdownProvider p, bool isDark, Color accentPurple, Color sidebarBg, Color borderColor, Color textMuted) {
    final isZh = p.locale == 'zh';

    return Container(
      width: 220,
      color: sidebarBg,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: ListView(
        children: [
          _treeCategoryHeader(isZh ? '常用配置' : 'COMMONLY USED'),
          _treeNode('commonly_used', p.t('general'), Icons.star_outline_rounded, isDark, accentPurple),
          
          const SizedBox(height: 16),
          _treeCategoryHeader(isZh ? '文本编辑器' : 'TEXT EDITOR'),
          _treeNode('editor_font', p.t('typography'), Icons.font_download_outlined, isDark, accentPurple),
          _treeNode('editor_formatting', p.t('editor_behavior'), Icons.format_align_left_rounded, isDark, accentPurple),
          
          const SizedBox(height: 16),
          _treeCategoryHeader(isZh ? '工作台界面' : 'WORKBENCH'),
          _treeNode('workbench_appearance', p.t('appearance'), Icons.palette_outlined, isDark, accentPurple),
          _treeNode('workbench_layout', p.t('layout_options'), Icons.splitscreen_rounded, isDark, accentPurple),
          
          const SizedBox(height: 16),
          _treeCategoryHeader(isZh ? '快捷键与关于' : 'SHORTCUTS & ABOUT'),
          _treeNode('features_shortcuts', p.t('shortcuts'), Icons.keyboard_outlined, isDark, accentPurple),
          _treeNode('features_about', p.t('about'), Icons.info_outline_rounded, isDark, accentPurple),
        ],
      ),
    );
  }

  Widget _treeCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 4, bottom: 6),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _treeNode(String id, String label, IconData icon, bool isDark, Color accentPurple) {
    final isSelected = _selectedCategory == id && _searchQuery.isEmpty;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = id;
          _searchQuery = '';
          _searchController.clear();
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentPurple.withOpacity(isDark ? 0.15 : 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isSelected ? Border.all(color: accentPurple.withOpacity(0.3), width: 1) : null,
        ),
        child: Row(
          children: [
            // Theme Purple Active Indicator Pillar Bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: isSelected ? accentPurple : Colors.transparent,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              icon,
              size: 15,
              color: isSelected ? accentPurple : (isDark ? Colors.white54 : Colors.black54),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white70 : Colors.black87),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Purified Category Content ──
  Widget _buildMarkaCategoryContent(MarkdownProvider p, bool isDark, Color accentPurple, Color titlePurple, Color textMuted) {
    switch (_selectedCategory) {
      case 'commonly_used':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _markaSectionHeader(p.t('general')),
            
            _buildMarkaSettingTile(
              settingId: 'general.language',
              title: p.t('language'),
              description: 'Controls the display language of the Marka IDE user interface.',
              isDark: isDark,
              accentPurple: accentPurple,
              titlePurple: titlePurple,
              control: _buildLanguageDropdown(p, isDark, accentPurple),
            ),
            _markaDivider(isDark),
            
            _buildMarkaSettingTile(
              settingId: 'workbench.colorTheme',
              title: p.t('theme'),
              description: 'Specifies the color theme used in the workbench (Light / Dark Theme).',
              isDark: isDark,
              accentPurple: accentPurple,
              titlePurple: titlePurple,
              control: _markaSwitch(isDark, (v) => AdaptiveTheme.of(context).toggleThemeMode(), isDark, accentPurple),
            ),
            _markaDivider(isDark),
            
            _buildMarkaSettingTile(
              settingId: 'files.autoSave',
              title: p.t('auto_save'),
              description: 'Controls auto save of dirty files. Automatically saves content changes to disk.',
              isDark: isDark,
              accentPurple: accentPurple,
              titlePurple: titlePurple,
              control: _markaSwitch(p.autoSave, (v) => p.toggleAutoSave(), isDark, accentPurple),
            ),
          ],
        );

      case 'editor_font':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _markaSectionHeader(p.t('typography')),
            _buildMarkaSettingTile(
              settingId: 'editor.fontFamily',
              title: p.t('font_family'),
              description: 'Controls the font family used in text editing canvas.',
              isDark: isDark,
              accentPurple: accentPurple,
              titlePurple: titlePurple,
              control: _buildFontDropdown(p, isDark, accentPurple),
            ),
            _markaDivider(isDark),
            _buildMarkaSettingTile(
              settingId: 'editor.fontSize',
              title: p.t('font_size'),
              description: 'Controls font size in pixels (8px - 32px range).',
              isDark: isDark,
              accentPurple: accentPurple,
              titlePurple: titlePurple,
              control: _markaSizeControls(p, isDark, accentPurple),
            ),
            _markaDivider(isDark),
            _buildMarkaSettingTile(
              settingId: 'editor.lineHeight',
              title: p.t('line_height'),
              description: 'Controls the line height multiplier for text paragraphs.',
              isDark: isDark,
              accentPurple: accentPurple,
              titlePurple: titlePurple,
              control: _buildLineHeightSlider(p, accentPurple, isDark),
            ),
          ],
        );

      case 'editor_formatting':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _markaSectionHeader(p.t('editor_behavior')),
            _buildMarkaSettingTile(
              settingId: 'editor.wordWrap',
              title: p.t('word_wrap'),
              description: 'Controls how lines should wrap. Enable soft wrap at viewport boundary.',
              isDark: isDark,
              accentPurple: accentPurple,
              titlePurple: titlePurple,
              control: _markaSwitch(p.isWrapped, (v) => p.toggleWrap(), isDark, accentPurple),
            ),
            _markaDivider(isDark),
            _buildMarkaSettingTile(
              settingId: 'editor.lineNumbers',
              title: p.t('show_line_numbers'),
              description: 'Controls the display of vertical line numbers in line gutter.',
              isDark: isDark,
              accentPurple: accentPurple,
              titlePurple: titlePurple,
              control: _markaSwitch(p.showLineNumbers, (v) => p.toggleLineNumbers(), isDark, accentPurple),
            ),
            _markaDivider(isDark),
            _buildMarkaSettingTile(
              settingId: 'editor.autoClosingBrackets',
              title: p.t('auto_pairing'),
              description: 'Controls whether the editor should automatically close quotes and brackets.',
              isDark: isDark,
              accentPurple: accentPurple,
              titlePurple: titlePurple,
              control: _markaSwitch(p.autoPairing, (v) => p.toggleAutoPairing(), isDark, accentPurple),
            ),
          ],
        );

      case 'workbench_appearance':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _markaSectionHeader(p.t('appearance')),
            _buildMarkaSettingTile(
              settingId: 'workbench.colorTheme',
              title: p.t('theme'),
              description: 'Switch between Dark and Light mode workbench theme.',
              isDark: isDark,
              accentPurple: accentPurple,
              titlePurple: titlePurple,
              control: _markaSwitch(isDark, (v) => AdaptiveTheme.of(context).toggleThemeMode(), isDark, accentPurple),
            ),
            _markaDivider(isDark),
            _buildMarkaSettingTile(
              settingId: 'workbench.showToolbar',
              title: p.t('show_toolbar'),
              description: 'Controls visibility of top editor formatting toolbar.',
              isDark: isDark,
              accentPurple: accentPurple,
              titlePurple: titlePurple,
              control: _markaSwitch(p.showToolbar, (v) => p.toggleToolbar(), isDark, accentPurple),
            ),
          ],
        );

      case 'workbench_layout':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _markaSectionHeader(p.t('layout_options')),
            _buildMarkaSettingTile(
              settingId: 'workbench.editorPadding',
              title: p.t('editor_padding'),
              description: 'Horizontal padding offset around text editing canvas in pixels.',
              isDark: isDark,
              accentPurple: accentPurple,
              titlePurple: titlePurple,
              control: _buildPaddingSlider(p, accentPurple, isDark),
            ),
            _markaDivider(isDark),
            _buildMarkaSettingTile(
              settingId: 'workbench.splitScreen',
              title: p.t('split_screen'),
              description: 'Controls side-by-side Markdown live preview pane.',
              isDark: isDark,
              accentPurple: accentPurple,
              titlePurple: titlePurple,
              control: _markaSwitch(p.isSplitScreen, (v) => p.toggleSplitScreen(), isDark, accentPurple),
            ),
            _markaDivider(isDark),
            _buildMarkaSettingTile(
              settingId: 'files.syncScroll',
              title: p.t('sync_scroll'),
              description: 'Synchronize editor scroll position with live Markdown preview.',
              isDark: isDark,
              accentPurple: accentPurple,
              titlePurple: titlePurple,
              control: _markaSwitch(p.isSyncScroll, (v) => p.toggleSyncScroll(), isDark, accentPurple),
            ),
          ],
        );

      case 'features_shortcuts':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _markaSectionHeader(p.t('shortcuts')),
            _buildMarkaShortcutTile(p.t('shortcut_save'), 'files.save', 'Ctrl', 'S', isDark, accentPurple),
            _markaDivider(isDark),
            _buildMarkaShortcutTile(p.t('shortcut_find'), 'editor.find', 'Ctrl', 'F', isDark, accentPurple),
            _markaDivider(isDark),
            _buildMarkaShortcutTile(p.t('shortcut_bold'), 'editor.formatBold', 'Ctrl', 'B', isDark, accentPurple),
            _markaDivider(isDark),
            _buildMarkaShortcutTile(p.t('shortcut_italic'), 'editor.formatItalic', 'Ctrl', 'I', isDark, accentPurple),
            _markaDivider(isDark),
            _buildMarkaShortcutTile(p.t('shortcut_link'), 'editor.insertLink', 'Ctrl', 'L', isDark, accentPurple),
            _markaDivider(isDark),
            _buildMarkaShortcutTile(p.t('shortcut_comment'), 'editor.toggleComment', 'Ctrl', '/', isDark, accentPurple),
          ],
        );

      default: // Beautified About Hero Section
        return _buildBeautifiedAboutHeroCard(p, isDark, accentPurple, titlePurple, textMuted);
    }
  }

  // ── Beautified "About Marka" Hero Card Component ──
  Widget _buildBeautifiedAboutHeroCard(MarkdownProvider p, bool isDark, Color accentPurple, Color titlePurple, Color textMuted) {
    final isZh = p.locale == 'zh';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _markaSectionHeader(p.t('about')),
        const SizedBox(height: 12),
        
        // Brand Hero Box
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.025),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: accentPurple.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: accentPurple.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset('markd.logo.jpg', width: 56, height: 56, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Marka IDE',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: titlePurple,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _markaBadge('v3.3.11', accentPurple, isDark),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isZh ? '工业级跨平台 Markdown 专有工作台' : 'Industrial-Grade Workspace Markdown Editor',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                p.t('about_desc'),
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Metadata Specification Grid
        _buildMarkaSettingTile(
          settingId: 'marka.version',
          title: p.t('about_version'),
          description: isZh ? '当前已安装的平台核心引擎版本' : 'Currently installed core platform release version',
          isDark: isDark,
          accentPurple: accentPurple,
          titlePurple: titlePurple,
          control: _markaBadge('v3.3.11', accentPurple, isDark),
        ),
        _markaDivider(isDark),
        
        _buildMarkaSettingTile(
          settingId: 'marka.author',
          title: p.t('about_author'),
          description: isZh ? 'Marka 架构与核心平台开发者' : 'Marka platform lead architect and developer',
          isDark: isDark,
          accentPurple: accentPurple,
          titlePurple: titlePurple,
          control: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accentPurple.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('Asniya', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: accentPurple)),
          ),
        ),
        _markaDivider(isDark),
        
        _buildMarkaSettingTile(
          settingId: 'marka.license',
          title: p.t('about_license'),
          description: isZh ? '开源软件分发与授权使用条款' : 'Open source software distribution license terms',
          isDark: isDark,
          accentPurple: accentPurple,
          titlePurple: titlePurple,
          control: Text('MIT License', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
        ),
        _markaDivider(isDark),
        
        _buildMarkaSettingTile(
          settingId: 'marka.repository',
          title: p.t('about_github'),
          description: isZh ? '官方 GitHub 源代码仓库与 Bug 跟踪' : 'Official GitHub repository and bug tracker',
          isDark: isDark,
          accentPurple: accentPurple,
          titlePurple: titlePurple,
          control: SelectableText(
            'github.com/aimy1/Marka',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: accentPurple),
          ),
        ),
      ],
    );
  }

  // ── Search Results Filter ──
  Widget _buildMarkaSearchResults(MarkdownProvider p, bool isDark, Color accentPurple, Color titlePurple, Color textMuted) {
    final List<Widget> results = [];
    final q = _searchQuery.toLowerCase();

    void addResult(String settingId, String title, String description, Widget control) {
      if (settingId.toLowerCase().contains(q) || title.toLowerCase().contains(q) || description.toLowerCase().contains(q)) {
        if (results.isNotEmpty) results.add(_markaDivider(isDark));
        results.add(_buildMarkaSettingTile(
          settingId: settingId,
          title: title,
          description: description,
          isDark: isDark,
          accentPurple: accentPurple,
          titlePurple: titlePurple,
          control: control,
        ));
      }
    }

    addResult('general.language', p.t('language'), 'Controls display language.', _buildLanguageDropdown(p, isDark, accentPurple));
    addResult('workbench.colorTheme', p.t('theme'), 'Controls dark / light theme.', _markaSwitch(isDark, (v) => AdaptiveTheme.of(context).toggleThemeMode(), isDark, accentPurple));
    addResult('files.autoSave', p.t('auto_save'), 'Controls auto save of modified files.', _markaSwitch(p.autoSave, (v) => p.toggleAutoSave(), isDark, accentPurple));
    addResult('editor.fontSize', p.t('font_size'), 'Controls font size in pixels.', _markaSizeControls(p, isDark, accentPurple));
    addResult('editor.fontFamily', p.t('font_family'), 'Controls font family.', _buildFontDropdown(p, isDark, accentPurple));
    addResult('editor.lineHeight', p.t('line_height'), 'Controls line height multiplier.', _buildLineHeightSlider(p, accentPurple, isDark));
    addResult('editor.wordWrap', p.t('word_wrap'), 'Controls soft wrapping of long lines.', _markaSwitch(p.isWrapped, (v) => p.toggleWrap(), isDark, accentPurple));
    addResult('editor.lineNumbers', p.t('show_line_numbers'), 'Controls vertical line numbers.', _markaSwitch(p.showLineNumbers, (v) => p.toggleLineNumbers(), isDark, accentPurple));
    addResult('workbench.editorPadding', p.t('editor_padding'), 'Horizontal padding offset.', _buildPaddingSlider(p, accentPurple, isDark));
    addResult('workbench.splitScreen', p.t('split_screen'), 'Controls side-by-side preview.', _markaSwitch(p.isSplitScreen, (v) => p.toggleSplitScreen(), isDark, accentPurple));

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 40, color: isDark ? Colors.white24 : Colors.black26),
              const SizedBox(height: 12),
              Text(
                '${p.t('no_results')}: "$_searchQuery"',
                style: GoogleFonts.inter(fontSize: 13, color: textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _markaSectionHeader('${p.t('find')} (${results.whereType<Padding>().length})'),
        ...results,
      ],
    );
  }

  Widget _markaSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _markaDivider(bool isDark) {
    return Divider(
      height: 24,
      thickness: 1,
      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
    );
  }

  // ── Marka Setting Tile Component ──
  Widget _buildMarkaSettingTile({
    required String settingId,
    required String title,
    required String description,
    required bool isDark,
    required Color accentPurple,
    required Color titlePurple,
    required Widget control,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: titlePurple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentPurple.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        settingId,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: accentPurple,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.45,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          control,
        ],
      ),
    );
  }

  // ── Shortcut Item ──
  Widget _buildMarkaShortcutTile(String title, String settingId, String mod, String key, bool isDark, Color accentPurple) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  settingId,
                  style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: isDark ? Colors.white38 : Colors.black45),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accentPurple.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: accentPurple.withOpacity(0.3)),
            ),
            child: Text(
              '$mod + $key',
              style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold, color: accentPurple),
            ),
          ),
        ],
      ),
    );
  }

  // ── Language Dropdown Selector ──
  Widget _buildLanguageDropdown(MarkdownProvider provider, bool isDark, Color accentPurple) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accentPurple.withOpacity(0.3)),
      ),
      child: DropdownButton<String>(
        value: provider.locale,
        underline: const SizedBox(),
        dropdownColor: isDark ? const Color(0xFF181825) : Colors.white,
        onChanged: (v) => v != null ? provider.updateLocale(v) : null,
        items: [
          {'code': 'zh', 'label': '🇨🇳 简体中文'},
          {'code': 'en', 'label': '🇺🇸 English'},
        ].map((l) => DropdownMenuItem(
          value: l['code'],
          child: Text(l['label']!, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
        )).toList(),
      ),
    );
  }

  // ── Theme Purple Controls ──
  Widget _markaSwitch(bool value, ValueChanged<bool> onChanged, bool isDark, Color accentPurple) {
    return Transform.scale(
      scale: 0.8,
      child: Switch(
        value: value,
        activeTrackColor: accentPurple.withOpacity(0.4),
        activeThumbColor: accentPurple,
        inactiveThumbColor: Colors.grey.shade400,
        inactiveTrackColor: Colors.grey.withOpacity(0.2),
        onChanged: onChanged,
      ),
    );
  }

  Widget _markaBadge(String text, Color accentPurple, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: accentPurple.withOpacity(0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold, color: accentPurple),
      ),
    );
  }

  Widget _markaSizeControls(MarkdownProvider provider, bool isDark, Color accentPurple) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniBtn(Icons.remove_rounded, () => provider.updateFontSize(provider.fontSize - 1), isDark, accentPurple),
        const SizedBox(width: 6),
        _markaBadge('${provider.fontSize.toInt()} px', accentPurple, isDark),
        const SizedBox(width: 6),
        _miniBtn(Icons.add_rounded, () => provider.updateFontSize(provider.fontSize + 1), isDark, accentPurple),
      ],
    );
  }

  Widget _buildLineHeightSlider(MarkdownProvider p, Color accentPurple, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          child: SliderTheme(
            data: const SliderThemeData(
              trackHeight: 2.5,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 4.5),
            ),
            child: Slider(
              value: p.lineHeight,
              min: 1.0,
              max: 2.5,
              divisions: 15,
              activeColor: accentPurple,
              onChanged: (v) => p.updateLineHeight(v),
            ),
          ),
        ),
        const SizedBox(width: 4),
        _markaBadge('${p.lineHeight.toStringAsFixed(2)}x', accentPurple, isDark),
      ],
    );
  }

  Widget _buildPaddingSlider(MarkdownProvider p, Color accentPurple, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          child: SliderTheme(
            data: const SliderThemeData(
              trackHeight: 2.5,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 4.5),
            ),
            child: Slider(
              value: p.editorPadding,
              min: 16.0,
              max: 96.0,
              divisions: 20,
              activeColor: accentPurple,
              onChanged: (v) => p.updateEditorPadding(v),
            ),
          ),
        ),
        const SizedBox(width: 4),
        _markaBadge('${p.editorPadding.toInt()} px', accentPurple, isDark),
      ],
    );
  }

  Widget _buildFontDropdown(MarkdownProvider provider, bool isDark, Color accentPurple) {
    final availableFonts = ['Inter', 'Fira Code', 'JetBrains Mono', 'Roboto Mono', 'Source Code Pro'];
    final currentFont = availableFonts.contains(provider.fontFamily) ? provider.fontFamily : 'Inter';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accentPurple.withOpacity(0.3)),
      ),
      child: DropdownButton<String>(
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

  Widget _miniBtn(IconData icon, VoidCallback tap, bool isDark, Color accentPurple) {
    return InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: accentPurple.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 13, color: accentPurple),
      ),
    );
  }

  Widget _buildMarkaFooter(BuildContext context, bool isDark, MarkdownProvider provider, Color headerBg, Color borderColor, Color accentPurple) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: headerBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentPurple,
              foregroundColor: isDark ? const Color(0xFF11111B) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              elevation: 0,
            ),
            child: Text(
              provider.t('close'),
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
