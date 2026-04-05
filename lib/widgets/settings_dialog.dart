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

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, color: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF), size: 24),
                const SizedBox(width: 12),
                Text(
                  provider.t('settings'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Language Selection
            _buildSettingRow(
              provider.t('language'),
              DropdownButton<String>(
                value: provider.locale,
                underline: const SizedBox(),
                dropdownColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
                onChanged: (String? value) {
                  if (value != null) provider.updateLocale(value);
                },
                items: [
                  {'code': 'en', 'label': '🇺🇸 English'},
                  {'code': 'zh', 'label': '🇨🇳 简体中文'},
                ].map<DropdownMenuItem<String>>((Map<String, String> lang) {
                  return DropdownMenuItem<String>(
                    value: lang['code'],
                    child: Text(lang['label']!, style: GoogleFonts.inter(fontSize: 13)),
                  );
                }).toList(),
              ),
            ),
            
            const Divider(height: 32),

            // Font Family
            _buildSettingRow(
              provider.t('font_family'),
              DropdownButton<String>(
                value: provider.fontFamily,
                underline: const SizedBox(),
                dropdownColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
                onChanged: (String? value) {
                  if (value != null) provider.updateFontFamily(value);
                },
                items: ['Inter', 'Fira Code', 'JetBrains Mono']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: _getSafeFont(value, 13)),
                  );
                }).toList(),
              ),
            ),

            // Font Size
            _buildSettingRow(
              provider.t('font_size'),
              Row(
                children: [
                  _buildMiniBtn(Icons.remove_rounded, () => provider.updateFontSize(provider.fontSize - 1), isDark),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${provider.fontSize.toInt()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildMiniBtn(Icons.add_rounded, () => provider.updateFontSize(provider.fontSize + 1), isDark),
                ],
              ),
            ),
            
            // Line Height
            _buildSettingRow(
              provider.t('line_height'),
              SizedBox(
                width: 100,
                child: Slider(
                  value: provider.lineHeight,
                  min: 1.0,
                  max: 2.5,
                  divisions: 15,
                  activeColor: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5),
                  onChanged: (val) => provider.updateLineHeight(val),
                ),
              ),
            ),
            
            const Divider(height: 32),
            
            // Toggles Group
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildToggleChip(provider.t('auto_save'), provider.autoSave, (v) => provider.toggleAutoSave(), isDark),
                _buildToggleChip(provider.t('split_screen'), provider.isSplitScreen, (v) => provider.toggleSplitScreen(), isDark),
                _buildToggleChip(provider.t('word_wrap'), provider.isWrapped, (v) => provider.toggleWrap(), isDark),
                _buildToggleChip(provider.t('theme'), isDark, (v) => AdaptiveTheme.of(context).toggleThemeMode(), isDark),
              ],
            ),
            
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  foregroundColor: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5),
                ),
                child: Text(provider.t('close'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBtn(IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildToggleChip(String label, bool value, Function(bool) onChanged, bool isDark) {
    return FilterChip(
      label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: value ? FontWeight.w600 : FontWeight.w400)),
      selected: value,
      onSelected: onChanged,
      backgroundColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
      selectedColor: isDark ? const Color(0xFFCBA6F7).withOpacity(0.2) : const Color(0xFF1E66F5).withOpacity(0.1),
      checkmarkColor: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide.none),
    );
  }

  TextStyle _getSafeFont(String family, double size) {
    try {
      return GoogleFonts.getFont(family, fontSize: size);
    } catch (_) {
      return TextStyle(fontFamily: 'sans-serif', fontSize: size);
    }
  }

  Widget _buildSettingRow(String label, Widget action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
          action,
        ],
      ),
    );
  }
}
