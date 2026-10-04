import 'package:flutter/widgets.dart';

import '../../../../core/design/design.dart';

/// Medidas de la invitación al mapa (Cine-Portada.dc.html y Movil-Portada.dc.html).
class PortadaMapInviteMetrics {
  const PortadaMapInviteMetrics({
    required this.mobile,
    required this.height,
    required this.outerPadding,
    required this.contentGap,
    required this.titleFontSize,
    required this.titleLineHeight,
    required this.kickerLetterSpacingEm,
    required this.backdropRadius,
    required this.backdropStop,
  });

  static const PortadaMapInviteMetrics desktop = PortadaMapInviteMetrics(
    mobile: false,
    height: 540,
    outerPadding: EdgeInsets.zero,
    contentGap: DsSpacing.s18,
    titleFontSize: 56,
    titleLineHeight: 1,
    kickerLetterSpacingEm: 0.22,
    backdropRadius: 2.5,
    backdropStop: 0.72,
  );

  static const PortadaMapInviteMetrics mobileCard = PortadaMapInviteMetrics(
    mobile: true,
    height: 250,
    outerPadding: EdgeInsets.fromLTRB(
      DsSpacing.pageMarginMobile,
      0,
      DsSpacing.pageMarginMobile,
      DsSpacing.s28,
    ),
    contentGap: DsSpacing.s10,
    titleFontSize: 26,
    titleLineHeight: 1.05,
    kickerLetterSpacingEm: 0.2,
    backdropRadius: 1.7,
    backdropStop: 0.8,
  );

  static PortadaMapInviteMetrics of(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= DsBreakpoints.desktop
      ? desktop
      : mobileCard;

  final bool mobile;
  final double height;
  final EdgeInsets outerPadding;
  final double contentGap;
  final double titleFontSize;
  final double titleLineHeight;
  final double kickerLetterSpacingEm;

  /// El CSS usa una elipse; el degradado radial de Flutter es circular, así que el radio es aproximado.
  final double backdropRadius;
  final double backdropStop;

  static const double desktopContentLeft = DsSpacing.pageMarginDesktop;
  static const double desktopContentTop = 130;
  static const double desktopContentWidth = 520;
  static const double mobileContentInset = DsSpacing.s18;

  static const double bodyFontSize = 17;
  static const double bodyLineHeight = 1.6;

  static const Alignment backdropCenter = Alignment(0, 0.2);
  static const double cardRadius = DsRadii.sheet;

  static const double desktopScrimStrong = 0.94;
  static const double desktopScrimMid = 0.55;
  static const double desktopScrimMidStop = 0.38;
  static const double desktopScrimEndStop = 0.62;
  static const double desktopEdgeFadeStop = 0.22;
  static const double mobileScrimStrong = 0.95;
  static const double mobileScrimMid = 0.3;
  static const double mobileScrimMidStop = 0.55;
}

/// Medidas del pie de la portada.
class PortadaFooterMetrics {
  const PortadaFooterMetrics({
    required this.stacked,
    required this.padding,
    required this.brandFontSize,
  });

  static const PortadaFooterMetrics desktop = PortadaFooterMetrics(
    stacked: false,
    padding: EdgeInsets.symmetric(horizontal: DsSpacing.pageMarginDesktop),
    brandFontSize: 16,
  );

  static const PortadaFooterMetrics mobile = PortadaFooterMetrics(
    stacked: true,
    padding: EdgeInsets.fromLTRB(
      DsSpacing.pageMarginMobile,
      DsSpacing.s12,
      DsSpacing.pageMarginMobile,
      DsSpacing.s24,
    ),
    brandFontSize: 15,
  );

  static PortadaFooterMetrics of(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= DsBreakpoints.desktop
      ? desktop
      : mobile;

  final bool stacked;
  final EdgeInsets padding;
  final double brandFontSize;

  static const double desktopHeight = 120;
  static const double stackedGap = 6;
  static const double brandLetterSpacingEm = 0.1;
  static const double noteFontSize = 13;
  static const double noteLineHeight = 1.5;
  static const double ruleWidth = 1;
}
