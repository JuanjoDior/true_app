import 'package:flutter/painting.dart';

/// Acabado visual del globo (doc 3.4).
abstract final class DsGlobeStyle {
  // Halo de categoría
  static const double haloDiameter = 1500;
  static const int haloAlpha = 0x30;
  static const double haloTransparentStop = 0.52;
  static const Duration haloFade = Duration(milliseconds: 1400);

  // Resplandor exterior
  static const double outerGlowBlur = 150;
  // Equivalencia con el radio de `box-shadow` de CSS.
  static const double blurSigmaPerBlur = 0.5;
  static const Color outerGlowColor = Color.fromRGBO(90, 160, 208, 0.22);

  // Cuerpo de la esfera
  static const double bodyFocalX = 0.38;
  static const double bodyFocalY = 0.32;
  // Fracción del lado del disco: 0,5 equivale al radio de la esfera.
  static const double bodyGradientRadius = 0.5;
  static const Color bodyCore = Color(0xFF1A2638);
  static const Color bodyMid = Color(0xFF0A0F18);
  static const Color bodyEdge = Color(0xFF05070B);
  static const double bodyMidStop = 0.55;
  static const double borderWidth = 1;
  static const Color borderColor = Color.fromRGBO(140, 190, 240, 0.2);

  // Sombreado superior (sin eventos)
  static const Color highlightColor = Color.fromRGBO(140, 190, 240, 0.16);
  static const double highlightFocalX = 0.3;
  static const double highlightFocalY = 0.25;
  static const double highlightRadius = 0.5;
  static const Color limbColor = Color.fromRGBO(5, 7, 11, 0.92);
  static const double limbClearStop = 0.6;

  // Marcadores y etiquetas
  static const double labelGap = 18;

  // Arcos de puntos dorados
  static const double arcDotDiameter = 5;
  static const double arcGlowRadius = 10;
  static const double arcGlowAlpha = 0.6;

  static Alignment alignmentOf(double fractionX, double fractionY) =>
      Alignment(fractionX * 2 - 1, fractionY * 2 - 1);
}
