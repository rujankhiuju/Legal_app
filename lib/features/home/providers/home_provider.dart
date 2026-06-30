import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../notes/model/case_note.dart';
import '../../notes/providers/notes_provider.dart';
import '../../calendar/model/court_event.dart';
import '../../calendar/providers/calendar_provider.dart';
import '../../reminders/model/reminder.dart';
import '../../reminders/providers/reminder_provider.dart';

final recentNotesProvider = Provider<List<CaseNote>>((ref) {
  final notesAsync = ref.watch(notesListProvider);
  return notesAsync.when(
    data: (notes) {
      final sorted = List<CaseNote>.from(notes);
      sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return sorted.take(3).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final pendingRemindersCountProvider = Provider<int>((ref) {
  final eventsCount = ref.watch(upcomingEventsProvider).length;
  final reminders = ref.watch(remindersListProvider);
  final reminderCount = reminders.when(
    data: (r) => r.where((r) => !r.isCompleted).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
  return eventsCount + reminderCount;
});

final upcomingHearingsProvider = Provider<List<CourtEvent>>((ref) {
  return ref.watch(upcomingEventsProvider);
});
