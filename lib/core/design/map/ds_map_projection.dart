import 'dart:ui';

import 'ds_land_grid.dart';

abstract final class DsMapProjection {
  static const double pixelsPerDegree = 4;
  static const double sceneWidth = 1440;
  static const double sceneHeight = 540;

  static const double verticalOffsetDesktopDossierBand = 40;
  static const double verticalOffsetDesktopFull = 180;
  static const double verticalOffsetMobile = 0;

  // El desplazamiento vertical lo aplica quien llama, según su contenedor.
  static Offset project(double latitude, double longitude) {
    return Offset(
      (longitude - DsLandGrid.firstLongitude) * pixelsPerDegree,
      (DsLandGrid.firstLatitude - latitude) * pixelsPerDegree,
    );
  }

  static ({double latitude, double longitude}) unproject(Offset scenePoint) {
    return (
      latitude: DsLandGrid.firstLatitude - scenePoint.dy / pixelsPerDegree,
      longitude: DsLandGrid.firstLongitude + scenePoint.dx / pixelsPerDegree,
    );
  }
}
