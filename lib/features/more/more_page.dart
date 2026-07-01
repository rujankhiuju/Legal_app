import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/polished_card.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _MenuTile(
            icon: Icons.document_scanner_rounded,
            iconColor: accentColor,
            title: 'Document Scanner',
            isDark: isDark,
            onTap: () => context.pushNamed(RouteNames.scanner),
          ),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.picture_as_pdf_rounded,
            iconColor: accentColor,
            title: 'PDF Library',
            isDark: isDark,
            onTap: () => context.pushNamed(RouteNames.pdfLibrary),
          ),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.notifications_active_rounded,
            iconColor: accentColor,
            title: 'Reminders',
            isDark: isDark,
            onTap: () => context.pushNamed(RouteNames.reminders),
          ),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.settings_rounded,
            iconColor: accentColor,
            title: 'Settings',
            isDark: isDark,
            onTap: () => context.pushNamed(RouteNames.settings),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool isDark;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PolishedCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
        ),
        onTap: onTap,
      ),
    );
  }
}
