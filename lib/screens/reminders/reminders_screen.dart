import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../features/reminders/model/reminder.dart';
import '../../features/reminders/providers/reminder_provider.dart';
import '../../features/reminders/service/notification_service.dart';

enum _ReminderGroup { today, tomorrow, thisWeek, later, completed }

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
      ),
      body: Column(
        children: [
          if (_permissionDenied)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.notifications_off_rounded, color: AppColors.error, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications Disabled',
                            style: AppTextStyles.subtitle.copyWith(fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Enable to receive reminder alerts',
                            style: AppTextStyles.caption,
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
            ),
          Expanded(
            child: _RemindersBody(
              reminders: ref.watch(sortedRemindersProvider),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemindersBody extends ConsumerWidget {
  final List<Reminder> reminders;

  const _RemindersBody({required this.reminders});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reminders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 72, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text('All caught up!', style: AppTextStyles.body),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final tomorrowEnd = todayEnd.add(const Duration(days: 1));
    final weekEnd = todayEnd.add(const Duration(days: 7));

    final grouped = <_ReminderGroup, List<Reminder>>{
      _ReminderGroup.today: [],
      _ReminderGroup.tomorrow: [],
      _ReminderGroup.thisWeek: [],
      _ReminderGroup.later: [],
      _ReminderGroup.completed: [],
    };

    for (final r in reminders) {
      if (r.isCompleted) {
        grouped[_ReminderGroup.completed]!.add(r);
      } else if (!r.dueDate.isAfter(now)) {
        grouped[_ReminderGroup.today]!.add(r);
      } else if (r.dueDate.isBefore(tomorrowEnd)) {
        grouped[_ReminderGroup.today]!.add(r);
      } else if (r.dueDate.isBefore(tomorrowEnd.add(const Duration(days: 1)))) {
        grouped[_ReminderGroup.tomorrow]!.add(r);
      } else if (r.dueDate.isBefore(weekEnd)) {
        grouped[_ReminderGroup.thisWeek]!.add(r);
      } else {
        grouped[_ReminderGroup.later]!.add(r);
      }
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        if (grouped[_ReminderGroup.today]!.isNotEmpty) ...[
          SectionHeader(title: 'Today', subtitle: '${grouped[_ReminderGroup.today]!.length} reminders'),
          for (final r in grouped[_ReminderGroup.today]!)
            _ReminderCard(reminder: r, overdue: r.dueDate.isBefore(DateTime.now())),
          const SizedBox(height: 16),
        ],
        if (grouped[_ReminderGroup.tomorrow]!.isNotEmpty) ...[
          SectionHeader(title: 'Tomorrow', subtitle: '${grouped[_ReminderGroup.tomorrow]!.length} reminders'),
          for (final r in grouped[_ReminderGroup.tomorrow]!)
            _ReminderCard(reminder: r),
          const SizedBox(height: 16),
        ],
        if (grouped[_ReminderGroup.thisWeek]!.isNotEmpty) ...[
          SectionHeader(title: 'This Week', subtitle: '${grouped[_ReminderGroup.thisWeek]!.length} reminders'),
          for (final r in grouped[_ReminderGroup.thisWeek]!)
            _ReminderCard(reminder: r),
          const SizedBox(height: 16),
        ],
        if (grouped[_ReminderGroup.later]!.isNotEmpty) ...[
          SectionHeader(title: 'Later', subtitle: '${grouped[_ReminderGroup.later]!.length} reminders'),
          for (final r in grouped[_ReminderGroup.later]!)
            _ReminderCard(reminder: r),
          const SizedBox(height: 16),
        ],
        if (grouped[_ReminderGroup.completed]!.isNotEmpty) ...[
          SectionHeader(title: 'Completed', subtitle: '${grouped[_ReminderGroup.completed]!.length} reminders'),
          for (final r in grouped[_ReminderGroup.completed]!)
            Opacity(
              opacity: 0.5,
              child: _ReminderCard(reminder: r, completed: true),
            ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  final Reminder reminder;
  final bool overdue;
  final bool completed;

  const _ReminderCard({
    required this.reminder,
    this.overdue = false,
    this.completed = false,
  });

  Color _priorityColor(Priority p) {
    return switch (p) {
      Priority.high => AppColors.error,
      Priority.medium => AppColors.accentPrimary,
      Priority.low => AppColors.textSecondary,
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
        style: AppTextStyles.caption.copyWith(
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
    final isOverdue = overdue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOverdue
                  ? AppColors.error.withOpacity(0.3)
                  : color.withOpacity(0.2),
              width: isOverdue ? 1.5 : 1,
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
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isOverdue ? AppColors.error : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  reminder.title,
                  style: AppTextStyles.subtitle.copyWith(fontSize: 16),
                ),
                if (reminder.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reminder.note,
                    style: AppTextStyles.body.copyWith(fontSize: 13),
                  ),
                ],
                if (!completed) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _ActionChip(
                        icon: Icons.snooze_rounded,
                        label: 'Snooze',
                        color: AppColors.textSecondary,
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
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Reminder'),
                              content: const Text('This cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    actions.deleteReminder(reminder);
                                  },
                                  child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
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
                style: AppTextStyles.caption.copyWith(
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
