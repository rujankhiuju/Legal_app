import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/route_names.dart';
import '../../shared/widgets/polished_card.dart';
import 'model/court_event.dart';
import 'providers/calendar_provider.dart';

Color? tryParseColor(String hex) {
  try {
    final h = hex.replaceFirst('#', '');
    if (h.length != 6 && h.length != 8) return null;
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return null;
  }
}

class HearingDetailScreen extends ConsumerWidget {
  final String eventId;

  const HearingDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtitleColor = isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    final eventsAsync = ref.watch(eventsListProvider);

    return Scaffold(
      backgroundColor: bgColor,
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (events) {
          final event = events.where((e) => e.id == eventId).firstOrNull;
          if (event == null) {
            return const Center(child: Text('Event not found'));
          }
          final color = tryParseColor(event.colorHex) ?? AppColors.lightSecondary;

          return SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightCard,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: textColor),
                    onPressed: () => context.pop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.3),
                            bgColor,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Hero(
                            tag: 'hearing_color_${event.id}',
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                event.isHearing ? Icons.gavel_rounded : Icons.event_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Hero(
                              tag: 'hearing_title_${event.id}',
                              child: Material(
                                color: Colors.transparent,
                                child: Text(
                                  event.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PolishedCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoRow(
                                icon: Icons.badge_rounded,
                                label: 'Case Name',
                                value: event.caseName,
                                isDark: isDark,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              ),
                              const SizedBox(height: 16),
                              _InfoRow(
                                icon: Icons.calendar_today_rounded,
                                label: 'Date & Time',
                                value: '${_formatDate(event.dateTime)} at ${_formatTime(event.dateTime)}',
                                isDark: isDark,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              ),
                              const SizedBox(height: 16),
                              _InfoRow(
                                icon: Icons.label_rounded,
                                label: 'Type',
                                value: event.isHearing ? 'Hearing' : 'Event',
                                isDark: isDark,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Color Code',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: subtitleColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      event.colorHex,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (event.notes.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          PolishedCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notes',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  event.notes,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.edit_rounded,
                                label: 'Edit',
                                color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                                isDark: isDark,
                                onTap: () {
                                  context.pop();
                                  context.pushNamed(RouteNames.addHearing, extra: event);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.delete_outline_rounded,
                                label: 'Delete',
                                color: AppColors.error,
                                isDark: isDark,
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                      title: const Text('Delete Event'),
                                      content: const Text('Are you sure? This cannot be undone.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(ctx).pop();
                                            ref.read(calendarActionsProvider).deleteEvent(event.id);
                                            context.pop();
                                          },
                                          child: Text('Delete', style: TextStyle(color: AppColors.error)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return '${days[dt.weekday % 7]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color textColor;
  final Color subtitleColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkAccent.withOpacity(0.12)
                : AppColors.lightSecondary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: isDark ? AppColors.darkAccent : AppColors.lightSecondary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: subtitleColor)),
              const SizedBox(height: 3),
              Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
