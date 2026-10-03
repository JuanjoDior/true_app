import 'dart:ui';

import 'package:flutter/foundation.dart' show ValueChanged, listEquals;
import 'package:flutter/rendering.dart'
    show CustomPainter, CustomPainterSemantics, SemanticsBuilderCallback;
import 'package:flutter/semantics.dart' show SemanticsProperties;
import 'package:flutter/widgets.dart' show ValueKey;

import '../tokens/ds_colors.dart';
import 'ds_map_marker_layout.dart';
import 'ds_map_marker_state.dart';

const double _ringWidth = 2;
const double _glowAlpha = 0.5;
// Equivalencia con el radio de `box-shadow` de CSS.
const double _glowSigmaPerRadius = 0.5;

/// Marcadores en espacio de pantalla: el tamaño no depende de la escala de la cámara.
class DsMapMarkerLayerPainter extends CustomPainter {
  const DsMapMarkerLayerPainter({
    required this.placements,
    required this.onMarkerTap,
    required this.textDirection,
  });

  final List<DsMapMarkerPlacement> placements;
  final ValueChanged<String>? onMarkerTap;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    for (final placement in placements) {
      _paintMarker(canvas, placement);
    }
  }

  void _paintMarker(Canvas canvas, DsMapMarkerPlacement placement) {
    final visual = placement.visual;
    final radius = visual.diameter / 2;
    final center = placement.center;
    final color = placement.marker.color;

    final glow = Paint()
      ..color = _withOpacity(color, _glowAlpha * visual.opacity)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        visual.glowRadius * _glowSigmaPerRadius,
      );
    canvas.drawCircle(center, radius, glow);

    final body = Paint()..color = _withOpacity(color, visual.opacity);
    canvas.drawCircle(center, radius - _ringWidth, body);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringWidth
      ..color = _withOpacity(
        visual.goldBorder ? DsColors.accentGold : DsColors.bgBase,
        visual.opacity,
      );
    canvas.drawCircle(center, radius - _ringWidth / 2, ring);
  }

  static Color _withOpacity(Color color, double opacity) =>
      color.withValues(alpha: color.a * opacity);

  @override
  bool shouldRepaint(DsMapMarkerLayerPainter oldDelegate) =>
      !listEquals(oldDelegate.placements, placements);

  @override
  SemanticsBuilderCallback? get semanticsBuilder =>
      (size) => [
        for (final placement in placements)
          CustomPainterSemantics(
            key: ValueKey(placement.marker.id),
            rect: Rect.fromCenter(
              center: placement.center,
              width: DsMapMarkerStates.minTapTarget,
              height: DsMapMarkerStates.minTapTarget,
            ),
            properties: SemanticsProperties(
              button: true,
              label: placement.marker.label,
              textDirection: textDirection,
              selected: placement.selected,
              onTap: () => onMarkerTap?.call(placement.marker.id),
            ),
          ),
      ];

  @override
  bool shouldRebuildSemantics(DsMapMarkerLayerPainter oldDelegate) =>
      !listEquals(oldDelegate.placements, placements) ||
      oldDelegate.onMarkerTap != onMarkerTap ||
      oldDelegate.textDirection != textDirection;
}
