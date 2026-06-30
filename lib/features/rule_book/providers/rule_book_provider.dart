import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/legal_document.dart';
import '../data/seed_data.dart';

final legalDocsBoxProvider = FutureProvider<Box<LegalDocument>>((ref) async {
  return Hive.openBox<LegalDocument>('legal_docs');
});

final recentIdsBoxProvider = FutureProvider<Box>((ref) async {
  return Hive.openBox('recent_views');
});

final legalDocsProvider = FutureProvider<List<LegalDocument>>((ref) async {
  final box = await ref.watch(legalDocsBoxProvider.future);
  if (box.isEmpty) {
    final seedDocs = seedLegalDocuments();
    final map = {for (final doc in seedDocs) doc.id: doc};
    await box.putAll(map);
  }
  return box.values.toList();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredDocsProvider =
    Provider<Map<String, List<LegalDocument>>>((ref) {
  final docsAsync = ref.watch(legalDocsProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  return docsAsync.when(
    loading: () => {},
    error: (_, __) => {},
    data: (docs) {
      var filtered = docs;
      if (query.isNotEmpty) {
        filtered = docs.where((doc) {
          return doc.titleEn.toLowerCase().contains(query) ||
              doc.titleNp.toLowerCase().contains(query) ||
              doc.contentEn.toLowerCase().contains(query) ||
              doc.contentNp.toLowerCase().contains(query) ||
              doc.keywords.any((k) => k.toLowerCase().contains(query));
        }).toList();
      }

      final Map<String, List<LegalDocument>> grouped = {};
      for (final doc in filtered) {
        grouped.putIfAbsent(doc.category, () => []);
        grouped[doc.category]!.add(doc);
      }
      return grouped;
    },
  );
});

final recentDocIdsProvider = FutureProvider<List<String>>((ref) async {
  final box = await ref.watch(recentIdsBoxProvider.future);
  final raw = box.get('ids', defaultValue: <String>[]);
  if (raw is List) {
    return raw.cast<String>().toList();
  }
  return [];
});

final recentDocsProvider = FutureProvider<List<LegalDocument>>((ref) async {
  final ids = await ref.watch(recentDocIdsProvider.future);
  if (ids.isEmpty) return [];
  final box = await ref.watch(legalDocsBoxProvider.future);
  return ids.map((id) => box.get(id)).whereType<LegalDocument>().toList();
});

final legalDocByIdProvider =
    FutureProvider.family<LegalDocument?, String>((ref, id) async {
  final box = await ref.watch(legalDocsBoxProvider.future);
  return box.get(id);
});

class RuleBookActions {
  final Ref ref;

  RuleBookActions(this.ref);

  Future<void> toggleBookmark(LegalDocument doc) async {
    final box = await ref.read(legalDocsBoxProvider.future);
    final updated = doc.copyWith(isBookmarked: !doc.isBookmarked);
    await box.put(doc.id, updated);
    ref.invalidate(legalDocsProvider);
  }

  Future<void> markAsViewed(LegalDocument doc) async {
    final box = await ref.read(legalDocsBoxProvider.future);
    final updated = doc.copyWith(lastViewed: DateTime.now());
    await box.put(doc.id, updated);

    final recentBox = await ref.read(recentIdsBoxProvider.future);
    final ids = List<String>.from(
        (recentBox.get('ids', defaultValue: []) as List).cast<String>());
    ids.remove(doc.id);
    ids.insert(0, doc.id);
    if (ids.length > 10) ids.removeLast();
    await recentBox.put('ids', ids);

    ref.invalidate(legalDocsProvider);
    ref.invalidate(recentDocsProvider);
    ref.invalidate(recentDocIdsProvider);
  }
}

final ruleBookActionsProvider = Provider<RuleBookActions>((ref) {
  return RuleBookActions(ref);
});
