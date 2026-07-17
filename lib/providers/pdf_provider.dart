import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../features/scanner/model/pdf_document.dart';

final pdfBoxProvider = FutureProvider<Box<PdfDocument>>((ref) async {
  return Hive.openBox<PdfDocument>('pdf_documents');
});

final pdfListProvider = FutureProvider<List<PdfDocument>>((ref) async {
  final box = await ref.watch(pdfBoxProvider.future);
  final list = box.values.toList();
  list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return list;
});

class PdfActions {
  final Ref ref;

  PdfActions(this.ref);

  Future<void> savePdf(PdfDocument doc) async {
    final box = await ref.read(pdfBoxProvider.future);
    await box.put(doc.id, doc);
    ref.invalidate(pdfListProvider);
  }

  Future<void> renamePdf(String id, String newTitle) async {
    final box = await ref.read(pdfBoxProvider.future);
    final doc = box.get(id);
    if (doc == null) return;
    final updated = doc.copyWith(title: newTitle);
    await box.put(id, updated);
    ref.invalidate(pdfListProvider);
  }

  Future<void> deletePdf(String id) async {
    final box = await ref.read(pdfBoxProvider.future);
    await box.delete(id);
    ref.invalidate(pdfListProvider);
  }
}

final pdfActionsProvider = Provider<PdfActions>((ref) {
  return PdfActions(ref);
});
