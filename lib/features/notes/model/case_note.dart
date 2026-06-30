import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

@immutable
class CaseNote {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CaseNote({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    this.pinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  CaseNote copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    bool? pinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CaseNote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      pinned: pinned ?? this.pinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaseNote &&
          id == other.id &&
          pinned == other.pinned &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => id.hashCode;
}

class CaseNoteAdapter extends TypeAdapter<CaseNote> {
  @override
  final int typeId = 1;

  @override
  CaseNote read(BinaryReader reader) {
    final id = reader.readString();
    final title = reader.readString();
    final content = reader.readString();
    final tags = reader.readStringList() ?? [];
    final pinned = reader.readBool();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());

    return CaseNote(
      id: id,
      title: title,
      content: content,
      tags: tags,
      pinned: pinned,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  void write(BinaryWriter writer, CaseNote obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.content);
    writer.writeStringList(obj.tags);
    writer.writeBool(obj.pinned);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }
}
