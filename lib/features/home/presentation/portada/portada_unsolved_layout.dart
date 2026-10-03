import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../core/design/design.dart';

/// Medidas de la fila «Sin resolver» (Cine-Portada.dc.html y Movil-Portada.dc.html).
class PortadaPosterMetrics {
  const PortadaPosterMetrics({
    required this.width,
    required this.height,
    required this.gap,
    required this.margin,
    required this.sectionBottom,
    required this.headerBottom,
    required this.stackedHeader,
    required this.titleFontSize,
    required this.locationFontSize,
    required this.basePadding,
    required this.baseGap,
    required this.ghostFontSize,
    required this.ghostTop,
    required this.ghostRight,
  });

  static const PortadaPosterMetrics desktop = PortadaPosterMetrics(
    width: 400,
    height: 225,
    gap: DsSpacing.s16,
    margin: DsSpacing.pageMarginDesktop,
    // 64 de la sección + 20 de aire bajo los pósters
    sectionBottom: 84,
    headerBottom: DsSpacing.s20,
    stackedHeader: false,
    titleFontSize: 26,
    locationFontSize: 13,
    basePadding: EdgeInsets.fromLTRB(20, 50, 20, 18),
    baseGap: 6,
    ghostFontSize: 95,
    ghostTop: 10,
    ghostRight: -6,
  );

  static const PortadaPosterMetrics mobile = PortadaPosterMetrics(
    width: 290,
    height: 168,
    gap: DsSpacing.s12,
    margin: DsSpacing.pageMarginMobile,
    sectionBottom: DsSpacing.s28,
    headerBottom: DsSpacing.s14,
    stackedHeader: true,
    titleFontSize: 21,
    locationFontSize: 12,
    basePadding: EdgeInsets.fromLTRB(16, 40, 16, 14),
    baseGap: DsSpacing.s4,
    ghostFontSize: 67,
    ghostTop: 20,
    ghostRight: -4,
  );

  static PortadaPosterMetrics of(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= DsBreakpoints.desktop
      ? desktop
      : mobile;

  final double width;
  final double height;
  final double gap;
  final double margin;
  final double sectionBottom;
  final double headerBottom;

  /// En móvil el subtítulo va bajo el título; en escritorio, en su línea base.
  final bool stackedHeader;
  final double titleFontSize;
  final double locationFontSize;
  final EdgeInsets basePadding;
  final double baseGap;
  final double ghostFontSize;
  final double ghostTop;
  final double ghostRight;

  static const double headerTitleGap = DsSpacing.s16;
  static const double headerStackedGap = DsSpacing.s4;

  static const double titleLineHeight = 1.05;
  static const double summaryFontSize = 13;
  static const double summaryLineHeight = 1.5;
  static const int titleMaxLines = 2;
  static const int summaryMaxLines = 5;

  static const double hoverLift = 12;
  static const double hoverScale = 1.06;
  static const double dimmedOpacity = 0.45;
  static const double moreSlide = 14;
  static const double moreGap = DsSpacing.s8;
  static const EdgeInsets morePadding = EdgeInsets.all(DsSpacing.s20);

  static const double ghostAlpha = 0.08;
  static const double baseScrimAlpha = 0.9;
  static const double moreScrimTopAlpha = 0.45;
  static const double moreScrimBottomAlpha = 0.95;
  static const double moreScrimStop = 0.6;

  static const Size minTapTarget = Size.square(44);

  // Un CSS `linear-gradient(160deg)` apunta abajo con una leve deriva a la derecha.
  static final Alignment gradientBegin = Alignment(
    -math.sin(_gradientAngle),
    math.cos(_gradientAngle),
  );
  static final Alignment gradientEnd = Alignment(
    math.sin(_gradientAngle),
    -math.cos(_gradientAngle),
  );
  static const Alignment glowCenter = Alignment(0.6, -1);
  static const double glowRadius = 1;
  static const double glowAlpha = 0.25;
  static const double glowStop = 0.65;

  static final double _gradientAngle = 160 * math.pi / 180;
}
