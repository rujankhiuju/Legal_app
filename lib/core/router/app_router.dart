import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/home_page.dart';
import '../../features/rule_book/rule_book_page.dart';
import '../../features/rule_book/rule_book_detail_page.dart';
import '../../features/notes/notes_page.dart';
import '../../features/notes/note_editor_page.dart';
import '../../features/notes/model/case_note.dart' show CaseNote;
import '../../features/calendar/calendar_page.dart';
import '../../features/calendar/add_hearing_page.dart';
import '../../features/more/more_page.dart';
import '../../features/more/settings_page.dart';
import '../../features/reminders/screen/reminders_page.dart';
import '../../features/scanner/screen/scanner_screen.dart';
import '../../features/scanner/screen/edit_scan_screen.dart';
import '../../features/scanner/screen/pdf_generate_screen.dart';
import '../../features/scanner/screen/pdf_library_screen.dart';
import '../../features/scanner/screen/pdf_viewer_screen.dart';
import '../../features/scanner/model/pdf_document.dart' show PdfDocument;
import '../../features/shell/app_shell.dart';
import 'route_names.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/${RouteNames.home}',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/${RouteNames.home}',
              name: RouteNames.home,
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/${RouteNames.ruleBook}',
              name: RouteNames.ruleBook,
              builder: (context, state) => const RuleBookPage(),
              routes: [
                GoRoute(
                  path: ':docId',
                  name: '${RouteNames.ruleBook}Detail',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final docId = state.pathParameters['docId']!;
                    return RuleBookDetailPage(docId: docId);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/${RouteNames.notes}',
              name: RouteNames.notes,
              builder: (context, state) => const NotesPage(),
              routes: [
                GoRoute(
                  path: 'editor',
                  name: RouteNames.notesEditor,
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final existing = state.extra as CaseNote?;
                    return NoteEditorPage(existingNote: existing);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/${RouteNames.calendar}',
              name: RouteNames.calendar,
              builder: (context, state) => const CalendarPage(),
              routes: [
                GoRoute(
                  path: 'add',
                  name: RouteNames.addHearing,
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const AddHearingPage(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/${RouteNames.more}',
              name: RouteNames.more,
              builder: (context, state) => const MorePage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/${RouteNames.settings}',
      name: RouteNames.settings,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/${RouteNames.reminders}',
      name: RouteNames.reminders,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RemindersPage(),
    ),
    GoRoute(
      path: '/${RouteNames.scanner}',
      name: RouteNames.scanner,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ScannerScreen(),
    ),
    GoRoute(
      path: '/${RouteNames.editScan}',
      name: RouteNames.editScan,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final path = state.extra as String;
        return EditScanScreen(imagePath: path);
      },
    ),
    GoRoute(
      path: '/${RouteNames.pdfGenerate}',
      name: RouteNames.pdfGenerate,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PdfGenerateScreen(),
    ),
    GoRoute(
      path: '/${RouteNames.pdfLibrary}',
      name: RouteNames.pdfLibrary,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PdfLibraryScreen(),
    ),
    GoRoute(
      path: '/${RouteNames.pdfViewer}',
      name: RouteNames.pdfViewer,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final doc = state.extra as PdfDocument;
        return PdfViewerScreen(doc: doc);
      },
    ),
  ],
);
