import 'dart:ui';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/rendering.dart' show CustomPainter;

import '../tokens/ds_colors.dart';
import 'ds_map_arc.dart';
import 'ds_map_camera.dart';
import 'ds_map_effects_controller.dart';
import 'ds_map_effects_layout.dart';
import 'ds_map_marker_layout.dart';
import 'ds_map_marker_state.dart';
import 'ds_map_motion_clock.dart';

const double _pulseStartAlpha = 0.6;
const double _pulseStrokeWidth = 1.5;

/// Arcos y anillos de pulso, por debajo de los marcadores (doc 2.3 y 2.4).
class DsMapEffectsPainter extends CustomPainter {
  DsMapEffectsPainter({
    required this.effects,
    required this.placements,
    required this.arcs,
    required this.camera,
    required this.markerIndices,
    required this.animate,
  }) : super(repaint: effects.repaint);

  final DsMapEffectsController effects;
  final List<DsMapMarkerPlacement> placements;
  final List<DsMapArcPlacement> arcs;
  final DsMapCamera camera;

  /// Posición de cada marcador en la lista original: fija el retraso del pulso.
  final Map<String, int> markerIndices;
  final bool animate;

  @override
  void paint(Canvas canvas, Size size) {
    _paintArcs(canvas);
    if (animate) _paintPulses(canvas);
  }

  // El arco se calcula en la escena y se lleva a pantalla antes de trazar los guiones, para que midan 7 px a cualquier zoom.
  void _paintArcs(Canvas canvas) {
    final phase = DsMapArc.dashPhase(effects.dashProgress);
    for (final placement in arcs) {
      final opacity = effects.arcOpacity(placement.key);
      if (opacity <= 0) continue;
      final path = placement.arc
          .mapPoints(camera.apply)
          .dashedPath(phase: phase);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = DsMapArc.strokeWidth
        ..color = DsColors.accentGold.withValues(
          alpha: DsColors.accentGold.a * opacity,
        );
      canvas.drawPath(path, paint);
    }
  }

  void _paintPulses(Canvas canvas) {
    final elapsed = effects.elapsed;
    for (final placement in placements) {
      final visual = placement.visual;
      if (!visual.pulsing) continue;
      final progress = DsMapMotionClock.pulseProgress(
        elapsed: elapsed,
        index: markerIndices[placement.marker.id] ?? 0,
        selected: placement.selected,
      );
      final scale =
          DsMapMarkerStates.pulseScaleFrom +
          (DsMapMarkerStates.pulseScaleTo - DsMapMarkerStates.pulseScaleFrom) *
              progress;
      final color = placement.marker.color;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _pulseStrokeWidth
        ..color = color.withValues(
          alpha: color.a * _pulseStartAlpha * (1 - progress) * visual.opacity,
        );
      canvas.drawCircle(placement.center, visual.diameter / 2 * scale, paint);
    }
  }

  @override
  bool shouldRepaint(DsMapEffectsPainter oldDelegate) =>
      oldDelegate.effects != effects ||
      oldDelegate.camera != camera ||
      oldDelegate.animate != animate ||
      !identical(oldDelegate.markerIndices, markerIndices) ||
      !listEquals(oldDelegate.placements, placements) ||
      !listEquals(oldDelegate.arcs, arcs);
}
