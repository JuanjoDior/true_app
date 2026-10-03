import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

void main() {
  group('DsMapCamera', () {
    test('world is the identity camera', () {
      const camera = DsMapCamera.world();
      expect(camera.translateX, 0);
      expect(camera.translateY, 0);
      expect(camera.scale, 1);
      expect(camera.apply(const Offset(10, 20)), const Offset(10, 20));
    });

    test('toMatrix is translate then scale with origin (0,0)', () {
      const camera = DsMapCamera(translateX: 30, translateY: -20, scale: 2);
      final m = camera.toMatrix();
      expect(m.storage[0], 2);
      expect(m.storage[5], 2);
      expect(m.storage[12], 30);
      expect(m.storage[13], -20);
      final mapped = MatrixUtils.transformPoint(m, const Offset(5, 7));
      expect(mapped, const Offset(40, -6));
      expect(mapped, camera.apply(const Offset(5, 7)));
    });

    test('apply maps a scene point to k*p + t', () {
      const camera = DsMapCamera(translateX: 100, translateY: 50, scale: 3);
      expect(camera.apply(const Offset(10, 20)), const Offset(130, 110));
    });

    test('invert is the exact inverse of apply', () {
      const camera = DsMapCamera(
        translateX: -1548,
        translateY: -778,
        scale: 3.4,
      );
      for (final p in const [
        Offset(0, 0),
        Offset(720, 320),
        Offset(1440, 540),
        Offset(-35.5, 812.25),
      ]) {
        final back = camera.invert(camera.apply(p));
        expect(back.dx, closeTo(p.dx, 1e-9));
        expect(back.dy, closeTo(p.dy, 1e-9));
      }
    });

    test('lerp at 0, 0.5 and 1 is linear on tx, ty and k', () {
      const a = DsMapCamera(translateX: 0, translateY: 0, scale: 1);
      const b = DsMapCamera(translateX: -1548, translateY: -778, scale: 3.4);
      expect(DsMapCamera.lerp(a, b, 0), a);
      expect(DsMapCamera.lerp(a, b, 1), b);
      final mid = DsMapCamera.lerp(a, b, 0.5);
      expect(mid.translateX, closeTo(-774, 1e-9));
      expect(mid.translateY, closeTo(-389, 1e-9));
      expect(mid.scale, closeTo(2.2, 1e-9));
    });

    test('fromFocus implements tx = target - k * center', () {
      final camera = DsMapCamera.fromFocus(
        sceneCenter: const Offset(720, 320),
        viewportTarget: const Offset(900, 310),
        scale: 3.4,
      );
      expect(camera.scale, 3.4);
      expect(camera.translateX, closeTo(-1548, 1e-9));
      expect(camera.translateY, closeTo(-778, 1e-9));
      final landed = camera.apply(const Offset(720, 320));
      expect(landed.dx, closeTo(900, 1e-9));
      expect(landed.dy, closeTo(310, 1e-9));
    });

    test('equality, hashCode and toString', () {
      const a = DsMapCamera(translateX: 1, translateY: 2, scale: 3);
      const b = DsMapCamera(translateX: 1, translateY: 2, scale: 3);
      const c = DsMapCamera(translateX: 1, translateY: 2, scale: 4);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
      expect(a.toString(), contains('DsMapCamera'));
      expect(a.toString(), contains('3'));
    });
  });
}
