import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/globe/globe.dart';
import 'package:true_app/core/design/tokens/tokens.dart';

void main() {
  const a = DsGlobeCamera(
    gx: -10,
    gy: 100,
    scale: 1,
    center: Offset(1010, 520),
  );
  const b = DsGlobeCamera(
    gx: 30,
    gy: 200,
    scale: 0.78,
    center: Offset(640, 455),
  );

  group('DsGlobeCamera value semantics', () {
    test('equal cameras share equality and hashCode', () {
      const same = DsGlobeCamera(
        gx: -10,
        gy: 100,
        scale: 1,
        center: Offset(1010, 520),
      );
      expect(a, same);
      expect(a.hashCode, same.hashCode);
      expect(a, isNot(b));
    });

    test('any differing field breaks equality', () {
      expect(a, isNot(a.copyWith(gx: 0)));
      expect(a, isNot(a.copyWith(gy: 0)));
      expect(a, isNot(a.copyWith(scale: 2)));
      expect(a, isNot(a.copyWith(center: Offset.zero)));
    });

    test('copyWith replaces only the given fields', () {
      final copy = a.copyWith(gy: 5);
      expect(copy.gx, -10);
      expect(copy.gy, 5);
      expect(copy.scale, 1);
      expect(copy.center, const Offset(1010, 520));
      expect(a.copyWith(), a);
    });

    test('toString lists every field', () {
      final text = a.toString();
      expect(text, startsWith('DsGlobeCamera('));
      expect(text, contains('-10'));
      expect(text, contains('100'));
      expect(text, contains('1010'));
    });
  });

  group('DsGlobeCamera.lerp', () {
    test('endpoints are exact', () {
      expect(DsGlobeCamera.lerp(a, b, 0), a);
      expect(DsGlobeCamera.lerp(a, b, 1), b);
    });

    test('midpoint is linear on every field', () {
      final mid = DsGlobeCamera.lerp(a, b, 0.5);
      expect(mid.gx, 10);
      expect(mid.gy, 150);
      expect(mid.scale, closeTo(0.89, 1e-12));
      expect(mid.center, const Offset(825, 487.5));
    });
  });

  group('DsGlobeCamera.drifted', () {
    test('drift step is 0.22 degrees', () {
      expect(DsGlobeCamera.driftDegreesPerStep, 0.22);
    });

    test('subtracts the default step from gy only', () {
      final next = a.drifted();
      expect(next.gy, closeTo(99.78, 1e-12));
      expect(next.gx, a.gx);
      expect(next.scale, a.scale);
      expect(next.center, a.center);
    });

    test('is cumulative', () {
      var camera = a;
      for (var i = 0; i < 10; i++) {
        camera = camera.drifted();
      }
      expect(camera.gy, closeTo(100 - 2.2, 1e-9));
    });

    test('accepts a custom amount', () {
      expect(a.drifted(degrees: 1).gy, 99);
    });
  });

  group('DsGlobeCameraAnimation.duration', () {
    test('is 1900 ms with motion', () {
      expect(
        DsGlobeCameraAnimation.duration(reduceMotion: false),
        const Duration(milliseconds: 1900),
      );
    });

    test('is zero with reduced motion', () {
      expect(
        DsGlobeCameraAnimation.duration(reduceMotion: true),
        Duration.zero,
      );
    });
  });

  group('DsGlobeCameraAnimation.driftEnabled', () {
    const expected = <(bool, bool, bool), bool>{
      (false, false, false): false,
      (false, false, true): true,
      (false, true, false): false,
      (false, true, true): false,
      (true, false, false): false,
      (true, false, true): false,
      (true, true, false): false,
      (true, true, true): false,
    };

    for (final entry in expected.entries) {
      final (reduceMotion, hasSelection, flightFinished) = entry.key;
      test('reduceMotion=$reduceMotion hasSelection=$hasSelection '
          'flightFinished=$flightFinished -> ${entry.value}', () {
        expect(
          DsGlobeCameraAnimation.driftEnabled(
            reduceMotion: reduceMotion,
            hasSelection: hasSelection,
            flightFinished: flightFinished,
          ),
          entry.value,
        );
      });
    }
  });

  group('DsGlobeCameraTween', () {
    test('interpolates with DsGlobeCamera.lerp', () {
      final tween = DsGlobeCameraTween(begin: a, end: b);
      expect(tween.transform(0.5), DsGlobeCamera.lerp(a, b, 0.5));
    });

    test('hits both endpoints exactly through the globe curve', () {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: DsGlobeCameraAnimation.duration(reduceMotion: false),
      );
      addTearDown(controller.dispose);
      final animation = DsGlobeCameraTween(
        begin: a,
        end: b,
      ).animate(CurvedAnimation(parent: controller, curve: DsMotion.easeGlobe));

      expect(animation.value, a);
      controller.value = 1;
      expect(animation.value, b);
    });
  });
}
