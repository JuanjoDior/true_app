import 'dart:ui';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/rendering.dart' show CustomPainter;

import '../map/ds_map_label_layer_painter.dart';
import 'ds_globe_marker_projection.dart';
import 'ds_globe_style.dart';

/// Etiquetas proyectadas: nombre del relacionado y del seleccionado, solo si la cara es legible (z2 > 40).
class DsGlobeLabelPainter extends CustomPainter {
  const DsGlobeLabelPainter({
    required this.markers,
    required this.showLabels,
    required this.textDirection,
  });

  final List<DsGlobePlacedMarker> markers;
  final bool showLabels;
  final TextDirection textDirection;

  List<DsMapLabelSpec> specs() {
    if (!showLabels) return const [];
    return [
      for (final marker in markers)
        if (marker.labelVisible &&
            (marker.placement.visual.showLabel || marker.placement.selected))
          DsMapLabelSpec(
            text: marker.placement.marker.label,
            kind: DsMapLabelKind.marker,
            anchor: marker.placement.center.translate(DsGlobeStyle.labelGap, 0),
            opacity: marker.placement.visual.opacity,
            style: DsMapLabelLayerPainter.markerStyle,
          ),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final spec in specs()) {
      DsMapLabelLayerPainter.paintLabel(canvas, spec, textDirection);
    }
  }

  @override
  bool shouldRepaint(DsGlobeLabelPainter oldDelegate) =>
      oldDelegate.showLabels != showLabels ||
      oldDelegate.textDirection != textDirection ||
      !listEquals(oldDelegate.markers, markers);
}
