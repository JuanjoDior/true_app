import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF090A0D);
  static const panel = Color(0xFF14161C);
  static const panelMuted = Color(0xFF1C2029);
  static const surface = Color(0xFF111318);
  static const border = Color(0xFF2A2F3A);
  static const accent = Color(0xFFB1232E);
  static const accentSoft = Color(0xFF6E1B22);
  static const textPrimary = Color(0xFFF3F0EA);
  static const textMuted = Color(0xFFB4AFAB);
  static const textSoft = Color(0xFF8A8681);
  static const gold = Color(0xFFD6B26E);
}

class AppTheme {
  static ThemeData buildTheme() {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.gold,
        surface: AppColors.panel,
        onPrimary: Colors.white,
        onSecondary: AppColors.background,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: base.textTheme
          .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
            fontFamily: 'NotoSans',
          )
          .copyWith(
            displayLarge: base.textTheme.displayLarge?.copyWith(
              fontFamily: 'NotoSerifDisplay',
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
            ),
            displayMedium: base.textTheme.displayMedium?.copyWith(
              fontFamily: 'NotoSerifDisplay',
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
            displaySmall: base.textTheme.displaySmall?.copyWith(
              fontFamily: 'NotoSerifDisplay',
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
            headlineMedium: base.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
            titleLarge: base.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
            titleMedium: base.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            bodyLarge: base.textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
            bodyMedium: base.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
      cardTheme: CardThemeData(
        color: AppColors.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerColor: AppColors.border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF171920),
        hintStyle: const TextStyle(color: AppColors.textSoft),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.panelMuted,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: const TextStyle(color: AppColors.textMuted),
      ),
    );
  }
}
