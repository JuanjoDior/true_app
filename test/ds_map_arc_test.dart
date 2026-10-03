import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

double _length(Path path) =>
    path.computeMetrics().fold(0.0, (sum, m) => sum + m.length);

void main() {
  group('DsMapArc constants', () {
    test('match the design doc', () {
      expect(DsMapArc.strokeWidth, 1.8);
      expect(DsMapArc.dashOn, 7);
      expect(DsMapArc.dashOff, 7);
      expect(DsMapArc.dashPeriod, 14);
      expect(DsMapArc.revealDelay, const Duration(milliseconds: 600));
    });
  });

  group('DsMapArc.between', () {
    test('horizontal pair has the hand-computed control and label', () {
      final arc = DsMapArc.between(
        const Offset(0, 100),
        const Offset(300, 100),
      );
      expect(arc.control.dx, closeTo(150, 1e-9));
      expect(arc.control.dy, closeTo(-4, 1e-9));
      expect(arc.labelPoint.dx, closeTo(150, 1e-9));
      expect(arc.labelPoint.dy, closeTo(48, 1e-9));
    });

    test('control and label are symmetric when swapping the ends', () {
      const a = Offset(40, 220);
      const b = Offset(310, 90);
      final ab = DsMapArc.between(a, b);
      final ba = DsMapArc.between(b, a);
      expect(ab.control.dx, closeTo(ba.control.dx, 1e-9));
      expect(ab.control.dy, closeTo(ba.control.dy, 1e-9));
      expect(ab.labelPoint.dx, closeTo(ba.labelPoint.dx, 1e-9));
      expect(ab.labelPoint.dy, closeTo(ba.labelPoint.dy, 1e-9));
    });

    test('vertical pair uses the smaller y and the vertical distance', () {
      final arc = DsMapArc.between(const Offset(50, 0), const Offset(50, 100));
      // dist 100 -> control y = 0 - 28 - 20
      expect(arc.control.dx, closeTo(50, 1e-9));
      expect(arc.control.dy, closeTo(-48, 1e-9));
      expect(arc.labelPoint.dx, closeTo(50, 1e-9));
      // 0.25*0 + 0.5*(-48) + 0.25*100
      expect(arc.labelPoint.dy, closeTo(1, 1e-9));
    });

    test('diagonal pair uses the euclidean distance', () {
      final arc = DsMapArc.between(const Offset(0, 0), const Offset(30, 40));
      // dist 50 -> control y = 0 - 14 - 20
      expect(arc.control.dx, closeTo(15, 1e-9));
      expect(arc.control.dy, closeTo(-34, 1e-9));
    });

    test('path starts at a and ends at b', () {
      final arc = DsMapArc.between(
        const Offset(0, 100),
        const Offset(300, 100),
      );
      final metric = arc.path.computeMetrics().single;
      expect(metric.getTangentForOffset(0)!.position, const Offset(0, 100));
      final end = metric.getTangentForOffset(metric.length)!.position;
      expect(end.dx, closeTo(300, 1e-6));
      expect(end.dy, closeTo(100, 1e-6));
    });

    test('path midpoint is the label point', () {
      final arc = DsMapArc.between(
        const Offset(0, 100),
        const Offset(300, 100),
      );
      final metric = arc.path.computeMetrics().single;
      // Symmetric curve: half the length is t = 0.5, y = 0.25*100 + 0.5*(-4) + 0.25*100
      final mid = metric.getTangentForOffset(metric.length / 2)!.position;
      expect(mid.dx, closeTo(arc.labelPoint.dx, 0.5));
      expect(mid.dy, closeTo(arc.labelPoint.dy, 0.5));
    });

    test('degenerate pair stays finite and does not throw', () {
      final arc = DsMapArc.between(const Offset(10, 10), const Offset(10, 10));
      expect(arc.control.dx.isFinite, isTrue);
      expect(arc.control.dy.isFinite, isTrue);
      expect(arc.labelPoint.dx.isFinite, isTrue);
      expect(arc.labelPoint.dy.isFinite, isTrue);
      expect(arc.control, const Offset(10, -10));
      expect(arc.labelPoint, const Offset(10, 0));
      expect(_length(arc.path).isFinite, isTrue);
      expect(() => arc.dashedPath(phase: 3), returnsNormally);
    });
  });

  group('DsMapArc.dashPhase', () {
    test('scales the animation value by the dash period', () {
      expect(DsMapArc.dashPhase(0), 0);
      expect(DsMapArc.dashPhase(0.5), 7);
      expect(DsMapArc.dashPhase(1), 14);
    });
  });

  group('DsMapArc.dashedPath', () {
    final arc = DsMapArc.between(const Offset(0, 100), const Offset(300, 100));
    final curveLength = _length(arc.path);
    final expected =
        curveLength * DsMapArc.dashOn / (DsMapArc.dashOn + DsMapArc.dashOff);

    test('dashes cover on/(on+off) of the curve within one dash', () {
      for (final phase in [0.0, 3.5, 7.0, 10.0]) {
        final dashed = _length(arc.dashedPath(phase: phase));
        expect(
          (dashed - expected).abs(),
          lessThanOrEqualTo(DsMapArc.dashOn),
          reason: 'phase $phase',
        );
      }
    });

    test('has many separate dash segments', () {
      final count = arc.dashedPath(phase: 0).computeMetrics().length;
      expect(count, (curveLength / DsMapArc.dashPeriod).ceil());
    });

    test('phases one period apart are equivalent', () {
      for (final phase in [0.0, 4.0, 9.5]) {
        final a = arc.dashedPath(phase: phase);
        final b = arc.dashedPath(phase: phase + DsMapArc.dashPeriod);
        expect(_length(a), closeTo(_length(b), 1e-6));
        expect(a.computeMetrics().length, b.computeMetrics().length);
      }
    });

    test('a different phase moves the dashes', () {
      final first = arc.dashedPath(phase: 0).computeMetrics().first;
      final shifted = arc.dashedPath(phase: 7).computeMetrics().first;
      final firstStart = first.getTangentForOffset(0)!.position;
      final shiftedStart = shifted.getTangentForOffset(0)!.position;
      expect(shiftedStart, isNot(firstStart));
    });

    test('with phase 0 the first dash starts at a and has length on', () {
      final first = arc.dashedPath(phase: 0).computeMetrics().first;
      expect(first.getTangentForOffset(0)!.position, const Offset(0, 100));
      expect(first.length, closeTo(DsMapArc.dashOn, 0.2));
    });
  });
}
