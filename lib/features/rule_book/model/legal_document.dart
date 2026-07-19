import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

@immutable
class LegalDocument {
  final String id;
  final String titleEn;
  final String titleNp;
  final String category;
  final String contentEn;
  final String contentNp;
  final List<String> keywords;
  final bool isBookmarked;
  final DateTime? lastViewed;
  final String? sectionNumber;

  const LegalDocument({
    required this.id,
    required this.titleEn,
    required this.titleNp,
    required this.category,
    required this.contentEn,
    required this.contentNp,
    required this.keywords,
    this.isBookmarked = false,
    this.lastViewed,
    this.sectionNumber,
  });

  LegalDocument copyWith({
    String? id,
    String? titleEn,
    String? titleNp,
    String? category,
    String? contentEn,
    String? contentNp,
    List<String>? keywords,
    bool? isBookmarked,
    DateTime? lastViewed,
    String? sectionNumber,
    bool clearLastViewed = false,
    bool clearSectionNumber = false,
  }) {
    return LegalDocument(
      id: id ?? this.id,
      titleEn: titleEn ?? this.titleEn,
      titleNp: titleNp ?? this.titleNp,
      category: category ?? this.category,
      contentEn: contentEn ?? this.contentEn,
      contentNp: contentNp ?? this.contentNp,
      keywords: keywords ?? this.keywords,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      lastViewed: clearLastViewed ? null : (lastViewed ?? this.lastViewed),
      sectionNumber: clearSectionNumber ? null : (sectionNumber ?? this.sectionNumber),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegalDocument &&
          id == other.id &&
          isBookmarked == other.isBookmarked &&
          lastViewed == other.lastViewed;

  @override
  int get hashCode => id.hashCode;
}

class LegalDocumentAdapter extends TypeAdapter<LegalDocument> {
  @override
  final int typeId = 0;

  @override
  LegalDocument read(BinaryReader reader) {
    final version = reader.readByte();
    final id = reader.readString();
    final titleEn = reader.readString();
    final titleNp = reader.readString();
    final category = reader.readString();
    final contentEn = reader.readString();
    final contentNp = reader.readString();
    final keywords = reader.readStringList();
    final isBookmarked = reader.readBool();
    final hasLastViewed = reader.readBool();
    final lastViewed =
        hasLastViewed ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null;

    String? sectionNumber;
    if (version >= 2) {
      final hasSectionNumber = reader.readBool();
      if (hasSectionNumber) {
        sectionNumber = reader.readString();
      }
    }

    return LegalDocument(
      id: id,
      titleEn: titleEn,
      titleNp: titleNp,
      category: category,
      contentEn: contentEn,
      contentNp: contentNp,
      keywords: keywords ?? [],
      isBookmarked: isBookmarked,
      lastViewed: lastViewed,
      sectionNumber: sectionNumber,
    );
  }

  @override
  void write(BinaryWriter writer, LegalDocument obj) {
    writer.writeByte(2);
    writer.writeString(obj.id);
    writer.writeString(obj.titleEn);
    writer.writeString(obj.titleNp);
    writer.writeString(obj.category);
    writer.writeString(obj.contentEn);
    writer.writeString(obj.contentNp);
    writer.writeStringList(obj.keywords);
    writer.writeBool(obj.isBookmarked);
    writer.writeBool(obj.lastViewed != null);
    if (obj.lastViewed != null) {
      writer.writeInt(obj.lastViewed!.millisecondsSinceEpoch);
    }
    writer.writeBool(obj.sectionNumber != null);
    if (obj.sectionNumber != null) {
      writer.writeString(obj.sectionNumber!);
    }
  }
}
