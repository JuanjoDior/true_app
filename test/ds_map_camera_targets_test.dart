import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

void _expectCamera(
  DsMapCamera actual, {
  required double tx,
  required double ty,
  required double k,
}) {
  expect(actual.scale, closeTo(k, 1e-9));
  expect(actual.translateX, closeTo(tx, 1e-9));
  expect(actual.translateY, closeTo(ty, 1e-9));
}

void _expectLands(DsMapCamera camera, Offset center, Offset target) {
  final landed = camera.apply(center);
  expect(landed.dx, closeTo(target.dx, 1e-9));
  expect(landed.dy, closeTo(target.dy, 1e-9));
}

Offset _centerOf(List<Offset> points) {
  var minX = points.first.dx;
  var maxX = minX;
  var minY = points.first.dy;
  var maxY = minY;
  for (final p in points) {
    if (p.dx < minX) minX = p.dx;
    if (p.dx > maxX) maxX = p.dx;
    if (p.dy < minY) minY = p.dy;
    if (p.dy > maxY) maxY = p.dy;
  }
  return Offset((minX + maxX) / 2, (minY + maxY) / 2);
}

void main() {
  group('DsMapCameraTargets.world', () {
    test('desktop is the identity camera', () {
      _expectCamera(
        DsMapCameraTargets.world(view: DsMapWorldView.desktop),
        tx: 0,
        ty: 0,
        k: 1,
      );
    });

    test('mobileBand centers (680, 190) on (195, 230) at k 0.42', () {
      final camera = DsMapCameraTargets.world(view: DsMapWorldView.mobileBand);
      _expectCamera(camera, tx: -90.6, ty: 150.2, k: 0.42);
      _expectLands(camera, const Offset(680, 190), const Offset(195, 230));
    });

    test('mobileMap centers (560, 180) on (195, 330) at k 0.62', () {
      final camera = DsMapCameraTargets.world(view: DsMapWorldView.mobileMap);
      _expectCamera(camera, tx: -152.2, ty: 218.4, k: 0.62);
      _expectLands(camera, const Offset(560, 180), const Offset(195, 330));
    });
  });

  group('DsMapCameraTargets.focusCase', () {
    test('desktop: k 3.4 and the case lands on (900, 310)', () {
      final camera = DsMapCameraTargets.focusCase(
        casePoint: const Offset(720, 320),
        layout: DsMapLayout.desktop,
      );
      _expectCamera(camera, tx: -1548, ty: -778, k: 3.4);
    });

    test('mobile: k 2.2 and the case lands on (195, 230)', () {
      final camera = DsMapCameraTargets.focusCase(
        casePoint: const Offset(100, 200),
        layout: DsMapLayout.mobile,
      );
      _expectCamera(camera, tx: 195 - 2.2 * 100, ty: 230 - 2.2 * 200, k: 2.2);
    });
  });

  group('DsMapCameraTargets.connections', () {
    test('clamps to the lower bound 1.2 for a wide spread', () {
      // bw 2000 -> 0.366, bh 1000 -> 0.344: min 0.344 -> 1.2
      final camera = DsMapCameraTargets.connections(
        layout: DsMapLayout.desktop,
        points: const [Offset(0, 0), Offset(2000, 1000)],
      );
      _expectCamera(camera, tx: 860 - 1.2 * 1000, ty: 310 - 1.2 * 500, k: 1.2);
    });

    test('keeps an in-range fit untouched', () {
      // bw 400 -> 820/640 = 1.28125, bh 100 -> 420/320 = 1.3125: min 1.28125
      final camera = DsMapCameraTargets.connections(
        layout: DsMapLayout.desktop,
        points: const [Offset(100, 200), Offset(500, 300)],
      );
      _expectCamera(
        camera,
        tx: 860 - 1.28125 * 300,
        ty: 310 - 1.28125 * 250,
        k: 1.28125,
      );
    });

    test('a single point has bw = bh = 0 and the height fit wins', () {
      // 820/240 = 3.41, 420/220 = 1.909...: min is the height fit
      final camera = DsMapCameraTargets.connections(
        layout: DsMapLayout.desktop,
        points: const [Offset(400, 100)],
      );
      const k = 420 / 220;
      _expectCamera(camera, tx: 860 - k * 400, ty: 310 - k * 100, k: k);
    });

    test('accepts any Iterable, not only lists', () {
      final camera = DsMapCameraTargets.connections(
        layout: DsMapLayout.desktop,
        points: {const Offset(100, 200), const Offset(500, 300)},
      );
      expect(camera.scale, closeTo(1.28125, 1e-9));
    });

    test('empty points throws ArgumentError', () {
      for (final layout in DsMapLayout.values) {
        expect(
          () => DsMapCameraTargets.connections(
            layout: layout,
            points: const <Offset>[],
          ),
          throwsArgumentError,
        );
      }
    });

    test('mobile clamps to the lower bound 0.5 for a wide spread', () {
      // bw 2000 -> 340/2120 = 0.160, bh 1000 -> 200/1100 = 0.182: min -> 0.5
      final camera = DsMapCameraTargets.connections(
        layout: DsMapLayout.mobile,
        points: const [Offset(0, 0), Offset(2000, 1000)],
      );
      _expectCamera(camera, tx: 195 - 0.5 * 1000, ty: 210 - 0.5 * 500, k: 0.5);
    });

    test('mobile keeps an in-range fit untouched', () {
      // bw 200 -> 340/320 = 1.0625, bh 60 -> 200/160 = 1.25: min 1.0625
      final camera = DsMapCameraTargets.connections(
        layout: DsMapLayout.mobile,
        points: const [Offset(100, 200), Offset(300, 260)],
      );
      _expectCamera(
        camera,
        tx: 195 - 1.0625 * 200,
        ty: 210 - 1.0625 * 230,
        k: 1.0625,
      );
    });

    test('mobile single point: the height fit 2 wins, below the 2.2 cap', () {
      // 340/120 = 2.833, 200/100 = 2.0: min 2.0
      final camera = DsMapCameraTargets.connections(
        layout: DsMapLayout.mobile,
        points: const [Offset(400, 100)],
      );
      _expectCamera(camera, tx: 195 - 2 * 400, ty: 210 - 2 * 100, k: 2);
    });
  });

  group('DsMapCameraTargets.exploreDesktop', () {
    test('clamps to the lower bound 1.4', () {
      final camera = DsMapCameraTargets.exploreDesktop(
        points: const [Offset(0, 0), Offset(3000, 1000)],
      );
      _expectCamera(camera, tx: 520 - 1.4 * 1500, ty: 470 - 1.4 * 500, k: 1.4);
    });

    test('keeps an in-range fit untouched', () {
      // bw 200 -> 900/460 = 1.9565, bh 100 -> 560/360 = 1.5556: min 1.5556
      final camera = DsMapCameraTargets.exploreDesktop(
        points: const [Offset(100, 100), Offset(300, 200)],
      );
      const k = 560 / 360;
      _expectCamera(camera, tx: 520 - k * 200, ty: 470 - k * 150, k: k);
    });

    test('a single point resolves to the height fit', () {
      final camera = DsMapCameraTargets.exploreDesktop(
        points: const [Offset(720, 320)],
      );
      const k = 560 / 260;
      _expectCamera(camera, tx: 520 - k * 720, ty: 470 - k * 320, k: k);
    });

    test('empty points throws ArgumentError', () {
      expect(
        () => DsMapCameraTargets.exploreDesktop(points: const <Offset>[]),
        throwsArgumentError,
      );
    });
  });

  group('DsMapCameraTargets.exploreMobile', () {
    test('clamps to the lower bound 0.6', () {
      final camera = DsMapCameraTargets.exploreMobile(
        points: const [Offset(0, 0), Offset(2000, 1000)],
      );
      _expectCamera(camera, tx: 195 - 0.6 * 1000, ty: 235 - 0.6 * 500, k: 0.6);
    });

    test('keeps an in-range fit untouched', () {
      // bw 200 -> 340/320 = 1.0625, bh 100 -> 260/220 = 1.18: min 1.0625
      final camera = DsMapCameraTargets.exploreMobile(
        points: const [Offset(100, 100), Offset(300, 200)],
      );
      _expectCamera(
        camera,
        tx: 195 - 1.0625 * 200,
        ty: 235 - 1.0625 * 150,
        k: 1.0625,
      );
    });

    test('a single point resolves to the height fit', () {
      final camera = DsMapCameraTargets.exploreMobile(
        points: const [Offset(50, 60)],
      );
      const k = 260 / 120;
      _expectCamera(camera, tx: 195 - k * 50, ty: 235 - k * 60, k: k);
    });

    test('empty points throws ArgumentError', () {
      expect(
        () => DsMapCameraTargets.exploreMobile(points: const <Offset>[]),
        throwsArgumentError,
      );
    });
  });

  group('focus lands on the viewport target', () {
    const clouds = <List<Offset>>[
      [Offset(720, 320)],
      [Offset(100, 200), Offset(500, 300)],
      [Offset(0, 0), Offset(2000, 1000)],
      [Offset(300, 400), Offset(310, 405), Offset(900, 120)],
      [Offset(1440, 540), Offset(-20, -35)],
    ];

    test('focusCase', () {
      for (final cloud in clouds) {
        for (final layout in DsMapLayout.values) {
          final camera = DsMapCameraTargets.focusCase(
            casePoint: cloud.first,
            layout: layout,
          );
          _expectLands(
            camera,
            cloud.first,
            layout == DsMapLayout.desktop
                ? const Offset(900, 310)
                : const Offset(195, 230),
          );
        }
      }
    });

    test('connections', () {
      const targets = {
        DsMapLayout.desktop: Offset(860, 310),
        DsMapLayout.mobile: Offset(195, 210),
      };
      for (final cloud in clouds) {
        for (final entry in targets.entries) {
          _expectLands(
            DsMapCameraTargets.connections(layout: entry.key, points: cloud),
            _centerOf(cloud),
            entry.value,
          );
        }
      }
    });

    test('exploreDesktop', () {
      for (final cloud in clouds) {
        _expectLands(
          DsMapCameraTargets.exploreDesktop(points: cloud),
          _centerOf(cloud),
          const Offset(520, 470),
        );
      }
    });

    test('exploreMobile', () {
      for (final cloud in clouds) {
        _expectLands(
          DsMapCameraTargets.exploreMobile(points: cloud),
          _centerOf(cloud),
          const Offset(195, 235),
        );
      }
    });
  });

  group('DsMapCameraAnimation', () {
    test('reduced motion is a direct cut, normal is 1800 ms', () {
      expect(DsMapCameraAnimation.duration(reduceMotion: true), Duration.zero);
      expect(
        DsMapCameraAnimation.duration(reduceMotion: false),
        const Duration(milliseconds: 1800),
      );
    });

    test('the tween with easeFly reaches the exact start and end', () {
      const begin = DsMapCamera.world();
      final end = DsMapCameraTargets.focusCase(
        casePoint: const Offset(720, 320),
        layout: DsMapLayout.desktop,
      );
      final tween = DsMapCameraTween(begin: begin, end: end);
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: DsMotion.fly,
      );
      addTearDown(controller.dispose);
      final curved = CurvedAnimation(
        parent: controller,
        curve: DsMotion.easeFly,
      );

      controller.value = 0;
      expect(tween.evaluate(curved), begin);
      controller.value = 1;
      expect(tween.evaluate(curved), end);
      controller.value = 0.5;
      final mid = tween.evaluate(curved);
      expect(mid.scale, greaterThan(1));
      expect(mid.scale, lessThan(3.4));
    });
  });
}
