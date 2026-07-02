import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/staggered_animation.dart';
import '../../../shared/widgets/polished_card.dart';
import '../model/reminder.dart';
import '../providers/reminder_provider.dart';
import '../service/notification_service.dart';

class RemindersPage extends ConsumerStatefulWidget {
  const RemindersPage({super.key});

  @override
  ConsumerState<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends ConsumerState<RemindersPage> {
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final has = await NotificationService.instance.hasPermission();
    if (mounted) setState(() => _permissionDenied = !has);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
      ),
      body: Container(
        color: bgColor,
        child: Column(
          children: [
            if (_permissionDenied)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard
                      : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_off_rounded,
                        color: AppColors.error, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications Disabled',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkText
                                  : AppColors.lightText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Enable to receive reminder alerts',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkSubtitle
                                  : AppColors.lightSubtitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await NotificationService.instance.openSettings();
                        await _checkPermission();
                      },
                      child: const Text('Open Settings'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _RemindersBody(
                reminders: ref.watch(sortedRemindersProvider),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemindersBody extends ConsumerWidget {
  final List<Reminder> reminders;
  final bool isDark;

  const _RemindersBody({required this.reminders, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 72,
              color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
            ),
            const SizedBox(height: 16),
            Text(
              'All caught up!',
              style: TextStyle(
                color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final overdue = reminders.where((r) => r.dueDate.isBefore(now)).toList();
    final upcoming = reminders.where((r) => !r.dueDate.isBefore(now)).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        if (overdue.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
                const SizedBox(width: 6),
                Text(
                  'Overdue (${overdue.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          for (final r in overdue)
            StaggeredFadeSlide(
              index: overdue.indexOf(r),
              child: _ReminderCard(reminder: r, isDark: isDark, overdue: true),
            ),
          const SizedBox(height: 20),
        ],
        if (upcoming.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Upcoming',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
              ],
            ),
          ),
          for (final r in upcoming)
            StaggeredFadeSlide(
              index: upcoming.indexOf(r),
              child: _ReminderCard(reminder: r, isDark: isDark, overdue: false),
            ),
        ],
      ],
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  final Reminder reminder;
  final bool isDark;
  final bool overdue;

  const _ReminderCard({
    required this.reminder,
    required this.isDark,
    required this.overdue,
  });

  Color _priorityColor(Priority p) {
    return switch (p) {
      Priority.high => AppColors.error,
      Priority.medium => AppColors.warning,
      Priority.low => isDark ? AppColors.darkAccent : AppColors.lightSecondary,
    };
  }

  Widget _priorityPill(Priority p) {
    final color = _priorityColor(p);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        p.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _time(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.inMinutes < 0) {
      final ago = -diff.inMinutes;
      if (ago < 60) return '${ago}m overdue';
      return '${-diff.inHours}h overdue';
    }
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _priorityColor(reminder.priority);
    final actions = ref.read(reminderActionsProvider);
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PolishedCard(
        padding: const EdgeInsets.all(16),
        margin: EdgeInsets.zero,
        backgroundColor: overdue
            ? AppColors.error.withOpacity(0.06)
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: overdue
                  ? AppColors.error.withOpacity(0.3)
                  : color.withOpacity(0.2),
              width: overdue ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _priorityPill(reminder.priority),
                    const Spacer(),
                    Text(
                      _time(reminder.dueDate),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: overdue
                            ? AppColors.error
                            : isDark
                                ? AppColors.darkSubtitle
                                : AppColors.lightSubtitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  reminder.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                if (reminder.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reminder.note,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    _ActionChip(
                      icon: Icons.snooze_rounded,
                      label: 'Snooze',
                      color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        actions.snooze(reminder);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Snoozed 15 min'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _ActionChip(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Complete',
                      color: AppColors.success,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        actions.markComplete(reminder);
                      },
                    ),
                    const SizedBox(width: 8),
                    _ActionChip(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                      color: AppColors.error,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        actions.deleteReminder(reminder);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
