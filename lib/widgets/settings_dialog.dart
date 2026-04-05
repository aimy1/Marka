import 'package:flutter/material.dart';
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
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            
            // Font Size
            _buildSettingRow(
              'Font Size',
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_rounded),
                    onPressed: () => provider.updateFontSize(provider.fontSize - 1),
                  ),
                  Text(
                    '${provider.fontSize.toInt()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => provider.updateFontSize(provider.fontSize + 1),
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // Auto Save
            _buildSettingRow(
              'Auto Save',
              Switch(
                value: provider.autoSave,
                onChanged: (_) => provider.toggleAutoSave(),
                activeColor: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5),
              ),
            ),
            
            const Divider(),
            
            // Theme
            _buildSettingRow(
              'Theme',
              Switch(
                value: isDark,
                onChanged: (_) => AdaptiveTheme.of(context).toggleThemeMode(),
                activeColor: isDark ? const Color(0xFFCBA6F7) : const Color(0xFF1E66F5),
              ),
            ),
            
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(String label, Widget action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          action,
        ],
      ),
    );
  }
}
