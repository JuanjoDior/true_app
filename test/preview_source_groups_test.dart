import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/case_source.dart';
import 'package:true_app/features/cases/presentation/intake/preview_source_groups.dart';

/// La derivación de grupos de la previsualización [diseño §9.3].
///
/// Se prueba como función pura porque las tres reglas que protege son de la
/// derivación, no del pintado: montar un árbol para comprobarlas sólo añadiría
/// formas de que el test falle por motivos ajenos.

void main() {
  group('un enlace sin tipo no desaparece', () {
    test('an untyped link lands in the unclassified group', () {
      final groups = previewSourceGroups(const [
        DraftLink(title: 'Sin tipo', url: 'https://example.com/a'),
      ]);

      expect(groups.single.sources.single.title, 'Sin tipo');
    });

    test('an untyped link and an explicit other share one group', () {
      final groups = previewSourceGroups(const [
        DraftLink(title: 'Sin tipo', url: 'https://example.com/a'),
        DraftLink(
          title: 'Marcado como otro',
          url: 'https://example.com/b',
          kind: DraftLinkKind.other,
        ),
      ]);

      expect(groups.single.sources, hasLength(2));
    });
  });

  group('el rótulo del grupo sin clasificar', () {
    test('the other group is labelled "Sin clasificar", never "Otro"', () {
      final groups = previewSourceGroups(const [
        DraftLink(title: 'Sin tipo', url: 'https://example.com/a'),
      ]);

      // `DraftLinkKind.other.label` es 'Otro'. Presentar como un tipo real algo
      // que nadie ha clasificado sería mentir sobre el estado del borrador.
      expect(groups.single.label, 'Sin clasificar');
    });

    test('a real kind keeps its own label', () {
      final groups = previewSourceGroups(const [
        DraftLink(
          title: 'Serial',
          url: 'https://example.com/a',
          kind: DraftLinkKind.podcast,
        ),
      ]);

      expect(groups.single.label, 'Podcast');
    });
  });

  group('la previsualización no recorta', () {
    test('a padded title survives verbatim', () {
      final groups = previewSourceGroups(const [
        DraftLink(title: '  Con espacios  ', url: 'https://example.com/a'),
      ]);

      // El exportador sí recorta. Son decisiones distintas a propósito, y este
      // test es lo que impide que alguien las unifique sin darse cuenta.
      expect(groups.single.sources.single.title, '  Con espacios  ');
    });

    test('a link without a title falls back to its url', () {
      final groups = previewSourceGroups(const [
        DraftLink(url: 'https://example.com/a'),
      ]);

      expect(groups.single.sources.single.title, 'https://example.com/a');
    });

    test('an empty title also falls back to the url', () {
      final groups = previewSourceGroups(const [
        DraftLink(title: '', url: 'https://example.com/a'),
      ]);

      expect(groups.single.sources.single.title, 'https://example.com/a');
    });
  });

  group('orden y omisión', () {
    test('groups follow the declared enum order, not the authoring order', () {
      final groups = previewSourceGroups(const [
        DraftLink(url: 'https://example.com/a', kind: DraftLinkKind.other),
        DraftLink(url: 'https://example.com/b', kind: DraftLinkKind.podcast),
      ]);

      expect(
        groups.map((group) => group.label),
        orderedEquals(const ['Podcast', 'Sin clasificar']),
      );
    });

    test('a kind with no links produces no group', () {
      final groups = previewSourceGroups(const [
        DraftLink(url: 'https://example.com/b', kind: DraftLinkKind.podcast),
      ]);

      expect(groups, hasLength(1));
    });

    test('no links at all produce no groups', () {
      expect(previewSourceGroups(const []), isEmpty);
    });

    test('a link without a url is skipped', () {
      final groups = previewSourceGroups(const [
        DraftLink(title: 'Sin URL'),
        DraftLink(title: 'Con URL', url: 'https://example.com/a'),
      ]);

      expect(groups.single.sources.single.title, 'Con URL');
    });
  });

  group('tipo de fuente', () {
    test('a podcast link becomes a podcast source', () {
      final groups = previewSourceGroups(const [
        DraftLink(url: 'https://example.com/a', kind: DraftLinkKind.podcast),
      ]);

      expect(groups.single.sources.single.kind, CaseSourceKind.podcast);
    });

    test('any other kind becomes an investigation source', () {
      final groups = previewSourceGroups(const [
        DraftLink(url: 'https://example.com/a', kind: DraftLinkKind.video),
      ]);

      expect(groups.single.sources.single.kind, CaseSourceKind.investigation);
    });
  });
}
