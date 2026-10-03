import 'dart:ui';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/rendering.dart' show CustomPainter;

import '../map/ds_land_grid.dart';
import '../tokens/ds_colors.dart';
import 'ds_globe_camera.dart';
import 'ds_globe_math.dart';

/// Puntos de tierra que comparten opacidad y diámetro (cuantizado).
@immutable
class DsGlobeLandBucket {
  const DsGlobeLandBucket({
    required this.opacity,
    required this.diameter,
    required this.points,
  });

  final double opacity;
  final double diameter;
  final List<Offset> points;
}

/// Tierra del globo: solo caras delanteras, un `drawPoints` por cubo.
class DsGlobeLandPainter extends CustomPainter {
  const DsGlobeLandPainter({required this.camera});

  final DsGlobeCamera camera;

  static const double diameterQuantum = 0.5;

  static double _quantize(double diameter) =>
      (diameter / diameterQuantum).round() * diameterQuantum;

  /// Cubos de menor a mayor opacidad y, dentro de ella, de menor a mayor diámetro.
  static List<DsGlobeLandBucket> buckets(DsGlobeCamera camera) {
    final grouped = <(double, double), List<Offset>>{};
    final cells = DsLandGrid.cells;
    final vectors = DsGlobeMath.landPoints;
    for (var i = 0; i < cells.length; i++) {
      final projection = DsGlobeMath.project(
        vectors[i],
        gx: camera.gx,
        gy: camera.gy,
        center: camera.center,
        scale: camera.scale,
      );
      if (!projection.isFront) continue;
      final diameter = _quantize(
        DsGlobeMath.landDotSizes[i] *
            camera.scale *
            projection.perspectiveFactor,
      );
      (grouped[(cells[i].opacity, diameter)] ??= []).add(projection.screen);
    }
    final keys = grouped.keys.toList()
      ..sort((a, b) {
        final byOpacity = a.$1.compareTo(b.$1);
        return byOpacity != 0 ? byOpacity : a.$2.compareTo(b.$2);
      });
    return [
      for (final key in keys)
        DsGlobeLandBucket(
          opacity: key.$1,
          diameter: key.$2,
          points: grouped[key]!,
        ),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final bucket in buckets(camera)) {
      paint
        ..strokeWidth = bucket.diameter
        ..color = DsColors.landDotFlat.withValues(alpha: bucket.opacity);
      canvas.drawPoints(PointMode.points, bucket.points, paint);
    }
  }

  @override
  bool shouldRepaint(DsGlobeLandPainter oldDelegate) =>
      oldDelegate.camera != camera;
}
