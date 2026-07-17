import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: isDark
            ? _darkBlur()
            : _lightBlur(),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface.withOpacity(0.85)
                : AppColors.lightSurface.withOpacity(0.85),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? AppColors.darkDivider.withOpacity(0.3)
                    : AppColors.lightDivider.withOpacity(0.5),
                width: 0.5,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 8,
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                final isSelected = index == currentIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onTap(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? AppColors.darkPrimary.withOpacity(0.1)
                                : AppColors.lightPrimary.withOpacity(0.08))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? item.activeIcon : item.icon,
                            size: 24,
                            color: isSelected
                                ? (isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.lightPrimary)
                                : (isDark
                                    ? AppColors.darkSubtitle
                                    : AppColors.lightSubtitle),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? (isDark
                                      ? AppColors.darkPrimary
                                      : AppColors.lightPrimary)
                                  : (isDark
                                      ? AppColors.darkSubtitle
                                      : AppColors.lightSubtitle),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  ImageFilter _lightBlur() {
    return ImageFilter.blur(sigmaX: 20, sigmaY: 20);
  }

  ImageFilter _darkBlur() {
    return ImageFilter.blur(sigmaX: 20, sigmaY: 20);
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const _items = [
  _NavItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Home',
  ),
  _NavItem(
    icon: Icons.book_outlined,
    activeIcon: Icons.book,
    label: 'Rule Book',
  ),
  _NavItem(
    icon: Icons.sticky_note_2_outlined,
    activeIcon: Icons.sticky_note_2,
    label: 'Notes',
  ),
  _NavItem(
    icon: Icons.calendar_month_outlined,
    activeIcon: Icons.calendar_month,
    label: 'Calendar',
  ),
  _NavItem(
    icon: Icons.picture_as_pdf_outlined,
    activeIcon: Icons.picture_as_pdf_rounded,
    label: 'PDF Tools',
  ),
  _NavItem(
    icon: Icons.more_horiz_outlined,
    activeIcon: Icons.more_horiz,
    label: 'More',
  ),
];
