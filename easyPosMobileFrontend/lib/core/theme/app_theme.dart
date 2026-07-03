import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.accent,
          onPrimary: AppColors.accentInk,
          surface: AppColors.surface,
          onSurface: AppColors.text,
          error: AppColors.danger,
        ),
        cardColor: AppColors.surface,
        dividerColor: AppColors.border,
        fontFamily: 'SF Pro Display',
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, letterSpacing: -0.8),
          titleLarge:   TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.2),
          titleMedium:  TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 15),
          bodyMedium:   TextStyle(color: AppColors.text, fontSize: 14),
          bodySmall:    TextStyle(color: AppColors.textMuted, fontSize: 12),
          labelSmall:   TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          hintStyle: const TextStyle(color: AppColors.textDim),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.text,
          elevation: 0,
          centerTitle: false,
        ),
      );
}
