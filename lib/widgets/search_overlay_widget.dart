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
    _replaceController = TextEditingController();
    _searchController.addListener(() {
      widget.provider.updateSearch(_searchController.text);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? const Color(0xFFCBA6F7) : const Color(0xFF8839EF);
    final glassColor = isDark ? const Color(0xFF1E1E2E).withOpacity(0.8) : const Color(0xFFFFFFFF).withOpacity(0.8);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12, width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Row
              Row(
                children: [
                   IconButton(
                    icon: Icon(_showReplace ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded, size: 18),
                    onPressed: () => setState(() => _showReplace = !_showReplace),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Toggle Replace',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: widget.provider.t('search'),
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                        isDense: true,
                        border: InputBorder.none,
                      ),
                      style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  if (widget.provider.searchMatches.isNotEmpty)
                    Text(
                      '${widget.provider.currentMatchIndex + 1} / ${widget.provider.searchMatches.length}',
                      style: GoogleFonts.jetbrainsMono(fontSize: 11, color: accentColor, fontWeight: FontWeight.bold),
                    ),
                   const SizedBox(width: 8),
                  _btn(Icons.keyboard_arrow_up_rounded, widget.provider.findPrev, isDark),
                  _btn(Icons.keyboard_arrow_down_rounded, widget.provider.findNext, isDark),
                  const SizedBox(width: 4),
                  _btn(Icons.close_rounded, widget.provider.toggleSearchOverlay, isDark),
                ],
              ),
              
              // Replace Section
              if (_showReplace) ...[
                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                Row(
                  children: [
                    const SizedBox(width: 26),
                    Expanded(
                      child: TextField(
                        controller: _replaceController,
                        decoration: InputDecoration(
                          hintText: widget.provider.t('replace'),
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                          isDense: true,
                          border: InputBorder.none,
                        ),
                        style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    _actionBtn(widget.provider.t('replace_all'), () => widget.provider.replaceAll(_replaceController.text), accentColor, isDark),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, bool isDark) {
    return IconButton(
      icon: Icon(icon, size: 18, color: isDark ? Colors.white38 : Colors.black45),
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      splashRadius: 16,
    );
  }

  Widget _actionBtn(String label, VoidCallback onTap, Color accent, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: accent.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: accent),
        ),
      ),
    );
  }
}
