import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';

import 'test_support/sample_cases.dart';

TrueCrimeCase _case(
  String id, {
  int? featuredRank,
  int? relevanceRank,
  int year = 2000,
  String? title,
  CaseStatus status = CaseStatus.open,
}) {
  return TrueCrimeCase(
    id: id,
    slug: id,
    title: title ?? id,
    category: CaseCategory.unsolved,
    country: 'España',
    countryCode: 'ES',
    regionOrCity: 'Madrid',
    year: year,
    latitude: 40,
    longitude: -3,
    summary: 'Resumen.',
    tags: const <String>[],
    featuredRank: featuredRank,
    relevanceRank: relevanceRank,
    sources: const [],
    status: status,
  );
}

Future<ProviderContainer> _loaded(List<TrueCrimeCase> cases) async {
  final container = ProviderContainer(
    overrides: [
      casesRepositoryProvider.overrideWithValue(FakeCasesRepository(cases)),
    ],
  );
  addTearDown(container.dispose);
  await container.read(casesProvider.future);
  return container;
}

List<String> _ids(List<TrueCrimeCase> cases) => [for (final c in cases) c.id];

ProviderContainer _pending() {
  final completer = Completer<List<TrueCrimeCase>>();
  final container = ProviderContainer(
    overrides: [casesProvider.overrideWith((ref) => completer.future)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('featuredCasesProvider', () {
    test('is empty with no featured cases', () async {
      final container = await _loaded([_case('a'), _case('b')]);
      expect(container.read(featuredCasesProvider), isEmpty);
    });

    test('returns a single featured case', () async {
      final container = await _loaded([
        _case('a'),
        _case('b', featuredRank: 1),
      ]);
      expect(_ids(container.read(featuredCasesProvider)), ['b']);
    });

    test('returns five featured cases sorted by featuredRank', () async {
      final container = await _loaded([
        _case('e', featuredRank: 5),
        _case('c', featuredRank: 3),
        _case('a', featuredRank: 1),
        _case('d', featuredRank: 4),
        _case('b', featuredRank: 2),
      ]);
      expect(_ids(container.read(featuredCasesProvider)), [
        'a',
        'b',
        'c',
        'd',
        'e',
      ]);
    });

    test(
      'caps at five keeping the lowest ranks when there are seven',
      () async {
        final container = await _loaded([
          for (var rank = 7; rank >= 1; rank--)
            _case('c$rank', featuredRank: rank),
        ]);
        expect(_ids(container.read(featuredCasesProvider)), [
          'c1',
          'c2',
          'c3',
          'c4',
          'c5',
        ]);
      },
    );

    test('breaks rank ties by relevanceRank then title', () async {
      final container = await _loaded([
        _case('t-b', featuredRank: 1, relevanceRank: 2, title: 'B'),
        _case('t-a', featuredRank: 1, relevanceRank: 2, title: 'A'),
        _case('t-r1', featuredRank: 1, relevanceRank: 1, title: 'Z'),
        _case('t-first', featuredRank: 0, relevanceRank: 9, title: 'Z'),
      ]);
      expect(_ids(container.read(featuredCasesProvider)), [
        't-first',
        't-r1',
        't-a',
        't-b',
      ]);
    });

    test('ignores cases with null featuredRank', () async {
      final container = await _loaded([
        _case('x', relevanceRank: 1),
        _case('y', featuredRank: 2),
        _case('z'),
      ]);
      expect(_ids(container.read(featuredCasesProvider)), ['y']);
    });

    test('is empty while loading', () {
      expect(_pending().read(featuredCasesProvider), isEmpty);
    });

    test('is empty on error', () async {
      final container = ProviderContainer(
        overrides: [
          casesProvider.overrideWith((ref) => throw StateError('boom')),
        ],
      );
      addTearDown(container.dispose);
      await expectLater(
        container.read(casesProvider.future),
        throwsA(isA<StateError>()),
      );
      expect(container.read(featuredCasesProvider), isEmpty);
    });

    test('keeps featuredCaseProvider returning the lowest rank', () async {
      final container = await _loaded([
        _case('b', featuredRank: 2),
        _case('a', featuredRank: 1),
      ]);
      expect(container.read(featuredCaseProvider)?.id, 'a');
    });
  });

  group('unsolvedCasesProvider', () {
    test('includes only open cases', () async {
      final container = await _loaded([
        _case('open', status: CaseStatus.open, relevanceRank: 1),
        _case('solved', status: CaseStatus.solved, relevanceRank: 1),
        _case('wip', status: CaseStatus.inProgress, relevanceRank: 1),
      ]);
      expect(_ids(container.read(unsolvedCasesProvider)), ['open']);
    });

    test('orders by relevanceRank, then year descending, then title', () async {
      final container = await _loaded([
        _case('no-rank', year: 2020, title: 'A'),
        _case('r2-old', relevanceRank: 2, year: 1990, title: 'A'),
        _case('r2-new-b', relevanceRank: 2, year: 2010, title: 'B'),
        _case('r2-new-a', relevanceRank: 2, year: 2010, title: 'A'),
        _case('r1', relevanceRank: 1, year: 1950, title: 'Z'),
      ]);
      expect(_ids(container.read(unsolvedCasesProvider)), [
        'r1',
        'r2-new-a',
        'r2-new-b',
        'r2-old',
        'no-rank',
      ]);
    });

    test('caps at twelve', () async {
      final container = await _loaded([
        for (var i = 1; i <= 15; i++) _case('c$i', relevanceRank: i),
      ]);
      final ids = _ids(container.read(unsolvedCasesProvider));
      expect(ids, hasLength(12));
      expect(ids.first, 'c1');
      expect(ids.last, 'c12');
    });

    test('is empty while loading', () {
      expect(_pending().read(unsolvedCasesProvider), isEmpty);
    });
  });
}
