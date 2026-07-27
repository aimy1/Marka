import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:provider/provider.dart';
import '../providers/markdown_provider.dart';

/// Marka IDE v3.6.0 - VS Code Settings Editor Architecture
/// Engineered after the VS Code Preferences (Settings Editor) UI/UX design specification.
/// Features Category Tree, Setting IDs (e.g. editor.fontSize), Scope Tabs (User/Workspace), and Search Filtering.
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  String _selectedCategory = 'commonly_used';
  String _searchQuery = '';
  int _scopeIndex = 0; // 0: User, 1: Workspace
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

    // VS Code Colors
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F3F3);
    final sidebarBg = isDark ? const Color(0xFF252526) : const Color(0xFFE8E8E8);
    final contentBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final accentColor = isDark ? const Color(0xFF007ACC) : const Color(0xFF0066B8);
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFCCCCCC);
    final textMuted = isDark ? const Color(0xFFCCCCCC) : const Color(0xFF616161);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4), // VS Code Crisp 4px
        child: Container(
          width: 900,
          height: 640,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.6 : 0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            children: [
              // ── VS Code Top Header & Search Bar ──
              _buildVSCodeHeader(provider, isDark, accentColor, borderColor, textMuted),
              
              Container(height: 1, color: borderColor),
              
              // ── Main Body (Sidebar Tree + Setting Canvas) ──
              Expanded(
                child: Row(
                  children: [
                    // Left VS Code Category Tree
                    _buildCategoryTree(provider, isDark, accentColor, sidebarBg, borderColor, textMuted),
                    
                    Container(width: 1, color: borderColor),
                    
                    // Right Settings Item List
                    Expanded(
                      child: Container(
                        color: contentBg,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                          child: _searchQuery.isNotEmpty
                              ? _buildVSCodeSearchResults(provider, isDark, accentColor, textMuted)
                              : _buildVSCodeCategoryContent(provider, isDark, accentColor, textMuted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Footer Bar ──
              _buildVSCodeFooter(context, isDark, provider, borderColor),
            ],
          ),
        ),
      ),
    );
  }

  // ── VS Code Top Header & Scope Bar ──
  Widget _buildVSCodeHeader(MarkdownProvider p, bool isDark, Color accent, Color borderColor, Color textMuted) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
      color: isDark ? const Color(0xFF252526) : const Color(0xFFF3F3F3),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Settings',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 20),
              
              // VS Code Search Input
              Expanded(
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3C3C3C) : Colors.white,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: isDark ? const Color(0xFF007ACC) : const Color(0xFF0066B8),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Search settings (e.g. editor.fontSize, files.autoSave)',
                      hintStyle: GoogleFonts.inter(fontSize: 12.5, color: isDark ? Colors.white38 : Colors.black38),
                      prefixIcon: Icon(Icons.search_rounded, size: 16, color: isDark ? Colors.white70 : Colors.black54),
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 7),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, size: 18, color: textMuted),
                tooltip: 'Close (Esc)',
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // VS Code Scope Tabs (User / Workspace)
          Row(
            children: [
              _scopeTab('User', 0, isDark, accent),
              const SizedBox(width: 16),
              _scopeTab('Workspace', 1, isDark, accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scopeTab(String title, int index, bool isDark, Color accent) {
    final isSelected = _scopeIndex == index;
    return InkWell(
      onTap: () => setState(() => _scopeIndex = index),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white54 : Colors.black54),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 32,
            color: isSelected ? accent : Colors.transparent,
          ),
        ],
      ),
    );
  }

  // ── VS Code Category Tree Sidebar ──
  Widget _buildCategoryTree(MarkdownProvider p, bool isDark, Color accent, Color sidebarBg, Color borderColor, Color textMuted) {
    return Container(
      width: 230,
      color: sidebarBg,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: ListView(
        children: [
          _treeCategoryHeader('COMMONLY USED'),
          _treeNode('commonly_used', 'Commonly Used', Icons.star_outline_rounded, isDark, accent),
          
          const SizedBox(height: 12),
          _treeCategoryHeader('TEXT EDITOR'),
          _treeNode('editor_font', 'Font', Icons.font_download_outlined, isDark, accent),
          _treeNode('editor_formatting', 'Formatting & Line', Icons.format_align_left_rounded, isDark, accent),
          _treeNode('editor_cursor', 'Cursor & Gutter', Icons.space_bar_rounded, isDark, accent),
          
          const SizedBox(height: 12),
          _treeCategoryHeader('WORKBENCH'),
          _treeNode('workbench_appearance', 'Appearance', Icons.palette_outlined, isDark, accent),
          _treeNode('workbench_layout', 'Layout & View', Icons.splitscreen_rounded, isDark, accent),
          
          const SizedBox(height: 12),
          _treeCategoryHeader('FEATURES'),
          _treeNode('features_files', 'Files & Auto Save', Icons.save_outlined, isDark, accent),
          _treeNode('features_shortcuts', 'Keyboard Shortcuts', Icons.keyboard_outlined, isDark, accent),
          _treeNode('features_about', 'About Marka', Icons.info_outline_rounded, isDark, accent),
        ],
      ),
    );
  }

  Widget _treeCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 4, bottom: 6),
      child: Text(
        title,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _treeNode(String id, String label, IconData icon, bool isDark, Color accent) {
    final isSelected = _selectedCategory == id && _searchQuery.isEmpty;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = id;
          _searchQuery = '';
          _searchController.clear();
        });
      },
      borderRadius: BorderRadius.circular(2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF37373D) : const Color(0xFFD0D0D0)) : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white54 : Colors.black54),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── VS Code Category Content ──
  Widget _buildVSCodeCategoryContent(MarkdownProvider p, bool isDark, Color accent, Color textMuted) {
    switch (_selectedCategory) {
      case 'commonly_used':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _vscodeSectionHeader('Commonly Used'),
            _buildVSCodeSettingTile(
              settingId: 'files.autoSave',
              title: 'Files: Auto Save',
              description: 'Controls auto save of dirty files. Automatically saves content changes to disk.',
              isDark: isDark,
              accent: accent,
              control: _vscodeCheckbox(p.autoSave, (v) => p.toggleAutoSave(), isDark, accent),
            ),
            _vscodeDivider(isDark),
            _buildVSCodeSettingTile(
              settingId: 'editor.fontSize',
              title: 'Editor: Font Size',
              description: 'Controls the font size in pixels for the main Markdown editor workspace.',
              isDark: isDark,
              accent: accent,
              control: _vscodeSizeControls(p, isDark, accent),
            ),
            _vscodeDivider(isDark),
            _buildVSCodeSettingTile(
              settingId: 'editor.fontFamily',
              title: 'Editor: Font Family',
              description: 'Controls the typography font family for code syntax and text editing.',
              isDark: isDark,
              accent: accent,
              control: _buildFontDropdown(p, isDark),
            ),
            _vscodeDivider(isDark),
            _buildVSCodeSettingTile(
              settingId: 'workbench.colorTheme',
              title: 'Workbench: Color Theme',
              description: 'Specifies the color theme used in the workbench (Light / Dark Catppuccin Theme).',
              isDark: isDark,
              accent: accent,
              control: _vscodeCheckbox(isDark, (v) => AdaptiveTheme.of(context).toggleThemeMode(), isDark, accent),
            ),
          ],
        );

      case 'editor_font':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _vscodeSectionHeader('Text Editor: Font'),
            _buildVSCodeSettingTile(
              settingId: 'editor.fontFamily',
              title: 'Editor: Font Family',
              description: 'Controls the font family used in text editing canvas.',
              isDark: isDark,
              accent: accent,
              control: _buildFontDropdown(p, isDark),
            ),
            _vscodeDivider(isDark),
            _buildVSCodeSettingTile(
              settingId: 'editor.fontSize',
              title: 'Editor: Font Size',
              description: 'Controls font size in pixels (8px - 32px range).',
              isDark: isDark,
              accent: accent,
              control: _vscodeSizeControls(p, isDark, accent),
            ),
            _vscodeDivider(isDark),
            _buildVSCodeSettingTile(
              settingId: 'editor.lineHeight',
              title: 'Editor: Line Height',
              description: 'Controls the line height multiplier for text paragraphs.',
              isDark: isDark,
              accent: accent,
              control: _buildLineHeightSlider(p, accent, isDark),
            ),
          ],
        );

      case 'editor_formatting':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _vscodeSectionHeader('Text Editor: Formatting & Line'),
            _buildVSCodeSettingTile(
              settingId: 'editor.wordWrap',
              title: 'Editor: Word Wrap',
              description: 'Controls how lines should wrap. Enable soft wrap at viewport boundary.',
              isDark: isDark,
              accent: accent,
              control: _vscodeCheckbox(p.isWrapped, (v) => p.toggleWrap(), isDark, accent),
            ),
            _vscodeDivider(isDark),
            _buildVSCodeSettingTile(
              settingId: 'editor.tabSize',
              title: 'Editor: Tab Size',
              description: 'The number of spaces a tab is equal to when indenting.',
              isDark: isDark,
              accent: accent,
              control: _buildTabDropdown(p, isDark),
            ),
            _vscodeDivider(isDark),
            _buildVSCodeSettingTile(
              settingId: 'editor.autoClosingBrackets',
              title: 'Editor: Auto Closing Brackets',
              description: 'Controls whether the editor should automatically close quotes and brackets.',
              isDark: isDark,
              accent: accent,
              control: _vscodeCheckbox(p.autoPairing, (v) => p.toggleAutoPairing(), isDark, accent),
            ),
          ],
        );

      case 'editor_cursor':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _vscodeSectionHeader('Text Editor: Cursor & Gutter'),
            _buildVSCodeSettingTile(
              settingId: 'editor.lineNumbers',
              title: 'Editor: Line Numbers',
              description: 'Controls the display of vertical line numbers in line gutter.',
              isDark: isDark,
              accent: accent,
              control: _vscodeCheckbox(p.showLineNumbers, (v) => p.toggleLineNumbers(), isDark, accent),
            ),
            _vscodeDivider(isDark),
            _buildVSCodeSettingTile(
              settingId: 'editor.renderLineHighlight',
              title: 'Editor: Render Line Highlight',
              description: 'Controls how the editor renders line highlight on current line.',
              isDark: isDark,
              accent: accent,
              control: _vscodeCheckbox(p.showLineHighlight, (v) => p.toggleLineHighlight(), isDark, accent),
            ),
            _vscodeDivider(isDark),
            _buildVSCodeSettingTile(
              settingId: 'editor.gridLines',
              title: 'Editor: Render Grid Reference Lines',
              description: 'Displays background grid guidelines for layout alignment.',
              isDark: isDark,
              accent: accent,
              control: _vscodeCheckbox(p.showGridLines, (v) => p.toggleGridLines(), isDark, accent),
            ),
          ],
        );

      case 'workbench_appearance':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _vscodeSectionHeader('Workbench: Appearance'),
            _buildVSCodeSettingTile(
              settingId: 'workbench.colorTheme',
              title: 'Workbench: Color Theme',
              description: 'Switch between Dark and Light mode workbench theme.',
              isDark: isDark,
              accent: accent,
              control: _vscodeCheckbox(isDark, (v) => AdaptiveTheme.of(context).toggleThemeMode(), isDark, accent),
            ),
            _vscodeDivider(isDark),
            _buildVSCodeSettingTile(
              settingId: 'workbench.editorPadding',
              title: 'Workbench: Editor Padding',
              description: 'Horizontal padding offset around text editing canvas in pixels.',
              isDark: isDark,
              accent: accent,
              control: _buildPaddingSlider(p, accent, isDark),
            ),
            _vscodeDivider(isDark),
            _buildVSCodeSettingTile(
              settingId: 'workbench.showToolbar',
              title: 'Workbench: Show Formatting Toolbar',
              description: 'Controls visibility of top editor formatting toolbar.',
              isDark: isDark,
              accent: accent,
              control: _vscodeCheckbox(p.showToolbar, (v) => p.toggleToolbar(), isDark, accent),
            ),
          ],
        );

      case 'workbench_layout':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _vscodeSectionHeader('Workbench: Layout & View'),
            _buildVSCodeSettingTile(
              settingId: 'workbench.splitScreen',
              title: 'Workbench: Split Screen Preview',
              description: 'Controls side-by-side Markdown live preview pane.',
              isDark: isDark,
              accent: accent,
              control: _vscodeCheckbox(p.isSplitScreen, (v) => p.toggleSplitScreen(), isDark, accent),
            ),
            _vscodeDivider(isDark),
            _buildVSCodeSettingTile(
              settingId: 'workbench.smoothScrolling',
              title: 'Workbench: Smooth Scrolling',
              description: 'Controls smooth scrolling animation across editor viewports.',
              isDark: isDark,
              accent: accent,
              control: _vscodeCheckbox(p.smoothScrolling, (v) => p.toggleSmoothScrolling(), isDark, accent),
            ),
          ],
        );

      case 'features_files':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _vscodeSectionHeader('Features: Files & Auto Save'),
            _buildVSCodeSettingTile(
              settingId: 'files.autoSave',
              title: 'Files: Auto Save',
              description: 'Controls auto saving of modified documents.',
              isDark: isDark,
              accent: accent,
              control: _vscodeCheckbox(p.autoSave, (v) => p.toggleAutoSave(), isDark, accent),
            ),
            _vscodeDivider(isDark),
            _buildVSCodeSettingTile(
              settingId: 'files.syncScroll',
              title: 'Files: Sync Scroll Preview',
              description: 'Synchronize editor scroll position with live Markdown preview.',
              isDark: isDark,
              accent: accent,
              control: _vscodeCheckbox(p.isSyncScroll, (v) => p.toggleSyncScroll(), isDark, accent),
            ),
          ],
        );

      case 'features_shortcuts':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _vscodeSectionHeader('Features: Keyboard Shortcuts'),
            _buildVSCodeShortcutTile('Save Active Document', 'files.save', 'Ctrl', 'S', isDark, accent),
            _vscodeDivider(isDark),
            _buildVSCodeShortcutTile('Find and Replace', 'editor.find', 'Ctrl', 'F', isDark, accent),
            _vscodeDivider(isDark),
            _buildVSCodeShortcutTile('Format Bold Selection', 'editor.formatBold', 'Ctrl', 'B', isDark, accent),
            _vscodeDivider(isDark),
            _buildVSCodeShortcutTile('Format Italic Selection', 'editor.formatItalic', 'Ctrl', 'I', isDark, accent),
            _vscodeDivider(isDark),
            _buildVSCodeShortcutTile('Insert Link Snippet', 'editor.insertLink', 'Ctrl', 'L', isDark, accent),
            _vscodeDivider(isDark),
            _buildVSCodeShortcutTile('Toggle Line Comment', 'editor.toggleComment', 'Ctrl', '/', isDark, accent),
          ],
        );

      default: // About
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _vscodeSectionHeader('About Marka IDE'),
            const SizedBox(height: 12),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset('markd.logo.jpg', width: 48, height: 48, fit: BoxFit.cover),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marka IDE v3.6.0',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                    ),
                    Text(
                      'Industrial-Grade Markdown Editor Engine',
                      style: GoogleFonts.inter(fontSize: 11.5, color: textMuted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              p.t('about_desc'),
              style: GoogleFonts.inter(fontSize: 12, height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 16),
            _vscodeDivider(isDark),
            _buildVSCodeSettingTile(
              settingId: 'marka.version',
              title: 'Engine Release',
              description: 'Installed platform core version',
              isDark: isDark,
              accent: accent,
              control: _vscodeBadge('v3.6.0', accent, isDark),
            ),
            _vscodeDivider(isDark),
            _buildVSCodeSettingTile(
              settingId: 'marka.license',
              title: 'Distribution License',
              description: 'Open source software distribution license terms',
              isDark: isDark,
              accent: accent,
              control: Text('MIT License', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
            ),
          ],
        );
    }
  }

  // ── VS Code Search Results Filter ──
  Widget _buildVSCodeSearchResults(MarkdownProvider p, bool isDark, Color accent, Color textMuted) {
    final List<Widget> results = [];
    final q = _searchQuery.toLowerCase();

    void addResult(String settingId, String title, String description, Widget control) {
      if (settingId.toLowerCase().contains(q) || title.toLowerCase().contains(q) || description.toLowerCase().contains(q)) {
        if (results.isNotEmpty) results.add(_vscodeDivider(isDark));
        results.add(_buildVSCodeSettingTile(
          settingId: settingId,
          title: title,
          description: description,
          isDark: isDark,
          accent: accent,
          control: control,
        ));
      }
    }

    addResult('files.autoSave', 'Files: Auto Save', 'Controls auto save of modified files.', _vscodeCheckbox(p.autoSave, (v) => p.toggleAutoSave(), isDark, accent));
    addResult('editor.fontSize', 'Editor: Font Size', 'Controls the font size in pixels.', _vscodeSizeControls(p, isDark, accent));
    addResult('editor.fontFamily', 'Editor: Font Family', 'Controls the font family used in editor.', _buildFontDropdown(p, isDark));
    addResult('editor.lineHeight', 'Editor: Line Height', 'Controls the line height multiplier for text paragraphs.', _buildLineHeightSlider(p, accent, isDark));
    addResult('editor.wordWrap', 'Editor: Word Wrap', 'Controls soft wrapping of long lines to viewport bounds.', _vscodeCheckbox(p.isWrapped, (v) => p.toggleWrap(), isDark, accent));
    addResult('editor.tabSize', 'Editor: Tab Size', 'The number of spaces a tab is equal to when indenting.', _buildTabDropdown(p, isDark));
    addResult('editor.lineNumbers', 'Editor: Line Numbers', 'Controls vertical line numbers gutter.', _vscodeCheckbox(p.showLineNumbers, (v) => p.toggleLineNumbers(), isDark, accent));
    addResult('workbench.colorTheme', 'Workbench: Color Theme', 'Controls dark / light workbench color theme.', _vscodeCheckbox(isDark, (v) => AdaptiveTheme.of(context).toggleThemeMode(), isDark, accent));
    addResult('workbench.editorPadding', 'Workbench: Editor Padding', 'Horizontal padding offset around text editing canvas.', _buildPaddingSlider(p, accent, isDark));
    addResult('workbench.splitScreen', 'Workbench: Split Screen Preview', 'Controls side-by-side Markdown live preview pane.', _vscodeCheckbox(p.isSplitScreen, (v) => p.toggleSplitScreen(), isDark, accent));

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 40, color: isDark ? Colors.white24 : Colors.black26),
              const SizedBox(height: 12),
              Text(
                'No matching settings found for "$_searchQuery"',
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
        _vscodeSectionHeader('Search Results (${results.whereType<InkWell>().length / 2 + 1})'),
        ...results,
      ],
    );
  }

  Widget _vscodeSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _vscodeDivider(bool isDark) {
    return Divider(
      height: 24,
      thickness: 1,
      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
    );
  }

  // ── VS Code Setting Tile Component ──
  Widget _buildVSCodeSettingTile({
    required String settingId,
    required String title,
    required String description,
    required bool isDark,
    required Color accent,
    required Widget control,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Setting Main Title
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF4FC1FF) : const Color(0xFF0066B8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    
                    // VS Code Setting ID Code Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        settingId,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    // Setting Description
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.4,
                        color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF616161),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              control,
            ],
          ),
        ],
      ),
    );
  }

  // ── VS Code Shortcut Item ──
  Widget _buildVSCodeShortcutTile(String title, String settingId, String mod, String key, bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                ),
                Text(
                  settingId,
                  style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: isDark ? Colors.white38 : Colors.black45),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E5E5),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            ),
            child: Text(
              '$mod + $key',
              style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold, color: accent),
            ),
          ),
        ],
      ),
    );
  }

  // ── VS Code Controls ──
  Widget _vscodeCheckbox(bool value, ValueChanged<bool> onChanged, bool isDark, Color accent) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: value ? accent : (isDark ? const Color(0xFF3C3C3C) : Colors.white),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: value ? accent : (isDark ? const Color(0xFF6B6B6B) : const Color(0xFFCECECE)),
            width: 1,
          ),
        ),
        child: value
            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _vscodeBadge(String text, Color accent, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold, color: accent),
      ),
    );
  }

  Widget _vscodeSizeControls(MarkdownProvider provider, bool isDark, Color accent) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniBtn(Icons.remove_rounded, () => provider.updateFontSize(provider.fontSize - 1), isDark),
        const SizedBox(width: 6),
        _vscodeBadge('${provider.fontSize.toInt()} px', accent, isDark),
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
          width: 80,
          child: SliderTheme(
            data: const SliderThemeData(
              trackHeight: 2,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 4),
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
        _vscodeBadge('${p.lineHeight.toStringAsFixed(2)}x', accent, isDark),
      ],
    );
  }

  Widget _buildPaddingSlider(MarkdownProvider p, Color accent, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          child: SliderTheme(
            data: const SliderThemeData(
              trackHeight: 2,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 4),
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
        _vscodeBadge('${p.editorPadding.toInt()} px', accent, isDark),
      ],
    );
  }

  Widget _buildFontDropdown(MarkdownProvider provider, bool isDark) {
    final availableFonts = ['Inter', 'Fira Code', 'JetBrains Mono', 'Roboto Mono', 'Source Code Pro'];
    final currentFont = availableFonts.contains(provider.fontFamily) ? provider.fontFamily : 'Inter';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3C3C3C) : Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: isDark ? const Color(0xFF555555) : const Color(0xFFCECECE)),
      ),
      child: DropdownButton<String>(
        value: currentFont,
        underline: const SizedBox(),
        dropdownColor: isDark ? const Color(0xFF252526) : Colors.white,
        onChanged: (v) => v != null ? provider.updateFontFamily(v) : null,
        items: availableFonts
            .map((f) => DropdownMenuItem(
          value: f,
          child: Text(f, style: GoogleFonts.getFont(f, fontSize: 12)),
        )).toList(),
      ),
    );
  }

  Widget _buildTabDropdown(MarkdownProvider p, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3C3C3C) : Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: isDark ? const Color(0xFF555555) : const Color(0xFFCECECE)),
      ),
      child: DropdownButton<int>(
        value: p.tabSize,
        underline: const SizedBox(),
        dropdownColor: isDark ? const Color(0xFF252526) : Colors.white,
        onChanged: (v) => v != null ? p.updateTabSize(v) : null,
        items: [2, 4].map((s) => DropdownMenuItem(value: s, child: Text('$s spaces', style: GoogleFonts.inter(fontSize: 12)))).toList(),
      ),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback tap, bool isDark) {
    return InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF3C3C3C) : const Color(0xFFE5E5E5),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Icon(icon, size: 12),
      ),
    );
  }

  Widget _buildVSCodeFooter(BuildContext context, bool isDark, MarkdownProvider provider, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? const Color(0xFF252526) : const Color(0xFFF3F3F3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF007ACC) : const Color(0xFF0066B8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
              elevation: 0,
            ),
            child: Text(
              provider.t('close'),
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
