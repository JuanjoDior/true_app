import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

void main() {
  group('DsMapProjection', () {
    test('scene size matches 360x135 degrees at 4 px per degree', () {
      expect(DsMapProjection.pixelsPerDegree, 4);
      expect(DsMapProjection.sceneWidth, 360 * 4);
      expect(DsMapProjection.sceneHeight, 135 * 4);
      expect(DsMapProjection.sceneWidth, 1440);
      expect(DsMapProjection.sceneHeight, 540);
    });

    test('vertical offsets match the design doc', () {
      expect(DsMapProjection.verticalOffsetDesktopDossierBand, 40);
      expect(DsMapProjection.verticalOffsetDesktopFull, 180);
      expect(DsMapProjection.verticalOffsetMobile, 0);
    });

    test('projects the scene corners and the origin', () {
      expect(DsMapProjection.project(80, -180), const Offset(0, 0));
      expect(DsMapProjection.project(0, 0), const Offset(720, 320));
      expect(DsMapProjection.project(-55, 180), const Offset(1440, 540));
    });

    test('unprojects known scene points', () {
      final origin = DsMapProjection.unproject(const Offset(720, 320));
      expect(origin.latitude, 0);
      expect(origin.longitude, 0);

      final corner = DsMapProjection.unproject(const Offset(0, 0));
      expect(corner.latitude, 80);
      expect(corner.longitude, -180);
    });

    test('project/unproject round trip over a grid of points', () {
      for (var lat = -55.0; lat <= 80.0; lat += 7.3) {
        for (var lon = -180.0; lon <= 180.0; lon += 11.7) {
          final back = DsMapProjection.unproject(
            DsMapProjection.project(lat, lon),
          );
          expect(back.latitude, closeTo(lat, 1e-9));
          expect(back.longitude, closeTo(lon, 1e-9));
        }
      }
    });
  });
}
