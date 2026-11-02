import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_chapter.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/domain/case_timeline_event.dart';
import 'package:true_app/features/cases/presentation/dossier/dossier_body_keys.dart';
import 'package:true_app/features/cases/presentation/dossier/dossier_facts_keys.dart';
import 'package:true_app/features/cases/presentation/dossier/dossier_hero_keys.dart';
import 'package:true_app/features/cases/presentation/dossier/dossier_map_keys.dart';
import 'package:true_app/features/cases/presentation/intake/intake_preview_panel.dart';

import 'test_support/sample_cases.dart';

/// La vista previa pinta el expediente nuevo de la página pública con el
/// borrador, al ancho del panel y sin inventar datos [P2f].

class _Store implements CaseDraftsStore {
  _Store(this._drafts);
  List<CaseDraft> _drafts;

  @override
  Future<List<CaseDraft>> loadDrafts() async => _drafts;

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async => _drafts = drafts;
}

const _complete = CaseDraft(
  draftId: 'draft-a',
  title: 'Caso completo',
  category: CaseCategory.serialKiller,
  year: 1990,
  status: CaseStatus.solved,
  summary: 'Un resumen del caso.',
  country: 'España',
  countryCode: 'ES',
  regionOrCity: 'Badajoz',
  latitude: 38.8,
  longitude: -6.9,
  victim: 'Ana',
  tags: ['etiqueta-uno'],
  chapters: CaseChapters(events: 'Los hechos ocurrieron de noche.'),
  timeline: [
    DraftTimelineEvent(
      date: '1990',
      title: 'Hito inicial',
      kind: CaseTimelineKind.process,
    ),
  ],
);

