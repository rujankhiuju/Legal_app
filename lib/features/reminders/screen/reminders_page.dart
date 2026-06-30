import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/staggered_animation.dart';
import '../model/reminder.dart';
import '../providers/reminder_provider.dart';

class RemindersPage extends ConsumerWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.deepNavy : AppColors.lightBackground;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
      ),
      body: Container(
        color: bgColor,
        child: ref.watch(sortedRemindersProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (reminders) {
            if (reminders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 72, color: AppColors.gold.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text(
                      'All caught up!',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.white.withValues(alpha: 0.7)
                            : AppColors.deepNavy.withValues(alpha: 0.7),
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              children: [
                if (overdue.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, size: 18, color: Colors.redAccent),
                        const SizedBox(width: 6),
                        Text(
                          'Overdue (${overdue.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.redAccent,
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
                  const SizedBox(height: 16),
                ],
                if (upcoming.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, size: 18, color: AppColors.gold),
                        const SizedBox(width: 6),
                        Text(
                          'Upcoming',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark ? AppColors.white : AppColors.deepNavy,
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
          },
        ),
      ),
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
      Priority.high => const Color(0xFFE53E3E),
      Priority.medium => const Color(0xFFDD6B20),
      Priority.low => AppColors.gold,
    };
  }

  String _priorityLabel(Priority p) {
    return p.name.toUpperCase();
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
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _priorityColor(reminder.priority);
    final actions = ref.read(reminderActionsProvider);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.white;
    final textColor = isDark ? AppColors.white : AppColors.deepNavy;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: overdue ? Colors.redAccent.withValues(alpha: 0.4) : color.withValues(alpha: 0.2),
          width: overdue ? 1.5 : 1,
        ),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: overdue ? Colors.redAccent.withValues(alpha: 0.06) : cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _priorityLabel(reminder.priority),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _time(reminder.dueDate),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: overdue ? Colors.redAccent : textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                reminder.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: textColor,
                ),
              ),
              if (reminder.note.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  reminder.note,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withValues(alpha: 0.65),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _ActionChip(
                    icon: Icons.snooze,
                    label: 'Snooze',
                    color: AppColors.darkBlue,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      actions.snooze(reminder);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Snoozed 15 min'), duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  _ActionChip(
                    icon: Icons.check_circle_outline,
                    label: 'Complete',
                    color: const Color(0xFF38A169),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      actions.markComplete(reminder);
                    },
                  ),
                  const SizedBox(width: 6),
                  _ActionChip(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: Colors.redAccent,
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
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
