import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/court_event.dart';
import '../../reminders/providers/reminder_provider.dart';

final eventsBoxProvider = FutureProvider<Box<CourtEvent>>((ref) async {
  return Hive.openBox<CourtEvent>('court_events');
});

final eventsListProvider = FutureProvider<List<CourtEvent>>((ref) async {
  final box = await ref.watch(eventsBoxProvider.future);
  return box.values.toList();
});

final eventsMapProvider = Provider<Map<DateTime, List<CourtEvent>>>((ref) {
  final eventsAsync = ref.watch(eventsListProvider);
  return eventsAsync.when(
    data: (events) {
      final map = <DateTime, List<CourtEvent>>{};
      for (final event in events) {
        final date =
            DateTime(event.dateTime.year, event.dateTime.month, event.dateTime.day);
        map.putIfAbsent(date, () => []);
        map[date]!.add(event);
      }
      return map;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

final upcomingEventsProvider = Provider<List<CourtEvent>>((ref) {
  final eventsAsync = ref.watch(eventsListProvider);
  final now = DateTime.now();
  return eventsAsync.when(
    data: (events) {
      final upcoming = events.where((e) => e.dateTime.isAfter(now)).toList();
      upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return upcoming;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final todayEventsProvider = Provider.autoDispose<List<CourtEvent>>((ref) {
  final eventsAsync = ref.watch(eventsMapProvider);
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  return eventsAsync[todayDate] ?? [];
});

class CalendarActions {
  final Ref ref;

  CalendarActions(this.ref);

  Future<void> addEvent(CourtEvent event) async {
    final box = await ref.read(eventsBoxProvider.future);
    await box.put(event.id, event);
    await ref.read(reminderActionsProvider).addEventReminder(event);
    ref.invalidate(eventsListProvider);
  }

  Future<void> deleteEvent(String id) async {
    final box = await ref.read(eventsBoxProvider.future);
    await box.delete(id);
    await ref.read(reminderActionsProvider).deleteEventReminders(id);
    ref.invalidate(eventsListProvider);
  }
}

final calendarActionsProvider = Provider<CalendarActions>((ref) {
  return CalendarActions(ref);
});
