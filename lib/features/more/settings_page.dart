import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isNepali = locale.languageCode == 'ne';
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    isNepali ? 'Nepali' : 'English',
                    style: TextStyle(
                      color: isDark ? AppColors.white : AppColors.deepNavy,
                    ),
                  ),
                  subtitle: Text(
                    isNepali ? 'नेपाली' : 'English',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.white.withValues(alpha: 0.7)
                          : AppColors.deepNavy.withValues(alpha: 0.7),
                    ),
                  ),
                  secondary: Icon(
                    Icons.language,
                    color: AppColors.gold,
                  ),
                  value: isNepali,
                  onChanged: (_) {
                    ref.read(localeProvider.notifier).toggle();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(
                    isDark ? 'Dark Mode' : 'Light Mode',
                    style: TextStyle(
                      color: isDark ? AppColors.white : AppColors.deepNavy,
                    ),
                  ),
                  secondary: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: AppColors.gold,
                  ),
                  value: isDark,
                  onChanged: (_) {
                    ref.read(themeModeProvider.notifier).setThemeMode(
                          isDark ? ThemeMode.light : ThemeMode.dark,
                        );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
