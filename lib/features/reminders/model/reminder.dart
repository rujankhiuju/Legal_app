import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

enum Priority { high, medium, low }

@immutable
class Reminder {
  final String id;
  final String title;
  final String note;
  final Priority priority;
  final DateTime dueDate;
  final bool isCompleted;
  final String? relatedEventId;
  final DateTime createdAt;

  const Reminder({
    required this.id,
    required this.title,
    this.note = '',
    this.priority = Priority.medium,
    required this.dueDate,
    this.isCompleted = false,
    this.relatedEventId,
    required this.createdAt,
  });

  Reminder copyWith({
    String? id,
    String? title,
    String? note,
    Priority? priority,
    DateTime? dueDate,
    bool? isCompleted,
    String? relatedEventId,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      relatedEventId: relatedEventId ?? this.relatedEventId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reminder &&
          id == other.id &&
          isCompleted == other.isCompleted &&
          dueDate == other.dueDate;

  @override
  int get hashCode => id.hashCode;
}

class ReminderAdapter extends TypeAdapter<Reminder> {
  @override
  final int typeId = 3;

  @override
  Reminder read(BinaryReader reader) {
    final id = reader.readString();
    final title = reader.readString();
    final note = reader.readString();
    final priority = Priority.values[reader.readByte()];
    final dueDate = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final isCompleted = reader.readBool();
    final hasRelated = reader.readBool();
    final relatedEventId = hasRelated ? reader.readString() : null;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());

    return Reminder(
      id: id,
      title: title,
      note: note,
      priority: priority,
      dueDate: dueDate,
      isCompleted: isCompleted,
      relatedEventId: relatedEventId,
      createdAt: createdAt,
    );
  }

  @override
  void write(BinaryWriter writer, Reminder obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.note);
    writer.writeByte(obj.priority.index);
    writer.writeInt(obj.dueDate.millisecondsSinceEpoch);
    writer.writeBool(obj.isCompleted);
    if (obj.relatedEventId != null) {
      writer.writeBool(true);
      writer.writeString(obj.relatedEventId!);
    } else {
      writer.writeBool(false);
    }
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}
