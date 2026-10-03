import 'dart:ui';

import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle;
import 'package:flutter/rendering.dart' show CustomPainter;

import '../tokens/ds_colors.dart';
import '../tokens/ds_radii.dart';
import '../tokens/ds_typography.dart';
import 'ds_map_camera.dart';
import 'ds_map_effects_controller.dart';
import 'ds_map_effects_layout.dart';
import 'ds_map_marker_layout.dart';

const double _fontSize = 12;
const double _padX = 8;
const double _padY = 4;
const double _borderWidth = 1;
const double _connectionBorderAlpha = 0.35;

enum DsMapLabelKind { marker, connection }

/// Etiqueta resuelta: [anchor] es el borde izquierdo (marcador) o el centro (conexión) de la píldora.
@immutable
class DsMapLabelSpec {
  const DsMapLabelSpec({
    required this.text,
    required this.kind,
    required this.anchor,
    required this.opacity,
    required this.style,
  });

  final String text;
  final DsMapLabelKind kind;
  final Offset anchor;
  final double opacity;
  final TextStyle style;
}

/// Etiquetas sobre los marcadores: nombre de los relacionados y relación de cada arco (doc 2.3 y 2.4).
class DsMapLabelLayerPainter extends CustomPainter {
  DsMapLabelLayerPainter({
    required this.effects,
    required this.placements,
    required this.arcs,
    required this.camera,
    required this.showConnectionLabels,
    required this.textDirection,
  }) : super(repaint: effects.revealRepaint);

  static const double markerLabelGap = 8;

  static const TextStyle markerStyle = TextStyle(
    fontFamily: DsFontFamilies.mono,
    fontSize: _fontSize,
    color: DsColors.textStrong,
  );
  static const TextStyle _connectionStyle = TextStyle(
    fontFamily: DsFontFamilies.mono,
    fontSize: _fontSize,
    color: DsColors.accentGold,
  );

  final DsMapEffectsController effects;
  final List<DsMapMarkerPlacement> placements;
  final List<DsMapArcPlacement> arcs;
  final DsMapCamera camera;
  final bool showConnectionLabels;
  final TextDirection textDirection;

  List<DsMapLabelSpec> specs() {
    final result = <DsMapLabelSpec>[];
    for (final placement in placements) {
      final visual = placement.visual;
      if (!visual.showLabel) continue;
      result.add(
        DsMapLabelSpec(
          text: placement.marker.label,
          kind: DsMapLabelKind.marker,
          anchor: placement.center.translate(
            visual.diameter / 2 + markerLabelGap,
            0,
          ),
          opacity: visual.opacity,
          style: markerStyle,
        ),
      );
    }
    if (showConnectionLabels) {
      for (final placement in arcs) {
        final opacity = effects.arcOpacity(placement.key);
        if (opacity <= 0) continue;
        result.add(
          DsMapLabelSpec(
            text: placement.connection.label,
            kind: DsMapLabelKind.connection,
            anchor: camera.apply(placement.arc.labelPoint),
            opacity: opacity,
            style: _connectionStyle,
          ),
        );
      }
    }
    return result;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final spec in specs()) {
      paintLabel(canvas, spec, textDirection);
    }
  }

  /// Dibuja una píldora de etiqueta; la comparte el globo.
  static void paintLabel(
    Canvas canvas,
    DsMapLabelSpec spec,
    TextDirection textDirection,
  ) {
    final text = TextPainter(
      text: TextSpan(
        text: spec.text,
        style: spec.style.copyWith(color: _faded(spec.style.color!, spec)),
      ),
      textDirection: textDirection,
      maxLines: 1,
    )..layout();
    final size = Size(text.width + _padX * 2, text.height + _padY * 2);
    final rect = spec.kind == DsMapLabelKind.marker
        ? Rect.fromLTWH(
            spec.anchor.dx,
            spec.anchor.dy - size.height / 2,
            size.width,
            size.height,
          )
        : Rect.fromCenter(
            center: spec.anchor,
            width: size.width,
            height: size.height,
          );
    final pill = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(DsRadii.pill),
    );
    final borderColor = spec.kind == DsMapLabelKind.marker
        ? DsColors.lineHairline
        : DsColors.accentGold.withValues(alpha: _connectionBorderAlpha);
    canvas.drawRRect(
      pill,
      Paint()..color = _faded(DsColors.surfaceGlass, spec),
    );
    canvas.drawRRect(
      pill,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _borderWidth
        ..color = _faded(borderColor, spec),
    );
    text.paint(canvas, rect.topLeft.translate(_padX, _padY));
    text.dispose();
  }

  static Color _faded(Color color, DsMapLabelSpec spec) =>
      color.withValues(alpha: color.a * spec.opacity);

  @override
  bool shouldRepaint(DsMapLabelLayerPainter oldDelegate) =>
      oldDelegate.effects != effects ||
      oldDelegate.camera != camera ||
      oldDelegate.showConnectionLabels != showConnectionLabels ||
      oldDelegate.textDirection != textDirection ||
      !listEquals(oldDelegate.placements, placements) ||
      !listEquals(oldDelegate.arcs, arcs);
}
