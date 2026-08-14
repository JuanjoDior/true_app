import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

/// Tipografías y átomos visuales compartidos por la "Sala de Situación".
abstract final class SituationStyles {
  /// Etiqueta monoespaciada en versalitas (coordenadas, secciones, métricas).
  static TextStyle mono({
    double size = 10,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textSoft,
    double letterSpacing = 0.1,
    double? height,
  }) {
    return TextStyle(
      fontFamily: kMonoFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Titulares con la serif editorial.
  static TextStyle serif({
    double size = 32,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.textPrimary,
    double height = 1.05,
    double letterSpacing = -0.2,
  }) {
    return TextStyle(
      fontFamily: 'NotoSerifDisplay',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Texto sans estándar.
  static TextStyle sans({
    double size = 13,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textBody,
    double? height,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: 'NotoSans',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

/// Punto de color con halo, usado en leyendas, cronologías y relacionados.
class SituationDot extends StatelessWidget {
  const SituationDot({
    super.key,
    required this.color,
    this.size = 9,
    this.glow = true,
  });

  final Color color;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 7,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

/// Píldora con etiqueta monoespaciada (chips de categoría/estado en el detalle).
class SituationBadge extends StatelessWidget {
  const SituationBadge({
    super.key,
    required this.label,
    required this.color,
    this.filled = false,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label.toUpperCase(),
        style: SituationStyles.mono(
          size: 9,
          weight: FontWeight.w600,
          color: filled ? Colors.white : color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Encabezado de sección en versalitas mono (p. ej. "Cronología verificada").
class SituationSectionLabel extends StatelessWidget {
  const SituationSectionLabel(
    this.text, {
    super.key,
    this.color = AppColors.textSoft,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: SituationStyles.mono(
        size: 10,
        weight: FontWeight.w600,
        color: color,
        letterSpacing: 2,
      ),
    );
  }
}
