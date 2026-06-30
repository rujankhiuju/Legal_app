import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../notes/model/case_note.dart';
import '../../notes/providers/notes_provider.dart';
import '../../calendar/model/court_event.dart';
import '../../calendar/providers/calendar_provider.dart';

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
  final eventsAsync = ref.watch(upcomingEventsProvider);
  return eventsAsync.length;
});

final upcomingHearingsProvider = Provider<List<CourtEvent>>((ref) {
  return ref.watch(upcomingEventsProvider);
});
