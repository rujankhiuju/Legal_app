import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserModel {
  final String firstName;
  final String lastName;
  final String pinHash;
  final bool biometricEnabled;
  final bool isGuest;

  const UserModel({
    required this.firstName,
    required this.lastName,
    required this.pinHash,
    this.biometricEnabled = false,
    this.isGuest = false,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'pinHash': pinHash,
        'biometricEnabled': biometricEnabled,
        'isGuest': isGuest,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        pinHash: json['pinHash'] as String,
        biometricEnabled: json['biometricEnabled'] as bool? ?? false,
        isGuest: json['isGuest'] as bool? ?? false,
      );

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? pinHash,
    bool? biometricEnabled,
    bool? isGuest,
  }) =>
      UserModel(
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        pinHash: pinHash ?? this.pinHash,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        isGuest: isGuest ?? this.isGuest,
      );
}

class UserStorage {
  static const _key = 'user_profile';
  static final _storage = const FlutterSecureStorage();

  static Future<UserModel?> load() async {
    try {
      final json = await _storage.read(key: _key);
      if (json == null) return null;
      return UserModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(UserModel user) async {
    await _storage.write(key: _key, value: jsonEncode(user.toJson()));
  }

  static Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
