import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:go_router/go_router.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationService.instance._storePendingPayload(response.payload);
}

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _pendingPayload;

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

  void _storePendingPayload(String? payload) {
    _pendingPayload = payload ?? _pendingPayload;
  }

  void _onNotificationTap(NotificationResponse response) {
    _storePendingPayload(response.payload);
    _navigateToReminders();
  }

  void _navigateToReminders() {
    final ctx = navigatorKey.currentContext;
    if (ctx != null && _pendingPayload != null) {
      GoRouter.of(ctx).push('/reminders');
      _pendingPayload = null;
    }
  }

  void retryPendingNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToReminders();
    });
  }

  String? consumePendingNavigation() {
    final p = _pendingPayload;
    _pendingPayload = null;
    return p;
  }

  Future<bool> requestPermissions() async {
    if (await Permission.notification.isGranted) return true;

    final status = await Permission.notification.request();
    if (status.isGranted) return true;

    if (await Permission.notification.shouldShowRequestRationale) {
      return false;
    }
    return false;
  }

  Future<bool> hasPermission() async {
    return await Permission.notification.isGranted;
  }

  Future<void> scheduleNotification(
    String id,
    String title,
    String body,
    DateTime scheduledTime,
  ) async {
    final has = await hasPermission();
    if (!has) {
      final granted = await requestPermissions();
      if (!granted) return;
    }

    final intId = id.hashCode & 0x7FFFFFFF;

    final androidDetails = AndroidNotificationDetails(
      'legal_app_reminders',
      'Legal App Reminders',
      channelDescription: 'Notifications for court hearings and reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      channelShowBadge: true,
      enableLights: true,
      ledColor: const Color(0xFFFF3B30),
      ledOnMs: 1000,
      ledOffMs: 500,
    );
    const iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentBadge: true,
      presentAlert: true,
    );
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

    await _plugin.zonedSchedule(
      intId,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: id,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelNotification(String id) async {
    await _plugin.cancel(id.hashCode & 0x7FFFFFFF);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
