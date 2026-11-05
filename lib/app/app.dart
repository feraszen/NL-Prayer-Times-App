import 'package:flutter/material.dart';

import 'navigation/main_navigation_screen.dart';
import 'theme/app_theme.dart';

class NLPrayerTimesApp extends StatelessWidget {
  const NLPrayerTimesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NL Prayer Times',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainNavigationScreen(),
    );
  }
}
