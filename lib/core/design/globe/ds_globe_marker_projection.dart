import 'package:flutter/foundation.dart' show immutable;

import '../map/ds_map_marker.dart';
import '../map/ds_map_marker_layout.dart';
import '../map/ds_map_marker_state.dart';
import 'ds_globe_camera.dart';
import 'ds_globe_math.dart';

/// Marcador del globo ya proyectado, con la visibilidad de su etiqueta.
@immutable
class DsGlobePlacedMarker {
  const DsGlobePlacedMarker({
    required this.placement,
    required this.labelVisible,
  });

  final DsMapMarkerPlacement placement;
  final bool labelVisible;

  @override
  bool operator ==(Object other) =>
      other is DsGlobePlacedMarker &&
      other.placement == placement &&
      other.labelVisible == labelVisible;

  @override
  int get hashCode => Object.hash(placement, labelVisible);
}

/// Proyección de marcadores sobre la esfera con las mismas reglas del mapa plano.
abstract final class DsGlobeMarkerProjection {
  static const double markerRadius =
      DsGlobeMath.radius + DsGlobeMath.markerElevation;

  /// Solo devuelve marcadores delanteros e interactivos, en orden de pintado: el seleccionado queda encima.
  static List<DsGlobePlacedMarker> place({
    required List<DsMapMarker> markers,
    required DsGlobeCamera camera,
    required String? selectedId,
    required Set<String> relatedIds,
    required Set<String>? matchingIds,
    required int? timelineYear,
  }) {
    final plain = <DsGlobePlacedMarker>[];
    final related = <DsGlobePlacedMarker>[];
    final selected = <DsGlobePlacedMarker>[];
    for (final marker in markers) {
      final projection = DsGlobeMath.project(
        DsGlobeMath.surfacePoint(
          latitude: marker.latitude,
          longitude: marker.longitude,
          radius: markerRadius,
        ),
        gx: camera.gx,
        gy: camera.gy,
        center: camera.center,
        scale: camera.scale,
      );
      if (!projection.isFront) continue;
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
        mobile: false,
      );
      if (!visual.interactive) continue;
      final placed = DsGlobePlacedMarker(
        placement: DsMapMarkerPlacement(
          marker: marker,
          center: projection.screen,
          visual: _scaled(visual, camera.scale * projection.perspectiveFactor),
          selected: isSelected,
          related: isRelated,
        ),
        labelVisible: projection.isLabelVisible,
      );
      (isSelected
              ? selected
              : isRelated
              ? related
              : plain)
          .add(placed);
    }
    return [...plain, ...related, ...selected];
  }

  static List<DsMapMarkerPlacement> placementsOf(
    List<DsGlobePlacedMarker> placed,
  ) => [for (final marker in placed) marker.placement];

  static DsMapMarkerVisual _scaled(DsMapMarkerVisual visual, double factor) =>
      DsMapMarkerVisual(
        diameter: visual.diameter * factor,
        glowRadius: visual.glowRadius,
        opacity: visual.opacity,
        showLabel: visual.showLabel,
        goldBorder: visual.goldBorder,
        pulsing: visual.pulsing,
        pulseDuration: visual.pulseDuration,
        interactive: visual.interactive,
      );
}
