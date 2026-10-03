import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';
import 'package:true_app/features/cases/domain/case_connection.dart';
import 'package:true_app/features/cases/presentation/design/case_connection_design.dart';

void main() {
  const ab = CaseConnection(aId: 'a', bId: 'b', relation: 'Misma época');
  const cA = CaseConnection(aId: 'c', bId: 'a', relation: 'Mismo país');
  const de = CaseConnection(aId: 'd', bId: 'e', relation: 'Mismo patrón');

  group('CaseConnection.toMapConnection', () {
    test('maps aId/bId/relation to from/to/label', () {
      expect(
        ab.toMapConnection(),
        const DsMapConnection(fromId: 'a', toId: 'b', label: 'Misma época'),
      );
    });
  });

  group('connectionsForCase', () {
    test('returns only pairs touching the case, preserving order', () {
      expect(connectionsForCase('a', const [ab, de, cA]), const [
        DsMapConnection(fromId: 'a', toId: 'b', label: 'Misma época'),
        DsMapConnection(fromId: 'c', toId: 'a', label: 'Mismo país'),
      ]);
    });

    test('returns empty when no pair touches the case', () {
      expect(connectionsForCase('z', const [ab, cA, de]), isEmpty);
    });

    test('returns empty for empty input', () {
      expect(connectionsForCase('a', const []), isEmpty);
    });
  });

  group('relatedIdsOf', () {
    test('collects the other end in both directions', () {
      expect(relatedIdsOf('a', const [ab, cA, de]), {'b', 'c'});
    });

    test('excludes the case itself and unrelated ids', () {
      final ids = relatedIdsOf('a', const [ab, cA, de]);
      expect(ids, isNot(contains('a')));
      expect(ids, isNot(contains('d')));
    });

    test('deduplicates repeated neighbours', () {
      const dup = CaseConnection(aId: 'b', bId: 'a', relation: 'Otra');
      expect(relatedIdsOf('a', const [ab, dup]), {'b'});
    });

    test('returns empty for empty input or no match', () {
      expect(relatedIdsOf('a', const []), isEmpty);
      expect(relatedIdsOf('z', const [ab, cA, de]), isEmpty);
    });
  });
}
