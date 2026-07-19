import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'features/rule_book/model/legal_document.dart';
import 'features/notes/model/case_note.dart';
import 'features/calendar/model/court_event.dart';
import 'features/reminders/model/reminder.dart';
import 'core/services/notification_service.dart';
import 'features/scanner/model/pdf_document.dart';
import 'features/home/model/advocate_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(LegalDocumentAdapter());
  Hive.registerAdapter(CaseNoteAdapter());
  Hive.registerAdapter(CourtEventAdapter());
  Hive.registerAdapter(ReminderAdapter());
  Hive.registerAdapter(PdfDocumentAdapter());
  Hive.registerAdapter(AdvocateProfileAdapter());
  await NotificationService.instance.initialize();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );

  NotificationService.instance.retryPendingNavigation();
}
