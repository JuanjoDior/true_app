import 'dart:ui';

import '../../../../core/design/design.dart';

/// Medidas del héroe sobre el lienzo de escritorio de 1440 px (docs/design/screens.md §1.1).
abstract final class PortadaLayout {
  static const double canvasWidth = 1440;

  static const double margin = DsSpacing.pageMarginDesktop;

  // Columna de texto: ancla inferior y límites del contenido.
  static const double contentBottom = 150;
  static const double contentTop = 96;
  static const double contentWidth = 700;
  static const double summaryMaxWidth = 540;
  static const int titleMaxLines = 3;
  static const int summaryMaxLines = 4;

  static const double titleFontSize = 88;
  static const double titleLineHeight = 0.96;
  static const double summaryFontSize = 18;
  static const double summaryLineHeight = 1.6;
  static const double metaFontSize = 15;

  static const double ghostLeft = 40;
  static const double ghostTop = 90;
  static const double ghostFontSize = 460;

  static const double coordsBottom = 44;

  static const double tabsBottom = 40;
  static const double tabsWidth = 680;
  static const double tabGap = 14;
  static const double tabHeight = 52;
  static const double tabBarHeight = 3;
  static const double tabNameFontSize = 13;

  // Barras tipo historias del héroe móvil (Movil-Portada.dc.html).
  static const double compactTabsTop = 72;
  static const double compactTabsMargin = 16;
  static const double compactTabGap = 6;
  static const double compactTabHeight = 44;

  static const double veilWidth = 980;

  // Lienzo de diseño del globo: centro (1010, 520) y radio 400 sobre 1440 × 900.
  static const double globeCanvasWidth = canvasWidth;
  static const double globeCanvasHeight = 1000;
  static const double globeCenterXFactor = 1010 / canvasWidth;
  static const double globeBottomGap = 12;
  static const double compactGlobeRadiusFactor = 0.36;
  static const double compactGlobeTopGap = 8;

  /// Centro y radio del globo en un héroe de ese tamaño; la esfera siempre cabe entera.
  ///
  /// En escritorio ocupa el alto libre bajo la barra superior; en estrecho
  /// queda arriba a la derecha, sin tocar el texto inferior.
  static ({Offset center, double radius}) globePlacement(Size hero) {
    if (hero.width < DsBreakpoints.desktop) {
      final radius = hero.width * compactGlobeRadiusFactor;
      return (
        center: Offset(
          hero.width - radius,
          compactTabsTop + compactTabHeight + compactGlobeTopGap + radius,
        ),
        radius: radius,
      );
    }
    final free = hero.height - contentTop;
    final radius = (free / 2 - globeBottomGap).clamp(0, DsGlobeMath.radius);
    return (
      center: Offset(hero.width * globeCenterXFactor, contentTop + free / 2),
      radius: radius.toDouble(),
    );
  }
}
