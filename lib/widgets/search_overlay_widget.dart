import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/markdown_provider.dart';

class SearchOverlayWidget extends StatefulWidget {
  final MarkdownProvider provider;
  const SearchOverlayWidget({super.key, required this.provider});

  @override
  State<SearchOverlayWidget> createState() => _SearchOverlayWidgetState();
}

class _SearchOverlayWidgetState extends State<SearchOverlayWidget> {
  late TextEditingController _searchController;
  late TextEditingController _replaceController;
  bool _showReplace = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.provider.searchQuery);
    _replaceController = TextEditingController(text: widget.provider.replaceQuery);
    
    _searchController.addListener(() {
      widget.provider.updateSearch(_searchController.text);
    });
    _replaceController.addListener(() {
      widget.provider.updateReplaceQuery(_replaceController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF);
    final glassColor = isDark ? const Color(0xFF1E1E2E).withOpacity(0.85) : const Color(0xFFFFFFFF).withOpacity(0.85);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 1),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Row
              Row(
                children: [
                  _toggleBtn(Icons.swap_vert_rounded, _showReplace, () => setState(() => _showReplace = !_showReplace), isDark, accentColor, 'Toggle Replace'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: p.t('search'),
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Search Modifiers
                  _modeBtn('Aa', p.isCaseSensitive, p.toggleCaseSensitive, isDark, accentColor, 'Case Sensitive'),
                  _modeBtn('.*', p.isRegex, p.toggleRegex, isDark, accentColor, 'Regex'),
                  
                  if (p.searchMatches.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${p.currentMatchIndex + 1}/${p.searchMatches.length}',
                        style: GoogleFonts.jetBrainsMono(fontSize: 11, color: accentColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  
                  _navBtn(Icons.arrow_upward_rounded, p.findPrev, isDark),
                  _navBtn(Icons.arrow_downward_rounded, p.findNext, isDark),
                  _navBtn(Icons.close_rounded, p.toggleSearchOverlay, isDark),
                ],
              ),
              
              // Replace Row
              if (_showReplace)
                Padding(
                  padding: const EdgeInsets.top(8),
                  child: Row(
                    children: [
                      const SizedBox(width: 32),
                      Expanded(
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: TextField(
                            controller: _replaceController,
                            decoration: InputDecoration(
                              hintText: p.t('replace'),
                              hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _actionBtn('Replace', p.replaceNext, accentColor, isDark),
                      const SizedBox(width: 4),
                      _actionBtn(p.t('replace_all'), p.replaceAll, accentColor, isDark),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeBtn(String label, bool active, VoidCallback onTap, bool isDark, Color accent, String tip) {
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 28, height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? accent.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: active ? accent.withOpacity(0.4) : Colors.transparent),
          ),
          child: Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold, color: active ? accent : (isDark ? Colors.white38 : Colors.black38))),
        ),
      ),
    );
  }

  Widget _toggleBtn(IconData icon, bool active, VoidCallback onTap, bool isDark, Color accent, String tip) {
    return IconButton(
      icon: Icon(icon, size: 18, color: active ? accent : (isDark ? Colors.white38 : Colors.black45)),
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      tooltip: tip,
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap, bool isDark) {
    return IconButton(
      icon: Icon(icon, size: 16, color: isDark ? Colors.white38 : Colors.black45),
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      splashRadius: 14,
    );
  }

  Widget _actionBtn(String label, VoidCallback onTap, Color accent, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }
}
