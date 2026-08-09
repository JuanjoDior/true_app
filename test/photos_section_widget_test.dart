import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/presentation/intake/sections/photos_section.dart';

class _FakeCaseDraftsStore implements CaseDraftsStore {
  List<CaseDraft> saved = const <CaseDraft>[];

  @override
  Future<List<CaseDraft>> loadDrafts() async => saved;

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async {
    saved = drafts;
  }
}

Future<(ProviderContainer, _FakeCaseDraftsStore)> _pumpSection(
  WidgetTester tester, {
  List<DraftPhoto> photos = const <DraftPhoto>[],
}) async {
  final store = _FakeCaseDraftsStore();
  final container = ProviderContainer(
    overrides: [caseDraftsStoreProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);

  await container.read(caseDraftsProvider.future);
  final draftId = await container.read(caseDraftsProvider.notifier).createDraft();
  await container
      .read(caseDraftsProvider.notifier)
      .updateDraft(CaseDraft(draftId: draftId, photos: photos));
  container.read(editingDraftIdProvider.notifier).state = draftId;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: PhotosSection()),
        ),
      ),
    ),
  );
  await tester.pump();
  return (container, store);
}

void main() {
  testWidgets('adds a photo with its caption and autosaves it', (tester) async {
    final (container, store) = await _pumpSection(tester);

    await tester.tap(find.byKey(const Key('intake-add-photo-button')));
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('intake-field-photo-url-0')),
      'https://example.com/foto.jpg',
    );
    await tester.enterText(
      find.byKey(const Key('intake-field-photo-caption-0')),
      'Fachada del edificio',
    );
    await tester.pump();

    final photo = container.read(editingDraftProvider)!.photos.single;
    expect(photo.url, 'https://example.com/foto.jpg');
    expect(photo.caption, 'Fachada del edificio');
    // El autoguardado persiste la foto en el store.
    expect(store.saved.single.photos.single.url, 'https://example.com/foto.jpg');
  });

  testWidgets('removes a photo from the draft', (tester) async {
    final (container, _) = await _pumpSection(
      tester,
      photos: const [
        DraftPhoto(url: 'https://example.com/a.jpg', caption: 'A'),
        DraftPhoto(url: 'https://example.com/b.jpg', caption: 'B'),
      ],
    );

    await tester.tap(find.byKey(const Key('intake-field-photo-remove-0')));
    await tester.pump();

    final photos = container.read(editingDraftProvider)!.photos;
    expect(photos, hasLength(1));
    expect(photos.single.url, 'https://example.com/b.jpg');
  });

  testWidgets('flags a malformed photo URL without blocking', (tester) async {
    final (container, _) = await _pumpSection(
      tester,
      photos: const [DraftPhoto(url: 'no es una url')],
    );

    expect(find.text('La foto no parece una URL válida'), findsOneWidget);
    // El borrador conserva el valor introducido; el aviso no lo descarta.
    expect(container.read(editingDraftProvider)!.photos.single.url,
        'no es una url');
  });

  testWidgets('does not overflow at the minimum supported width 360x640',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pumpSection(
      tester,
      photos: const [
        DraftPhoto(
          url: 'https://example.com/foto-larga.jpg',
          caption: 'Un pie de foto razonablemente largo',
        ),
      ],
    );

    expect(tester.takeException(), isNull);

    // El "sin desborde" por sí solo NO prueba nada aquí: en la rama `Row` los
    // campos flexibles se encogen (medido: 151px cada uno a 360px de ancho) en
    // vez de desbordar, así que la fila sin apilar también pasaría esa
    // comprobación. El ancho es lo que separa apilado de encogido.
    expect(
      tester.getSize(find.byKey(const Key('intake-field-photo-url-0'))).width,
      360,
      reason: 'Below Breakpoints.formRowStack the row must stack, giving each '
          'field the full width — not merely avoid an overflow.',
    );
  });
}
