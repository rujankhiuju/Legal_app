import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/case_note.dart';

final notesBoxProvider = FutureProvider<Box<CaseNote>>((ref) async {
  return Hive.openBox<CaseNote>('case_notes');
});

final notesListProvider = FutureProvider<List<CaseNote>>((ref) async {
  final box = await ref.watch(notesBoxProvider.future);
  return box.values.toList();
});

final notesSearchQueryProvider = StateProvider<String>((ref) => '');

final sortedNotesProvider = Provider<List<CaseNote>>((ref) {
  final notesAsync = ref.watch(notesListProvider);
  final query = ref.watch(notesSearchQueryProvider).trim().toLowerCase();

  return notesAsync.when(
    loading: () => [],
    error: (_, __) => [],
    data: (notes) {
      var filtered = notes;
      if (query.isNotEmpty) {
        filtered = notes.where((note) {
          return note.title.toLowerCase().contains(query) ||
              note.content.toLowerCase().contains(query) ||
              note.tags.any((t) => t.toLowerCase().contains(query));
        }).toList();
      }

      filtered.sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

      return filtered;
    },
  );
});

class NotesActions {
  final Ref ref;

  NotesActions(this.ref);

  Future<void> addNote(CaseNote note) async {
    final box = await ref.read(notesBoxProvider.future);
    await box.put(note.id, note);
    ref.invalidate(notesListProvider);
  }

  Future<void> updateNote(CaseNote note) async {
    final box = await ref.read(notesBoxProvider.future);
    await box.put(note.id, note);
    ref.invalidate(notesListProvider);
  }

  Future<void> deleteNote(String id) async {
    final box = await ref.read(notesBoxProvider.future);
    await box.delete(id);
    ref.invalidate(notesListProvider);
  }

  Future<void> togglePin(CaseNote note) async {
    final box = await ref.read(notesBoxProvider.future);
    final updated = note.copyWith(
      pinned: !note.pinned,
      updatedAt: DateTime.now(),
    );
    await box.put(note.id, updated);
    ref.invalidate(notesListProvider);
  }
}

final notesActionsProvider = Provider<NotesActions>((ref) {
  return NotesActions(ref);
});
