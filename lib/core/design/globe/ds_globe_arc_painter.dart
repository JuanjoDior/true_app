import 'dart:ui';

import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:flutter/rendering.dart' show CustomPainter;

import '../map/ds_map_connection.dart';
import '../map/ds_map_marker.dart';
import '../tokens/ds_colors.dart';
import 'ds_globe_arc_reveal.dart';
import 'ds_globe_camera.dart';
import 'ds_globe_marker_projection.dart';
import 'ds_globe_math.dart';
import 'ds_globe_style.dart';

/// Arco listo para pintar entre dos marcadores visibles.
@immutable
class DsGlobeArcSpec {
  const DsGlobeArcSpec({
    required this.key,
    required this.from,
    required this.to,
  });

  /// Extremos en orden: no cambia con la cámara, así que no reinicia la aparición.
  final String key;
  final DsMapMarker from;
  final DsMapMarker to;

  @override
  bool operator ==(Object other) =>
      other is DsGlobeArcSpec &&
      other.key == key &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(key, from, to);
}

abstract final class DsGlobeArcLayout {
  static String keyOf(DsMapConnection connection) =>
      '${connection.fromId}>${connection.toId}';

  /// Omite sin error ids desconocidos y extremos traseros u ocultos por año.
  static List<DsGlobeArcSpec> visible({
    required List<DsMapConnection> connections,
    required List<DsGlobePlacedMarker> placed,
  }) {
    if (connections.isEmpty) return const [];
    final byId = {for (final p in placed) p.placement.marker.id: p.placement};
    final arcs = <DsGlobeArcSpec>[];
    for (final connection in connections) {
      final from = byId[connection.fromId];
      final to = byId[connection.toId];
      if (from == null || to == null || identical(from, to)) continue;
      arcs.add(
        DsGlobeArcSpec(
          key: keyOf(connection),
          from: from.marker,
          to: to.marker,
        ),
      );
    }
    return arcs;
  }

  /// Claves de aparición: dependen solo de los ids conocidos, no de la visibilidad.
  static Set<String> keys({
    required List<DsMapConnection> connections,
    required List<DsMapMarker> markers,
  }) {
    if (connections.isEmpty) return const {};
    final ids = {for (final marker in markers) marker.id};
    return {
      for (final connection in connections)
        if (connection.fromId != connection.toId &&
            ids.contains(connection.fromId) &&
            ids.contains(connection.toId))
          keyOf(connection),
    };
  }
}

/// Arcos de 27 puntos dorados con brillo, proyectados con la cámara actual (doc 3.3).
class DsGlobeArcPainter extends CustomPainter {
  DsGlobeArcPainter({
    required this.camera,
    required this.arcs,
    required this.elapsedOf,
    super.repaint,
  });

  final DsGlobeCamera camera;
  final List<DsGlobeArcSpec> arcs;

  /// Tiempo transcurrido de la aparición de cada arco, por clave.
  final Duration Function(String key) elapsedOf;

  @override
  void paint(Canvas canvas, Size size) {
    for (final arc in arcs) {
      final elapsed = elapsedOf(arc.key);
      final points = DsGlobeMath.arcPoints(
        latitudeA: arc.from.latitude,
        longitudeA: arc.from.longitude,
        latitudeB: arc.to.latitude,
        longitudeB: arc.to.longitude,
      );
      for (var k = 0; k < points.length; k++) {
        final opacity = DsGlobeArcReveal.dotOpacity(k, elapsed);
        if (opacity <= 0) continue;
        final projection = DsGlobeMath.project(
          points[k],
          gx: camera.gx,
          gy: camera.gy,
          center: camera.center,
          scale: camera.scale,
        );
        if (!projection.isFront) continue;
        _paintDot(canvas, projection, opacity);
      }
    }
  }

  void _paintDot(Canvas canvas, DsGlobeProjection projection, double opacity) {
    final zoom = camera.scale * projection.perspectiveFactor;
    final radius = DsGlobeStyle.arcDotDiameter / 2 * zoom;
    canvas.drawCircle(
      projection.screen,
      radius,
      Paint()
        ..color = DsColors.accentGold.withValues(
          alpha: DsGlobeStyle.arcGlowAlpha * opacity,
        )
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          DsGlobeStyle.arcGlowRadius * DsGlobeStyle.blurSigmaPerBlur * zoom,
        ),
    );
    canvas.drawCircle(
      projection.screen,
      radius,
      Paint()..color = DsColors.accentGold.withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(DsGlobeArcPainter oldDelegate) =>
      oldDelegate.camera != camera ||
      oldDelegate.elapsedOf != elapsedOf ||
      !listEquals(oldDelegate.arcs, arcs);
}
