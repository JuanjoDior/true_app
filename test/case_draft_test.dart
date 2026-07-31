import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/case_status.dart';

void main() {
  test('round-trips a fully filled draft through JSON', () {
    const draft = CaseDraft(
      draftId: 'draft-1',
      title: 'Caso de prueba',
      category: CaseCategory.unsolved,
      year: 1994,
      status: CaseStatus.open,
      summary: 'Resumen del caso',
      links: [
        DraftLink(
          title: 'Wikipedia',
          url: 'https://example.com',
          kind: DraftLinkKind.publication,
        ),
      ],
    );

    final json = draft.toJson();
    final restored = CaseDraft.fromJson(json);

    expect(restored.draftId, 'draft-1');
    expect(restored.title, 'Caso de prueba');
    expect(restored.category, CaseCategory.unsolved);
    expect(restored.year, 1994);
    expect(restored.status, CaseStatus.open);
    expect(restored.summary, 'Resumen del caso');
    expect(restored.links, hasLength(1));
    expect(restored.links.first.title, 'Wikipedia');
    expect(restored.links.first.url, 'https://example.com');
    expect(restored.links.first.kind, DraftLinkKind.publication);
  });

  test('maps every known link kind string to its typed value', () {
    expect(DraftLinkKind.fromJson('podcast'), DraftLinkKind.podcast);
    expect(DraftLinkKind.fromJson('video'), DraftLinkKind.video);
    expect(DraftLinkKind.fromJson('document'), DraftLinkKind.document);
    expect(DraftLinkKind.fromJson('publication'), DraftLinkKind.publication);
    expect(DraftLinkKind.fromJson('other'), DraftLinkKind.other);
  });

  test('falls back to "other" for unknown or legacy link kind strings', () {
    // Borradores de la fase 2 guardaban `kind` como texto libre.
    expect(DraftLinkKind.fromJson('investigation'), DraftLinkKind.other);
    expect(DraftLinkKind.fromJson('article'), DraftLinkKind.other);
    expect(DraftLinkKind.fromJson(''), DraftLinkKind.other);
  });

  test('loads a legacy draft whose link kind is a free-form string', () {
    final restored = CaseDraft.fromJson({
      'draftId': 'draft-legacy',
      'links': [
        {'title': 'Fuente', 'url': 'https://example.com', 'kind': 'investigation'},
        {'title': 'Serial', 'url': 'https://example.com/serial', 'kind': 'podcast'},
      ],
    });

    expect(restored.links, hasLength(2));
    expect(restored.links.first.kind, DraftLinkKind.other);
    // `podcast` ya existía en la fase 2 y debe conservar su significado.
    expect(restored.links.last.kind, DraftLinkKind.podcast);
  });

  test('defaults a link kind to "other" when the key is absent', () {
    final restored = CaseDraft.fromJson({
      'draftId': 'draft-3',
      'links': [
        {'title': 'Sin tipo', 'url': 'https://example.com'},
      ],
    });

    expect(restored.links.single.kind, DraftLinkKind.other);
  });

  test('round-trips draft photos with their captions', () {
    const draft = CaseDraft(
      draftId: 'draft-photos',
      photos: [
        DraftPhoto(
          url: 'https://example.com/foto.jpg',
          caption: 'Fachada del edificio',
        ),
        DraftPhoto(url: 'https://example.com/plano.png'),
      ],
    );

    final restored = CaseDraft.fromJson(draft.toJson());

    expect(restored.photos, hasLength(2));
    expect(restored.photos.first.url, 'https://example.com/foto.jpg');
    expect(restored.photos.first.caption, 'Fachada del edificio');
    expect(restored.photos.last.url, 'https://example.com/plano.png');
    // El pie de foto es opcional.
    expect(restored.photos.last.caption, isNull);
  });

  test('defaults photos to an empty list when absent from the payload', () {
    final restored = CaseDraft.fromJson({'draftId': 'draft-sin-fotos'});

    expect(restored.photos, isEmpty);
  });

  test('round-trips the location fields of a draft', () {
    const draft = CaseDraft(
      draftId: 'draft-ubicacion',
      country: 'España',
      countryCode: 'ES',
      regionOrCity: 'Cuenca',
      latitude: 40.07,
      longitude: -2.13,
    );

    final restored = CaseDraft.fromJson(draft.toJson());

    expect(restored.country, 'España');
    expect(restored.countryCode, 'ES');
    expect(restored.regionOrCity, 'Cuenca');
    expect(restored.latitude, 40.07);
    expect(restored.longitude, -2.13);
  });

  test('loads a draft saved before the location fields existed', () {
    // Los borradores de las fases 1-3 no guardaban ubicación: deben seguir
    // abriéndose, sólo que incompletos.
    final restored = CaseDraft.fromJson({
      'draftId': 'draft-sin-ubicacion',
      'title': 'Caso antiguo',
    });

    expect(restored.title, 'Caso antiguo');
    expect(restored.country, isNull);
    expect(restored.countryCode, isNull);
    expect(restored.regionOrCity, isNull);
    expect(restored.latitude, isNull);
    expect(restored.longitude, isNull);
  });

  test('reads integer coordinates stored as whole numbers', () {
    // `jsonDecode` devuelve `int` para 40 y `double` para 40.07.
    final restored = CaseDraft.fromJson({
      'draftId': 'draft-coords-enteras',
      'latitude': 40,
      'longitude': -2,
    });

    expect(restored.latitude, 40.0);
    expect(restored.longitude, -2.0);
  });

  test('applies tolerant defaults when fields are missing from the payload', () {
    final restored = CaseDraft.fromJson({'draftId': 'draft-2'});

    expect(restored.draftId, 'draft-2');
    expect(restored.title, isNull);
    expect(restored.category, isNull);
    expect(restored.year, isNull);
    expect(restored.status, isNull);
    expect(restored.summary, isNull);
    expect(restored.links, isEmpty);
  });
}
