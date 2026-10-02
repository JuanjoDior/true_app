import 'package:flutter/painting.dart';

import 'ds_colors.dart';

// Valores: DESIGN.md 3.2 (se toma un punto dentro de cada rango)
abstract final class DsFontFamilies {
  static const String sans = 'NotoSans';
  static const String display = 'NotoSerifDisplay';
  static const String mono = 'IBMPlexMono';
}

class DsTextStyles {
  const DsTextStyles({
    required this.displayHero,
    required this.displayPage,
    required this.displayCard,
    required this.displaySection,
    required this.displayPoster,
    required this.displayGhostYear,
    required this.bodyLead,
    required this.bodyLarge,
    required this.body,
    required this.uiButton,
    required this.monoLabel,
    required this.monoData,
  });

  final TextStyle displayHero;
  final TextStyle displayPage;
  final TextStyle displayCard;
  final TextStyle displaySection;
  final TextStyle displayPoster;
  final TextStyle displayGhostYear;
  // La serif solo se empaqueta en 700, por eso el resumen también va en negrita
  final TextStyle bodyLead;
  final TextStyle bodyLarge;
  final TextStyle body;
  final TextStyle uiButton;

  /// El texto se pasa a mayúsculas en el llamador; el estilo no lo hace.
  final TextStyle monoLabel;
  final TextStyle monoData;

  static const DsTextStyles desktop = DsTextStyles(
    displayHero: TextStyle(
      fontFamily: DsFontFamilies.display,
      fontSize: 104,
      fontWeight: FontWeight.w700,
      height: 0.95,
      letterSpacing: -1.04,
      color: DsColors.textStrong,
    ),
    displayPage: TextStyle(
      fontFamily: DsFontFamilies.display,
      fontSize: 42,
      fontWeight: FontWeight.w700,
      color: DsColors.textStrong,
    ),
    displayCard: TextStyle(
      fontFamily: DsFontFamilies.display,
      fontSize: 35,
      fontWeight: FontWeight.w700,
      color: DsColors.textPrimary,
    ),
    displaySection: TextStyle(
      fontFamily: DsFontFamilies.display,
      fontSize: 27,
      fontWeight: FontWeight.w700,
      color: DsColors.textPrimary,
    ),
    displayPoster: TextStyle(
      fontFamily: DsFontFamilies.display,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: DsColors.textPrimary,
    ),
    displayGhostYear: TextStyle(
      fontFamily: DsFontFamilies.display,
      fontSize: 490,
      fontWeight: FontWeight.w700,
      color: _ghostColor,
    ),
    bodyLead: TextStyle(
      fontFamily: DsFontFamilies.display,
      fontSize: 30,
      fontWeight: FontWeight.w700,
      height: 1.4,
      color: DsColors.textBody,
    ),
    bodyLarge: TextStyle(
      fontFamily: DsFontFamilies.sans,
      fontSize: 18,
      fontWeight: FontWeight.w400,
      height: 1.6,
      color: DsColors.textBody,
    ),
    body: TextStyle(
      fontFamily: DsFontFamilies.sans,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.6,
      color: DsColors.textBody,
    ),
    uiButton: TextStyle(
      fontFamily: DsFontFamilies.sans,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: DsColors.textBody,
    ),
    monoLabel: TextStyle(
      fontFamily: DsFontFamilies.mono,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.98,
      color: DsColors.textMuted,
    ),
    monoData: TextStyle(
      fontFamily: DsFontFamilies.mono,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: DsColors.accentGold,
    ),
  );

  static const DsTextStyles mobile = DsTextStyles(
    displayHero: TextStyle(
      fontFamily: DsFontFamilies.display,
      fontSize: 56,
      fontWeight: FontWeight.w700,
      height: 0.95,
      letterSpacing: -0.56,
      color: DsColors.textStrong,
    ),
    displayPage: TextStyle(
      fontFamily: DsFontFamilies.display,
      fontSize: 33,
      fontWeight: FontWeight.w700,
      color: DsColors.textStrong,
    ),
    displayCard: TextStyle(
      fontFamily: DsFontFamilies.display,
      fontSize: 31,
      fontWeight: FontWeight.w700,
      color: DsColors.textPrimary,
    ),
    displaySection: TextStyle(
      fontFamily: DsFontFamilies.display,
      fontSize: 23,
      fontWeight: FontWeight.w700,
      color: DsColors.textPrimary,
    ),
    displayPoster: TextStyle(
      fontFamily: DsFontFamilies.display,
      fontSize: 19,
      fontWeight: FontWeight.w700,
      color: DsColors.textPrimary,
    ),
    displayGhostYear: TextStyle(
      fontFamily: DsFontFamilies.display,
      fontSize: 250,
      fontWeight: FontWeight.w700,
      color: _ghostColor,
    ),
    bodyLead: TextStyle(
      fontFamily: DsFontFamilies.display,
      fontSize: 23,
      fontWeight: FontWeight.w700,
      height: 1.4,
      color: DsColors.textBody,
    ),
    bodyLarge: TextStyle(
      fontFamily: DsFontFamilies.sans,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.6,
      color: DsColors.textBody,
    ),
    body: TextStyle(
      fontFamily: DsFontFamilies.sans,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.6,
      color: DsColors.textBody,
    ),
    uiButton: TextStyle(
      fontFamily: DsFontFamilies.sans,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: DsColors.textBody,
    ),
    monoLabel: TextStyle(
      fontFamily: DsFontFamilies.mono,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.98,
      color: DsColors.textMuted,
    ),
    monoData: TextStyle(
      fontFamily: DsFontFamilies.mono,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: DsColors.accentGold,
    ),
  );
}

// Blanco al 4,75 % (punto medio de 4,5–5 %)
const Color _ghostColor = Color.fromRGBO(255, 255, 255, 0.0475);
