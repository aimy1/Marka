import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:provider/provider.dart';
import '../providers/markdown_provider.dart';

/// Marka IDE v3.3.10 - Professional Settings Modal
/// Features Modern Card Grouping, Value Feedback Badges, and Shortcut Reference Cheat Sheet.
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarkdownProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF);
    final glassColor = isDark ? const Color(0xFF181825).withOpacity(0.92) : const Color(0xFFFFFFFF).withOpacity(0.92);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 760,
            height: 560,
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 40,
                  offset: const Offset(0, 15),
                )
              ],
            ),
            child: Row(
              children: [
                // ── Modern Navigation Sidebar ──
                _buildSidebar(provider, isDark, accentColor),
                
                // ── Vertical Divider ──
                Container(width: 1, color: isDark ? Colors.white10 : Colors.black12),
                
                // ── Main Content Area ──
                Expanded(
                  child: Column(
                    children: [
                      _buildContentHeader(provider, isDark),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
                          child: _buildContent(provider, isDark, accentColor),
                        ),
                      ),
                      _buildFooter(context, isDark, provider),
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

  Widget _buildSidebar(MarkdownProvider p, bool isDark, Color accentColor) {
    return Container(
      width: 210,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.tune_rounded, size: 18, color: accentColor),
                ),
                const SizedBox(width: 10),
                Text(
                  p.t('settings'),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          _navItem(0, p.t('general'), Icons.tune_rounded, accentColor, isDark),
          _navItem(1, p.t('editor'), Icons.edit_note_rounded, accentColor, isDark),
          _navItem(2, p.t('appearance'), Icons.space_dashboard_rounded, accentColor, isDark),
          _navItem(3, p.t('advanced'), Icons.terminal_rounded, accentColor, isDark),
          const Spacer(),
          _navItem(4, p.t('about'), Icons.info_outline_rounded, accentColor, isDark),
        ],
      ),
    );
  }

  Widget _navItem(int index, String label, IconData icon, Color accent, bool isDark) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected 
                ? (isDark ? accent.withOpacity(0.18) : accent.withOpacity(0.12))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected 
                ? Border.all(color: accent.withOpacity(0.3), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isSelected ? accent : (isDark ? Colors.white38 : Colors.black38)),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? accent : (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(MarkdownProvider p, bool isDark, Color accentColor) {
    switch (_selectedIndex) {
      case 0: // General Settings
        return Column(
          children: [
            _buildCardGroup(
              title: p.t('general'),
              isDark: isDark,
              children: [
                _buildLanguageDropdown(p, isDark),
                _divider(isDark),
                _settingTile(
                  p.t('theme'), 
                  Icons.palette_outlined, 
                  isDark, 
                  _buildCustomSwitch(
                    value: isDark,
                    accentColor: accentColor,
                    onChanged: (v) => AdaptiveTheme.of(context).toggleThemeMode(),
                  ),
                ),
                _divider(isDark),
                _settingTile(
                  p.t('auto_save'), 
                  Icons.auto_awesome_rounded, 
                  isDark, 
                  _buildCustomSwitch(
                    value: p.autoSave,
                    accentColor: accentColor,
                    onChanged: (v) => p.toggleAutoSave(),
                  ),
                ),
              ],
            ),
          ],
        );

      case 1: // Editor Settings
        return Column(
          children: [
            _buildCardGroup(
              title: p.t('typography'),
              isDark: isDark,
              children: [
                _buildFontDropdown(p, isDark),
                _divider(isDark),
                _settingTile(
                  p.t('font_size'), 
                  Icons.format_size_rounded, 
                  isDark, 
                  _buildSizeControls(p, isDark, accentColor),
                ),
                _divider(isDark),
                _settingTile(
                  p.t('line_height'), 
                  Icons.format_line_spacing_rounded, 
                  isDark, 
                  _buildLineHeightSlider(p, accentColor, isDark),
                ),
              ],
            ),
          ],
        );

      case 2: // Appearance Settings
        return Column(
          children: [
            _buildCardGroup(
              title: p.t('layout_options'),
              isDark: isDark,
              children: [
                _settingTile(
                  p.t('editor_padding'), 
                  Icons.horizontal_distribute_rounded, 
                  isDark, 
                  _buildPaddingSlider(p, accentColor, isDark),
                ),
                _divider(isDark),
                _settingTile(
                  p.t('word_wrap'), 
                  Icons.wrap_text_rounded, 
                  isDark, 
                  _buildCustomSwitch(
                    value: p.isWrapped,
                    accentColor: accentColor,
                    onChanged: (v) => p.toggleWrap(),
                  ),
                ),
                _divider(isDark),
                _settingTile(
                  p.t('split_screen'), 
                  Icons.splitscreen_rounded, 
                  isDark, 
                  _buildCustomSwitch(
                    value: p.isSplitScreen,
                    accentColor: accentColor,
                    onChanged: (v) => p.toggleSplitScreen(),
                  ),
                ),
                _divider(isDark),
                _settingTile(
                  p.t('show_toolbar'), 
                  Icons.construction_rounded, 
                  isDark, 
                  _buildCustomSwitch(
                    value: p.showToolbar,
                    accentColor: accentColor,
                    onChanged: (v) => p.toggleToolbar(),
                  ),
                ),
                _divider(isDark),
                _settingTile(
                  p.t('show_line_numbers'), 
                  Icons.format_list_numbered_rounded, 
                  isDark, 
                  _buildCustomSwitch(
                    value: p.showLineNumbers,
                    accentColor: accentColor,
                    onChanged: (v) => p.toggleLineNumbers(),
                  ),
                ),
                _divider(isDark),
                _settingTile(
                  p.t('show_grid_lines'), 
                  Icons.grid_on_rounded, 
                  isDark, 
                  _buildCustomSwitch(
                    value: p.showGridLines,
                    accentColor: accentColor,
                    onChanged: (v) => p.toggleGridLines(),
                  ),
                ),
                _divider(isDark),
                _settingTile(
                  p.t('line_highlight'), 
                  Icons.border_horizontal_rounded, 
                  isDark, 
                  _buildCustomSwitch(
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
            _buildCardGroup(
              title: p.t('editor_behavior'),
              isDark: isDark,
              children: [
                _settingTile(p.t('tab_size'), Icons.keyboard_tab_rounded, isDark, _buildTabDropdown(p, isDark)),
                _divider(isDark),
                _settingTile(
                  p.t('auto_pairing'), 
                  Icons.code_rounded, 
                  isDark, 
                  _buildCustomSwitch(
                    value: p.autoPairing,
                    accentColor: accentColor,
                    onChanged: (v) => p.toggleAutoPairing(),
                  ),
                ),
                _divider(isDark),
                _settingTile(
                  p.t('sync_scroll'), 
                  Icons.sync_rounded, 
                  isDark, 
                  _buildCustomSwitch(
                    value: p.isSyncScroll,
                    accentColor: accentColor,
                    onChanged: (v) => p.toggleSyncScroll(),
                  ),
                ),
                _divider(isDark),
                _settingTile(
                  p.t('smooth_scrolling'), 
                  Icons.mouse_rounded, 
                  isDark, 
                  _buildCustomSwitch(
                    value: p.smoothScrolling,
                    accentColor: accentColor,
                    onChanged: (v) => p.toggleSmoothScrolling(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCardGroup(
              title: p.t('shortcuts'),
              isDark: isDark,
              children: [
                _buildShortcutTile(p.t('shortcut_save'), 'Ctrl + S', isDark, accentColor),
                _divider(isDark),
                _buildShortcutTile(p.t('shortcut_find'), 'Ctrl + F', isDark, accentColor),
                _divider(isDark),
                _buildShortcutTile(p.t('shortcut_bold'), 'Ctrl + B', isDark, accentColor),
                _divider(isDark),
                _buildShortcutTile(p.t('shortcut_italic'), 'Ctrl + I', isDark, accentColor),
                _divider(isDark),
                _buildShortcutTile(p.t('shortcut_link'), 'Ctrl + L', isDark, accentColor),
                _divider(isDark),
                _buildShortcutTile(p.t('shortcut_comment'), 'Ctrl + /', isDark, accentColor),
              ],
            ),
          ],
        );

      default: // About Section
        return Column(
          children: [
            _buildCardGroup(
              title: p.t('about'),
              isDark: isDark,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset('markd.logo.jpg', width: 72, height: 72, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Marka IDE',
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    p.t('about_desc'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12.5, height: 1.5, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                ),
                const SizedBox(height: 20),
                _divider(isDark),
                _settingTile(p.t('about_version'), Icons.info_outline_rounded, isDark, _badge('v3.3.10', accentColor, isDark)),
                _divider(isDark),
                _settingTile(p.t('about_author'), Icons.person_outline_rounded, isDark, Text('Asniya', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87))),
                _divider(isDark),
                _settingTile(p.t('about_license'), Icons.description_outlined, isDark, Text('MIT License', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87))),
                _divider(isDark),
                _settingTile(p.t('about_github'), Icons.link_rounded, isDark, SelectableText('github.com/aimy1/Marka', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor))),
              ],
            ),
          ],
        );
    }
  }

  // ── Card Container Helper ──
  Widget _buildCardGroup({required String title, required bool isDark, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.035) : Colors.black.withOpacity(0.025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(height: 16, thickness: 1, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04));
  }

  Widget _settingTile(String label, IconData icon, bool isDark, Widget action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 17, color: isDark ? Colors.white38 : Colors.black38),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label, 
              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87),
            ),
          ),
          action,
        ],
      ),
    );
  }

  Widget _buildShortcutTile(String actionLabel, String keyCombo, bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: Row(
        children: [
          Text(
            actionLabel,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            ),
            child: Text(
              keyCombo,
              style: GoogleFonts.jetBrainsMono(fontSize: 11.5, fontWeight: FontWeight.bold, color: accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomSwitch({required bool value, required Color accentColor, required ValueChanged<bool> onChanged}) {
    return Transform.scale(
      scale: 0.85,
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

  Widget _badge(String text, Color accent, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.bold, color: accent),
      ),
    );
  }

  Widget _buildContentHeader(MarkdownProvider p, bool isDark) {
    final titles = [p.t('general'), p.t('editor'), p.t('appearance'), p.t('advanced'), p.t('about')];
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 20, 12),
      child: Row(
        children: [
          Text(
            titles[_selectedIndex], 
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context), 
            icon: Icon(Icons.close_rounded, size: 20, color: isDark ? Colors.white54 : Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark, MarkdownProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text(
              provider.t('close'), 
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dropdowns & Sliders ──

  Widget _buildLanguageDropdown(MarkdownProvider provider, bool isDark) {
    return _settingTile(provider.t('language'), Icons.translate_rounded, isDark, DropdownButton<String>(
      value: provider.locale,
      underline: const SizedBox(),
      dropdownColor: isDark ? const Color(0xFF1E1E2F) : Colors.white,
      onChanged: (v) => v != null ? provider.updateLocale(v) : null,
      items: [
        {'code': 'en', 'label': '🇺🇸 English'},
        {'code': 'zh', 'label': '🇨🇳 简体中文'},
      ].map((l) => DropdownMenuItem(
        value: l['code'],
        child: Text(l['label']!, style: GoogleFonts.inter(fontSize: 13)),
      )).toList(),
    ));
  }

  Widget _buildFontDropdown(MarkdownProvider provider, bool isDark) {
    final availableFonts = ['Inter', 'Fira Code', 'JetBrains Mono', 'Roboto Mono', 'Source Code Pro'];
    final currentFont = availableFonts.contains(provider.fontFamily) ? provider.fontFamily : 'Inter';
    return _settingTile(provider.t('font_family'), Icons.font_download_outlined, isDark, DropdownButton<String>(
      value: currentFont,
      underline: const SizedBox(),
      dropdownColor: isDark ? const Color(0xFF1E1E2F) : Colors.white,
      onChanged: (v) => v != null ? provider.updateFontFamily(v) : null,
      items: availableFonts
          .map((f) => DropdownMenuItem(
        value: f,
        child: Text(f, style: GoogleFonts.getFont(f, fontSize: 13)),
      )).toList(),
    ));
  }

  Widget _buildSizeControls(MarkdownProvider provider, bool isDark, Color accent) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniBtn(Icons.remove_rounded, () => provider.updateFontSize(provider.fontSize - 1), isDark),
        const SizedBox(width: 8),
        _badge('${provider.fontSize.toInt()} px', accent, isDark),
        const SizedBox(width: 8),
        _miniBtn(Icons.add_rounded, () => provider.updateFontSize(provider.fontSize + 1), isDark),
      ],
    );
  }

  Widget _buildLineHeightSlider(MarkdownProvider p, Color accent, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 90, 
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
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
        _badge('${p.lineHeight.toStringAsFixed(2)}x', accent, isDark),
      ],
    );
  }

  Widget _buildPaddingSlider(MarkdownProvider p, Color accent, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 90, 
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
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
        _badge('${p.editorPadding.toInt()} px', accent, isDark),
      ],
    );
  }

  Widget _buildTabDropdown(MarkdownProvider p, bool isDark) {
    return DropdownButton<int>(
      value: p.tabSize,
      underline: const SizedBox(),
      dropdownColor: isDark ? const Color(0xFF1E1E2F) : Colors.white,
      onChanged: (v) => v != null ? p.updateTabSize(v) : null,
      items: [2, 4].map((s) => DropdownMenuItem(value: s, child: Text('$s ${p.t('spaces')}', style: GoogleFonts.inter(fontSize: 13)))).toList(),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback tap, bool isDark) {
    return InkWell(
      onTap: tap, 
      borderRadius: BorderRadius.circular(6), 
      child: Container(
        padding: const EdgeInsets.all(4), 
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), 
          borderRadius: BorderRadius.circular(6),
        ), 
        child: Icon(icon, size: 14),
      ),
    );
  }
}
