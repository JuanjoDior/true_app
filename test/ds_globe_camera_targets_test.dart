import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/globe/globe.dart';

typedef _Target = ({double latitude, double longitude});

const _targets = <_Target>[
  (latitude: 38, longitude: -122),
  (latitude: -33.9, longitude: 151.2),
  (latitude: 0, longitude: 0),
  (latitude: 64.1, longitude: -21.9),
  (latitude: -54.8, longitude: -68.3),
  (latitude: 35.7, longitude: 139.7),
];

const _startingGys = <double>[0, 90, -170, 350, 725, -400];
const _halfTurn = 180.0;
const _tolerance = 1e-9;

Offset _markerOnScreen(DsGlobeCamera camera, _Target target) {
  final marker = DsGlobeMath.surfacePoint(
    latitude: target.latitude,
    longitude: target.longitude,
    radius: DsGlobeMath.radius + DsGlobeMath.markerElevation,
  );
  return DsGlobeMath.project(
    marker,
    gx: camera.gx,
    gy: camera.gy,
    center: camera.center,
    scale: camera.scale,
  ).screen;
}

void main() {
  group('DsGlobeCameraTargets constants (map-and-globe 3.3)', () {
    test('cover mode', () {
      expect(DsGlobeCameraTargets.coverCenter, const Offset(1010, 520));
      expect(DsGlobeCameraTargets.coverScale, 1.0);
    });

    test('explore mode', () {
      expect(DsGlobeCameraTargets.exploreCenter, const Offset(640, 455));
      expect(DsGlobeCameraTargets.exploreScale, 0.78);
    });
  });

  group('hand-computed Zodiac-like target (38, -122) from gy 0', () {
    test('cover faces the case', () {
      final camera = DsGlobeCameraTargets.cover(
        latitude: 38,
        longitude: -122,
        currentGy: 0,
      );
      expect(camera.gx, -38);
      expect(camera.gy, 122);
      expect(camera.scale, 1.0);
      expect(camera.center, const Offset(1010, 520));
    });

    test('explore faces the case', () {
      final camera = DsGlobeCameraTargets.explore(
        latitude: 38,
        longitude: -122,
        currentGy: 0,
      );
      expect(camera.gx, -38);
      expect(camera.gy, 122);
      expect(camera.scale, 0.78);
      expect(camera.center, const Offset(640, 455));
    });
  });

  group('short-way unwrap', () {
    test('currentGy 350 and lon 10 stays on the nearby 350 turn', () {
      final camera = DsGlobeCameraTargets.cover(
        latitude: 0,
        longitude: 10,
        currentGy: 350,
      );
      expect(camera.gy, 350);
    });

    test('currentGy 350 and lon -10 turns 20 degrees forward to 370', () {
      final camera = DsGlobeCameraTargets.explore(
        latitude: 0,
        longitude: -10,
        currentGy: 350,
      );
      expect(camera.gy, 370);
    });

    test('never turns more than half a revolution', () {
      for (final target in _targets) {
        for (final currentGy in _startingGys) {
          final cover = DsGlobeCameraTargets.cover(
            latitude: target.latitude,
            longitude: target.longitude,
            currentGy: currentGy,
          );
          final explore = DsGlobeCameraTargets.explore(
            latitude: target.latitude,
            longitude: target.longitude,
            currentGy: currentGy,
          );
          expect((cover.gy - currentGy).abs(), lessThanOrEqualTo(_halfTurn));
          expect((explore.gy - currentGy).abs(), lessThanOrEqualTo(_halfTurn));
        }
      }
    });
  });

  group('marker lands on the mode center', () {
    for (final target in _targets) {
      for (final currentGy in _startingGys) {
        test('$target from gy $currentGy', () {
          final cover = DsGlobeCameraTargets.cover(
            latitude: target.latitude,
            longitude: target.longitude,
            currentGy: currentGy,
          );
          final coverScreen = _markerOnScreen(cover, target);
          expect(coverScreen.dx, closeTo(1010, _tolerance));
          expect(coverScreen.dy, closeTo(520, _tolerance));

          final explore = DsGlobeCameraTargets.explore(
            latitude: target.latitude,
            longitude: target.longitude,
            currentGy: currentGy,
          );
          final exploreScreen = _markerOnScreen(explore, target);
          expect(exploreScreen.dx, closeTo(640, _tolerance));
          expect(exploreScreen.dy, closeTo(455, _tolerance));
        });
      }
    }
  });

  group('exploreIdle', () {
    test('takes explore center and scale and keeps the orientation', () {
      const current = DsGlobeCamera(
        gx: -12.5,
        gy: 87.3,
        scale: 1,
        center: Offset(1010, 520),
      );
      final idle = DsGlobeCameraTargets.exploreIdle(current: current);
      expect(idle.gx, -12.5);
      expect(idle.gy, 87.3);
      expect(idle.scale, DsGlobeCameraTargets.exploreScale);
      expect(idle.center, DsGlobeCameraTargets.exploreCenter);
    });
  });
}
