import 'dart:ui';

import 'package:flutter/rendering.dart' show CustomPainter;

import '../tokens/ds_colors.dart';
import 'ds_land_grid.dart';
import 'ds_map_camera.dart';
import 'ds_map_projection.dart';

/// Capa de tierra: un solo painter, un `drawPoints` por cubo de opacidad.
class DsMapLandLayerPainter extends CustomPainter {
  const DsMapLandLayerPainter({
    required this.camera,
    required this.verticalOffset,
    required this.dotDiameter,
  });

  final DsMapCamera camera;
  final double verticalOffset;
  final double dotDiameter;

  static Offset _scenePoint(DsLandCell cell, double verticalOffset) =>
      DsMapProjection.project(cell.latitude, cell.longitude) +
      Offset(0, verticalOffset);

  static List<DsLandCell> visibleCells({
    required DsMapCamera camera,
    required Size size,
    required double verticalOffset,
    required double dotDiameter,
  }) {
    // El margen es el radio del punto en pantalla, para no recortar los del borde.
    final viewport = (Offset.zero & size).inflate(
      dotDiameter / 2 * camera.scale,
    );
    return [
      for (final cell in DsLandGrid.cells)
        if (viewport.contains(camera.apply(_scenePoint(cell, verticalOffset))))
          cell,
    ];
  }

  /// Puntos de escena visibles agrupados por opacidad, de menor a mayor.
  static Map<double, List<Offset>> dotBuckets({
    required DsMapCamera camera,
    required Size size,
    required double verticalOffset,
    required double dotDiameter,
  }) {
    final buckets = <double, List<Offset>>{};
    for (final cell in visibleCells(
      camera: camera,
      size: size,
      verticalOffset: verticalOffset,
      dotDiameter: dotDiameter,
    )) {
      (buckets[cell.opacity] ??= []).add(_scenePoint(cell, verticalOffset));
    }
    final opacities = buckets.keys.toList()..sort();
    return {for (final opacity in opacities) opacity: buckets[opacity]!};
  }

  @override
  void paint(Canvas canvas, Size size) {
    final buckets = dotBuckets(
      camera: camera,
      size: size,
      verticalOffset: verticalOffset,
      dotDiameter: dotDiameter,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = dotDiameter;
    canvas.save();
    canvas.transform(camera.toMatrix().storage);
    for (final MapEntry(key: opacity, value: points) in buckets.entries) {
      paint.color = DsColors.landDotFlat.withValues(alpha: opacity);
      canvas.drawPoints(PointMode.points, points, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(DsMapLandLayerPainter oldDelegate) =>
      oldDelegate.camera != camera ||
      oldDelegate.verticalOffset != verticalOffset ||
      oldDelegate.dotDiameter != dotDiameter;
}
