import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';
import '../core/services/biometric_service.dart';

enum AuthStatus { uninitialized, setupRequired, loginRequired, authenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final DateTime? lastActivity;
  final int failedAttempts;
  final DateTime? lockoutUntil;

  const AuthState({
    this.status = AuthStatus.uninitialized,
    this.user,
    this.error,
    this.lastActivity,
    this.failedAttempts = 0,
    this.lockoutUntil,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    DateTime? lastActivity,
    int? failedAttempts,
    DateTime? lockoutUntil,
    bool clearError = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: clearError ? null : (error ?? this.error),
        lastActivity: lastActivity ?? this.lastActivity,
        failedAttempts: failedAttempts ?? this.failedAttempts,
        lockoutUntil: lockoutUntil ?? this.lockoutUntil,
      );

  bool get isLockedOut =>
      lockoutUntil != null && DateTime.now().isBefore(lockoutUntil!);
  int get remainingLockoutSeconds =>
      lockoutUntil != null
          ? max(0, lockoutUntil!.difference(DateTime.now()).inSeconds)
          : 0;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) { _initialize(); }

  Future<void> _initialize() async {
    final user = await UserStorage.load();
    if (user == null) {
      state = const AuthState(status: AuthStatus.setupRequired);
    } else if (!user.requiresAuth) {
      state = AuthState(status: AuthStatus.authenticated, user: user, lastActivity: DateTime.now());
    } else {
      state = AuthState(status: AuthStatus.loginRequired, user: user, lastActivity: DateTime.now());
    }
  }

  Future<String?> setupAccount({
    required String firstName,
    required String lastName,
    String pin = '',
    bool biometricEnabled = false,
    bool requiresAuth = false,
  }) async {
    if (firstName.trim().isEmpty || lastName.trim().isEmpty) return 'First and last name are required';
    if (requiresAuth) {
      if (pin.length < 4) return 'PIN must be at least 4 digits';
      if (pin.length > 10) return 'PIN must not exceed 10 digits';
      if (!RegExp(r'^\d+$').hasMatch(pin)) return 'PIN must contain only numbers';
    }
    final salt = requiresAuth ? _generateSalt() : '';
    final hash = requiresAuth ? _hashPin(pin, salt) : '';
    final user = UserModel(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      pinHash: hash,
      pinSalt: salt,
      biometricEnabled: requiresAuth && biometricEnabled,
      requiresAuth: requiresAuth,
    );
    await UserStorage.save(user);
    state = AuthState(status: AuthStatus.authenticated, user: user, lastActivity: DateTime.now());
    return null;
  }

  Future<String?> loginWithPin(String pin) async {
    if (state.isLockedOut) return 'Too many attempts. Try again in ${state.remainingLockoutSeconds}s';
    final user = state.user;
    if (user == null) return 'Authentication failed';
    if (user.pinHash != _hashPin(pin, user.pinSalt)) {
      final attempts = state.failedAttempts + 1;
      const maxAttempts = 5;
      if (attempts >= maxAttempts) {
        state = state.copyWith(failedAttempts: attempts, lockoutUntil: DateTime.now().add(const Duration(minutes: 2)), error: 'Too many attempts. Locked for 2 minutes.');
        return null;
      }
      state = state.copyWith(failedAttempts: attempts, error: 'Incorrect PIN ($attempts/$maxAttempts)');
      return null;
    }
    state = state.copyWith(status: AuthStatus.authenticated, lastActivity: DateTime.now(), failedAttempts: 0, lockoutUntil: null, clearError: true);
    return null;
  }

  Future<String?> loginWithBiometrics() async {
    final service = BiometricService();
    final available = await service.isAvailable();
    if (!available) return 'Biometrics not available';
    final authenticated = await service.authenticate(reason: 'Authenticate to access your legal documents');
    if (!authenticated) return 'Biometric authentication failed';
    state = state.copyWith(status: AuthStatus.authenticated, lastActivity: DateTime.now(), failedAttempts: 0, clearError: true);
    return null;
  }

  Future<void> continueAsGuest() async {
    final guest = UserModel(firstName: 'Guest', lastName: '', pinHash: '', pinSalt: '', isGuest: true);
    await UserStorage.save(guest);
    state = AuthState(status: AuthStatus.authenticated, user: guest, lastActivity: DateTime.now());
  }

  Future<void> lock() async {
    final user = state.user;
    if (user != null && !user.requiresAuth) return;
    state = state.copyWith(status: AuthStatus.loginRequired, clearError: true);
  }

  Future<void> logout() async {
    await UserStorage.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_failed_attempts');
    state = const AuthState(status: AuthStatus.setupRequired);
  }

  void updateActivity() { state = state.copyWith(lastActivity: DateTime.now()); }

  Future<void> setRequiresAuth(bool value) async {
    final user = state.user;
    if (user == null) return;
    final updated = user.copyWith(requiresAuth: value);
    await UserStorage.save(updated);
    state = state.copyWith(user: updated);
  }

  Future<void> updateProfile(String firstName, String lastName) async {
    final user = state.user;
    if (user == null) return;
    final updated = user.copyWith(firstName: firstName, lastName: lastName);
    await UserStorage.save(updated);
    state = state.copyWith(user: updated);
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }
  String _hashPin(String pin, String salt) {
    final key = utf8.encode(salt + pin);
    return sha256.convert(key).toString();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
final canEditProvider = Provider<bool>((ref) {
  final user = ref.watch(authProvider).user;
  return user != null && !user.isGuest;
});
