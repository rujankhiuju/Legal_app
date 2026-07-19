import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/rule_book/rule_book_screen.dart';
import '../../features/rule_book/rule_book_detail_page.dart';
import '../../screens/notes/notes_screen.dart';
import '../../features/notes/note_editor_page.dart';
import '../../features/notes/model/case_note.dart' show CaseNote;
import '../../screens/calendar/calendar_screen.dart';
import '../../features/calendar/add_hearing_page.dart';
import '../../features/calendar/model/court_event.dart' show CourtEvent;
import '../../screens/calendar/hearing_detail_screen.dart' show HearingDetailScreen;
import '../../features/more/more_page.dart';
import '../../features/more/settings_page.dart';
import '../../screens/reminders/reminders_screen.dart';
import '../../features/scanner/screen/scanner_screen.dart';
import '../../features/scanner/screen/edit_scan_screen.dart';
import '../../features/scanner/screen/pdf_generate_screen.dart';
import '../../features/scanner/screen/pdf_library_screen.dart';
import '../../features/scanner/screen/pdf_viewer_screen.dart';
import '../../features/scanner/model/pdf_document.dart' show PdfDocument;
import '../../features/pdf_tools/pdf_tools_screen.dart';
import '../../screens/pdf_tools/pdf_combiner_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/setup_account_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/lock_screen.dart';
import '../../core/services/notification_service.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  ref.watch(authProvider);
  return GoRouter(
    navigatorKey: NotificationService.navigatorKey,
    initialLocation: '/${RouteNames.home}',
    redirect: (context, state) {
      final path = state.matchedLocation;
      final onAuthScreen = path == '/setup' || path == '/login' || path == '/lock';
      final auth = ProviderScope.containerOf(context).read(authProvider);
      final user = auth.user;

      if (auth.status == AuthStatus.authenticated) {
        if (onAuthScreen) return '/${RouteNames.home}';
        return null;
      }
      if (auth.status == AuthStatus.uninitialized) return null;
      if (auth.status == AuthStatus.setupRequired) {
        if (!onAuthScreen) return '/setup';
        return null;
      }
      if (auth.status == AuthStatus.loginRequired) {
        final skipAuth = user != null && !user.requiresAuth;
        if (skipAuth) {
          ref.read(authProvider.notifier).updateActivity();
          return '/${RouteNames.home}';
        }
        if (path == '/setup') return '/login';
        if (!onAuthScreen) return '/login';
        return null;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/setup', name: 'setup', builder: (context, state) => const SetupAccountScreen()),
      GoRoute(path: '/login', name: 'login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/lock', name: 'lock', builder: (context, state) => const LockScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/${RouteNames.home}', name: RouteNames.home, builder: (context, state) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/${RouteNames.ruleBook}', name: RouteNames.ruleBook, builder: (context, state) => const RuleBookScreen(), routes: [GoRoute(path: ':docId', name: '${RouteNames.ruleBook}Detail', parentNavigatorKey: NotificationService.navigatorKey, builder: (context, state) { final docId = state.pathParameters['docId']!; return RuleBookDetailPage(docId: docId); })]),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/${RouteNames.notes}', name: RouteNames.notes, builder: (context, state) => const NotesScreen(), routes: [GoRoute(path: 'editor', name: RouteNames.notesEditor, parentNavigatorKey: NotificationService.navigatorKey, builder: (context, state) { final existing = state.extra as CaseNote?; return NoteEditorPage(existingNote: existing); })]),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/${RouteNames.calendar}', name: RouteNames.calendar, builder: (context, state) => const CalendarScreen(), routes: [GoRoute(path: 'add', name: RouteNames.addHearing, parentNavigatorKey: NotificationService.navigatorKey, builder: (context, state) => const AddHearingPage()),
GoRoute(path: 'hearing-detail', name: RouteNames.hearingDetail, parentNavigatorKey: NotificationService.navigatorKey, builder: (context, state) {
  final event = state.extra as CourtEvent;
  return HearingDetailScreen(event: event);
})]),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/${RouteNames.pdfTools}', name: RouteNames.pdfTools, builder: (context, state) => const PdfToolsScreen(), routes: [
            GoRoute(path: 'combiner', name: RouteNames.pdfCombiner, parentNavigatorKey: NotificationService.navigatorKey, builder: (context, state) => const PdfCombinerScreen()),
          ])]),
          StatefulShellBranch(routes: [GoRoute(path: '/${RouteNames.more}', name: RouteNames.more, builder: (context, state) => const MorePage())]),
        ],
      ),
      GoRoute(path: '/${RouteNames.settings}', name: RouteNames.settings, parentNavigatorKey: NotificationService.navigatorKey, builder: (context, state) => const SettingsPage()),
      GoRoute(path: '/${RouteNames.reminders}', name: RouteNames.reminders, parentNavigatorKey: NotificationService.navigatorKey, builder: (context, state) => const RemindersScreen()),
      GoRoute(path: '/${RouteNames.scanner}', name: RouteNames.scanner, parentNavigatorKey: NotificationService.navigatorKey, builder: (context, state) => const ScannerScreen()),
      GoRoute(path: '/${RouteNames.editScan}', name: RouteNames.editScan, parentNavigatorKey: NotificationService.navigatorKey, builder: (context, state) { final path = state.extra as String; return EditScanScreen(imagePath: path); }),
      GoRoute(path: '/${RouteNames.pdfGenerate}', name: RouteNames.pdfGenerate, parentNavigatorKey: NotificationService.navigatorKey, builder: (context, state) => const PdfGenerateScreen()),
      GoRoute(path: '/${RouteNames.pdfLibrary}', name: RouteNames.pdfLibrary, parentNavigatorKey: NotificationService.navigatorKey, builder: (context, state) => const PdfLibraryScreen()),
      GoRoute(path: '/${RouteNames.pdfViewer}', name: RouteNames.pdfViewer, parentNavigatorKey: NotificationService.navigatorKey, builder: (context, state) { final doc = state.extra as PdfDocument; return PdfViewerScreen(doc: doc); }),
    ],
  );
});
