import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../features/scanner/model/pdf_document.dart';

class PdfFile {
  final String id;
  final String name;
  final String path;
  final DateTime createdAt;
  final int sizeInBytes;

  const PdfFile({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    required this.sizeInBytes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'createdAt': createdAt.toIso8601String(),
        'sizeInBytes': sizeInBytes,
      };

  factory PdfFile.fromJson(Map<String, dynamic> json) => PdfFile(
        id: json['id'] as String,
        name: json['name'] as String,
        path: json['path'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        sizeInBytes: json['sizeInBytes'] as int,
      );
}

final pdfBoxProvider = FutureProvider<Box<PdfDocument>>((ref) async {
  return Hive.openBox<PdfDocument>('pdf_documents');
});

final pdfListProvider = FutureProvider<List<PdfDocument>>((ref) async {
  final box = await ref.watch(pdfBoxProvider.future);
  final list = box.values.toList();
  list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return list;
});

final pdfFileBoxProvider = FutureProvider<Box<String>>((ref) async {
  return Hive.openBox<String>('pdf_files');
});

final pdfFileListProvider = FutureProvider<List<PdfFile>>((ref) async {
  final box = await ref.watch(pdfFileBoxProvider.future);
  final list = box.values
      .map((json) => PdfFile.fromJson(jsonDecode(json) as Map<String, dynamic>))
      .toList();
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

  Future<void> addPdf(PdfFile file) async {
    final box = await ref.read(pdfFileBoxProvider.future);
    await box.put(file.id, jsonEncode(file.toJson()));
    ref.invalidate(pdfFileListProvider);
  }

  Future<void> deleteFile(String id) async {
    final box = await ref.read(pdfFileBoxProvider.future);
    await box.delete(id);
    ref.invalidate(pdfFileListProvider);
  }

  Future<List<PdfFile>> getAllFiles() async {
    final box = await ref.read(pdfFileBoxProvider.future);
    return box.values
        .map((json) => PdfFile.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }
}

final pdfActionsProvider = Provider<PdfActions>((ref) {
  return PdfActions(ref);
});
