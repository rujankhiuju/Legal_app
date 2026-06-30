import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'features/rule_book/model/legal_document.dart';
import 'features/notes/model/case_note.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(LegalDocumentAdapter());
  Hive.registerAdapter(CaseNoteAdapter());
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
