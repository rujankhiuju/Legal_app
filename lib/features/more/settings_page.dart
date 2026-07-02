import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/polished_card.dart';
import '../../shared/widgets/pill_button.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/user_model.dart';
import '../home/model/advocate_profile.dart';
import '../home/providers/advocate_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  void _showEditNameDialog(UserModel user) {
    final firstNameCtrl = TextEditingController(text: user.firstName);
    final lastNameCtrl = TextEditingController(text: user.lastName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameCtrl,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lastNameCtrl,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(authProvider.notifier).updateProfile(
                    firstNameCtrl.text.trim(),
                    lastNameCtrl.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isNepali = locale.languageCode == 'ne';
    final isDarkMode = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final profileAsync = ref.watch(advocateProfileProvider);
    final defaultProfile = ref.watch(defaultAdvocateProvider);

    final profile = profileAsync.when(
      data: (p) => p ?? defaultProfile,
      loading: () => defaultProfile,
      error: (_, __) => defaultProfile,
    );

    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'Profile', isDark: isDark),
          const SizedBox(height: 8),
          PolishedCard(
            padding: const EdgeInsets.all(4),
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkAccent.withOpacity(0.12)
                      : AppColors.lightSecondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                  size: 20,
                ),
              ),
              title: Text(
                user?.fullName ?? 'Guest',
                style: TextStyle(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                user?.isGuest == true ? 'Guest Mode' : 'Tap to edit name',
                style: TextStyle(
                  color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: user?.isGuest == true
                  ? null
                  : () => _showEditNameDialog(user!),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Advocate Profile', isDark: isDark),
          const SizedBox(height: 8),
          PolishedCard(
            padding: const EdgeInsets.all(20),
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                      ),
                      child: Center(
                        child: Text(
                          profile.name.split(' ').map((w) => w[0]).take(2).join(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkText : AppColors.lightText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (profile.barNumber != null ||
                    profile.firmName != null ||
                    profile.email != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        if (profile.barNumber != null)
                          _InfoRow(
                            icon: Icons.badge_rounded,
                            label: 'Bar No.',
                            value: profile.barNumber!,
                            isDark: isDark,
                          ),
                        if (profile.firmName != null)
                          _InfoRow(
                            icon: Icons.business_rounded,
                            label: 'Firm',
                            value: profile.firmName!,
                            isDark: isDark,
                          ),
                        if (profile.email != null)
                          _InfoRow(
                            icon: Icons.email_rounded,
                            label: 'Email',
                            value: profile.email!,
                            isDark: isDark,
                          ),
                        if (profile.phone != null)
                          _InfoRow(
                            icon: Icons.phone_rounded,
                            label: 'Phone',
                            value: profile.phone!,
                            isDark: isDark,
                          ),
                        if (profile.address != null)
                          _InfoRow(
                            icon: Icons.location_on_rounded,
                            label: 'Address',
                            value: profile.address!,
                            isDark: isDark,
                          ),
                        if (profile.bio != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              profile.bio!,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Appearance', isDark: isDark),
          const SizedBox(height: 8),
          PolishedCard(
            padding: const EdgeInsets.all(4),
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkAccent.withOpacity(0.12)
                          : AppColors.lightSecondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.language_rounded,
                      color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    isNepali ? 'Language' : 'Language',
                    style: TextStyle(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    isNepali ? 'नेपाली' : 'English',
                    style: TextStyle(
                      color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                    ),
                  ),
                  trailing: Switch(
                    value: isNepali,
                    onChanged: (_) => ref.read(localeProvider.notifier).toggle(),
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 72,
                  color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkAccent.withOpacity(0.12)
                          : AppColors.lightSecondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    isDarkMode ? 'Dark Mode' : 'Light Mode',
                    style: TextStyle(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (_) {
                      ref.read(themeModeProvider.notifier).setThemeMode(
                            isDarkMode ? ThemeMode.light : ThemeMode.dark,
                          );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Support', isDark: isDark),
          const SizedBox(height: 8),
          PolishedCard(
            padding: const EdgeInsets.all(4),
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkAccent.withOpacity(0.12)
                      : AppColors.lightSecondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.feedback_rounded,
                  color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                  size: 20,
                ),
              ),
              title: Text(
                'Send Feedback',
                style: TextStyle(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Email us your suggestions',
                style: TextStyle(
                  color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                final uri = Uri(
                  scheme: 'mailto',
                  path: 'rujan@khiujulaw.com',
                  queryParameters: {
                    'subject': 'Nepali Legal Assistant Feedback',
                    'body': 'Hello Rujan,\n\n',
                  },
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '© ${DateTime.now().year} Rujan Khiuju. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkText : AppColors.lightText,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
        ],
      ),
    );
  }
}
