import 'dart:ui';

import 'package:flutter/foundation.dart' show immutable;

import 'ds_map_camera.dart';
import 'ds_map_marker.dart';
import 'ds_map_marker_state.dart';
import 'ds_map_projection.dart';

/// Marcador ya resuelto en coordenadas de pantalla.
@immutable
class DsMapMarkerPlacement {
  const DsMapMarkerPlacement({
    required this.marker,
    required this.center,
    required this.visual,
    required this.selected,
    required this.related,
  });

  final DsMapMarker marker;
  final Offset center;
  final DsMapMarkerVisual visual;
  final bool selected;
  final bool related;

  @override
  bool operator ==(Object other) =>
      other is DsMapMarkerPlacement &&
      other.marker == marker &&
      other.center == center &&
      other.visual == visual &&
      other.selected == selected &&
      other.related == related;

  @override
  int get hashCode => Object.hash(marker, center, visual, selected, related);
}

abstract final class DsMapMarkerLayout {
  static const double hitRadius = DsMapMarkerStates.minTapTarget / 2;

  /// Solo devuelve marcadores interactivos, en orden de pintado: el seleccionado queda encima.
  static List<DsMapMarkerPlacement> place({
    required List<DsMapMarker> markers,
    required DsMapCamera camera,
    required double verticalOffset,
    required String? selectedId,
    required Set<String> relatedIds,
    required Set<String>? matchingIds,
    required int? timelineYear,
    required bool mobile,
  }) {
    final plain = <DsMapMarkerPlacement>[];
    final related = <DsMapMarkerPlacement>[];
    final selected = <DsMapMarkerPlacement>[];
    for (final marker in markers) {
      final isSelected = marker.id == selectedId;
      final isRelated = !isSelected && relatedIds.contains(marker.id);
      final visual = DsMapMarkerStates.resolve(
        selected: isSelected,
        related: isRelated,
        matchesFilter: matchingIds == null || matchingIds.contains(marker.id),
        shownByYear:
            timelineYear == null ||
            DsMapMarkerStates.shownByYear(
              caseYear: marker.year,
              timelineYear: timelineYear,
            ),
        hasSelection: selectedId != null,
        mobile: mobile,
      );
      if (!visual.interactive) continue;
      final scenePoint = DsMapProjection.project(
        marker.latitude,
        marker.longitude,
      );
      final placement = DsMapMarkerPlacement(
        marker: marker,
        center: camera.apply(scenePoint + Offset(0, verticalOffset)),
        visual: visual,
        selected: isSelected,
        related: isRelated,
      );
      (isSelected
              ? selected
              : isRelated
              ? related
              : plain)
          .add(placement);
    }
    return [...plain, ...related, ...selected];
  }

  /// En empate gana el último en orden de pintado (el que se ve encima).
  static DsMapMarkerPlacement? hitTest(
    List<DsMapMarkerPlacement> placements,
    Offset position,
  ) {
    DsMapMarkerPlacement? best;
    var bestDistance = double.infinity;
    for (final placement in placements) {
      final distance = (placement.center - position).distance;
      if (distance <= hitRadius && distance <= bestDistance) {
        best = placement;
        bestDistance = distance;
      }
    }
    return best;
  }
}
