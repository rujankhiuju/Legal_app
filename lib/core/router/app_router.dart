import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/home_page.dart';
import '../../features/rule_book/rule_book_page.dart';
import '../../features/rule_book/rule_book_detail_page.dart';
import '../../features/notes/notes_page.dart';
import '../../features/calendar/calendar_page.dart';
import '../../features/more/more_page.dart';
import '../../features/more/settings_page.dart';
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
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/${RouteNames.calendar}',
              name: RouteNames.calendar,
              builder: (context, state) => const CalendarPage(),
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
  ],
);