/// [paneWidth] es el ancho del panel; la ventana es mucho más ancha para
/// probar que el expediente se adapta al panel y no a la ventana.
Future<void> _pump(
  WidgetTester tester,
  CaseDraft draft, {
  double paneWidth = 380,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      caseDraftsStoreProvider.overrideWithValue(_Store([draft])),
      casesRepositoryProvider.overrideWithValue(
        const FakeCasesRepository(sampleCases),
      ),
    ],
  );
  addTearDown(container.dispose);
  await container.read(caseDraftsProvider.future);
  await container.read(casesProvider.future);
  container.read(editingDraftIdProvider.notifier).state = draft.draftId;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: paneWidth,
              height: 700,
              child: const IntakePreviewPanel(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Finder _inPreview(Finder finder) =>
    find.descendant(of: find.byType(IntakePreviewPanel), matching: finder);

Finder _in(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

String _textOf(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

void main() {
  group('borrador vacío', () {
    testWidgets('no fabrica valores: ni año 0, ni «Por confirmar», ni 0.00°', (
      tester,
    ) async {
      await _pump(tester, const CaseDraft(draftId: 'draft-a'));

      expect(_inPreview(find.text('Por confirmar')), findsNothing);
      expect(_inPreview(find.textContaining('Por confirmar')), findsNothing);
      expect(_inPreview(find.textContaining('0.00°')), findsNothing);
      // El único «0» es el recuento real de conexiones (ficha y lateral).
      expect(_inPreview(find.text('0')), findsNWidgets(2));
      expect(_in(DossierFactsKeys.connections, find.text('0')), findsOneWidget);
      // El año fantasma «0» ni existe, y la línea del lugar no lleva «· 0».
      expect(find.byKey(DossierHeroKeys.ghostYear), findsNothing);
      expect(_textOf(tester, DossierHeroKeys.place), isNot(contains('0')));
      expect(_textOf(tester, DossierHeroKeys.place), isNot(contains('--')));
    });

    testWidgets('dice «pendiente» en cabecera, ficha y ubicación', (
      tester,
    ) async {
      await _pump(tester, const CaseDraft(draftId: 'draft-a'));

      expect(
        _textOf(tester, DossierHeroKeys.place),
        '· PENDIENTE · PENDIENTE · PENDIENTE',
      );
      expect(
        _in(DossierHeroKeys.category, find.text('pendiente')),
        findsOneWidget,
      );
      expect(
        _in(DossierHeroKeys.status, find.text('pendiente')),
        findsOneWidget,
      );
      expect(_textOf(tester, DossierHeroKeys.summary), 'Resumen pendiente.');
      for (final key in [
        DossierFactsKeys.year,
        DossierFactsKeys.victims,
        DossierFactsKeys.status,
      ]) {
        expect(
          _in(key, find.text('pendiente')),
          findsOneWidget,
          reason: '$key',
        );
      }
      expect(
        _in(DossierFactsKeys.place, find.text('pendiente\npendiente')),
        findsOneWidget,
      );
      // Ubicación: lugar, año y las dos coordenadas, todo pendiente.
      expect(
        _in(
          DossierMapKeys.locationCard,
          find.text('pendiente · pendiente · pendiente'),
        ),
        findsOneWidget,
      );
      expect(
        _in(DossierMapKeys.locationCard, find.text('pendiente')),
        findsNWidgets(2),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('borrador completo', () {
    testWidgets('muestra las secciones del expediente nuevo', (tester) async {
      await _pump(tester, _complete);

      expect(find.byKey(DossierHeroKeys.background), findsOneWidget);
      expect(_textOf(tester, DossierHeroKeys.title), 'Caso completo');
      expect(
        _textOf(tester, DossierHeroKeys.place),
        '· BADAJOZ · ESPAÑA · 1990',
      );
      expect(_textOf(tester, DossierHeroKeys.summary), 'Un resumen del caso.');
      expect(find.byKey(DossierFactsKeys.strip), findsOneWidget);
      expect(_in(DossierFactsKeys.year, find.text('1990')), findsOneWidget);
      expect(find.byKey(DossierMapKeys.band), findsOneWidget);
      expect(
        _in(DossierMapKeys.locationCard, find.text('38.80° N')),
        findsOneWidget,
      );
      expect(
        _in(DossierMapKeys.locationCard, find.text('6.90° O')),
        findsOneWidget,
      );
      expect(find.byKey(DossierBodyKeys.detailPanel), findsOneWidget);
      expect(find.byKey(DossierBodyKeys.aside), findsOneWidget);
      expect(find.byKey(DossierBodyKeys.footer), findsOneWidget);
      expect(_inPreview(find.text('pendiente')), findsNothing);
      // Capítulo, cronología y etiquetas del borrador.
      expect(find.text('Los hechos ocurrieron de noche.'), findsOneWidget);
      expect(find.text('Hito inicial'), findsOneWidget);
      expect(find.text('etiqueta-uno'), findsOneWidget);
      // Un borrador no tiene casos relacionados.
      expect(find.text('CASOS RELACIONADOS'), findsNothing);
    });

    testWidgets('mantiene el resumen, la lista y el aviso encima', (
      tester,
    ) async {
      await _pump(tester, _complete);

      expect(find.text('PREVISUALIZACIÓN'), findsOneWidget);
      expect(find.byKey(const Key('intake-checklist-title')), findsOneWidget);
      expect(find.textContaining('ENVIAR A REVISIÓN'), findsOneWidget);
    });
  });

  group('ancho del panel', () {
    for (final width in [380.0, 390.0]) {
      testWidgets('a ${width.toInt()} px no desborda ni usa el titulo de '
          'escritorio', (tester) async {
        await _pump(tester, _complete, paneWidth: width);

        expect(tester.takeException(), isNull);
        final title = tester.widget<Text>(find.byKey(DossierHeroKeys.title));
        expect(
          title.style!.fontSize,
          48,
          reason: 'movil, no 128 de escritorio',
        );
        expect(
          tester.getSize(find.byKey(DossierHeroKeys.background)).width,
          width,
        );
        expect(
          tester.getSize(find.byKey(DossierFactsKeys.strip)).width,
          lessThanOrEqualTo(width),
        );
      });
    }

    testWidgets('el borrador vacio tampoco desborda a 380 px', (tester) async {
      await _pump(tester, const CaseDraft(draftId: 'draft-a'));

      expect(tester.takeException(), isNull);
    });
  });

  group('un solo scroll', () {
    testWidgets('el panel se desplaza como un unico scroll natural', (
      tester,
    ) async {
      await _pump(tester, _complete);

      final scrollables = _inPreview(find.byType(Scrollable));
      final outer = tester.state<ScrollableState>(scrollables.first);
      expect(outer.position.maxScrollExtent, greaterThan(0));

      // Con la cabecera del expediente a la vista, un arrastre sobre ella
      // desplaza el panel entero: no hay un scroll interior que lo atrape.
      outer.position.jumpTo(900);
      await tester.pump();
      await tester.drag(
        find.byKey(DossierHeroKeys.background),
        const Offset(0, -200),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(outer.position.pixels, greaterThan(900));
    });
  });

  group('mapa', () {
    testWidgets('enfocar otro caso no ofrece «Abrir expediente»', (
      tester,
    ) async {
      await _pump(tester, _complete);

      // Control de presencia: el mapa de la vista previa sí deja enfocar
      // otro caso del catálogo; lo que no ofrece es navegar a él.
      final scene = tester.widget<DsMapScene>(find.byType(DsMapScene));
      scene.onMarkerTap?.call(sampleCases.first.id);
      await tester.pump();

      expect(
        _in(DossierMapKeys.locationCard, find.text(sampleCases.first.title)),
        findsOneWidget,
      );
      expect(find.byKey(DossierMapKeys.openCase), findsNothing);
      expect(find.text('Abrir expediente'), findsNothing);
    });
  });
}
