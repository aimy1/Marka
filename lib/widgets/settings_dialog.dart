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

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.tune_rounded, color: accentColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  provider.t('settings'),
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: isDark ? Colors.white24 : Colors.black26),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(provider.t('appearance'), accentColor),
                    
                    // Language
                    _buildSettingItem(
                      provider.t('language'),
                      DropdownButton<String>(
                        value: provider.locale,
                        underline: const SizedBox(),
                        dropdownColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
                        onChanged: (v) => v != null ? provider.updateLocale(v) : null,
                        items: [
                          {'code': 'en', 'label': '🇺🇸 English'},
                          {'code': 'zh', 'label': '🇨🇳 简体中文'},
                        ].map((l) => DropdownMenuItem(
                          value: l['code'],
                          child: Text(l['label']!, style: GoogleFonts.inter(fontSize: 13)),
                        )).toList(),
                      ),
                    ),
                    
                    // Theme Switch
                    _buildSettingItem(
                      provider.t('theme'),
                      Switch(
                        value: isDark,
                        activeColor: accentColor,
                        onChanged: (v) => AdaptiveTheme.of(context).toggleThemeMode(),
                      ),
                    ),

                    const Divider(height: 32),
                    _buildSectionTitle(provider.t('typography'), accentColor),

                    // Font Family
                    _buildSettingItem(
                      provider.t('font_family'),
                      DropdownButton<String>(
                        value: provider.fontFamily,
                        underline: const SizedBox(),
                        dropdownColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFEFF1F5),
                        onChanged: (v) => v != null ? provider.updateFontFamily(v) : null,
                        items: ['Inter', 'Fira Code', 'JetBrains Mono']
                            .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f, style: _getSafeFont(f, 13)),
                        )).toList(),
                      ),
                    ),

                    // Font Size
                    _buildSettingItem(
                      provider.t('font_size'),
                      Row(
                        children: [
                          _buildMiniBtn(Icons.remove_rounded, () => provider.updateFontSize(provider.fontSize - 1), isDark),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('${provider.fontSize.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          _buildMiniBtn(Icons.add_rounded, () => provider.updateFontSize(provider.fontSize + 1), isDark),
                        ],
                      ),
                    ),

                    // Line Height
                    _buildSettingItem(
                      provider.t('line_height'),
                      SizedBox(
                        width: 140,
                        child: Slider(
                          value: provider.lineHeight,
                          min: 1.0,
                          max: 2.5,
                          divisions: 15,
                          activeColor: accentColor,
                          label: provider.lineHeight.toStringAsFixed(1),
                          onChanged: (v) => provider.updateLineHeight(v),
                        ),
                      ),
                    ),

                    const Divider(height: 32),
                    _buildSectionTitle(provider.t('pro_features'), accentColor),

                    _buildSwitchTile(provider.t('sync_scroll'), provider.isSyncScroll, (v) => provider.toggleSyncScroll(), isDark, accentColor),
                    _buildSwitchTile(provider.t('show_toolbar'), provider.showToolbar, (v) => provider.toggleToolbar(), isDark, accentColor),
                    _buildSwitchTile(provider.t('auto_save'), provider.autoSave, (v) => provider.toggleAutoSave(), isDark, accentColor),
                    _buildSwitchTile(provider.t('split_screen'), provider.isSplitScreen, (v) => provider.toggleSplitScreen(), isDark, accentColor),
                    _buildSwitchTile(provider.t('word_wrap'), provider.isWrapped, (v) => provider.toggleWrap(), isDark, accentColor),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: color.withOpacity(0.8)),
      ),
    );
  }

  Widget _buildSettingItem(String label, Widget action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
          action,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String label, bool value, Function(bool) onChanged, bool isDark, Color accentColor) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      title: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87)),
      trailing: Transform.scale(
        scale: 0.8,
        child: Switch(
          value: value,
          activeColor: accentColor,
          onChanged: onChanged,
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

  TextStyle _getSafeFont(String family, double size) {
    try {
      return GoogleFonts.getFont(family, fontSize: size);
    } catch (_) {
      return TextStyle(fontFamily: 'monospace', fontSize: size);
    }
  }
}
