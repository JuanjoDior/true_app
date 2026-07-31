import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';

Map<String, dynamic> caseJson({Object? photos}) {
  return {
    'id': 'caso-1',
    'slug': 'caso-1',
    'title': 'Caso con fotos',
    'category': 'unsolved',
    'country': 'España',
    'countryCode': 'ES',
    'regionOrCity': 'Cuenca',
    'year': 1974,
    'latitude': 40.07,
    'longitude': -2.13,
    'summary': 'Resumen.',
    'tags': <String>[],
    'sources': <Map<String, dynamic>>[],
    'photos': ?photos,
  };
}

void main() {
  test('reads the photos of a published case', () {
    final restored = TrueCrimeCase.fromJson(
      caseJson(
        photos: [
          {'url': 'https://example.com/foto.jpg', 'caption': 'Fachada'},
          {'url': 'https://example.com/plano.png'},
        ],
      ),
    );

    expect(restored.photos, hasLength(2));
    expect(restored.photos.first.url, 'https://example.com/foto.jpg');
    expect(restored.photos.first.caption, 'Fachada');
    // El pie es opcional.
    expect(restored.photos.last.caption, isNull);
  });

  test('defaults to no photos when the key is absent', () {
    // Los 14 casos del catálogo actual no tienen fotos.
    final restored = TrueCrimeCase.fromJson(caseJson());

    expect(restored.photos, isEmpty);
  });

  test('drops photo entries without a usable URL', () {
    // Una foto sin URL no se puede pintar; no debe llegar a la vista.
    final restored = TrueCrimeCase.fromJson(
      caseJson(
        photos: [
          {'caption': 'Sin URL'},
          {'url': '   '},
          {'url': 'https://example.com/ok.jpg'},
        ],
      ),
    );

    expect(restored.photos, hasLength(1));
    expect(restored.photos.single.url, 'https://example.com/ok.jpg');
  });

  test('trims the stored URL and caption', () {
    final restored = TrueCrimeCase.fromJson(
      caseJson(
        photos: [
          {'url': '  https://example.com/ok.jpg  ', 'caption': '  Fachada  '},
        ],
      ),
    );

    expect(restored.photos.single.url, 'https://example.com/ok.jpg');
    expect(restored.photos.single.caption, 'Fachada');
  });
}
