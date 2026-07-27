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
