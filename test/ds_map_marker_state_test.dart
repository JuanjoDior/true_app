import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

DsMapMarkerVisual _resolve({
  bool selected = false,
  bool related = false,
  bool matchesFilter = true,
  bool shownByYear = true,
  bool hasSelection = false,
  bool mobile = false,
}) => DsMapMarkerStates.resolve(
  selected: selected,
  related: related,
  matchesFilter: matchesFilter,
  shownByYear: shownByYear,
  hasSelection: hasSelection,
  mobile: mobile,
);

void main() {
  group('DsMapMarkerStates.resolve', () {
    test('normal marker without selection', () {
      final v = _resolve();
      expect(v.diameter, 12);
      expect(v.glowRadius, 12);
      expect(v.opacity, 1);
      expect(v.showLabel, isFalse);
      expect(v.goldBorder, isFalse);
      expect(v.pulsing, isTrue);
      expect(v.pulseDuration, DsMotion.pulseIdle);
      expect(v.interactive, isTrue);
    });

    test('normal marker on mobile is 14', () {
      expect(_resolve(mobile: true).diameter, 14);
    });

    test('selected marker', () {
      final v = _resolve(selected: true, hasSelection: true);
      expect(v.diameter, 18);
      expect(v.glowRadius, 26);
      expect(v.opacity, 1);
      expect(v.showLabel, isFalse);
      expect(v.goldBorder, isFalse);
      expect(v.pulsing, isTrue);
      expect(v.pulseDuration, DsMotion.pulseSelected);
      expect(v.interactive, isTrue);
    });

    test('selected marker on mobile is 20', () {
      final v = _resolve(selected: true, hasSelection: true, mobile: true);
      expect(v.diameter, 20);
      expect(v.glowRadius, 26);
    });

    test('related marker has gold border and label', () {
      final v = _resolve(related: true, hasSelection: true);
      expect(v.diameter, 12);
      expect(v.glowRadius, 12);
      expect(v.opacity, 1);
      expect(v.showLabel, isTrue);
      expect(v.goldBorder, isTrue);
      expect(v.pulseDuration, DsMotion.pulseIdle);
      expect(v.interactive, isTrue);
    });

    test('related marker on mobile is 14', () {
      final v = _resolve(related: true, hasSelection: true, mobile: true);
      expect(v.diameter, 14);
      expect(v.goldBorder, isTrue);
    });

    test('other marker with a selection is dimmed to 0.4', () {
      final v = _resolve(hasSelection: true);
      expect(v.opacity, 0.4);
      expect(v.diameter, 12);
      expect(v.showLabel, isFalse);
      expect(v.goldBorder, isFalse);
      expect(v.interactive, isTrue);
    });

    test('other marker without a selection is fully visible', () {
      expect(_resolve().opacity, 1);
    });

    test('filtered-out marker is 0.12 with or without selection', () {
      expect(_resolve(matchesFilter: false).opacity, 0.12);
      expect(_resolve(matchesFilter: false, hasSelection: true).opacity, 0.12);
      expect(
        _resolve(
          matchesFilter: false,
          selected: true,
          hasSelection: true,
        ).opacity,
        0.12,
      );
    });

    test('marker later than the timeline year is hidden and inert', () {
      final v = _resolve(shownByYear: false);
      expect(v.opacity, 0);
      expect(v.interactive, isFalse);
      expect(v.pulsing, isFalse);
    });

    test('hidden by year wins over every other state', () {
      final v = _resolve(
        shownByYear: false,
        selected: true,
        related: true,
        hasSelection: true,
        matchesFilter: false,
      );
      expect(v.opacity, 0);
      expect(v.interactive, isFalse);
      expect(v.pulsing, isFalse);
    });

    test('mobile only changes the diameter', () {
      for (final selected in [false, true]) {
        for (final related in [false, true]) {
          final d = _resolve(selected: selected, related: related);
          final m = _resolve(
            selected: selected,
            related: related,
            mobile: true,
          );
          expect(m.diameter, d.diameter + 2);
          expect(m.opacity, d.opacity);
          expect(m.glowRadius, d.glowRadius);
        }
      }
    });
  });

  group('DsMapMarkerVisual', () {
    test('has value equality', () {
      expect(_resolve(selected: true), _resolve(selected: true));
      expect(
        _resolve(selected: true).hashCode,
        _resolve(selected: true).hashCode,
      );
      expect(_resolve(selected: true), isNot(_resolve()));
    });
  });

  group('pulse', () {
    test('constants', () {
      expect(DsMapMarkerStates.pulseScaleFrom, 0.5);
      expect(DsMapMarkerStates.pulseScaleTo, 2.8);
      expect(DsMapMarkerStates.minTapTarget, 44);
    });

    test('delay is (i * 0.41) mod 3 seconds', () {
      expect(DsMapMarkerStates.pulseDelay(0), Duration.zero);
      expect(
        DsMapMarkerStates.pulseDelay(1),
        const Duration(milliseconds: 410),
      );
      expect(
        DsMapMarkerStates.pulseDelay(7),
        const Duration(milliseconds: 2870),
      );
      expect(
        DsMapMarkerStates.pulseDelay(8),
        const Duration(milliseconds: 280),
      );
    });

    test('delay is always below 3 seconds', () {
      for (var i = 0; i < 200; i++) {
        expect(
          DsMapMarkerStates.pulseDelay(i),
          lessThan(const Duration(seconds: 3)),
        );
      }
    });
  });

  group('counterScale', () {
    test('is the inverse of the camera scale', () {
      expect(DsMapMarkerStates.counterScale(1), 1);
      expect(DsMapMarkerStates.counterScale(2), 0.5);
      expect(DsMapMarkerStates.counterScale(0.25), 4);
    });

    test('rejects non-positive scales', () {
      expect(() => DsMapMarkerStates.counterScale(0), throwsAssertionError);
      expect(() => DsMapMarkerStates.counterScale(-1), throwsAssertionError);
    });
  });

  group('shownByYear', () {
    test('case is visible when year <= timeline value', () {
      expect(
        DsMapMarkerStates.shownByYear(caseYear: 1969, timelineYear: 1969),
        isTrue,
      );
      expect(
        DsMapMarkerStates.shownByYear(caseYear: 1888, timelineYear: 2025),
        isTrue,
      );
    });

    test('case is hidden when it is later than the timeline value', () {
      expect(
        DsMapMarkerStates.shownByYear(caseYear: 1970, timelineYear: 1969),
        isFalse,
      );
    });
  });
}
