import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_search_service.dart';

import 'test_support/sample_cases.dart';

void main() {
  const service = CaseSearchService();

  test('searches by title, country and tag', () {
    expect(service.search(sampleCases, 'zodiac').first.id, 'zodiac-killer');
    expect(service.search(sampleCases, 'spain').first.id, 'alcasser-girls');
    expect(
      service.search(sampleCases, 'cult').first.id,
      'manson-family-murders',
    );
  });

  test('orders featured and relevant cases by rank', () {
    final featured = service.topFeatured(sampleCases);
    final relevant = service.topRelevant(sampleCases);

    expect(featured.map((crimeCase) => crimeCase.id), [
      'zodiac-killer',
      'alcasser-girls',
      'manson-family-murders',
    ]);
    expect(relevant.map((crimeCase) => crimeCase.id), [
      'alcasser-girls',
      'zodiac-killer',
      'manson-family-murders',
    ]);
  });
}
