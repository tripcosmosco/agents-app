import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SlidingNavItem {
  final IconData icon;
  final String label;
  final int badgeCount;
  final Color? badgeColor;
  final Color? activeColor;

  const SlidingNavItem({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
    this.badgeColor,
    this.activeColor,
  });
}

class SlidingBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<SlidingNavItem> items;

  const SlidingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.items,
  });

  @override
  State<SlidingBottomNav> createState() => _SlidingBottomNavState();
}

class _SlidingBottomNavState extends State<SlidingBottomNav> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void didUpdateWidget(covariant SlidingBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _scrollToActiveIndex();
    }
  }

  void _scrollToActiveIndex() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      const itemWidth = 84.0;
      final targetOffset = (widget.currentIndex * itemWidth) - (MediaQuery.of(context).size.width / 2) + (itemWidth / 2);
      final clampedOffset = targetOffset.clamp(0.0, _scrollCtrl.position.maxScrollExtent);
      _scrollCtrl.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassBg = isDark
        ? const Color(0xCC090D16)
        : Colors.white.withValues(alpha: 0.88);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.08);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, (bottomInset > 0 ? bottomInset : 10)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 58.0,
            decoration: BoxDecoration(
              color: glassBg,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: borderColor, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(widget.items.length, (index) {
                  final item = widget.items[index];
                  final isSelected = index == widget.currentIndex;
                  final activeColor = item.activeColor ?? const Color(0xFF38BDF8);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          widget.onIndexChanged(index);
                          _scrollToActiveIndex();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSelected ? 13 : 9,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? activeColor.withValues(alpha: 0.16)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? activeColor.withValues(alpha: 0.45)
                                  : Colors.transparent,
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    item.icon,
                                    size: isSelected ? 20.0 : 18.0,
                                    color: isSelected
                                        ? activeColor
                                        : (isDark ? Colors.white54 : Colors.black54),
                                  ),
                                  if (item.badgeCount > 0)
                                    Positioned(
                                      top: -3,
                                      right: -7,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: item.badgeColor ?? const Color(0xFFEF4444),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                        child: Text(
                                          item.badgeCount > 99 ? '99+' : '${item.badgeCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                            height: 1.1,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: isSelected ? 10.5 : 9.5,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  color: isSelected
                                      ? activeColor
                                      : (isDark ? Colors.white60 : Colors.black54),
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
