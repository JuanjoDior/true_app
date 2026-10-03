import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

const Duration _selectedCycle = Duration(milliseconds: 1800);
const Duration _idleCycle = Duration(seconds: 3);
const Duration _dashCycle = Duration(milliseconds: 1200);
const double _tolerance = 1e-9;

double _pulse(Duration elapsed, {int index = 0, bool selected = false}) =>
    DsMapMotionClock.pulseProgress(
      elapsed: elapsed,
      index: index,
      selected: selected,
    );

Duration _ms(int value) => Duration(milliseconds: value);

void main() {
  group('period', () {
    test('is 18 s', () {
      expect(DsMapMotionClock.period, const Duration(seconds: 18));
    });

    test('is a whole multiple of every cycle so the loop is seamless', () {
      for (final cycle in [_selectedCycle, _idleCycle, _dashCycle]) {
        expect(
          DsMapMotionClock.period.inMicroseconds % cycle.inMicroseconds,
          0,
          reason: '$cycle',
        );
      }
    });

    test('is the least common multiple of the cycles', () {
      for (final candidate in [for (var s = 1; s < 18; s++) _ms(s * 600)]) {
        final common = [
          _selectedCycle,
          _idleCycle,
          _dashCycle,
        ].every((c) => candidate.inMicroseconds % c.inMicroseconds == 0);
        expect(common, isFalse, reason: '$candidate');
      }
    });

    test('matches the design cycles', () {
      expect(_selectedCycle, DsMotion.pulseSelected);
      expect(_idleCycle, DsMotion.pulseIdle);
      expect(_dashCycle, DsMotion.dash);
    });
  });

  group('pulseProgress', () {
    test('starts at 0 for marker 0 at elapsed 0', () {
      expect(_pulse(Duration.zero), 0);
      expect(_pulse(Duration.zero, selected: true), 0);
    });

    test('idle markers advance linearly over 3 s', () {
      expect(_pulse(_ms(750)), closeTo(0.25, _tolerance));
      expect(_pulse(_ms(1500)), closeTo(0.5, _tolerance));
      expect(_pulse(_ms(2250)), closeTo(0.75, _tolerance));
    });

    test('selected markers advance linearly over 1.8 s', () {
      expect(_pulse(_ms(450), selected: true), closeTo(0.25, _tolerance));
      expect(_pulse(_ms(900), selected: true), closeTo(0.5, _tolerance));
      expect(_pulse(_ms(1350), selected: true), closeTo(0.75, _tolerance));
    });

    test('wraps to 0 at exact multiples of the idle cycle', () {
      for (var n = 1; n <= 6; n++) {
        expect(_pulse(_idleCycle * n), 0, reason: 'n=$n');
      }
    });

    test('wraps to 0 at exact multiples of the selected cycle', () {
      for (var n = 1; n <= 10; n++) {
        expect(_pulse(_selectedCycle * n, selected: true), 0, reason: 'n=$n');
      }
    });

    test('just before the end of a cycle it is close to 1 but below it', () {
      final almost = _idleCycle - const Duration(microseconds: 1);
      expect(_pulse(almost), lessThan(1));
      expect(_pulse(almost), closeTo(1, 1e-6));
    });

    test('is periodic over the whole 18 s loop', () {
      for (final elapsed in [0, 123, 2999, 4567, 9000, 17999]) {
        for (final selected in [false, true]) {
          for (final index in [0, 1, 7, 12]) {
            expect(
              _pulse(
                _ms(elapsed) + DsMapMotionClock.period,
                index: index,
                selected: selected,
              ),
              closeTo(
                _pulse(_ms(elapsed), index: index, selected: selected),
                _tolerance,
              ),
              reason: '$elapsed/$index/$selected',
            );
          }
        }
      }
    });

    test('is continuous across the loop boundary', () {
      for (final selected in [false, true]) {
        final before = _pulse(
          DsMapMotionClock.period - const Duration(microseconds: 1),
          index: 3,
          selected: selected,
        );
        final after = _pulse(
          DsMapMotionClock.period,
          index: 3,
          selected: selected,
        );
        final circular = (after - before).abs();
        expect(
          circular < 1e-6 || (1 - circular) < 1e-6,
          isTrue,
          reason: 'selected=$selected before=$before after=$after',
        );
      }
    });

    test('a marker starts its cycle when its delay has elapsed', () {
      for (var index = 0; index < 10; index++) {
        final delay = DsMapMarkerStates.pulseDelay(index);
        expect(_pulse(delay, index: index), 0, reason: 'idle $index');
        expect(
          _pulse(delay, index: index, selected: true),
          0,
          reason: 'selected $index',
        );
      }
    });

    test('before its delay a marker is late in its previous cycle', () {
      // Retraso del índice 1: 410 ms.
      expect(_pulse(Duration.zero, index: 1), closeTo(2590 / 3000, _tolerance));
      expect(
        _pulse(Duration.zero, index: 1, selected: true),
        closeTo(1390 / 1800, _tolerance),
      );
    });

    test('progress after the delay is measured from the delay', () {
      expect(_pulse(_ms(410 + 750), index: 1), closeTo(0.25, _tolerance));
      expect(
        _pulse(_ms(410 + 450), index: 1, selected: true),
        closeTo(0.25, _tolerance),
      );
    });

    test('delays wrap every 3 s: index 8 is shifted by 280 ms', () {
      expect(DsMapMarkerStates.pulseDelay(8), _ms(280));
      expect(_pulse(_ms(280), index: 8), 0);
      expect(_pulse(_ms(280 + 1500), index: 8), closeTo(0.5, _tolerance));
    });

    test('different indexes are out of phase', () {
      expect(_pulse(_ms(1000), index: 0), isNot(_pulse(_ms(1000), index: 1)));
    });

    test('stays within 0 (inclusive) and 1 (exclusive) for a dense sweep', () {
      for (var micros = 0; micros < 40000000; micros += 99991) {
        for (final selected in [false, true]) {
          final value = _pulse(
            Duration(microseconds: micros),
            index: micros % 13,
            selected: selected,
          );
          expect(value, inInclusiveRange(0, 1));
          expect(value, lessThan(1));
        }
      }
    });

    test('elapsed beyond several loops behaves like its remainder', () {
      final elapsed = DsMapMotionClock.period * 5 + _ms(1234);
      expect(
        _pulse(elapsed, index: 4),
        closeTo(_pulse(_ms(1234), index: 4), _tolerance),
      );
    });
  });

  group('dashProgress', () {
    test('is 0 at elapsed 0', () {
      expect(DsMapMotionClock.dashProgress(Duration.zero), 0);
    });

    test('advances linearly over 1.2 s', () {
      expect(
        DsMapMotionClock.dashProgress(_ms(300)),
        closeTo(0.25, _tolerance),
      );
      expect(DsMapMotionClock.dashProgress(_ms(600)), closeTo(0.5, _tolerance));
      expect(
        DsMapMotionClock.dashProgress(_ms(900)),
        closeTo(0.75, _tolerance),
      );
    });

    test('wraps to 0 at exact multiples of 1.2 s', () {
      for (var n = 1; n <= 15; n++) {
        expect(DsMapMotionClock.dashProgress(_dashCycle * n), 0, reason: '$n');
      }
    });

    test('wraps: 1.8 s is half a cycle', () {
      expect(
        DsMapMotionClock.dashProgress(_ms(1800)),
        closeTo(0.5, _tolerance),
      );
    });

    test('is 0 at the loop boundary, with no jump from the previous value', () {
      expect(DsMapMotionClock.dashProgress(DsMapMotionClock.period), 0);
      expect(
        DsMapMotionClock.dashProgress(
          DsMapMotionClock.period - const Duration(microseconds: 1),
        ),
        closeTo(1, 1e-6),
      );
    });

    test('stays within 0 (inclusive) and 1 (exclusive)', () {
      for (var micros = 0; micros < 40000000; micros += 99991) {
        final value = DsMapMotionClock.dashProgress(
          Duration(microseconds: micros),
        );
        expect(value, inInclusiveRange(0, 1));
        expect(value, lessThan(1));
      }
    });

    test('feeds DsMapArc.dashPhase within one dash period', () {
      final phase = DsMapArc.dashPhase(DsMapMotionClock.dashProgress(_ms(900)));
      expect(phase, closeTo(0.75 * DsMapArc.dashPeriod, _tolerance));
    });
  });
}
