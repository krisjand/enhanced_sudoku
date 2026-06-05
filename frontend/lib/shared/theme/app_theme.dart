import 'package:flutter/material.dart';

import 'game_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: GameColors.primary,
      brightness: Brightness.light,
    ).copyWith(surface: GameColors.background, onSurface: GameColors.clueDigit);

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: GameColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: GameColors.background,
        foregroundColor: GameColors.clueDigit,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: GameColors.clueDigit,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: const CardThemeData(
        color: GameColors.surface,
        elevation: 2,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GameColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: GameColors.primary),
      ),
    );
  }
}
