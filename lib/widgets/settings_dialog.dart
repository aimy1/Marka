import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:provider/provider.dart';
import '../providers/markdown_provider.dart';

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
    final glassColor = isDark ? const Color(0xFF181825).withOpacity(0.9) : const Color(0xFFFFFFFF).withOpacity(0.9);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 720,
            height: 520,
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 40,
                  offset: const Offset(0, 15),
                )
              ],
            ),
            child: Row(
              children: [
                // ── Sidebar ──
                _buildSidebar(provider, isDark, accentColor),
                
                // ── Vertical Divider ──
                Container(width: 1, color: isDark ? Colors.white10 : Colors.black12),
                
                // ── Content Area ──
                Expanded(
                  child: Column(
                    children: [
                      _buildContentHeader(provider, isDark),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
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
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          _navItem(0, p.t('general'), Icons.settings_rounded, accentColor, isDark),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? accent.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isSelected ? accent : (isDark ? Colors.white38 : Colors.black38)),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
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
      case 0: // General
        return Column(
          children: [
            _sectionTitle(p.t('general')),
            _buildLanguageDropdown(p, isDark),
            _settingTile(p.t('theme'), Icons.palette_outlined, isDark, Switch(
              value: isDark,
              activeColor: accentColor,
              onChanged: (v) => AdaptiveTheme.of(context).toggleThemeMode(),
            )),
            _settingTile(p.t('auto_save'), Icons.auto_awesome_rounded, isDark, Switch(
              value: p.autoSave,
              activeColor: accentColor,
              onChanged: (v) => p.toggleAutoSave(),
            )),
          ],
        );
      case 1: // Editor
        return Column(
          children: [
            _sectionTitle(p.t('editor')),
            _buildFontDropdown(p, isDark),
            _settingTile(p.t('font_size'), Icons.format_size_rounded, isDark, _buildSizeControls(p, isDark)),
            _settingTile(p.t('line_height'), Icons.format_line_spacing_rounded, isDark, _buildLineHeightSlider(p, accentColor)),

          ],
        );
      case 2: // Appearance
        return Column(
          children: [
            _sectionTitle(p.t('appearance')),
            _settingTile(p.t('editor_padding'), Icons.horizontal_distribute_rounded, isDark, _buildPaddingSlider(p, accentColor)),
            _settingTile(p.t('word_wrap'), Icons.wrap_text_rounded, isDark, Switch(
              value: p.isWrapped,
              activeColor: accentColor,
              onChanged: (v) => p.toggleWrap(),
            )),
            _settingTile(p.t('split_screen'), Icons.splitscreen_rounded, isDark, Switch(
              value: p.isSplitScreen,
              activeColor: accentColor,
              onChanged: (v) => p.toggleSplitScreen(),
            )),
            _settingTile(p.t('show_toolbar'), Icons.construction_rounded, isDark, Switch(
              value: p.showToolbar,
              activeColor: accentColor,
              onChanged: (v) => p.toggleToolbar(),
            )),
          ],
        );
      case 3: // Advanced
        return Column(
          children: [
            _sectionTitle(p.t('advanced')),
            _settingTile(p.t('tab_size'), Icons.keyboard_tab_rounded, isDark, _buildTabDropdown(p, isDark)),
            _settingTile(p.t('auto_pairing'), Icons.code_rounded, isDark, Switch(
              value: p.autoPairing,
              activeColor: accentColor,
              onChanged: (v) => p.toggleAutoPairing(),
            )),
            _settingTile(p.t('sync_scroll'), Icons.sync_rounded, isDark, Switch(
              value: p.isSyncScroll,
              activeColor: accentColor,
              onChanged: (v) => p.toggleSyncScroll(),
            )),
            _settingTile(p.t('smooth_scrolling'), Icons.mouse_rounded, isDark, Switch(
              value: p.smoothScrolling,
              activeColor: accentColor,
              onChanged: (v) => p.toggleSmoothScrolling(),
            )),
          ],
        );
      default:
        return Column(
          children: [
            _sectionTitle(p.t('about')),
            const SizedBox(height: 20),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset('markd.logo.jpg', width: 80, height: 80, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Marka IDE',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                p.t('about_desc'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : Colors.black54),
              ),
            ),
            const SizedBox(height: 40),
            _settingTile(p.t('about_version'), Icons.info_outline_rounded, isDark, Text('v3.3.6', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87))),

            _settingTile(p.t('about_author'), Icons.person_outline_rounded, isDark, Text('Asniya', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87))),

            _settingTile(p.t('about_license'), Icons.description_outlined, isDark, Text('MIT License', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87))),
            _settingTile(p.t('about_github'), Icons.link_rounded, isDark, SelectableText('github.com/aimy1/Marka', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5)))),
          ],
        );
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Text(title.toUpperCase(), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.grey)),
          const SizedBox(width: 16),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _settingTile(String label, IconData icon, bool isDark, Widget action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? Colors.white24 : Colors.black26),
          const SizedBox(width: 16),
          Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87)),
          const Spacer(),
          action,
        ],
      ),
    );
  }

  Widget _buildContentHeader(MarkdownProvider p, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 24, 16),
      child: Row(
        children: [
          Text([p.t('general'), p.t('editor'), p.t('appearance'), p.t('advanced'), p.t('about')][_selectedIndex], 
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black)),
          const Spacer(),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 20)),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark, MarkdownProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(provider.t('close'), style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  // ── Existing Dropdowns & Sliders (Migrated) ──
  #define MyAppPublisher "Asniya"

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
    return _settingTile(provider.t('font_family'), Icons.font_download_outlined, isDark, DropdownButton<String>(
      value: provider.fontFamily,
      underline: const SizedBox(),
      dropdownColor: isDark ? const Color(0xFF1E1E2F) : Colors.white,
      onChanged: (v) => v != null ? provider.updateFontFamily(v) : null,
      items: ['Inter', 'Fira Code', 'JetBrains Mono', 'Roboto Mono']
          .map((f) => DropdownMenuItem(
        value: f,
        child: Text(f, style: GoogleFonts.getFont(f, fontSize: 13)),
      )).toList(),
    ));
  }

  Widget _buildSizeControls(MarkdownProvider provider, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniBtn(Icons.remove_rounded, () => provider.updateFontSize(provider.fontSize - 1), isDark),
        const SizedBox(width: 8),
        Text('${provider.fontSize.toInt()}', style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(width: 8),
        _miniBtn(Icons.add_rounded, () => provider.updateFontSize(provider.fontSize + 1), isDark),
      ],
    );
  }

  Widget _buildLineHeightSlider(MarkdownProvider p, Color accent) {
    return SizedBox(width: 100, child: Slider(value: p.lineHeight, min: 1.0, max: 2.5, divisions: 15, activeColor: accent, onChanged: (v) => p.updateLineHeight(v)));
  }

  Widget _buildPaddingSlider(MarkdownProvider p, Color accent) {
    return SizedBox(width: 100, child: Slider(value: p.editorPadding, min: 16.0, max: 96.0, divisions: 20, activeColor: accent, onChanged: (v) => p.updateEditorPadding(v)));
  }

  Widget _buildTabDropdown(MarkdownProvider p, bool isDark) {
    return DropdownButton<int>(
      value: p.tabSize,
      underline: const SizedBox(),
      onChanged: (v) => v != null ? p.updateTabSize(v) : null,
      items: [2, 4].map((s) => DropdownMenuItem(value: s, child: Text('$s ${p.t('spaces')}', style: GoogleFonts.inter(fontSize: 13)))).toList(),
    );

  }

  Widget _miniBtn(IconData icon, VoidCallback tap, bool isDark) {
    return InkWell(onTap: tap, borderRadius: BorderRadius.circular(6), child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(6)), child: Icon(icon, size: 14)));
  }
}
