import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_search_service.dart';
import 'package:true_app/features/cases/domain/case_category.dart';

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

  test('orders featured and relevant cases by rank', () {
    final featured = service.topFeatured(sampleCases);
    final relevant = service.topRelevant(sampleCases);

    expect(featured.map((crimeCase) => crimeCase.id), [
      'zodiac-killer',
      'meredith-kercher',
      'madeleine-mccann',
      'black-dahlia',
    ]);
    expect(relevant.map((crimeCase) => crimeCase.id), [
      'madeleine-mccann',
      'zodiac-killer',
      'black-dahlia',
      'meredith-kercher',
    ]);
  });

  test('counts cases by category', () {
    final counts = service.countByCategory(sampleCases);

    expect(counts[CaseCategory.isolatedMurder], 1);
    expect(counts[CaseCategory.serialKiller], 1);
    expect(counts[CaseCategory.kidnapping], 1);
    expect(counts[CaseCategory.unsolved], 1);
  });
}
