import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_nav_bar.dart';

const double _desktopBreakpoint = 900;

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > _desktopBreakpoint) {
          return _DesktopShell(navigationShell: navigationShell);
        }
        return _MobileShell(navigationShell: navigationShell);
      },
    );
  }
}

class _MobileShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _MobileShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: GlassNavBar(
        currentIndex: currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _DesktopShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    return Row(
      children: [
        _Sidebar(
          currentIndex: currentIndex,
          onTap: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
        ),
        const VerticalDivider(width: 1, color: AppColors.divider),
        Expanded(child: navigationShell),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _Sidebar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.primaryBg,
      child: Column(
        children: [
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.accentPrimary,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.gavel_rounded,
                      size: 20,
                      color: AppColors.primaryBg,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Legal Assistant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 8),
          ...List.generate(_items.length, (index) {
            final item = _items[index];
            final isSelected = index == currentIndex;
            return _SidebarItem(
              icon: isSelected ? item.activeIcon : item.icon,
              label: item.label,
              isSelected: isSelected,
              onTap: () => onTap(index),
            );
          }),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accentPrimary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.accentPrimary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.accentPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
