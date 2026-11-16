import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);
  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final apple =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.royalBlue,
      brightness: brightness,
      primary: dark ? AppColors.brightBlue : AppColors.royalBlue,
      surface: dark ? const Color(0xFF142B49) : Colors.white,
      onSurface: dark ? const Color(0xFFF1F5FC) : AppColors.primaryText,
      error: AppColors.error,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: apple ? null : 'IBM Plex Sans Arabic',
      fontFamilyFallback: const ['IBM Plex Sans Arabic'],
      scaffoldBackgroundColor: dark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      dividerColor: dark ? const Color(0xFF2A4260) : const Color(0xFFE1E8F2),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.deepSkyBlue
              : null,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }
}
