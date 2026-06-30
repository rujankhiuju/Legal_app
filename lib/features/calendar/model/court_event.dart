import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

@immutable
class CourtEvent {
  final String id;
  final String title;
  final String caseName;
  final DateTime dateTime;
  final String notes;
  final String colorHex;
  final bool isHearing;

  const CourtEvent({
    required this.id,
    required this.title,
    required this.caseName,
    required this.dateTime,
    this.notes = '',
    this.colorHex = '1E3A8A',
    this.isHearing = true,
  });

  CourtEvent copyWith({
    String? id,
    String? title,
    String? caseName,
    DateTime? dateTime,
    String? notes,
    String? colorHex,
    bool? isHearing,
  }) {
    return CourtEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      caseName: caseName ?? this.caseName,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
      colorHex: colorHex ?? this.colorHex,
      isHearing: isHearing ?? this.isHearing,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourtEvent && id == other.id && dateTime == other.dateTime;

  @override
  int get hashCode => id.hashCode;
}

class CourtEventAdapter extends TypeAdapter<CourtEvent> {
  @override
  final int typeId = 2;

  @override
  CourtEvent read(BinaryReader reader) {
    final id = reader.readString();
    final title = reader.readString();
    final caseName = reader.readString();
    final dateTime = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final notes = reader.readString();
    final colorHex = reader.readString();
    final isHearing = reader.readBool();

    return CourtEvent(
      id: id,
      title: title,
      caseName: caseName,
      dateTime: dateTime,
      notes: notes,
      colorHex: colorHex,
      isHearing: isHearing,
    );
  }

  @override
  void write(BinaryWriter writer, CourtEvent obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.caseName);
    writer.writeInt(obj.dateTime.millisecondsSinceEpoch);
    writer.writeString(obj.notes);
    writer.writeString(obj.colorHex);
    writer.writeBool(obj.isHearing);
  }
}
