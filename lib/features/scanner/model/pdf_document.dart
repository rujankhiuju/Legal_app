import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

@immutable
class PdfDocument {
  final String id;
  final String title;
  final String filePath;
  final int pageCount;
  final DateTime createdAt;

  const PdfDocument({
    required this.id,
    required this.title,
    required this.filePath,
    required this.pageCount,
    required this.createdAt,
  });

  PdfDocument copyWith({
    String? id,
    String? title,
    String? filePath,
    int? pageCount,
    DateTime? createdAt,
  }) {
    return PdfDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      pageCount: pageCount ?? this.pageCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfDocument && id == other.id && title == other.title;

  @override
  int get hashCode => id.hashCode;
}

class PdfDocumentAdapter extends TypeAdapter<PdfDocument> {
  @override
  final int typeId = 4;

  @override
  PdfDocument read(BinaryReader reader) {
    final id = reader.readString();
    final title = reader.readString();
    final filePath = reader.readString();
    final pageCount = reader.readInt();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());

    return PdfDocument(
      id: id,
      title: title,
      filePath: filePath,
      pageCount: pageCount,
      createdAt: createdAt,
    );
  }

  @override
  void write(BinaryWriter writer, PdfDocument obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.filePath);
    writer.writeInt(obj.pageCount);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}
