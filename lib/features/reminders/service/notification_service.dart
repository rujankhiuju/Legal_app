import 'dart:async';
import 'dart:ui' show Color;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:go_router/go_router.dart';
import '../model/reminder.dart' hide Priority;

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {}

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _pendingNavigationPayload;

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    final route = payload != null ? '/reminders' : null;
    if (route != null) {
      _pendingNavigationPayload = payload;
      final nav = navigatorKey.currentContext;
      if (nav != null) {
        GoRouter.of(nav).go(route);
      }
    }
  }

  String? consumePendingNavigation() {
    final p = _pendingNavigationPayload;
    _pendingNavigationPayload = null;
    return p;
  }

  Future<bool> requestPermissionWithExplanation(BuildContext context) async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      final shouldShowRationale = await Permission.notification.shouldShowRequestRationale;
      if (shouldShowRationale) {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Enable Notifications'),
            content: const Text(
              'Reminders for court hearings, case deadlines, and legal tasks need notification permission to alert you at the right time.\n\n'
              'We will only send notifications for your scheduled reminders.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Not Now'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Enable'),
              ),
            ],
          ),
        );
        if (result != true) return false;
      }
    }
    final newStatus = await Permission.notification.request();
    return newStatus.isGranted;
  }

  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async {
    return await Permission.notification.isGranted;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    final id = _uniqueId(reminder.id);
    final title = reminder.title;
    final body = reminder.note.isNotEmpty
        ? reminder.note
        : 'Priority: ${reminder.priority.name.toUpperCase()}';

    final androidDetails = AndroidNotificationDetails(
      'legal_app_reminders',
      'Legal App Reminders',
      channelDescription: 'Notifications for court hearings and reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      channelShowBadge: true,
      enableLights: true,
      ledColor: Color(0xFFFF3B30),
      ledOnMs: 1000,
      ledOffMs: 500,
    );
    const iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentBadge: true,
      presentAlert: true,
    );
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final scheduledDate = tz.TZDateTime.from(reminder.dueDate, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminder.id,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder(String reminderId) async {
    await _plugin.cancel(_uniqueId(reminderId));
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  int _uniqueId(String reminderId) {
    return reminderId.hashCode & 0x7FFFFFFF;
  }
}
