import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool isLoading;

  const SettingsState({this.isLoading = true});

  SettingsState copyWith({bool? isLoading}) =>
      SettingsState(isLoading: isLoading ?? this.isLoading);
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    await SharedPreferences.getInstance();
    state = const SettingsState(isLoading: false);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
