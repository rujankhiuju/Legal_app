import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../core/services/biometric_service.dart';

enum AuthStatus { uninitialized, setupRequired, loginRequired, authenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final DateTime? lastActivity;

  const AuthState({
    this.status = AuthStatus.uninitialized,
    this.user,
    this.error,
    this.lastActivity,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    DateTime? lastActivity,
    bool clearError = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: clearError ? null : (error ?? this.error),
        lastActivity: lastActivity ?? this.lastActivity,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final user = await UserStorage.load();
    if (user == null) {
      state = const AuthState(status: AuthStatus.setupRequired);
    } else {
      state = AuthState(
        status: AuthStatus.loginRequired,
        user: user,
        lastActivity: DateTime.now(),
      );
    }
  }

  Future<void> setupAccount({
    required String firstName,
    required String lastName,
    required String pin,
    bool biometricEnabled = false,
  }) async {
    final hash = _hashPin(pin);
    final user = UserModel(
      firstName: firstName,
      lastName: lastName,
      pinHash: hash,
      biometricEnabled: biometricEnabled,
    );
    await UserStorage.save(user);
    state = AuthState(
      status: AuthStatus.authenticated,
      user: user,
      lastActivity: DateTime.now(),
    );
  }

  Future<String?> loginWithPin(String pin) async {
    final user = state.user;
    if (user == null) return 'No account found';
    if (user.pinHash != _hashPin(pin)) return 'Incorrect PIN';
    state = state.copyWith(
      status: AuthStatus.authenticated,
      lastActivity: DateTime.now(),
      clearError: true,
    );
    return null;
  }

  Future<String?> loginWithBiometrics() async {
    final service = BiometricService();
    final available = await service.isAvailable();
    if (!available) return 'Biometrics not available';
    final authenticated = await service.authenticate();
    if (!authenticated) return 'Biometric authentication failed';
    state = state.copyWith(
      status: AuthStatus.authenticated,
      lastActivity: DateTime.now(),
      clearError: true,
    );
    return null;
  }

  Future<void> continueAsGuest() async {
    final guest = UserModel(
      firstName: 'Guest',
      lastName: '',
      pinHash: '',
      isGuest: true,
    );
    state = AuthState(
      status: AuthStatus.authenticated,
      user: guest,
      lastActivity: DateTime.now(),
    );
  }

  Future<void> lock() async {
    state = state.copyWith(
      status: AuthStatus.loginRequired,
      clearError: true,
    );
  }

  Future<void> logout() async {
    await UserStorage.clear();
    state = const AuthState(status: AuthStatus.setupRequired);
  }

  void updateActivity() {
    state = state.copyWith(lastActivity: DateTime.now());
  }

  Future<void> updateProfile(String firstName, String lastName) async {
    final user = state.user;
    if (user == null) return;
    final updated = user.copyWith(firstName: firstName, lastName: lastName);
    await UserStorage.save(updated);
    state = state.copyWith(user: updated);
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final canEditProvider = Provider<bool>((ref) {
  final user = ref.watch(authProvider).user;
  return user != null && !user.isGuest;
});
