import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/draft_validator.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/case_status.dart';

/// Borrador con todos los campos obligatorios cubiertos, incluida la
/// ubicación. Las pruebas parten de aquí y quitan lo que quieren comprobar.
CaseDraft completeDraft({
  String draftId = 'draft-completo',
  List<DraftLink> links = const <DraftLink>[],
  List<DraftPhoto> photos = const <DraftPhoto>[],
}) {
  return CaseDraft(
    draftId: draftId,
    title: 'Caso completo',
    category: CaseCategory.unsolved,
    year: 2001,
    status: CaseStatus.open,
    country: 'España',
    countryCode: 'ES',
    regionOrCity: 'Cuenca',
    latitude: 40.07,
    longitude: -2.13,
    links: links,
    photos: photos,
  );
}

void main() {
  test('rejects a draft missing all required fields', () {
    const draft = CaseDraft(draftId: 'draft-1');

    final result = validateDraft(draft);

    expect(result.isValid, isFalse);
    expect(result.titleError, isNotNull);
    expect(result.categoryError, isNotNull);
    expect(result.yearError, isNotNull);
    expect(result.statusError, isNotNull);
    expect(result.countryError, isNotNull);
    expect(result.countryCodeError, isNotNull);
    expect(result.regionOrCityError, isNotNull);
    expect(result.latitudeError, isNotNull);
    expect(result.longitudeError, isNotNull);
  });

  test('accepts a draft with all required fields filled', () {
    final result = validateDraft(completeDraft());

    expect(result.isValid, isTrue);
    expect(result.titleError, isNull);
    expect(result.categoryError, isNull);
    expect(result.yearError, isNull);
    expect(result.statusError, isNull);
    expect(result.countryError, isNull);
    expect(result.countryCodeError, isNull);
    expect(result.regionOrCityError, isNull);
    expect(result.latitudeError, isNull);
    expect(result.longitudeError, isNull);
  });

  test('rejects a draft that has everything but its location', () {
    // Sin coordenadas el caso no puede pintarse en el mapa, así que no es
    // publicable [Spec: Location].
    const draft = CaseDraft(
      draftId: 'draft-sin-ubicacion',
      title: 'Caso completo',
      category: CaseCategory.unsolved,
      year: 2001,
      status: CaseStatus.open,
    );

    final result = validateDraft(draft);

    expect(result.isValid, isFalse);
    expect(result.titleError, isNull);
    expect(result.countryError, isNotNull);
    expect(result.latitudeError, isNotNull);
    expect(result.longitudeError, isNotNull);
  });

  test('rejects blank location text fields', () {
    final result = validateDraft(
      completeDraft().copyWith(
        country: '   ',
        regionOrCity: '',
      ),
    );

    expect(result.isValid, isFalse);
    expect(result.countryError, isNotNull);
    expect(result.regionOrCityError, isNotNull);
  });

  test('requires a two-letter country code', () {
    expect(validateCountryCode('ES'), isNull);
    // Se acepta en minúsculas: el exportador lo normaliza.
    expect(validateCountryCode('es'), isNull);
    expect(validateCountryCode('ESP'), isNotNull);
    expect(validateCountryCode('E'), isNotNull);
    expect(validateCountryCode('E5'), isNotNull);
    expect(validateCountryCode(null), isNotNull);
  });

  test('rejects coordinates outside their valid range', () {
    expect(validateLatitude(40.07), isNull);
    expect(validateLatitude(-90), isNull);
    expect(validateLatitude(90), isNull);
    expect(validateLatitude(90.1), isNotNull);
    expect(validateLatitude(-90.1), isNotNull);
    expect(validateLatitude(null), isNotNull);

    expect(validateLongitude(-2.13), isNull);
    expect(validateLongitude(-180), isNull);
    expect(validateLongitude(180), isNull);
    expect(validateLongitude(180.1), isNotNull);
    expect(validateLongitude(-180.1), isNotNull);
    expect(validateLongitude(null), isNotNull);
  });

  test('flags a malformed link without blocking the rest of the draft', () {
    final draft = completeDraft(
      links: const [
        DraftLink(
          title: 'Nota',
          url: 'no es una url',
          kind: DraftLinkKind.document,
        ),
      ],
    );

    final result = validateDraft(draft);

    expect(result.isValid, isTrue);
    expect(result.hasLinkWarnings, isTrue);
    expect(result.linkErrors.first, isNotNull);
  });

  test('does not flag a well-formed link', () {
    final draft = completeDraft(
      links: const [
        DraftLink(
          title: 'Fuente',
          url: 'https://example.com',
          kind: DraftLinkKind.document,
        ),
      ],
    );

    final result = validateDraft(draft);

    expect(result.hasLinkWarnings, isFalse);
    expect(result.linkErrors.first, isNull);
  });

  test('flags a malformed photo URL without blocking the draft', () {
    final draft = completeDraft(
      photos: const [
        DraftPhoto(url: 'no es una url', caption: 'Fachada'),
        DraftPhoto(url: 'https://example.com/foto.jpg'),
      ],
    );

    final result = validateDraft(draft);

    // Igual que los enlaces: se avisa, pero no invalida el borrador.
    expect(result.isValid, isTrue);
    expect(result.hasPhotoWarnings, isTrue);
    expect(result.photoErrors.first, isNotNull);
    expect(result.photoErrors.last, isNull);
  });

  test('does not flag a draft without photos', () {
    final result = validateDraft(completeDraft());

    expect(result.hasPhotoWarnings, isFalse);
    expect(result.photoErrors, isEmpty);
  });
}
