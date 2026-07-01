import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.white,
        selectedItemColor: AppColors.gold,
        unselectedItemColor:
            isDark ? AppColors.white.withOpacity(0.6) : AppColors.darkBlue,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: [
          _animatedNavItem(
            key: const ValueKey('home'),
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
            isSelected: currentIndex == 0,
          ),
          _animatedNavItem(
            key: const ValueKey('rule_book'),
            icon: Icons.book_outlined,
            activeIcon: Icons.book,
            label: 'Rule Book',
            isSelected: currentIndex == 1,
          ),
          _animatedNavItem(
            key: const ValueKey('notes'),
            icon: Icons.sticky_note_2_outlined,
            activeIcon: Icons.sticky_note_2,
            label: 'Notes',
            isSelected: currentIndex == 2,
          ),
          _animatedNavItem(
            key: const ValueKey('calendar'),
            icon: Icons.calendar_month_outlined,
            activeIcon: Icons.calendar_month,
            label: 'Calendar',
            isSelected: currentIndex == 3,
          ),
          _animatedNavItem(
            key: const ValueKey('more'),
            icon: Icons.more_horiz_outlined,
            activeIcon: Icons.more_horiz,
            label: 'More',
            isSelected: currentIndex == 4,
          ),
        ],
      ),
    );
  }

  BottomNavigationBarItem _animatedNavItem({
    required Key key,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
  }) {
    return BottomNavigationBarItem(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: Icon(
          isSelected ? activeIcon : icon,
          key: ValueKey(isSelected),
        ),
      ),
      activeIcon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: Icon(
          isSelected ? activeIcon : icon,
          key: ValueKey('active_$isSelected'),
        ),
      ),
      label: label,
    );
  }
}
