import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/locale_provider.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  Timer? _autoLockTimer;
  Timer? _sessionTimer;
  static const _sessionTimeout = Duration(hours: 2);
  static const _autoLockDelay = Duration(minutes: 1);
  DateTime _lastInteraction = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startSessionTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoLockTimer?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      final auth = ref.read(authProvider);
      if (auth.status == AuthStatus.authenticated && !(auth.user?.isGuest ?? true)) {
        final elapsed = DateTime.now().difference(_lastInteraction);
        if (elapsed > _sessionTimeout) {
          ref.read(authProvider.notifier).lock();
        }
      }
    });
  }

  void _recordInteraction() {
    _lastInteraction = DateTime.now();
    _autoLockTimer?.cancel();
    final auth = ref.read(authProvider);
    if (auth.status == AuthStatus.authenticated) {
      ref.read(authProvider.notifier).updateActivity();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _autoLockTimer?.cancel();
      _autoLockTimer = Timer(_autoLockDelay, () {
        final auth = ref.read(authProvider);
        if (auth.status == AuthStatus.authenticated) {
          ref.read(authProvider.notifier).lock();
        }
      });
    } else if (state == AppLifecycleState.resumed) {
      _autoLockTimer?.cancel();
      _recordInteraction();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final router = ref.watch(appRouterProvider);

    return GestureDetector(
      onTap: _recordInteraction,
      onPanDown: (_) => _recordInteraction,
      child: MaterialApp.router(
        title: 'Nepali Legal Assistant',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        scrollBehavior: AppScrollBehavior(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
  }
}
