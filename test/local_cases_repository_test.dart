import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/data/local_cases_repository.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this.payload);

  final String payload;

  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(utf8.encode(payload));
    return ByteData.view(bytes.buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => payload;
}

void main() {
  test('parses cases from bundled json', () async {
    const payload = '''
    [
      {
        "id": "sample",
        "slug": "sample",
        "title": "Sample Case",
        "country": "Spain",
        "countryCode": "ES",
        "regionOrCity": "Madrid",
        "year": 1994,
        "latitude": 40.4,
        "longitude": -3.7,
        "summary": "Resumen",
        "tags": ["media frenzy"],
        "featuredRank": 1,
        "relevanceRank": 2,
        "sources": [
          {
            "id": "source-1",
            "title": "Wikipedia",
            "url": "https://example.com",
            "kind": "investigation"
          }
        ]
      }
    ]
    ''';

    final repository = LocalCasesRepository(bundle: _FakeAssetBundle(payload));
    final cases = await repository.getCases();

    expect(cases, hasLength(1));
    expect(cases.first.title, 'Sample Case');
    expect(cases.first.investigationSources, hasLength(1));
  });
}
