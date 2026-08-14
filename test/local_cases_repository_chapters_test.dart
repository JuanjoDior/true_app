import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/data/local_cases_repository.dart';
import 'package:true_app/features/cases/domain/case_chapter.dart';

/// Frontera de tolerancia del catálogo [spec: case-editorial-chapters,
/// Additive Published-Case Decoding].
///
/// Los capítulos son opcionales y su decodificación perdona entrada a entrada.
/// Un campo core malformado NO está dentro de esa frontera: debe seguir
/// fallando en alto, no desaparecer un caso del catálogo en silencio.
Map<String, dynamic> _case({Object? chapters, Object? year = 1970}) {
  return {
    'id': 'isdal',
    'slug': 'isdal',
    'title': 'La mujer de Isdal',
    'category': 'unsolved',
    'country': 'Noruega',
    'countryCode': 'NO',
    'regionOrCity': 'Bergen',
    'year': year,
    'latitude': 60.39,
    'longitude': 5.32,
    'summary': 'Un cuerpo sin nombre.',
    'tags': <String>[],
    'sources': <Map<String, dynamic>>[],
    'chapters': ?chapters,
  };
}

String _payload(Map<String, dynamic> entry) => jsonEncode([entry]);

void main() {
  group('entradas heredadas', () {
    test('a catalog entry without the member loads', () {
      final cases = LocalCasesRepository.parseCasesJson(_payload(_case()));

      expect(cases.single.chapters.orderedMeaningful, isEmpty);
    });

    test('a catalog entry without the member keeps its core fields', () {
      final cases = LocalCasesRepository.parseCasesJson(_payload(_case()));

      expect(cases.single.title, 'La mujer de Isdal');
    });

    test('the real published catalog still parses', () async {
      // Los 15 casos publicados no tienen capítulos. Si este test se pusiera
      // rojo, la incorporación habría dejado de ser aditiva.
      final payload = await File('assets/data/cases.json').readAsString();

      expect(LocalCasesRepository.parseCasesJson(payload), isNotEmpty);
    });
  });

  group('capítulos opcionales tolerantes', () {
    test('decodes well-formed chapters', () {
      final cases = LocalCasesRepository.parseCasesJson(
        _payload(
          _case(
            chapters: const [
              {'type': 'background', 'content': 'Antes'},
            ],
          ),
        ),
      );

      expect(
        cases.single.chapters.contentFor(CaseChapterType.background),
        'Antes',
      );
    });

    test('keeps valid chapters around a malformed entry', () {
      final cases = LocalCasesRepository.parseCasesJson(
        _payload(
          _case(
            chapters: const [
              {'type': 'background', 'content': 'Antes'},
              {'type': 'events', 'content': 99},
              {'type': 'investigation', 'content': 'Pistas'},
            ],
          ),
        ),
      );

      expect(
        cases.single.chapters.orderedMeaningful.map((c) => c.type),
        orderedEquals(const [
          CaseChapterType.background,
          CaseChapterType.investigation,
        ]),
      );
    });

    test('ignores an unsupported chapter type without losing the case', () {
      final cases = LocalCasesRepository.parseCasesJson(
        _payload(
          _case(
            chapters: const [
              {'type': 'epilogue', 'content': 'No existe'},
            ],
          ),
        ),
      );

      expect(cases.single.chapters.orderedMeaningful, isEmpty);
    });

    test('keeps the first accepted entry when a type repeats', () {
      final cases = LocalCasesRepository.parseCasesJson(
        _payload(
          _case(
            chapters: const [
              {'type': 'background', 'content': 'Primera'},
              {'type': 'background', 'content': 'Segunda'},
            ],
          ),
        ),
      );

      expect(
        cases.single.chapters.contentFor(CaseChapterType.background),
        'Primera',
      );
    });

    test('treats a non-array chapters member as empty', () {
      final cases = LocalCasesRepository.parseCasesJson(
        _payload(_case(chapters: 'capítulos')),
      );

      expect(cases.single.chapters.orderedMeaningful, isEmpty);
    });

    test('a case whose chapters are all malformed still loads', () {
      final cases = LocalCasesRepository.parseCasesJson(
        _payload(
          _case(
            chapters: const [
              {'type': 'nope', 'content': 'x'},
            ],
          ),
        ),
      );

      expect(cases.single.title, 'La mujer de Isdal');
    });
  });

  group('catálogo mixto', () {
    // El catálogo real va a convivir así durante mucho tiempo: los 15 casos
    // actuales sin capítulos y los nuevos con ellos.
    String mixedPayload() => jsonEncode([
      _case(),
      {
        ..._case(),
        'id': 'somerton',
        'slug': 'somerton',
        'chapters': const [
          {'type': 'background', 'content': 'Antes'},
        ],
      },
    ]);

    test('loads both the legacy and the chapter-bearing case', () {
      expect(LocalCasesRepository.parseCasesJson(mixedPayload()), hasLength(2));
    });

    test('leaves the legacy case without chapters', () {
      final cases = LocalCasesRepository.parseCasesJson(mixedPayload());

      expect(cases.first.chapters.orderedMeaningful, isEmpty);
    });

    test('gives the new case its chapters', () {
      final cases = LocalCasesRepository.parseCasesJson(mixedPayload());

      expect(
        cases.last.chapters.contentFor(CaseChapterType.background),
        'Antes',
      );
    });
  });

  group('la frontera: un campo core malformado no es tolerable', () {
    test('a malformed core field raises instead of dropping the case', () {
      expect(
        () => LocalCasesRepository.parseCasesJson(
          _payload(_case(year: 'mil novecientos setenta')),
        ),
        throwsA(isA<TypeError>()),
      );
    });

    test('a malformed core field is not rescued by valid chapters', () {
      expect(
        () => LocalCasesRepository.parseCasesJson(
          _payload(
            _case(
              year: 'mil novecientos setenta',
              chapters: const [
                {'type': 'background', 'content': 'Antes'},
              ],
            ),
          ),
        ),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
