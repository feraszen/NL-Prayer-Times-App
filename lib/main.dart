import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.instance
      .initialize();

  await NotificationService.instance
      .requestPermissions();

  runApp(
    const NLPrayerTimesApp(),
  );
}
