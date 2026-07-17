import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/route_names.dart';
import '../../shared/widgets/staggered_animation.dart';
import '../../shared/widgets/polished_card.dart';
import 'model/court_event.dart';
import 'providers/calendar_provider.dart';

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

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtitleColor = isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle;

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

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            color: bgColor,
            child: Column(
              children: [
                if (_view != CalendarView.agenda)
                  _CalendarWidget(
                    view: _view,
                    focusedDate: _focusedDate,
                    selectedDate: _selectedDate,
                    eventsMap: eventsMap,
                    isDark: isDark,
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
                    isDark: isDark,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    onDelete: (id) {
                      HapticFeedback.lightImpact();
                      _confirmDelete(context, id);
                    },
                  ),
                if (_view == CalendarView.agenda)
                  _AgendaList(
                    eventsMap: eventsMap,
                    isDark: isDark,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    onDelete: (id) {
                      HapticFeedback.lightImpact();
                      _confirmDelete(context, id);
                    },
                  ),
              ],
            ),
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
  }

  void _confirmDelete(BuildContext context, String eventId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
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
  final bool isDark;
  final void Function(DateTime, DateTime) onDaySelected;
  final void Function(CalendarView) onFormatChanged;
  final void Function(DateTime) onPageChanged;

  const _CalendarWidget({
    required this.view,
    required this.focusedDate,
    required this.selectedDate,
    required this.eventsMap,
    required this.isDark,
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

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
            titleTextStyle: TextStyle(
              color: isDark ? AppColors.darkText : AppColors.lightText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            formatButtonTextStyle: TextStyle(
              color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
            ),
            formatButtonDecoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkAccent.withOpacity(0.15)
                  : AppColors.lightSecondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left_rounded,
              color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
            ),
          ),
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: TextStyle(
              color: isDark ? AppColors.darkBackground : AppColors.white,
              fontWeight: FontWeight.bold,
            ),
            todayDecoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkAccent.withOpacity(0.25)
                  : AppColors.lightSecondary.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(
              color: isDark ? AppColors.darkText : AppColors.lightText,
              fontWeight: FontWeight.bold,
            ),
            defaultTextStyle: TextStyle(
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
            weekendTextStyle: TextStyle(
              color: isDark
                  ? AppColors.darkText.withOpacity(0.6)
                  : AppColors.lightText.withOpacity(0.6),
            ),
            outsideTextStyle: TextStyle(
              color: isDark
                  ? AppColors.darkText.withOpacity(0.3)
                  : AppColors.lightText.withOpacity(0.3),
            ),
            markerDecoration: BoxDecoration(
              color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
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
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
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
  final bool isDark;
  final Color textColor;
  final Color subtitleColor;
  final void Function(String) onDelete;

  const _DayEventsList({
    required this.date,
    required this.events,
    required this.isDark,
    required this.textColor,
    required this.subtitleColor,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            children: [
              Icon(
                Icons.event_rounded,
                size: 18,
                color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                _monthDay(date),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkAccent.withOpacity(0.15)
                      : AppColors.lightSecondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${events.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...events.map((event) {
          final color = tryParseColor(event.colorHex) ?? AppColors.lightSecondary;
          return StaggeredFadeSlide(
            index: events.indexOf(event),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: PolishedCard(
                padding: const EdgeInsets.all(16),
                margin: EdgeInsets.zero,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pushNamed(
                        RouteNames.hearingDetail,
                        extra: event.id,
                      ),
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                event.caseName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13, color: subtitleColor),
                              ),
                              const SizedBox(height: 4),
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
                                    _time(event.dateTime),
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
    );
  }
}

class _AgendaList extends ConsumerWidget {
  final Map<DateTime, List<CourtEvent>> eventsMap;
  final bool isDark;
  final Color textColor;
  final Color subtitleColor;
  final void Function(String) onDelete;

  const _AgendaList({
    required this.eventsMap,
    required this.isDark,
    required this.textColor,
    required this.subtitleColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (eventsMap.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 64,
                color: isDark ? AppColors.darkSubtitle : AppColors.lightSubtitle,
              ),
              const SizedBox(height: 16),
              Text(
                'No events scheduled',
                style: TextStyle(color: subtitleColor),
              ),
            ],
          ),
        ),
      );
    }

    final sortedDates = eventsMap.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    '$dateStr - $dayName',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkAccent.withOpacity(0.15)
                          : AppColors.lightSecondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${dayEvents.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...dayEvents.map((event) => StaggeredFadeSlide(
                  index: dayEvents.indexOf(event),
                  child: _AgendaEventCard(
                    event: event,
                    isDark: isDark,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    onDelete: () => onDelete(event.id),
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
  final bool isDark;
  final Color textColor;
  final Color subtitleColor;
  final VoidCallback onDelete;

  const _AgendaEventCard({
    required this.event,
    required this.isDark,
    required this.textColor,
    required this.subtitleColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = tryParseColor(event.colorHex) ?? AppColors.lightSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: PolishedCard(
        padding: const EdgeInsets.all(16),
        margin: EdgeInsets.zero,
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
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    event.caseName,
                    style: TextStyle(fontSize: 13, color: subtitleColor),
                  ),
                ],
              ),
            ),
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
      ),
    );
  }
}
