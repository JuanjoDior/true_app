import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart' show immutable;

import 'ds_map_arc.dart';
import 'ds_map_connection.dart';
import 'ds_map_marker_layout.dart';
import 'ds_map_projection.dart';

/// Arco en espacio de escena listo para pintar.
@immutable
class DsMapArcPlacement {
  const DsMapArcPlacement({
    required this.connection,
    required this.arc,
    required this.key,
  });

  final DsMapConnection connection;
  final DsMapArc arc;

  /// Identifica el arco por sus extremos: cambia si un extremo se mueve, no con la cámara.
  final String key;

  @override
  bool operator ==(Object other) =>
      other is DsMapArcPlacement &&
      other.key == key &&
      other.connection == connection;

  @override
  int get hashCode => Object.hash(key, connection);
}

abstract final class DsMapEffectsLayout {
  /// Omite sin error los ids desconocidos y los extremos no interactivos (ocultos por año).
  static List<DsMapArcPlacement> arcs({
    required List<DsMapConnection> connections,
    required List<DsMapMarkerPlacement> placements,
    required double verticalOffset,
  }) {
    if (connections.isEmpty) return const [];
    final byId = {for (final p in placements) p.marker.id: p};
    final arcs = <DsMapArcPlacement>[];
    for (final connection in connections) {
      final from = byId[connection.fromId];
      final to = byId[connection.toId];
      if (from == null || to == null || identical(from, to)) continue;
      final start = _scenePoint(from, verticalOffset);
      final end = _scenePoint(to, verticalOffset);
      arcs.add(
        DsMapArcPlacement(
          connection: connection,
          arc: DsMapArc.between(start, end),
          key: '${connection.fromId}>${connection.toId}@$start>$end',
        ),
      );
    }
    return arcs;
  }

  static Offset _scenePoint(DsMapMarkerPlacement placement, double offsetY) =>
      DsMapProjection.project(
        placement.marker.latitude,
        placement.marker.longitude,
      ).translate(0, offsetY);
}
