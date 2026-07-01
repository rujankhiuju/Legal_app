import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

@immutable
class AdvocateProfile {
  final String id;
  final String name;
  final String? barNumber;
  final String specialization;
  final String? firmName;
  final String? address;
  final String? phone;
  final String? email;
  final String? bio;
  final String? photoPath;

  const AdvocateProfile({
    required this.id,
    required this.name,
    this.barNumber,
    this.specialization = '',
    this.firmName,
    this.address,
    this.phone,
    this.email,
    this.bio,
    this.photoPath,
  });

  AdvocateProfile copyWith({
    String? id,
    String? name,
    String? barNumber,
    String? specialization,
    String? firmName,
    String? address,
    String? phone,
    String? email,
    String? bio,
    String? photoPath,
    bool clearPhoto = false,
  }) {
    return AdvocateProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      barNumber: barNumber ?? this.barNumber,
      specialization: specialization ?? this.specialization,
      firmName: firmName ?? this.firmName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdvocateProfile && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class AdvocateProfileAdapter extends TypeAdapter<AdvocateProfile> {
  @override
  final int typeId = 5;

  @override
  AdvocateProfile read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final hasBarNumber = reader.readBool();
    final barNumber = hasBarNumber ? reader.readString() : null;
    final specialization = reader.readString();
    final hasFirmName = reader.readBool();
    final firmName = hasFirmName ? reader.readString() : null;
    final hasAddress = reader.readBool();
    final address = hasAddress ? reader.readString() : null;
    final hasPhone = reader.readBool();
    final phone = hasPhone ? reader.readString() : null;
    final hasEmail = reader.readBool();
    final email = hasEmail ? reader.readString() : null;
    final hasBio = reader.readBool();
    final bio = hasBio ? reader.readString() : null;
    final hasPhoto = reader.readBool();
    final photoPath = hasPhoto ? reader.readString() : null;

    return AdvocateProfile(
      id: id,
      name: name,
      barNumber: barNumber,
      specialization: specialization,
      firmName: firmName,
      address: address,
      phone: phone,
      email: email,
      bio: bio,
      photoPath: photoPath,
    );
  }

  @override
  void write(BinaryWriter writer, AdvocateProfile obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeBool(obj.barNumber != null);
    if (obj.barNumber != null) writer.writeString(obj.barNumber!);
    writer.writeString(obj.specialization);
    writer.writeBool(obj.firmName != null);
    if (obj.firmName != null) writer.writeString(obj.firmName!);
    writer.writeBool(obj.address != null);
    if (obj.address != null) writer.writeString(obj.address!);
    writer.writeBool(obj.phone != null);
    if (obj.phone != null) writer.writeString(obj.phone!);
    writer.writeBool(obj.email != null);
    if (obj.email != null) writer.writeString(obj.email!);
    writer.writeBool(obj.bio != null);
    if (obj.bio != null) writer.writeString(obj.bio!);
    writer.writeBool(obj.photoPath != null);
    if (obj.photoPath != null) writer.writeString(obj.photoPath!);
  }
}
