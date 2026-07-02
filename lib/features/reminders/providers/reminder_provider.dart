import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/reminder.dart';
import '../service/notification_service.dart';
import '../../calendar/model/court_event.dart';
import '../../calendar/providers/calendar_provider.dart';

final remindersBoxProvider = FutureProvider<Box<Reminder>>((ref) async {
  return Hive.openBox<Reminder>('reminders');
});

final remindersListProvider = FutureProvider<List<Reminder>>((ref) async {
  final box = await ref.watch(remindersBoxProvider.future);
  return box.values.toList();
});

final sortedRemindersProvider = Provider<List<Reminder>>((ref) {
  final async = ref.watch(remindersListProvider);
  return async.when(
    data: (reminders) {
      final incomplete = reminders.where((r) => !r.isCompleted).toList();
      incomplete.sort((a, b) {
        final aOverdue = a.dueDate.isBefore(DateTime.now());
        final bOverdue = b.dueDate.isBefore(DateTime.now());
        if (aOverdue != bOverdue) return aOverdue ? -1 : 1;
        return a.dueDate.compareTo(b.dueDate);
      });
      return incomplete;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final overdueCountProvider = Provider<int>((ref) {
  final async = ref.watch(sortedRemindersProvider);
  final now = DateTime.now();
  return async.where((r) => r.dueDate.isBefore(now)).length;
});

class ReminderActions {
  final Ref ref;

  ReminderActions(this.ref);

  Future<void> addReminder(Reminder reminder) async {
    final box = await ref.read(remindersBoxProvider.future);
    await box.put(reminder.id, reminder);
    if (!reminder.isCompleted) {
      final hasPermission = await NotificationService.instance.hasPermission();
      if (!hasPermission) {
        await NotificationService.instance.requestPermission();
      }
      await NotificationService.instance.scheduleReminder(reminder);
    }
    ref.invalidate(remindersListProvider);
  }

  Future<void> addEventReminder(CourtEvent event) async {
    final scheduled = event.dateTime.subtract(const Duration(hours: 1));
    if (scheduled.isBefore(DateTime.now())) return;

    final reminder = Reminder(
      id: 'event_${event.id}',
      title: 'Hearing: ${event.title}',
      note: event.caseName,
      priority: Priority.high,
      dueDate: scheduled,
      relatedEventId: event.id,
      createdAt: DateTime.now(),
    );
    await addReminder(reminder);
  }

  Future<void> markComplete(Reminder reminder) async {
    final box = await ref.read(remindersBoxProvider.future);
    final updated = reminder.copyWith(isCompleted: true);
    await box.put(reminder.id, updated);
    await NotificationService.instance.cancelReminder(reminder.id);
    ref.invalidate(remindersListProvider);
  }

  Future<void> snooze(Reminder reminder) async {
    final box = await ref.read(remindersBoxProvider.future);
    final snoozed = reminder.copyWith(
      dueDate: DateTime.now().add(const Duration(minutes: 15)),
    );
    await box.put(reminder.id, snoozed);
    await NotificationService.instance.scheduleReminder(snoozed);
    ref.invalidate(remindersListProvider);
  }

  Future<void> deleteReminder(Reminder reminder) async {
    final box = await ref.read(remindersBoxProvider.future);
    await box.delete(reminder.id);
    await NotificationService.instance.cancelReminder(reminder.id);
    ref.invalidate(remindersListProvider);
  }

  Future<void> deleteEventReminders(String eventId) async {
    final box = await ref.read(remindersBoxProvider.future);
    final toRemove = box.values.where((r) => r.relatedEventId == eventId);
    for (final r in toRemove) {
      await box.delete(r.id);
      await NotificationService.instance.cancelReminder(r.id);
    }
    ref.invalidate(remindersListProvider);
  }
}

final reminderActionsProvider = Provider<ReminderActions>((ref) {
  return ReminderActions(ref);
});
