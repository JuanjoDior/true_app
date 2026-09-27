import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';

/// Carga única del catálogo en Supabase (CRP-02).
///
/// La migración lleva el catálogo incrustado entre marcas `$cases$`. Desde que
/// se aplica, Supabase es la única fuente de los casos publicados, así que lo
/// que se cargue tiene que poder leerlo la app entrada a entrada.
const _migrationPath = 'supabase/migrations/20260927110000_seed_cases.sql';
const _marker = r'$cases$';

List<dynamic> _seedEntries() {
  final sql = File(_migrationPath).readAsStringSync();
  final start = sql.indexOf(_marker);
  final end = sql.indexOf(_marker, start + _marker.length);
  expect(start, isNonNegative, reason: 'falta la marca de apertura');
  expect(end, greaterThan(start), reason: 'falta la marca de cierre');
  return jsonDecode(sql.substring(start + _marker.length, end))
      as List<dynamic>;
}

void main() {
  // Mientras existía assets/data/cases.json, un test probaba que la carga era
  // idéntica al fichero. Tras verificarlo también contra la API real, el
  // fichero se retiró; queda fijado el orden publicado.
  test('the seed keeps the published order', () {
    expect(
      [for (final entry in _seedEntries()) (entry as Map)['slug']],
      [
        'zodiac',
        'blackdahlia',
        'jonbenet',
        'tylenol',
        'lizzie',
        'btk',
        'goldenstate',
        'mccann',
        'ripper',
        'isdal',
        'hinterkaifeck',
        'kercher',
        'dyatlov',
        'somerton',
        'caso-asunta',
        'camarena',
      ],
    );
  });

  test('every seeded entry parses as a published case', () {
    final cases = [
      for (final entry in _seedEntries())
        TrueCrimeCase.fromJson(entry as Map<String, dynamic>),
    ];

    expect(cases, hasLength(16));
    expect(cases.map((c) => c.slug).toSet(), hasLength(16));
    expect(cases.last.slug, 'camarena');
  });
}
