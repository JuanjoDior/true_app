import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/presentation/intake/intake_preview_panel.dart';

import 'test_support/sample_cases.dart';

class _FakeCaseDraftsStore implements CaseDraftsStore {
  List<CaseDraft> saved = const <CaseDraft>[];

  @override
  Future<List<CaseDraft>> loadDrafts() async => saved;

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async {
    saved = drafts;
  }
}

Future<ProviderContainer> _pumpPreview(
  WidgetTester tester,
  List<DraftLink> links, {
  List<DraftPhoto> photos = const <DraftPhoto>[],
}) async {
  final store = _FakeCaseDraftsStore();
  final container = ProviderContainer(
    overrides: [
      caseDraftsStoreProvider.overrideWithValue(store),
      casesRepositoryProvider.overrideWithValue(const FakeCasesRepository([])),
    ],
  );
  addTearDown(container.dispose);

  await container.read(caseDraftsProvider.future);
  final draftId = await container
      .read(caseDraftsProvider.notifier)
      .createDraft();
  await container
      .read(caseDraftsProvider.notifier)
      .updateDraft(
        CaseDraft(
          draftId: draftId,
          title: 'Caso agrupado',
          links: links,
          photos: photos,
        ),
      );
  container.read(editingDraftIdProvider.notifier).state = draftId;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 700, child: IntakePreviewPanel()),
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

/// Los textos que la previsualización pinta, en orden de árbol.
///
/// Sustituye a las claves `intake-preview-link-group-*` que llevaba el widget
/// borrado en la Unit 4c. Ya no hay un renderizador propio al que ponerle
/// claves: los enlaces los pinta el expediente compartido, así que lo que se
/// afirma es el orden en que aparecen encabezado y enlaces, que es
/// exactamente el agrupamiento visible para quien lo lee.
List<String> _visibleTexts(WidgetTester tester, Set<String> wanted) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .where(wanted.contains)
      .toList(growable: false);
}

void main() {
  testWidgets('groups preview links by their typed kind', (tester) async {
    await _pumpPreview(tester, const [
      DraftLink(
        title: 'Serial',
        url: 'https://example.com/serial',
        kind: DraftLinkKind.podcast,
      ),
      DraftLink(
        title: 'Crimen en el bosque',
        url: 'https://example.com/crimen',
        kind: DraftLinkKind.podcast,
      ),
      DraftLink(
        title: 'Documental',
        url: 'https://example.com/doc',
        kind: DraftLinkKind.video,
      ),
    ]);

    // Los dos podcasts quedan entre su encabezado y el siguiente; el vídeo,
    // detrás del suyo. Eso ES el agrupamiento.
    expect(
      _visibleTexts(tester, {
        'PODCAST',
        'Serial',
        'Crimen en el bosque',
        'VÍDEO',
        'Documental',
      }),
      orderedEquals(const [
        'PODCAST',
        'Serial',
        'Crimen en el bosque',
        'VÍDEO',
        'Documental',
      ]),
    );
  });

  testWidgets(
    'groups unset and "other" links under a single unclassified group',
    (tester) async {
      await _pumpPreview(tester, const [
        DraftLink(title: 'Sin tipo', url: 'https://example.com/a'),
        DraftLink(
          title: 'Marcado como otro',
          url: 'https://example.com/b',
          kind: DraftLinkKind.other,
        ),
      ]);

      // Un solo encabezado para los dos, y dice "Sin clasificar" y no "Otro".
      expect(
        _visibleTexts(tester, {
          'SIN CLASIFICAR',
          'OTRO',
          'Sin tipo',
          'Marcado como otro',
        }),
        orderedEquals(const [
          'SIN CLASIFICAR',
          'Sin tipo',
          'Marcado como otro',
        ]),
      );
    },
  );

  testWidgets('a single link still gets its own group heading', (
    tester,
  ) async {
    await _pumpPreview(tester, const [
      DraftLink(
        title: 'Serial',
        url: 'https://example.com/serial',
        kind: DraftLinkKind.podcast,
      ),
    ]);

    // Gemelo de presencia del test de abajo: sin él, "no se pinta ningún
    // grupo nunca" pasaría el caso vacío sin probar nada.
    expect(
      _visibleTexts(tester, {'PODCAST'}),
      orderedEquals(const ['PODCAST']),
    );
  });

  testWidgets('renders nothing but the dossier when the draft has no links', (
    tester,
  ) async {
    await _pumpPreview(tester, const []);

    expect(
      _visibleTexts(tester, {
        for (final kind in DraftLinkKind.values) kind.label.toUpperCase(),
        'SIN CLASIFICAR',
      }),
      isEmpty,
    );
  });

  testWidgets('the preview shows no map chrome', (tester) async {
    await _pumpPreview(tester, const []);

    // La cadena completa: IntakePreviewPanel → CaseDossierPanel(preview) →
    // CaseDossierContent. Si algún eslabón perdiera el modo, volvería a
    // aparecer el cromo del mapa dentro del formulario de intake.
    expect(find.text('VOLVER AL MAPA'), findsNothing);
  });

  testWidgets('renders each draft photo with its caption', (tester) async {
    await _pumpPreview(
      tester,
      const [],
      photos: const [
        DraftPhoto(
          url: 'https://example.com/foto.jpg',
          caption: 'Fachada del edificio',
        ),
        DraftPhoto(url: 'https://example.com/plano.png'),
      ],
    );

    // Las fotos se pintan con el mismo widget que un caso publicado, no con
    // una tira propia de la previsualización [Spec: Expediente Preview Parity].
    expect(find.byKey(const Key('case-photos')), findsOneWidget);
    expect(find.byKey(const Key('case-photo-0')), findsOneWidget);
    expect(find.byKey(const Key('case-photo-1')), findsOneWidget);
    expect(find.text('Fachada del edificio'), findsOneWidget);
  });

  testWidgets('omits the photo section when the draft has no photos', (
    tester,
  ) async {
    await _pumpPreview(tester, const []);

    expect(find.byKey(const Key('case-photos')), findsNothing);
  });

  testWidgets('skips photos without a URL instead of failing', (tester) async {
    await _pumpPreview(
      tester,
      const [],
      photos: const [DraftPhoto(caption: 'Pie sin imagen')],
    );

    expect(find.byKey(const Key('case-photos')), findsNothing);
  });
}
