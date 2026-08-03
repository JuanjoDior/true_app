import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_search_service.dart';

import 'test_support/sample_cases.dart';

void main() {
  const service = CaseSearchService();

  test('searches by title, country, tag and category label', () {
    expect(service.search(sampleCases, 'zodiac').first.id, 'zodiac-killer');
    expect(service.search(sampleCases, 'italy').first.id, 'meredith-kercher');
    expect(service.search(sampleCases, 'cold case').first.id, 'black-dahlia');
    expect(
      service.search(sampleCases, 'secuestros').first.id,
      'madeleine-mccann',
    );
  });

  test('orders by relevance rank when there is no query', () {
    // Sin búsqueda, el archivo se ordena por relevancia editorial.
    final ordered = service.search(sampleCases, '');

    expect(ordered.map((crimeCase) => crimeCase.id), [
      'madeleine-mccann',
      'zodiac-killer',
      'black-dahlia',
      'meredith-kercher',
    ]);
  });
}
