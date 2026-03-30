import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'db/db_service.dart';
import 'providers/db_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = await DatabaseService.init();
  await db.seedIfEmpty();

  runApp(
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(db),
      ],
      child: const App(),
    ),
  );
}
