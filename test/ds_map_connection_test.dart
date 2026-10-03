import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

void main() {
  group('DsMapConnection', () {
    const base = DsMapConnection(fromId: 'a', toId: 'b', label: 'Same region');

    test('exposes its fields', () {
      expect(base.fromId, 'a');
      expect(base.toId, 'b');
      expect(base.label, 'Same region');
    });

    test('equal fields are equal and share a hash code', () {
      const same = DsMapConnection(
        fromId: 'a',
        toId: 'b',
        label: 'Same region',
      );
      expect(base, same);
      expect(base.hashCode, same.hashCode);
    });

    test('each field takes part in equality', () {
      expect(
        base,
        isNot(
          const DsMapConnection(fromId: 'x', toId: 'b', label: 'Same region'),
        ),
      );
      expect(
        base,
        isNot(
          const DsMapConnection(fromId: 'a', toId: 'x', label: 'Same region'),
        ),
      );
      expect(
        base,
        isNot(const DsMapConnection(fromId: 'a', toId: 'b', label: 'Other')),
      );
    });

    test('direction matters', () {
      expect(
        base,
        isNot(
          const DsMapConnection(fromId: 'b', toId: 'a', label: 'Same region'),
        ),
      );
    });

    test('works as a set element', () {
      const same = DsMapConnection(
        fromId: 'a',
        toId: 'b',
        label: 'Same region',
      );
      expect(
        <DsMapConnection>{}
          ..add(base)
          ..add(same),
        hasLength(1),
      );
    });
  });
}
