import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/tokens/tokens.dart';

void main() {
  group('DsMotion curves (DESIGN.md 3.4)', () {
    test('ui is cubic-bezier(.2,.8,.2,1)', () {
      expect(DsMotion.easeUi, const Cubic(0.2, 0.8, 0.2, 1));
    });

    test('fly is cubic-bezier(.22,.8,.2,1)', () {
      expect(DsMotion.easeFly, const Cubic(0.22, 0.8, 0.2, 1));
    });

    test('globe is cubic-bezier(.45,.05,.2,1)', () {
      expect(DsMotion.easeGlobe, const Cubic(0.45, 0.05, 0.2, 1));
    });
  });

  group('DsMotion durations', () {
    test('frequent UI motion stays under 300 ms', () {
      expect(DsMotion.hover, lessThan(const Duration(milliseconds: 300)));
      expect(DsMotion.press, lessThan(const Duration(milliseconds: 300)));
      expect(DsMotion.press, lessThan(DsMotion.hover));
    });

    test('documented values', () {
      expect(DsMotion.hover, const Duration(milliseconds: 250));
      expect(DsMotion.press, const Duration(milliseconds: 160));
      expect(DsMotion.crossfade, const Duration(milliseconds: 900));
      expect(DsMotion.kenBurns, const Duration(seconds: 8));
      expect(DsMotion.fly, const Duration(milliseconds: 1800));
      expect(DsMotion.carouselDesktop, const Duration(seconds: 7));
      expect(DsMotion.carouselMobile, const Duration(milliseconds: 6500));
      expect(DsMotion.pulseSelected, const Duration(milliseconds: 1800));
      expect(DsMotion.pulseIdle, const Duration(seconds: 3));
      expect(DsMotion.dash, const Duration(milliseconds: 1200));
    });

    test('globe camera values (map-and-globe 3.3)', () {
      expect(DsMotion.globeFly, const Duration(milliseconds: 1900));
      expect(DsMotion.globeDriftStep, const Duration(milliseconds: 70));
      expect(DsMotion.globeDriftTransition, const Duration(milliseconds: 80));
      expect(DsMotion.globeDriftTransition, lessThan(DsMotion.globeFly));
    });

    test('mobile carousel advances faster than desktop', () {
      expect(DsMotion.carouselMobile, lessThan(DsMotion.carouselDesktop));
    });
  });

  group('DsMotion.resolve', () {
    test('returns zero when motion is reduced', () {
      expect(
        DsMotion.resolve(DsMotion.crossfade, reduceMotion: true),
        Duration.zero,
      );
    });

    test('returns the same duration otherwise', () {
      expect(
        DsMotion.resolve(DsMotion.crossfade, reduceMotion: false),
        DsMotion.crossfade,
      );
    });
  });
}
