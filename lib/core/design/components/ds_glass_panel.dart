import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';

/// Cristal del sistema: fondo translúcido, desenfoque del fondo y borde fino.
class DsGlassPanel extends StatelessWidget {
  const DsGlassPanel({
    super.key,
    required this.child,
    this.strong = false,
    this.borderRadius,
    this.padding = EdgeInsets.zero,
    this.shadows,
    this.borderColor = DsColors.lineHairline,
  });

  final Widget child;
  final bool strong;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;

  /// Null usa la sombra de cristal; una lista vacía la quita.
  final List<BoxShadow>? shadows;
  final Color borderColor;

  // Punto medio del rango 14–24 del diseño (DESIGN.md 3.3)
  static const double blurSigma = 18;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? DsRadii.sheetBorder;

    // La sombra va fuera del recorte: dentro del ClipRRect se perdería
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: shadows ?? DsShadows.glass,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: strong
                    ? DsColors.surfaceGlassStrong
                    : DsColors.surfaceGlass,
                borderRadius: radius,
                border: Border.all(color: borderColor),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
