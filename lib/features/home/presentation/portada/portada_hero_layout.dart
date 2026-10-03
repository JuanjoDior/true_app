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
  static const double tabHeight = 52;
  static const double tabBarHeight = 3;
  static const double tabNameFontSize = 13;

  static const double veilWidth = 980;
}
