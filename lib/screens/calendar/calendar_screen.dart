import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/route_names.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/staggered_animation.dart';
import '../../features/calendar/model/court_event.dart';
import '../../features/calendar/providers/calendar_provider.dart';

const double _desktopBreakpoint = 900;

enum CalendarView { month, week, agenda }

Color? tryParseColor(String hex) {
  try {
    final h = hex.replaceFirst('#', '');
    if (h.length != 6 && h.length != 8) return null;
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return null;
  }
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarView _view = CalendarView.month;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  late PageController _agendaController;

  @override
  void initState() {
    super.initState();
    _agendaController = PageController();
  }

  @override
  void dispose() {
    _agendaController.dispose();
    super.dispose();
  }

  List<CourtEvent> _eventsForDate(DateTime date, Map<DateTime, List<CourtEvent>> map) {
    final d = DateTime(date.year, date.month, date.day);
    return map[d] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > _desktopBreakpoint;
        final iconSize = isDesktop ? 28.0 : 22.0;
        final titleSize = isDesktop ? 22.0 : 18.0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Calendar'),
            actions: [
              _ViewToggle(
                view: _view,
                onChanged: (v) => setState(() => _view = v),
              ),
            ],
          ),
          body: Builder(builder: (context) {
            final eventsMap = ref.watch(eventsMapProvider);
            final dayEvents = _eventsForDate(_selectedDate, eventsMap);

            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 400,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          if (_view != CalendarView.agenda)
                            _CalendarWidget(
                              view: _view,
                              focusedDate: _focusedDate,
                              selectedDate: _selectedDate,
                              eventsMap: eventsMap,
                              onDaySelected: (sel, foc) {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _selectedDate = sel;
                                  _focusedDate = foc;
                                });
                              },
                              onFormatChanged: (v) {
                                setState(() => _view = v);
                              },
                              onPageChanged: (foc) {
                                setState(() => _focusedDate = foc);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: AppColors.divider),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (dayEvents.isNotEmpty && _view != CalendarView.agenda)
                            _DayEventsList(
                              date: _selectedDate,
                              events: dayEvents,
                              onDelete: (id) {
                                HapticFeedback.lightImpact();
                                _confirmDelete(context, id);
                              },
                            ),
                          if (_view == CalendarView.agenda)
                            _AgendaList(
                              eventsMap: eventsMap,
                              onDelete: (id) {
                                HapticFeedback.lightImpact();
                                _confirmDelete(context, id);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  if (_view != CalendarView.agenda)
                    _CalendarWidget(
                      view: _view,
                      focusedDate: _focusedDate,
                      selectedDate: _selectedDate,
                      eventsMap: eventsMap,
                      onDaySelected: (sel, foc) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _selectedDate = sel;
                          _focusedDate = foc;
                        });
                      },
                      onFormatChanged: (v) {
                        setState(() => _view = v);
                      },
                      onPageChanged: (foc) {
                        setState(() => _focusedDate = foc);
                      },
                    ),
                  if (dayEvents.isNotEmpty && _view != CalendarView.agenda)
                    _DayEventsList(
                      date: _selectedDate,
                      events: dayEvents,
                      onDelete: (id) {
                        HapticFeedback.lightImpact();
                        _confirmDelete(context, id);
                      },
                    ),
                  if (_view == CalendarView.agenda)
                    _AgendaList(
                      eventsMap: eventsMap,
                      onDelete: (id) {
                        HapticFeedback.lightImpact();
                        _confirmDelete(context, id);
                      },
                    ),
                ],
              ),
            );
          }),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              context.pushNamed(RouteNames.addHearing);
            },
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String eventId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(calendarActionsProvider).deleteEvent(eventId);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final CalendarView view;
  final ValueChanged<CalendarView> onChanged;

  const _ViewToggle({required this.view, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SegmentedButton<CalendarView>(
        segments: const [
          ButtonSegment(value: CalendarView.month, label: Text('M', style: TextStyle(fontSize: 12))),
          ButtonSegment(value: CalendarView.week, label: Text('W', style: TextStyle(fontSize: 12))),
          ButtonSegment(value: CalendarView.agenda, label: Text('A', style: TextStyle(fontSize: 12))),
        ],
        selected: {view},
        onSelectionChanged: (v) => onChanged(v.first),
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _CalendarWidget extends StatelessWidget {
  final CalendarView view;
  final DateTime focusedDate;
  final DateTime selectedDate;
  final Map<DateTime, List<CourtEvent>> eventsMap;
  final void Function(DateTime, DateTime) onDaySelected;
  final void Function(CalendarView) onFormatChanged;
  final void Function(DateTime) onPageChanged;

  const _CalendarWidget({
    required this.view,
    required this.focusedDate,
    required this.selectedDate,
    required this.eventsMap,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final format = switch (view) {
      CalendarView.month => CalendarFormat.month,
      CalendarView.week => CalendarFormat.week,
      CalendarView.agenda => CalendarFormat.month,
    };

    return Padding(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: focusedDate,
            selectedDayPredicate: (day) => isSameDay(day, selectedDate),
            calendarFormat: format,
            availableCalendarFormats: const {
              CalendarFormat.month: '',
              CalendarFormat.week: '',
            },
            eventLoader: (day) => _eventsForDate(day, eventsMap),
            onFormatChanged: (f) {
              onFormatChanged(
                f == CalendarFormat.month ? CalendarView.month : CalendarView.week,
              );
            },
            onDaySelected: (sel, foc) => onDaySelected(sel, foc),
            onPageChanged: onPageChanged,
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              headerPadding: const EdgeInsets.symmetric(vertical: 12),
              titleTextStyle: AppTextStyles.subtitle.copyWith(fontSize: 16),
              formatButtonTextStyle: const TextStyle(color: AppColors.accentPrimary),
              formatButtonDecoration: BoxDecoration(
                color: AppColors.accentPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: AppColors.accentPrimary),
              rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: AppColors.accentPrimary),
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: AppColors.accentPrimary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: AppColors.primaryBg,
                fontWeight: FontWeight.bold,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.accentPrimary.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
              weekendTextStyle: TextStyle(
                color: AppColors.textPrimary.withOpacity(0.6),
              ),
              outsideTextStyle: TextStyle(
                color: AppColors.textPrimary.withOpacity(0.3),
              ),
              markerDecoration: const BoxDecoration(
                color: AppColors.accentPrimary,
                shape: BoxShape.circle,
              ),
              cellMargin: const EdgeInsets.all(4),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                final colors = events
                    .map((e) => tryParseColor((e as CourtEvent).colorHex))
                    .whereType<Color>()
                    .toSet()
                    .toList();
                if (colors.isEmpty) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 28),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.accentPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 28),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: colors.take(3).map((c) {
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<CourtEvent> _eventsForDate(DateTime date, Map<DateTime, List<CourtEvent>> map) {
    final d = DateTime(date.year, date.month, date.day);
    return map[d] ?? [];
  }
}

class _DayEventsList extends StatelessWidget {
  final DateTime date;
  final List<CourtEvent> events;
  final void Function(String) onDelete;

  const _DayEventsList({
    required this.date,
    required this.events,
    required this.onDelete,
  });

  String _monthDay(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  String _time(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_rounded, size: 18, color: AppColors.accentPrimary),
              const SizedBox(width: 8),
              Text(
                _monthDay(date),
                style: AppTextStyles.subtitle.copyWith(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${events.length}',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...events.map((event) {
            final color = tryParseColor(event.colorHex) ?? AppColors.accentPrimary;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => context.pushNamed(RouteNames.hearingDetail, extra: event),
                child: AppCard(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pushNamed(RouteNames.hearingDetail, extra: event),
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
                            Column(
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
                                      _time(event.dateTime),
                                      style: AppTextStyles.caption.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.accentPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => onDelete(event.id),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AgendaList extends ConsumerWidget {
  final Map<DateTime, List<CourtEvent>> eventsMap;
  final void Function(String) onDelete;

  const _AgendaList({
    required this.eventsMap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (eventsMap.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_busy_rounded, size: 64, color: AppColors.textSecondary),
              SizedBox(height: 16),
              Text('No events scheduled', style: AppTextStyles.body),
            ],
          ),
        ),
      );
    }

    final sortedDates = eventsMap.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIndex) {
        final date = sortedDates[dateIndex];
        final dayEvents = eventsMap[date]!;
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final dateStr = '${months[date.month - 1]} ${date.day}, ${date.year}';
        final dayName = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][date.weekday % 7];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Row(
                children: [
                  Text(
                    '$dateStr - $dayName',
                    style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${dayEvents.length}',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...dayEvents.map((event) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: StaggeredFadeSlide(
                index: dayEvents.indexOf(event),
                child: _AgendaEventCard(
                  event: event,
                  onDelete: () => onDelete(event.id),
                ),
              ),
            )),
          ],
        );
      },
    );
  }
}

class _AgendaEventCard extends StatelessWidget {
  final CourtEvent event;
  final VoidCallback onDelete;

  const _AgendaEventCard({
    required this.event,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = tryParseColor(event.colorHex) ?? AppColors.accentPrimary;
    return AppCard(
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pushNamed(RouteNames.hearingDetail, extra: event),
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      event.caseName,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
