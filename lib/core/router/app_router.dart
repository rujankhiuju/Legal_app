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
              pageBuilder: (context, state) => _cupertinoPage(
                const HomePage(),
                state,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/${RouteNames.ruleBook}',
              name: RouteNames.ruleBook,
              pageBuilder: (context, state) => _cupertinoPage(
                const RuleBookPage(),
                state,
              ),
              routes: [
                GoRoute(
                  path: ':docId',
                  name: '${RouteNames.ruleBook}Detail',
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) {
                    final docId = state.pathParameters['docId']!;
                    return _cupertinoPage(
                      RuleBookDetailPage(docId: docId),
                      state,
                    );
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
              pageBuilder: (context, state) => _cupertinoPage(
                const NotesPage(),
                state,
              ),
              routes: [
                GoRoute(
                  path: 'editor',
                  name: RouteNames.notesEditor,
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) {
                    final existing = state.extra as CaseNote?;
                    return _cupertinoPage(
                      NoteEditorPage(existingNote: existing),
                      state,
                    );
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
              pageBuilder: (context, state) => _cupertinoPage(
                const CalendarPage(),
                state,
              ),
              routes: [
                GoRoute(
                  path: 'add',
                  name: RouteNames.addHearing,
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) => _cupertinoPage(
                    const AddHearingPage(),
                    state,
                  ),
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
              pageBuilder: (context, state) => _cupertinoPage(
                const MorePage(),
                state,
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/${RouteNames.settings}',
      name: RouteNames.settings,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _cupertinoPage(
        const SettingsPage(),
        state,
      ),
    ),
    GoRoute(
      path: '/${RouteNames.reminders}',
      name: RouteNames.reminders,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _cupertinoPage(
        const RemindersPage(),
        state,
      ),
    ),
    GoRoute(
      path: '/${RouteNames.scanner}',
      name: RouteNames.scanner,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _cupertinoPage(
        const ScannerScreen(),
        state,
      ),
    ),
    GoRoute(
      path: '/${RouteNames.editScan}',
      name: RouteNames.editScan,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final path = state.extra as String;
        return _cupertinoPage(
          EditScanScreen(imagePath: path),
          state,
        );
      },
    ),
    GoRoute(
      path: '/${RouteNames.pdfGenerate}',
      name: RouteNames.pdfGenerate,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _cupertinoPage(
        const PdfGenerateScreen(),
        state,
      ),
    ),
    GoRoute(
      path: '/${RouteNames.pdfLibrary}',
      name: RouteNames.pdfLibrary,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _cupertinoPage(
        const PdfLibraryScreen(),
        state,
      ),
    ),
    GoRoute(
      path: '/${RouteNames.pdfViewer}',
      name: RouteNames.pdfViewer,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final doc = state.extra as PdfDocument;
        return _cupertinoPage(
          PdfViewerScreen(doc: doc),
          state,
        );
      },
    ),
  ],
);

Page _cupertinoPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return CupertinoPageTransitionsBuilder().buildTransitions<dynamic>(
        _dummyRoute(context),
        context,
        animation,
        secondaryAnimation,
        child,
      );
    },
  );
}

PageRoute<dynamic> _dummyRoute(BuildContext context) {
  return PageRouteBuilder<dynamic>(
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    settings: const RouteSettings(),
  );
}
