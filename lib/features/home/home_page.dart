import 'dart:ui' show Color;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/route_names.dart';
import '../../shared/widgets/staggered_animation.dart';
import '../../shared/widgets/polished_card.dart';
import '../../shared/services/update_checker.dart';
import '../../providers/auth_provider.dart';
import '../notes/model/case_note.dart';
import 'providers/home_provider.dart';
import 'providers/advocate_provider.dart';

Color? tryParseColor(String hex) {
  try {
    final h = hex.replaceFirst('#', '');
    if (h.length != 6 && h.length != 8) return null;
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return null;
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtitleColor = isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle;

    Future.microtask(() => ref.read(updateCheckerProvider.notifier).checkForUpdate());

    return Scaffold(
      body: Container(
        color: bgColor,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _AdvocateHeader(),
                const _UpdateBanner(),
                const SizedBox(height: 4),
                const _PendingRemindersBadge(),
                const SizedBox(height: 24),
                _SectionTitle(
                  icon: Icons.gavel_rounded,
                  title: 'Upcoming Hearings',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _UpcomingHearings(
                  isDark: isDark,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                ),
                const SizedBox(height: 24),
                _SectionTitle(
                  icon: Icons.sticky_note_2_rounded,
                  title: 'Recent Notes',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _RecentNotesList(
                  isDark: isDark,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdvocateHeader extends ConsumerWidget {
  const _AdvocateHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isGuest = user?.isGuest ?? true;
    final profileAsync = ref.watch(advocateProfileProvider);
    final defaultProfile = ref.watch(defaultAdvocateProvider);

    final profile = profileAsync.when(
      data: (p) => p ?? defaultProfile,
      loading: () => defaultProfile,
      error: (_, __) => defaultProfile,
    );

    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtitleColor = isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: 'advocate_avatar',
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      profile.name.isNotEmpty
                          ? profile.name.split(' ').map((w) => w[0]).take(2).join()
                          : 'AK',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                      ),
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
                      isGuest ? 'Welcome, Guest' : 'Welcome back,',
                      style: TextStyle(
                        fontSize: 14,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGuest ? profile.name : user!.fullName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    if (!isGuest && profile.specialization.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        profile.specialization,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                        ),
                      ),
                    ],
                    if (isGuest) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => context.pushNamed('setup'),
                        child: Text(
                          'Create an account to unlock all features',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (profile.barNumber != null ||
              profile.firmName != null ||
              profile.email != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard.withOpacity(0.5) : AppColors.lightCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkDivider.withOpacity(0.3)
                      : AppColors.lightDivider.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  if (profile.barNumber != null)
                    _InfoChip(
                      icon: Icons.badge_rounded,
                      label: profile.barNumber!,
                      isDark: isDark,
                    ),
                  if (profile.firmName != null) ...[
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.business_rounded,
                      label: profile.firmName!,
                      isDark: isDark,
                    ),
                  ],
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.pushNamed(RouteNames.settings),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPrimary.withOpacity(0.1)
                            : AppColors.lightPrimary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.settings_rounded,
                        size: 16,
                        color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
          ),
        ),
      ],
    );
  }
}

class _UpdateBanner extends ConsumerWidget {
  const _UpdateBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateAsync = ref.watch(updateCheckerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return updateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (info) {
        if (info == null || !info.isNewer) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.darkCard, AppColors.darkSurface]
                  : [AppColors.lightCard, AppColors.lightBackground],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDark ? AppColors.darkAccent : AppColors.lightSecondary)
                  .withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkAccent : AppColors.lightSecondary)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.system_update_rounded,
                  size: 20,
                  color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update ${info.latestVersion} available',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info.releaseNotes.split('\n').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final uri = Uri.tryParse(info.downloadUrl);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Update',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PendingRemindersBadge extends ConsumerWidget {
  const _PendingRemindersBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingRemindersCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: PolishedCard(
        padding: const EdgeInsets.all(16),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkAccent.withOpacity(0.15)
                    : AppColors.lightSecondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                size: 22,
                color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count Pending Reminders',
                    style: TextStyle(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Upcoming court events and hearings',
                    style: TextStyle(
                      color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingHearings extends ConsumerWidget {
  final bool isDark;
  final Color textColor;
  final Color subtitleColor;

  const _UpcomingHearings({
    required this.isDark,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hearings = ref.watch(upcomingHearingsProvider);

    if (hearings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: () => context.pushNamed(RouteNames.addHearing),
          child: PolishedCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.event_busy_rounded,
                  color: isDark
                      ? AppColors.darkSubtitle
                      : AppColors.lightSubtitle,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No upcoming hearings',
                        style: TextStyle(color: subtitleColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to add a hearing',
                        style: TextStyle(
                          color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: hearings.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final event = hearings[index];
          final color = tryParseColor(event.colorHex) ?? AppColors.lightSecondary;

          return StaggeredFadeSlide(
            index: index,
            child: GestureDetector(
              onTap: () => context.pushNamed(RouteNames.hearingDetail, extra: event.id),
              child: PolishedCard(
                padding: const EdgeInsets.all(16),
                margin: EdgeInsets.zero,
                borderRadius: 24,
                child: Container(
                  width: 170,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        event.caseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: subtitleColor),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: isDark
                                ? AppColors.darkAccent
                                : AppColors.lightSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.dateTime.difference(DateTime.now()).inDays < 1
                                ? 'Today'
                                : '${event.dateTime.difference(DateTime.now()).inDays}d away',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkAccent
                                  : AppColors.lightSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecentNotesList extends ConsumerWidget {
  final bool isDark;
  final Color textColor;
  final Color subtitleColor;

  const _RecentNotesList({
    required this.isDark,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(recentNotesProvider);

    if (notes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: () => context.pushNamed(RouteNames.notesEditor),
          child: PolishedCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.note_add_outlined,
                  color: isDark
                      ? AppColors.darkSubtitle
                      : AppColors.lightSubtitle,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No notes yet',
                        style: TextStyle(color: subtitleColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to create a note',
                        style: TextStyle(
                          color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: notes.asMap().entries.map((entry) {
          return StaggeredFadeSlide(
            index: entry.key + 5,
            child: _NoteMiniCard(
              note: entry.value,
              isDark: isDark,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NoteMiniCard extends StatelessWidget {
  final CaseNote note;
  final bool isDark;
  final Color textColor;
  final Color subtitleColor;

  const _NoteMiniCard({
    required this.note,
    required this.isDark,
    required this.textColor,
    required this.subtitleColor,
  });

  String _time(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed(RouteNames.notes),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: PolishedCard(
          padding: const EdgeInsets.all(16),
          margin: EdgeInsets.zero,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkAccent.withOpacity(0.12)
                      : AppColors.lightSecondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.sticky_note_2_rounded,
                  size: 20,
                  color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title.isEmpty ? 'Untitled' : note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: textColor,
                      ),
                    ),
                    if (note.content.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        note.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: subtitleColor),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _time(note.updatedAt),
                style: TextStyle(fontSize: 12, color: subtitleColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
