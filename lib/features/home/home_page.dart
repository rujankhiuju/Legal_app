import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/route_names.dart';
import '../../shared/widgets/staggered_animation.dart';
import '../calendar/model/court_event.dart';
import '../notes/model/case_note.dart';
import 'providers/home_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.deepNavy : AppColors.lightBackground;
    final textColor = isDark ? AppColors.white : AppColors.deepNavy;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.white;
    final subtitleColor = textColor.withOpacity(0.6);

    return Scaffold(
      body: Container(
        color: bgColor,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WelcomeHeader(isDark: isDark, textColor: textColor),
                const SizedBox(height: 8),
                const _PendingRemindersBadge(),
                const SizedBox(height: 20),
                _SectionTitle(
                  icon: Icons.gavel,
                  title: 'Upcoming Hearings',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _UpcomingHearings(
                  isDark: isDark,
                  textColor: textColor,
                  cardBg: cardBg,
                  subtitleColor: subtitleColor,
                ),
                const SizedBox(height: 20),
                _SectionTitle(
                  icon: Icons.sticky_note_2,
                  title: 'Recent Notes',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _RecentNotesList(
                  isDark: isDark,
                  textColor: textColor,
                  cardBg: cardBg,
                  subtitleColor: subtitleColor,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  final bool isDark;
  final Color textColor;

  const _WelcomeHeader({required this.isDark, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: TextStyle(
              fontSize: 16,
              color: textColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Adv. Rujan',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.gavel, color: AppColors.gold, size: 24),
            ],
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.darkBlue, AppColors.darkSurface]
              : [AppColors.darkBlue, AppColors.darkBlue.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_active, color: AppColors.gold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Pending Reminders',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Upcoming court events and hearings',
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppColors.deepNavy,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
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
          Icon(icon, size: 18, color: AppColors.gold),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.white : AppColors.deepNavy,
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
  final Color cardBg;
  final Color subtitleColor;

  const _UpcomingHearings({
    required this.isDark,
    required this.textColor,
    required this.cardBg,
    required this.subtitleColor,
  });

  Color _parseColor(String hex) => Color(int.parse('FF$hex', radix: 16));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hearings = ref.watch(upcomingHearingsProvider);

    if (hearings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.event_busy, color: AppColors.gold.withOpacity(0.4)),
              const SizedBox(width: 12),
              Text('No upcoming hearings', style: TextStyle(color: subtitleColor)),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: hearings.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final event = hearings[index];
          final color = _parseColor(event.colorHex);

          return StaggeredFadeSlide(
            index: index,
            child: GestureDetector(
              onTap: () => context.pushNamed(RouteNames.calendar),
              child: Container(
                width: 160,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.caseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: subtitleColor),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 12, color: AppColors.gold),
                        const SizedBox(width: 4),
                        Text(
                          event.dateTime.difference(DateTime.now()).inDays < 1
                              ? 'Today'
                              : '${event.dateTime.difference(DateTime.now()).inDays}d away',
                          style: const TextStyle(fontSize: 11, color: AppColors.gold),
                        ),
                      ],
                    ),
                  ],
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
  final Color cardBg;
  final Color subtitleColor;

  const _RecentNotesList({
    required this.isDark,
    required this.textColor,
    required this.cardBg,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(recentNotesProvider);

    if (notes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.note_add_outlined, color: AppColors.gold.withOpacity(0.4)),
              const SizedBox(width: 12),
              Text('No notes yet', style: TextStyle(color: subtitleColor)),
            ],
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
              cardBg: cardBg,
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
  final Color cardBg;
  final Color subtitleColor;

  const _NoteMiniCard({
    required this.note,
    required this.isDark,
    required this.textColor,
    required this.cardBg,
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sticky_note_2, color: AppColors.gold, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title.isEmpty ? 'Untitled' : note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor),
                  ),
                  if (note.content.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      note.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: subtitleColor),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(_time(note.updatedAt), style: TextStyle(fontSize: 11, color: subtitleColor)),
          ],
        ),
      ),
    );
  }
}
