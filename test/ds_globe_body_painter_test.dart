import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

import 'test_support/ds_globe_scene_test_support.dart';

const Color _red = Color(0xFFE5484D);
const Color _blue = Color(0xFF3E63DD);
const double _haloRadius = 750;
const double _glowSigma = 75;
const double _bodyRadius = DsGlobeMath.radius;
const double _alpha30 = 0x30 / 0xFF;

Widget _halo({
  required DsGlobeCamera camera,
  required Color? color,
  bool disableAnimations = false,
}) => MediaQuery(
  data: MediaQueryData(disableAnimations: disableAnimations),
  child: DsGlobeHalo(camera: camera, color: color),
);

Color _haloColor(WidgetTester tester) =>
    painterOf<DsGlobeHaloPainter>(tester).color;

TestRecordingCanvas _paint(CustomPainter painter) {
  final canvas = TestRecordingCanvas();
  painter.paint(canvas, desktop);
  return canvas;
}

void main() {
  group('halo painter', () {
    test('is a 1500 px circle centered on the globe center', () {
      final canvas = _paint(
        DsGlobeHaloPainter(camera: coverCamera, color: _red),
      );
      final circles = calls(canvas, #drawCircle);
      expect(circles, hasLength(1));
      expect(circles.single[0], coverCamera.center);
      expect(circles.single[1], _haloRadius * coverCamera.scale);
      expect((circles.single[2]! as Paint).shader, isNotNull);
    });

    test('scales with the camera and follows its center', () {
      final canvas = _paint(
        DsGlobeHaloPainter(camera: exploreCamera, color: _red),
      );
      final circle = calls(canvas, #drawCircle).single;
      expect(circle[0], exploreCamera.center);
      expect(circle[1], _haloRadius * exploreCamera.scale);
      expect(exploreCamera.scale, lessThan(1));
    });

    test(
      'gradient goes from the color at alpha 0x30 to transparent at 52%',
      () {
        final gradient = DsGlobeHaloPainter.gradient(_red);
        expect(gradient.stops, [0, 0.52]);
        expect(gradient.colors.first.a, closeTo(_alpha30, 0.002));
        expect(
          gradient.colors.first.toARGB32() & 0x00FFFFFF,
          _red.toARGB32() & 0x00FFFFFF,
        );
        expect(gradient.colors.last.a, 0);
        expect(
          gradient.colors.last.toARGB32() & 0x00FFFFFF,
          _red.toARGB32() & 0x00FFFFFF,
        );
      },
    );

    test('draws nothing without a visible color', () {
      expect(
        _paint(
          DsGlobeHaloPainter(camera: coverCamera, color: Colors.transparent),
        ).invocations,
        isEmpty,
      );
    });

    test('repaints when the camera or the color change', () {
      final base = DsGlobeHaloPainter(camera: coverCamera, color: _red);
      expect(
        base.shouldRepaint(
          DsGlobeHaloPainter(camera: coverCamera, color: _red),
        ),
        isFalse,
      );
      expect(
        base.shouldRepaint(
          DsGlobeHaloPainter(camera: coverCamera, color: _blue),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          DsGlobeHaloPainter(camera: exploreCamera, color: _red),
        ),
        isTrue,
      );
    });
  });

  group('halo fade', () {
    testWidgets('the first color is shown immediately', (tester) async {
      await tester.pumpWidget(_halo(camera: coverCamera, color: _red));
      expect(_haloColor(tester), _red);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('fades between categories over 1400 ms', (tester) async {
      await tester.pumpWidget(_halo(camera: coverCamera, color: _red));
      await tester.pumpWidget(_halo(camera: coverCamera, color: _blue));
      await tester.pump();
      expect(_haloColor(tester), _red);

      await tester.pump(haloFade ~/ 2);
      final mid = _haloColor(tester);
      expect(mid.r, lessThan(_red.r));
      expect(mid.r, greaterThan(_blue.r));
      expect(mid.b, greaterThan(_red.b));
      expect(mid.b, lessThan(_blue.b));

      await tester.pump(haloFade ~/ 2);
      expect(_haloColor(tester), _blue);
      // La simulación termina estrictamente después de su duración.
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('does not finish before 1400 ms', (tester) async {
      await tester.pumpWidget(_halo(camera: coverCamera, color: _red));
      await tester.pumpWidget(_halo(camera: coverCamera, color: _blue));
      await tester.pump();
      await tester.pump(haloFade - const Duration(milliseconds: 1));
      expect(_haloColor(tester), isNot(_blue));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(const Duration(milliseconds: 1));
      expect(_haloColor(tester), _blue);
    });

    testWidgets('reduced motion snaps to the new color', (tester) async {
      await tester.pumpWidget(
        _halo(camera: coverCamera, color: _red, disableAnimations: true),
      );
      await tester.pumpWidget(
        _halo(camera: coverCamera, color: _blue, disableAnimations: true),
      );
      expect(_haloColor(tester), _blue);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('no halo fades out keeping the hue and ends invisible', (
      tester,
    ) async {
      await tester.pumpWidget(_halo(camera: coverCamera, color: _red));
      await tester.pumpWidget(_halo(camera: coverCamera, color: null));
      await tester.pump();
      await tester.pump(haloFade ~/ 2);
      final mid = _haloColor(tester);
      expect(mid.a, allOf(greaterThan(0), lessThan(1)));
      expect(mid.toARGB32() & 0x00FFFFFF, _red.toARGB32() & 0x00FFFFFF);
      await tester.pump(haloFade ~/ 2);
      expect(_haloColor(tester).a, 0);
    });

    testWidgets('a halo that appears fades in keeping the hue', (tester) async {
      await tester.pumpWidget(_halo(camera: coverCamera, color: null));
      expect(_haloColor(tester).a, 0);
      await tester.pumpWidget(_halo(camera: coverCamera, color: _blue));
      await tester.pump();
      await tester.pump(haloFade ~/ 2);
      final mid = _haloColor(tester);
      expect(mid.a, allOf(greaterThan(0), lessThan(1)));
      expect(mid.toARGB32() & 0x00FFFFFF, _blue.toARGB32() & 0x00FFFFFF);
      await tester.pump(haloFade ~/ 2);
      expect(_haloColor(tester), _blue);
    });

    testWidgets('pumpAndSettle terminates', (tester) async {
      await tester.pumpWidget(_halo(camera: coverCamera, color: _red));
      await tester.pumpWidget(_halo(camera: coverCamera, color: _blue));
      await tester.pumpAndSettle();
      expect(_haloColor(tester), _blue);
    });
  });

  group('sphere body painter', () {
    test('draws the outer glow, the gradient body and the border in order', () {
      final canvas = _paint(DsGlobeBodyPainter(camera: coverCamera));
      final circles = calls(canvas, #drawCircle);
      expect(circles, hasLength(3));
      for (final args in circles) {
        expect(args[0], coverCamera.center);
        expect(args[1], _bodyRadius * coverCamera.scale);
      }

      final glow = circles[0][2]! as Paint;
      expect(
        glow.color.toARGB32(),
        const Color.fromRGBO(90, 160, 208, 0.22).toARGB32(),
      );
      expect(
        glow.maskFilter,
        const MaskFilter.blur(BlurStyle.normal, _glowSigma),
      );

      final body = circles[1][2]! as Paint;
      expect(body.shader, isNotNull);
      expect(body.style, PaintingStyle.fill);

      final border = circles[2][2]! as Paint;
      expect(border.style, PaintingStyle.stroke);
      expect(border.strokeWidth, 1);
      expect(
        border.color.toARGB32(),
        const Color.fromRGBO(140, 190, 240, 0.2).toARGB32(),
      );
    });

    test('the radius, center and glow follow camera scale and center', () {
      final canvas = _paint(DsGlobeBodyPainter(camera: exploreCamera));
      final circles = calls(canvas, #drawCircle);
      for (final args in circles) {
        expect(args[0], exploreCamera.center);
        expect(args[1], _bodyRadius * exploreCamera.scale);
      }
      expect(
        (circles[0][2]! as Paint).maskFilter,
        MaskFilter.blur(BlurStyle.normal, _glowSigma * exploreCamera.scale),
      );
    });

    test(
      'body gradient: focus at 38%/32%, #1A2638 -> #0A0F18 55% -> #05070B',
      () {
        final gradient = DsGlobeBodyPainter.bodyGradient;
        expect((gradient.center as Alignment).x, closeTo(-0.24, 1e-9));
        expect((gradient.center as Alignment).y, closeTo(-0.36, 1e-9));
        expect(gradient.radius, 0.5);
        expect(gradient.colors, const [
          Color(0xFF1A2638),
          Color(0xFF0A0F18),
          Color(0xFF05070B),
        ]);
        expect(gradient.stops, [0, 0.55, 1]);
      },
    );

    test('repaints only when the camera changes', () {
      final base = DsGlobeBodyPainter(camera: coverCamera);
      expect(
        base.shouldRepaint(DsGlobeBodyPainter(camera: coverCamera)),
        isFalse,
      );
      expect(
        base.shouldRepaint(DsGlobeBodyPainter(camera: exploreCamera)),
        isTrue,
      );
    });
  });

  group('sphere shading painter', () {
    test('draws the specular highlight then the limb darkening', () {
      final canvas = _paint(DsGlobeShadingPainter(camera: coverCamera));
      final circles = calls(canvas, #drawCircle);
      expect(circles, hasLength(2));
      for (final args in circles) {
        expect(args[0], coverCamera.center);
        expect(args[1], _bodyRadius * coverCamera.scale);
        expect((args[2]! as Paint).shader, isNotNull);
      }
    });

    test('highlight is rgba(140,190,240,.16) fading to transparent', () {
      final gradient = DsGlobeShadingPainter.highlightGradient;
      expect(gradient.colors.first, const Color.fromRGBO(140, 190, 240, 0.16));
      expect(gradient.colors.last.a, 0);
      final center = gradient.center as Alignment;
      expect(center.x, lessThan(0));
      expect(center.y, lessThan(0));
    });

    test('limb darkens toward rgba(5,7,11,.92) at the edge', () {
      final gradient = DsGlobeShadingPainter.limbGradient;
      expect(gradient.center, Alignment.center);
      expect(gradient.colors.first.a, 0);
      expect(gradient.colors.last, const Color.fromRGBO(5, 7, 11, 0.92));
      expect(gradient.stops!.last, 1);
      expect(gradient.stops!.first, greaterThan(0));
    });

    test('repaints only when the camera changes', () {
      final base = DsGlobeShadingPainter(camera: coverCamera);
      expect(
        base.shouldRepaint(DsGlobeShadingPainter(camera: coverCamera)),
        isFalse,
      );
      expect(
        base.shouldRepaint(DsGlobeShadingPainter(camera: exploreCamera)),
        isTrue,
      );
    });
  });
}
