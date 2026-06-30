import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/pdf_document.dart';

final pdfBoxProvider = FutureProvider<Box<PdfDocument>>((ref) async {
  return Hive.openBox<PdfDocument>('pdf_documents');
});

final pdfListProvider = FutureProvider<List<PdfDocument>>((ref) async {
  final box = await ref.watch(pdfBoxProvider.future);
  final list = box.values.toList();
  list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return list;
});

final scannedImagePathsProvider = StateNotifierProvider<ScannedImagesNotifier, List<String>>((ref) {
  return ScannedImagesNotifier();
});

class ScannedImagesNotifier extends StateNotifier<List<String>> {
  ScannedImagesNotifier() : super([]);

  void add(String path) => state = [...state, path];
  void remove(int index) => state = [...state]..removeAt(index);
  void replace(int index, String path) {
    final list = [...state];
    list[index] = path;
    state = list;
  }

  void clear() => state = [];
}

class PdfActions {
  final Ref ref;

  PdfActions(this.ref);

  Future<PdfDocument> savePdf({
    required String title,
    required String filePath,
    required int pageCount,
  }) async {
    final box = await ref.read(pdfBoxProvider.future);
    final doc = PdfDocument(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      filePath: filePath,
      pageCount: pageCount,
      createdAt: DateTime.now(),
    );
    await box.put(doc.id, doc);
    ref.invalidate(pdfListProvider);
    return doc;
  }

  Future<void> rename(PdfDocument doc, String newTitle) async {
    final box = await ref.read(pdfBoxProvider.future);
    await box.put(doc.id, doc.copyWith(title: newTitle));
    ref.invalidate(pdfListProvider);
  }

  Future<void> delete(PdfDocument doc) async {
    final box = await ref.read(pdfBoxProvider.future);
    await box.delete(doc.id);
    ref.invalidate(pdfListProvider);
  }
}

final pdfActionsProvider = Provider<PdfActions>((ref) => PdfActions(ref));
