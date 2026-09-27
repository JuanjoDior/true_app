import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/data/supabase_cases_repository.dart';
import 'package:true_app/features/cases/domain/case_chapter.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';

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

/// Decodifica un array de casos tal como llega de Supabase: cada caso dentro
/// de la columna `payload` de su fila.
List<TrueCrimeCase> _parse(String casesArray) {
  final entries = jsonDecode(casesArray) as List<dynamic>;
  return SupabaseCasesRepository.parseCaseRows(
    jsonEncode([
      for (final entry in entries) {'payload': entry},
    ]),
  );
}

void main() {
  group('entradas heredadas', () {
    test('a catalog entry without the member loads', () {
      final cases = _parse(_payload(_case()));

      expect(cases.single.chapters.orderedMeaningful, isEmpty);
    });

    test('a catalog entry without the member keeps its core fields', () {
      final cases = _parse(_payload(_case()));

      expect(cases.single.title, 'La mujer de Isdal');
    });

    // El catálogo real (sin capítulos) se prueba entero en
    // seed_cases_migration_test.dart, contra la carga inicial de Supabase.
  });

  group('capítulos opcionales tolerantes', () {
    test('decodes well-formed chapters', () {
      final cases = _parse(
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
      final cases = _parse(
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
      final cases = _parse(
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
      final cases = _parse(
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
      final cases = _parse(_payload(_case(chapters: 'capítulos')));

      expect(cases.single.chapters.orderedMeaningful, isEmpty);
    });

    test('a case whose chapters are all malformed still loads', () {
      final cases = _parse(
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
      expect(_parse(mixedPayload()), hasLength(2));
    });

    test('leaves the legacy case without chapters', () {
      final cases = _parse(mixedPayload());

      expect(cases.first.chapters.orderedMeaningful, isEmpty);
    });

    test('gives the new case its chapters', () {
      final cases = _parse(mixedPayload());

      expect(
        cases.last.chapters.contentFor(CaseChapterType.background),
        'Antes',
      );
    });
  });

  group('la frontera: un campo core malformado no es tolerable', () {
    test('a malformed core field raises instead of dropping the case', () {
      expect(
        () => _parse(_payload(_case(year: 'mil novecientos setenta'))),
        throwsA(isA<TypeError>()),
      );
    });

    test('a malformed core field is not rescued by valid chapters', () {
      expect(
        () => _parse(
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
