import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/route_names.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/staggered_animation.dart';
import '../../features/home/providers/home_provider.dart';
import '../../features/home/providers/advocate_provider.dart';
import '../../providers/auth_provider.dart';
import '../../shared/services/update_checker.dart';
import '../../features/notes/model/case_note.dart';
import '../../features/calendar/model/court_event.dart';

const double _tabletBreakpoint = 600;
const double _desktopBreakpoint = 900;

Color? tryParseColor(String hex) {
  try {
    final h = hex.replaceFirst('#', '');
    if (h.length != 6 && h.length != 8) return null;
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return null;
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > _tabletBreakpoint;
        final isDesktop = constraints.maxWidth > _desktopBreakpoint;

        Future.microtask(() => ref.read(updateCheckerProvider.notifier).checkForUpdate());

        return Scaffold(
          body: SafeArea(
            child: isDesktop
                ? const _DesktopLayout()
                : _MobileTabletLayout(
                    isTablet: isTablet,
                  ),
          ),
        );
      },
    );
  }
}

class _DesktopLayout extends ConsumerWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _AdvocateHeader(),
                const SizedBox(height: 20),
                const _UpdateBanner(),
                const SizedBox(height: 16),
                const _PendingRemindersBadge(),
                const SizedBox(height: 32),
                const _QuickActionsGrid(columns: 4),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1, color: AppColors.divider),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: 'Upcoming Hearings', subtitle: 'Your scheduled court events'),
                const SizedBox(height: 12),
                const _UpcomingHearingsList(),
                const SizedBox(height: 32),
                SectionHeader(title: 'Recent Notes', subtitle: 'Latest case notes'),
                const SizedBox(height: 12),
                const _RecentNotesList(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileTabletLayout extends ConsumerWidget {
  final bool isTablet;

  const _MobileTabletLayout({
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padding = EdgeInsets.symmetric(
      horizontal: MediaQuery.of(context).size.width * 0.05,
    );
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AdvocateHeader(),
            const SizedBox(height: 4),
            const _UpdateBanner(),
            const SizedBox(height: 16),
            const _PendingRemindersBadge(),
            const SizedBox(height: 24),
            SectionHeader(title: 'Upcoming Hearings'),
            const SizedBox(height: 12),
            const _UpcomingHearingsHorizontal(),
            const SizedBox(height: 24),
            SectionHeader(title: 'Recent Notes'),
            const SizedBox(height: 12),
            const _RecentNotesList(),
            const SizedBox(height: 24),
            const _QuickActionsGrid(columns: 2),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _AdvocateHeader extends ConsumerWidget {
  const _AdvocateHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 0),
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
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.3),
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentPrimary,
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
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGuest ? profile.name : user!.fullName,
                      style: AppTextStyles.title.copyWith(fontSize: 22),
                    ),
                    if (!isGuest && profile.specialization.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        profile.specialization,
                        style: AppTextStyles.caption.copyWith(color: AppColors.accentPrimary),
                      ),
                    ],
                    if (isGuest) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => context.pushNamed('setup'),
                        child: Text(
                          'Create an account to unlock all features',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.accentPrimary,
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
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: AppCard(
                child: Row(
                  children: [
                    if (profile.barNumber != null)
                      _InfoChip(
                        icon: Icons.badge_rounded,
                        label: profile.barNumber!,
                      ),
                    if (profile.firmName != null) ...[
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.business_rounded,
                        label: profile.firmName!,
                      ),
                    ],
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.pushNamed(RouteNames.settings),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.accentPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.settings_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
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

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.accentPrimary),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.accentSecondary,
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
    return updateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (info) {
        if (info == null || !info.isNewer) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: AppCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    size: 20,
                    color: AppColors.accentPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update ${info.latestVersion} available',
                        style: AppTextStyles.subtitle.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        info.releaseNotes.split('\n').first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
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
                      color: AppColors.accentPrimary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Update',
                      style: TextStyle(
                        color: AppColors.primaryBg,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              size: 22,
              color: AppColors.accentPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Pending Reminders',
                  style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  'Upcoming court events and hearings',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentPrimary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppColors.primaryBg,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final int columns;

  const _QuickActionsGrid({required this.columns});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _QuickActionTile(
              icon: Icons.document_scanner_rounded,
              label: 'Scan',
              onTap: () => context.pushNamed(RouteNames.scanner),
            ),
            _QuickActionTile(
              icon: Icons.add_rounded,
              label: 'Add Hearing',
              onTap: () => context.pushNamed(RouteNames.addHearing),
            ),
            _QuickActionTile(
              icon: Icons.sticky_note_2_rounded,
              label: 'New Note',
              onTap: () => context.pushNamed(RouteNames.notesEditor),
            ),
            _QuickActionTile(
              icon: Icons.notifications_active_rounded,
              label: 'Reminders',
              onTap: () => context.pushNamed(RouteNames.reminders),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Icon(icon, color: AppColors.accentPrimary, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.accentSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingHearingsHorizontal extends ConsumerWidget {
  const _UpcomingHearingsHorizontal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hearings = ref.watch(upcomingHearingsProvider);
    if (hearings.isEmpty) {
      return GestureDetector(
        onTap: () => context.pushNamed(RouteNames.addHearing),
        child: AppCard(
          child: Row(
            children: [
              const Icon(Icons.event_busy_rounded, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No upcoming hearings', style: AppTextStyles.body),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to add a hearing',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accentPrimary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentPrimary, size: 22),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: hearings.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final event = hearings[index];
          final color = tryParseColor(event.colorHex) ?? AppColors.accentPrimary;
          return StaggeredFadeSlide(
            index: index,
            child: GestureDetector(
              onTap: () => context.pushNamed(RouteNames.hearingDetail, extra: event),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 180,
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
                              style: AppTextStyles.subtitle.copyWith(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        event.caseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 13, color: AppColors.accentPrimary),
                          const SizedBox(width: 4),
                          Text(
                            event.dateTime.difference(DateTime.now()).inDays < 1
                                ? 'Today'
                                : '${event.dateTime.difference(DateTime.now()).inDays}d away',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.accentPrimary,
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

class _UpcomingHearingsList extends ConsumerWidget {
  const _UpcomingHearingsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hearings = ref.watch(upcomingHearingsProvider);
    if (hearings.isEmpty) {
      return GestureDetector(
        onTap: () => context.pushNamed(RouteNames.addHearing),
        child: AppCard(
          child: Row(
            children: [
              const Icon(Icons.event_busy_rounded, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No upcoming hearings', style: AppTextStyles.body),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to add a hearing',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accentPrimary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentPrimary, size: 22),
            ],
          ),
        ),
      );
    }
    return Column(
      children: hearings.map((event) {
        final color = tryParseColor(event.colorHex) ?? AppColors.accentPrimary;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => context.pushNamed(RouteNames.hearingDetail, extra: event),
            child: AppCard(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          event.caseName,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, size: 13, color: AppColors.accentPrimary),
                            const SizedBox(width: 4),
                            Text(
                              event.dateTime.difference(DateTime.now()).inDays < 1
                                  ? 'Today'
                                  : '${event.dateTime.difference(DateTime.now()).inDays}d away',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppColors.accentPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RecentNotesList extends ConsumerWidget {
  const _RecentNotesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(recentNotesProvider);
    if (notes.isEmpty) {
      return GestureDetector(
        onTap: () => context.pushNamed(RouteNames.notesEditor),
        child: AppCard(
          child: Row(
            children: [
              const Icon(Icons.note_add_outlined, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No notes yet', style: AppTextStyles.body),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to create a note',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accentPrimary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentPrimary, size: 22),
            ],
          ),
        ),
      );
    }
    return Column(
      children: notes.map((note) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => context.pushNamed(RouteNames.notes),
            child: AppCard(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.sticky_note_2_rounded,
                      size: 20,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title.isEmpty ? 'Untitled' : note.title,
                          style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (note.content.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            note.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(note.updatedAt),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
