import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

void main() {
  group('DsTimelineRange', () {
    test('exposes the 1888-2025 range', () {
      expect(DsTimelineRange.startYear, 1888);
      expect(DsTimelineRange.endYear, 2025);
    });

    test('markPosition maps the bounds to 0 and 1', () {
      expect(DsTimelineRange.markPosition(1888), 0);
      expect(DsTimelineRange.markPosition(2025), 1);
    });

    test('markPosition is linear in between', () {
      expect(DsTimelineRange.markPosition(1957), closeTo(69 / 137, 1e-12));
      expect(DsTimelineRange.markPosition(1957), closeTo(0.5036, 1e-4));
    });

    test('markPosition clamps years outside the range', () {
      expect(DsTimelineRange.markPosition(1800), 0);
      expect(DsTimelineRange.markPosition(2100), 1);
    });
  });
}
