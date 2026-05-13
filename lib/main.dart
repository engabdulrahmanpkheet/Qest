import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/providers.dart';
import 'app/qest_app.dart';
import 'core/services/isar_service.dart';
import 'core/services/notifications/background_scheduler.dart';
import 'core/services/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isar = await IsarService.init();
  final prefs = await SharedPreferences.getInstance();
  await NotificationService.instance.init();
  // Best-effort: background isolate may not be available on every platform.
  try {
    await BackgroundScheduler.instance.init();
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [
        isarServiceProvider.overrideWithValue(isar),
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const QestApp(),
    ),
  );
}
