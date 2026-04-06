import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:provider/provider.dart';
import '../providers/markdown_provider.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarkdownProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF);
    final glassColor = isDark ? const Color(0xFF1E1E2E).withOpacity(0.7) : const Color(0xFFFFFFFF).withOpacity(0.7);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 520,
            constraints: const BoxConstraints(maxHeight: 700),
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Premium Header
                _buildHeader(context, provider, isDark, accentColor),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSection(
                          provider.t('appearance'), 
                          accentColor,
                          [
                            _buildSettingRow(
                              provider.t('language'),
                              Icons.translate_rounded,
                              _buildLanguageDropdown(provider, isDark),
                              isDark
                            ),
                            _buildSettingRow(
                              provider.t('theme'),
                              Icons.palette_outlined,
                              Switch(
                                value: isDark,
                                activeColor: accentColor,
                                onChanged: (v) => AdaptiveTheme.of(context).toggleThemeMode(),
                              ),
                              isDark
                            ),
                          ],
                          isDark
                        ),
                        
                        const SizedBox(height: 20),
                        _buildSection(
                          provider.t('typography'), 
                          accentColor,
                          [
                            _buildSettingRow(
                              provider.t('font_family'),
                              Icons.font_download_outlined,
                              _buildFontDropdown(provider, isDark),
                              isDark
                            ),
                            _buildSettingRow(
                              provider.t('font_size'),
                              Icons.format_size_rounded,
                              _buildSizeControls(provider, isDark),
                              isDark
                            ),
                            _buildSettingRow(
                              provider.t('line_height'),
                              Icons.format_line_spacing_rounded,
                              _buildLineHeightSlider(provider, accentColor),
                              isDark
                            ),
                            _buildSettingRow(
                              provider.t('editor_padding'),
                              Icons.horizontal_distribute_rounded,
                              _buildPaddingSlider(provider, accentColor),
                              isDark
                            ),
                          ],
                          isDark
                        ),
                        
                        const SizedBox(height: 20),
                        _buildSection(
                          provider.t('pro_features'), 
                          accentColor,
                          [
                            _buildSwitchItem(provider.t('sync_scroll'), Icons.sync_rounded, provider.isSyncScroll, (v) => provider.toggleSyncScroll(), isDark, accentColor),
                            _buildSwitchItem(provider.t('show_toolbar'), Icons.construction_rounded, provider.showToolbar, (v) => provider.toggleToolbar(), isDark, accentColor),
                            _buildSwitchItem(provider.t('auto_save'), Icons.auto_awesome_rounded, provider.autoSave, (v) => provider.toggleAutoSave(), isDark, accentColor),
                            _buildSwitchItem(provider.t('auto_pairing'), Icons.code_rounded, provider.autoPairing, (v) => provider.toggleAutoPairing(), isDark, accentColor),
                            _buildSwitchItem(provider.t('line_highlight'), Icons.highlight_rounded, provider.showLineHighlight, (v) => provider.toggleLineHighlight(), isDark, accentColor),
                            _buildSettingRow(
                              provider.t('tab_size'),
                              Icons.keyboard_tab_rounded,
                              _buildTabDropdown(provider, isDark),
                              isDark
                            ),
                            _buildSwitchItem(provider.t('split_screen'), Icons.splitscreen_rounded, provider.isSplitScreen, (v) => provider.toggleSplitScreen(), isDark, accentColor),
                            _buildSwitchItem(provider.t('word_wrap'), Icons.wrap_text_rounded, provider.isWrapped, (v) => provider.toggleWrap(), isDark, accentColor),
                          ],
                          isDark
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MarkdownProvider provider, bool isDark, Color accentColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.settings_input_component_rounded, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Text(
            provider.t('settings'),
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: isDark ? Colors.white24 : Colors.black26),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Color color, List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
                color: color.withOpacity(0.8),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, IconData icon, Widget action, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? Colors.white30 : Colors.black38),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const Spacer(),
          action,
        ],
      ),
    );
  }

  Widget _buildSwitchItem(String label, IconData icon, bool value, Function(bool) onChanged, bool isDark, Color accentColor) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isDark ? Colors.white30 : Colors.black38),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value,
                activeColor: accentColor,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(MarkdownProvider provider, bool isDark) {
    return DropdownButton<String>(
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
    );
  }

  Widget _buildFontDropdown(MarkdownProvider provider, bool isDark) {
    return DropdownButton<String>(
      value: provider.fontFamily,
      underline: const SizedBox(),
      dropdownColor: isDark ? const Color(0xFF1E1E2F) : Colors.white,
      onChanged: (v) => v != null ? provider.updateFontFamily(v) : null,
      items: ['Inter', 'Fira Code', 'JetBrains Mono', 'Roboto Mono']
          .map((f) => DropdownMenuItem(
        value: f,
        child: Text(f, style: GoogleFonts.getFont(f, fontSize: 13)),
      )).toList(),
    );
  }

  Widget _buildSizeControls(MarkdownProvider provider, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMiniBtn(Icons.remove_rounded, () => provider.updateFontSize(provider.fontSize - 1), isDark),
        Container(
          width: 40,
          alignment: Alignment.center,
          child: Text(
            '${provider.fontSize.toInt()}',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        _buildMiniBtn(Icons.add_rounded, () => provider.updateFontSize(provider.fontSize + 1), isDark),
      ],
    );
  }

  Widget _buildLineHeightSlider(MarkdownProvider provider, Color accentColor) {
    return SizedBox(
      width: 120,
      child: Slider(
        value: provider.lineHeight,
        min: 1.0,
        max: 2.5,
        divisions: 15,
        activeColor: accentColor,
        onChanged: (v) => provider.updateLineHeight(v),
      ),
    );
  }

  Widget _buildPaddingSlider(MarkdownProvider provider, Color accentColor) {
    return SizedBox(
      width: 120,
      child: Slider(
        value: provider.editorPadding,
        min: 16.0,
        max: 96.0,
        divisions: 20,
        activeColor: accentColor,
        onChanged: (v) => provider.updateEditorPadding(v),
      ),
    );
  }

  Widget _buildTabDropdown(MarkdownProvider provider, bool isDark) {
    return DropdownButton<int>(
      value: provider.tabSize,
      underline: const SizedBox(),
      dropdownColor: isDark ? const Color(0xFF1E1E2F) : Colors.white,
      onChanged: (v) => v != null ? provider.updateTabSize(v) : null,
      items: [2, 4].map((s) => DropdownMenuItem(
        value: s,
        child: Text('$s Spaces', style: GoogleFonts.inter(fontSize: 13)),
      )).toList(),
    );
  }

  Widget _buildMiniBtn(IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: isDark ? Colors.white70 : Colors.black54),
      ),
    );
  }
}
