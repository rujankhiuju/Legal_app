import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/route_names.dart';
import '../../shared/widgets/staggered_animation.dart';
import 'model/court_event.dart';
import 'providers/calendar_provider.dart';

enum CalendarView { month, week, agenda }

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

  Color _parseColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  List<CourtEvent> _eventsForDate(DateTime date, Map<DateTime, List<CourtEvent>> map) {
    final d = DateTime(date.year, date.month, date.day);
    return map[d] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.deepNavy : AppColors.lightBackground;
    final textColor = isDark ? AppColors.white : AppColors.deepNavy;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.white;

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
        final allDates = eventsMap.keys.toSet();

        return SingleChildScrollView(
          child: Container(
            color: bgColor,
            child: Column(
              children: [
                if (_view != CalendarView.agenda)
                  _CalendarWidget(
                    view: _view,
                    focusedDate: _focusedDate,
                    selectedDate: _selectedDate,
                    allDates: allDates,
                    eventsMap: eventsMap,
                    isDark: isDark,
                    onDaySelected: (sel, foc) {
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
                if (_view == CalendarView.agenda)
                  _AgendaList(
                    eventsMap: eventsMap,
                    isDark: isDark,
                    textColor: textColor,
                    cardBg: cardBg,
                    onDelete: (id) {
                      HapticFeedback.lightImpact();
                      ref.read(calendarActionsProvider).deleteEvent(id);
                    },
                  ),
                if (dayEvents.isNotEmpty && _view != CalendarView.agenda)
                  _DayEventsList(
                    date: _selectedDate,
                    events: dayEvents,
                    isDark: isDark,
                    textColor: textColor,
                    cardBg: cardBg,
                    onDelete: (id) {
                      HapticFeedback.lightImpact();
                      ref.read(calendarActionsProvider).deleteEvent(id);
                    },
                  ),
              ],
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.deepNavy,
        onPressed: () {
          context.pushNamed(RouteNames.addHearing, extra: null);
        },
        child: const Icon(Icons.add),
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
  final Set<DateTime> allDates;
  final Map<DateTime, List<CourtEvent>> eventsMap;
  final bool isDark;
  final void Function(DateTime, DateTime) onDaySelected;
  final void Function(CalendarView) onFormatChanged;
  final void Function(DateTime) onPageChanged;

  const _CalendarWidget({
    required this.view,
    required this.focusedDate,
    required this.selectedDate,
    required this.allDates,
    required this.eventsMap,
    required this.isDark,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
  });

  Color _parseColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final format = switch (view) {
      CalendarView.month => CalendarFormat.month,
      CalendarView.week => CalendarFormat.week,
      CalendarView.agenda => CalendarFormat.month,
    };

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
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
          headerPadding: const EdgeInsets.symmetric(vertical: 8),
          titleTextStyle: TextStyle(
            color: isDark ? AppColors.white : AppColors.deepNavy,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          formatButtonTextStyle: const TextStyle(color: AppColors.gold),
          formatButtonDecoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.gold),
          rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.gold),
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: const BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.bold),
          todayDecoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: isDark ? AppColors.white : AppColors.deepNavy,
            fontWeight: FontWeight.bold,
          ),
          defaultTextStyle: TextStyle(color: isDark ? AppColors.white : AppColors.deepNavy),
          weekendTextStyle: TextStyle(
            color: isDark ? AppColors.white.withOpacity(0.6) : AppColors.deepNavy.withOpacity(0.6),
          ),
          outsideTextStyle: TextStyle(
            color: isDark ? AppColors.white.withOpacity(0.3) : AppColors.deepNavy.withOpacity(0.3),
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
          ),
        ),
        eventLoader: (day) {
          return eventsMap[DateTime(day.year, day.month, day.day)] ?? [];
        },
      ),
    );
  }
}

class _DayEventsList extends StatelessWidget {
  final DateTime date;
  final List<CourtEvent> events;
  final bool isDark;
  final Color textColor;
  final Color cardBg;
  final void Function(String) onDelete;

  const _DayEventsList({
    required this.date,
    required this.events,
    required this.isDark,
    required this.textColor,
    required this.cardBg,
    required this.onDelete,
  });

  String _month(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m[d.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.event, size: 16, color: AppColors.gold),
                const SizedBox(width: 6),
                Text(
                  '${_month(date)} ${date.day}, ${date.year}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          ...events.asMap().entries.map((entry) {
            return StaggeredFadeSlide(
              index: entry.key,
              child: _EventCard(event: entry.value, isDark: isDark, textColor: textColor, cardBg: cardBg, onDelete: onDelete),
            );
          }),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CourtEvent event;
  final bool isDark;
  final Color textColor;
  final Color cardBg;
  final void Function(String) onDelete;

  const _EventCard({
    required this.event,
    required this.isDark,
    required this.textColor,
    required this.cardBg,
    required this.onDelete,
  });

  Color _parseColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  String _time(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(event.colorHex);

    return Dismissible(
      key: ValueKey(event.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.white, size: 28),
      ),
      onDismissed: (_) => onDelete(event.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 2),
                  Text(
                    event.caseName,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _time(event.dateTime),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaList extends ConsumerWidget {
  final Map<DateTime, List<CourtEvent>> eventsMap;
  final bool isDark;
  final Color textColor;
  final Color cardBg;
  final void Function(String) onDelete;

  const _AgendaList({
    required this.eventsMap,
    required this.isDark,
    required this.textColor,
    required this.cardBg,
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
              Icon(Icons.event_busy, size: 64, color: AppColors.gold.withOpacity(0.4)),
              const SizedBox(height: 16),
              Text('No events scheduled', style: TextStyle(color: textColor.withOpacity(0.6))),
            ],
          ),
        ),
      );
    }

    final sortedDates = eventsMap.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.list, size: 18, color: AppColors.gold),
                SizedBox(width: 6),
                Text(
                  'All Events',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          ...sortedDates.expand((date) {
            final events = eventsMap[date]!;
            final m = [
              'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
            ];
            return [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  '${m[date.month - 1]} ${date.day}, ${date.year}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
              ...events.map((event) => _EventCard(
                event: event,
                isDark: isDark,
                textColor: textColor,
                cardBg: cardBg,
                onDelete: onDelete,
              )),
            ];
          }),
        ],
      ),
    );
  }
}
