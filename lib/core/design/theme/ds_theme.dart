import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

abstract final class DsTheme {
  static ThemeData build() {
    const styles = DsTextStyles.desktop;

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: DsFontFamilies.sans,
      colorScheme: _colorScheme,
    );

    final textTheme = base.textTheme
        .apply(
          fontFamily: DsFontFamilies.sans,
          bodyColor: DsColors.textBody,
          displayColor: DsColors.textPrimary,
        )
        .copyWith(
          displayLarge: styles.displayHero,
          displayMedium: styles.displayPage,
          displaySmall: styles.displayCard,
          headlineMedium: styles.displaySection,
          titleLarge: styles.displayPoster,
          bodyLarge: styles.bodyLarge,
          bodyMedium: styles.body,
          labelLarge: styles.uiButton,
          labelSmall: styles.monoLabel,
        );

    const controlShape = RoundedRectangleBorder(
      borderRadius: DsRadii.controlBorder,
    );
    const hairline = BorderSide(color: DsColors.lineHairline);

    return base.copyWith(
      scaffoldBackgroundColor: DsColors.bgBase,
      textTheme: textTheme,
      dividerColor: DsColors.lineHairline,
      dividerTheme: const DividerThemeData(
        color: DsColors.lineHairline,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: _inputDecorationTheme(),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: DsColors.ctaBg,
          foregroundColor: DsColors.ctaFg,
          disabledBackgroundColor: DsColors.surfaceCard,
          disabledForegroundColor: DsColors.textPlaceholder,
          elevation: 0,
          shape: controlShape,
          textStyle: styles.uiButton,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: DsColors.ctaGlass,
          foregroundColor: DsColors.textPrimary,
          disabledForegroundColor: DsColors.textPlaceholder,
          side: const BorderSide(color: DsColors.ctaGlassBorder),
          shape: controlShape,
          textStyle: styles.uiButton,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DsColors.textPrimary,
          disabledForegroundColor: DsColors.textPlaceholder,
          shape: controlShape,
          textStyle: styles.uiButton,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: DsColors.surfaceGlassStrong,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: DsRadii.sheetBorder,
          side: hairline,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: DsColors.bgGlow,
        contentTextStyle: styles.body.copyWith(color: DsColors.textPrimary),
        shape: controlShape,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: DsColors.surfaceCard,
        side: hairline,
        shape: const RoundedRectangleBorder(borderRadius: DsRadii.pillBorder),
        labelStyle: const TextStyle(color: DsColors.textMuted),
      ),
    );
  }

  static const ColorScheme _colorScheme = ColorScheme.dark(
    primary: DsColors.accentRed,
    onPrimary: Colors.white,
    secondary: DsColors.accentGold,
    onSecondary: DsColors.bgBase,
    surface: DsColors.bgBase,
    onSurface: DsColors.textPrimary,
    onSurfaceVariant: DsColors.textMuted,
    error: DsColors.accentRedText,
    onError: DsColors.bgBase,
    outline: DsColors.lineInput,
    outlineVariant: DsColors.lineHairline,
    // Los tokens de vidrio son translúcidos; los contenedores M3 deben ser opacos
    surfaceContainerLowest: DsColors.bgBase,
    surfaceContainerLow: DsColors.bgBase,
    surfaceContainer: DsColors.surfaceInput,
    surfaceContainerHigh: DsColors.bgGlow,
    surfaceContainerHighest: DsColors.bgGlow,
  );

  static InputDecorationTheme _inputDecorationTheme() {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: DsRadii.controlBorder,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecorationTheme(
      filled: true,
      fillColor: DsColors.surfaceInput,
      hintStyle: const TextStyle(color: DsColors.textPlaceholder),
      errorStyle: const TextStyle(color: DsColors.accentRedText),
      prefixIconColor: DsColors.textMuted,
      suffixIconColor: DsColors.textMuted,
      border: border(DsColors.lineInput),
      enabledBorder: border(DsColors.lineInput),
      focusedBorder: border(DsColors.accentRed, 1.2),
      errorBorder: border(DsColors.accentRedText),
      focusedErrorBorder: border(DsColors.accentRedText, 1.2),
    );
  }
}
