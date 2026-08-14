import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_chapter.dart';
import 'package:true_app/features/cases/domain/case_photo.dart';
import 'package:true_app/features/cases/domain/case_source.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/domain/case_timeline_event.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';
import 'package:true_app/features/home/presentation/widgets/situation/case_dossier_content.dart';
import 'package:true_app/features/home/presentation/widgets/situation/dossier_source_group.dart';

/// El renderizador compartido del expediente [spec: expanded-case-dossier].
///
/// `CaseDossierContent` no depende de Riverpod, así que se monta a pelo: sin
/// contenedor, sin overrides, sin providers. Eso es justamente lo que la Unit
/// 4a-2 compró, y lo que permite que la página ampliada lo reutilice.

const _chapterLabels = {
  'ANTECEDENTES',
  'LOS HECHOS',
  'LA INVESTIGACIÓN',
  'ESTADO ACTUAL',
};

TrueCrimeCase _crimeCase({
  String id = 'caso-faro',
  String title = 'El caso del faro',
  CaseChapters chapters = const CaseChapters(),
  List<CasePhoto> photos = const [],
  List<CaseTimelineEvent> timeline = const [],
  List<CaseSource> sources = const [],
}) {
  return TrueCrimeCase(
    id: id,
    slug: id,
    title: title,
    category: CaseCategory.unsolved,
    country: 'España',
    countryCode: 'ES',
    regionOrCity: 'A Coruña',
    year: 1974,
    latitude: 43.39,
    longitude: -8.41,
    summary: 'Un farero desaparece durante una noche de temporal.',
    tags: const <String>[],
    sources: sources,
    photos: photos,
    timeline: timeline,
    chapters: chapters,
    status: CaseStatus.open,
  );
}

CaseSource _source(String title, String url) => CaseSource(
  id: url,
  title: title,
  url: url,
  kind: CaseSourceKind.investigation,
);

Future<void> _pumpContent(
  WidgetTester tester, {
  TrueCrimeCase? crimeCase,
  List<RelatedCase> relatedCases = const [],
  CaseDossierMode mode = CaseDossierMode.map,
  VoidCallback? onReturnToMap,
  VoidCallback? onCenterMap,
  ValueChanged<TrueCrimeCase>? onOpenRelatedCase,
  List<DossierSourceGroup>? sourceGroups,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CaseDossierContent(
          crimeCase: crimeCase ?? _crimeCase(),
          relatedCases: relatedCases,
          mode: mode,
          onReturnToMap: onReturnToMap,
          onCenterMap: onCenterMap,
          onOpenRelatedCase: onOpenRelatedCase,
          sourceGroups: sourceGroups,
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Las etiquetas de sección presentes, en el orden en que las pinta el árbol.
List<String> _labelsMatching(WidgetTester tester, Set<String> wanted) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .where(wanted.contains)
      .toList(growable: false);
}

void main() {
  group('capítulos: una vez y en orden editorial', () {
    testWidgets('renders the four chapters in the fixed editorial order', (
      tester,
    ) async {
      await _pumpContent(
        tester,
        crimeCase: _crimeCase(
          // Deliberadamente al revés del orden editorial: si el renderizador
          // respetase el orden de autoría, este test lo cazaría.
          chapters: const CaseChapters(
            currentStatus: 'Ahora',
            investigation: 'Pistas',
            events: 'Hechos',
            background: 'Antes',
          ),
        ),
      );

      expect(
        _labelsMatching(tester, _chapterLabels),
        orderedEquals(const [
          'ANTECEDENTES',
          'LOS HECHOS',
          'LA INVESTIGACIÓN',
          'ESTADO ACTUAL',
        ]),
      );
    });

    testWidgets('renders each chapter heading exactly once', (tester) async {
      await _pumpContent(
        tester,
        crimeCase: _crimeCase(
          chapters: const CaseChapters(background: 'Antes'),
        ),
      );

      expect(
        _labelsMatching(tester, _chapterLabels),
        orderedEquals(const ['ANTECEDENTES']),
      );
    });

    testWidgets('renders the content of a chapter, not only its heading', (
      tester,
    ) async {
      await _pumpContent(
        tester,
        crimeCase: _crimeCase(
          chapters: const CaseChapters(background: 'El faro llevaba años'),
        ),
      );

      expect(find.text('El faro llevaba años'), findsOneWidget);
    });

    testWidgets('omits a chapter whose content is only whitespace', (
      tester,
    ) async {
      await _pumpContent(
        tester,
        crimeCase: _crimeCase(
          chapters: const CaseChapters(background: 'Antes', events: '   '),
        ),
      );

      // Con el capítulo bueno al lado: `isEmpty` a secas pasaría igual sin
      // renderizado ninguno de capítulos.
      expect(
        _labelsMatching(tester, _chapterLabels),
        orderedEquals(const ['ANTECEDENTES']),
      );
    });

    testWidgets('a legacy case without chapters renders no chapter heading', (
      tester,
    ) async {
      await _pumpContent(tester, crimeCase: _crimeCase());

      expect(_labelsMatching(tester, _chapterLabels), isEmpty);
    });

    testWidgets('a legacy case without chapters still renders its summary', (
      tester,
    ) async {
      final crimeCase = _crimeCase();
      await _pumpContent(tester, crimeCase: crimeCase);

      expect(find.text(crimeCase.summary), findsOneWidget);
    });
  });

  group('override de fuentes', () {
    testWidgets('with no override it renders the published sources', (
      tester,
    ) async {
      await _pumpContent(
        tester,
        crimeCase: _crimeCase(
          sources: [_source('Crónica del temporal', 'https://elpais.com/a')],
        ),
      );

      expect(find.text('Crónica del temporal'), findsOneWidget);
    });

    testWidgets('an override replaces the published sources entirely', (
      tester,
    ) async {
      await _pumpContent(
        tester,
        crimeCase: _crimeCase(
          sources: [_source('Publicada', 'https://elpais.com/a')],
        ),
        sourceGroups: [
          DossierSourceGroup(
            label: 'Podcast',
            sources: [_source('Del borrador', 'https://ivoox.com/b')],
          ),
        ],
      );

      // La regla que evita pintar dos veces las fuentes en la
      // previsualización: si hay override, las publicadas NO se añaden.
      expect(find.text('Publicada'), findsNothing);
    });

    testWidgets('an override renders its own sources', (tester) async {
      await _pumpContent(
        tester,
        crimeCase: _crimeCase(
          sources: [_source('Publicada', 'https://elpais.com/a')],
        ),
        sourceGroups: [
          DossierSourceGroup(
            label: 'Podcast',
            sources: [_source('Del borrador', 'https://ivoox.com/b')],
          ),
        ],
      );

      expect(find.text('Del borrador', findRichText: true), findsOneWidget);
    });

    testWidgets('an override renders its group label', (tester) async {
      await _pumpContent(
        tester,
        sourceGroups: [
          DossierSourceGroup(
            label: 'Sin clasificar',
            sources: [_source('Un enlace', 'https://ivoox.com/b')],
          ),
        ],
      );

      expect(find.text('SIN CLASIFICAR'), findsOneWidget);
    });

    testWidgets('an EMPTY override list still suppresses published sources', (
      tester,
    ) async {
      await _pumpContent(
        tester,
        crimeCase: _crimeCase(
          sources: [_source('Publicada', 'https://elpais.com/a')],
        ),
        sourceGroups: const [],
      );

      // `[]` no es lo mismo que `null`: el host dice "yo mando las fuentes y
      // no tengo ninguna", no "decide tú".
      expect(find.text('Publicada'), findsNothing);
    });

    testWidgets('a group with no sources is omitted', (tester) async {
      await _pumpContent(
        tester,
        sourceGroups: [
          const DossierSourceGroup(label: 'Vacío', sources: []),
          DossierSourceGroup(
            label: 'Podcast',
            sources: [_source('Un enlace', 'https://ivoox.com/b')],
          ),
        ],
      );

      expect(find.text('VACÍO'), findsNothing);
    });

    testWidgets('groups render in the order they were given', (tester) async {
      await _pumpContent(
        tester,
        sourceGroups: [
          DossierSourceGroup(
            label: 'Podcast',
            sources: [_source('Uno', 'https://ivoox.com/b')],
          ),
          DossierSourceGroup(
            label: 'Sin clasificar',
            sources: [_source('Dos', 'https://example.com/c')],
          ),
        ],
      );

      expect(
        _labelsMatching(tester, {'PODCAST', 'SIN CLASIFICAR'}),
        orderedEquals(const ['PODCAST', 'SIN CLASIFICAR']),
      );
    });
  });

  group('cromo de mapa frente a previsualización', () {
    testWidgets('map mode offers the return-to-map affordance', (tester) async {
      await _pumpContent(tester, onReturnToMap: () {});

      expect(find.text('VOLVER AL MAPA'), findsOneWidget);
    });

    testWidgets('preview mode suppresses the return-to-map affordance', (
      tester,
    ) async {
      await _pumpContent(tester, mode: CaseDossierMode.preview);

      expect(find.text('VOLVER AL MAPA'), findsNothing);
    });

    testWidgets('map mode offers the recenter control', (tester) async {
      await _pumpContent(tester, onCenterMap: () {});

      expect(find.text('Centrar'), findsOneWidget);
    });

    testWidgets('preview mode suppresses the recenter control', (tester) async {
      await _pumpContent(tester, mode: CaseDossierMode.preview);

      expect(find.text('Centrar'), findsNothing);
    });

    testWidgets('preview mode suppresses the follow control', (tester) async {
      await _pumpContent(tester, mode: CaseDossierMode.preview);

      expect(find.text('Seguir el caso'), findsNothing);
    });

    testWidgets('preview mode still renders the editorial identity', (
      tester,
    ) async {
      // Lo que se suprime es el cromo del mapa, no el expediente. Sin este
      // test, "preview no pinta nada" pasaría los cuatro anteriores.
      final crimeCase = _crimeCase();
      await _pumpContent(
        tester,
        crimeCase: crimeCase,
        mode: CaseDossierMode.preview,
      );

      expect(find.text(crimeCase.title), findsOneWidget);
    });
  });

  group('acciones devueltas por callback', () {
    testWidgets('the return-to-map affordance calls back', (tester) async {
      var called = 0;
      await _pumpContent(tester, onReturnToMap: () => called++);

      await tester.tap(find.text('VOLVER AL MAPA'));
      await tester.pump();

      expect(called, 1);
    });

    testWidgets('the recenter control calls back', (tester) async {
      var called = 0;
      await _pumpContent(tester, onCenterMap: () => called++);

      await tester.tap(find.text('Centrar'));
      await tester.pump();

      expect(called, 1);
    });

    testWidgets('a related card calls back with its own case', (tester) async {
      final other = _crimeCase(id: 'caso-mina', title: 'El caso de la mina');
      TrueCrimeCase? opened;
      await _pumpContent(
        tester,
        relatedCases: [(crimeCase: other, relation: 'Misma comarca')],
        onOpenRelatedCase: (crimeCase) => opened = crimeCase,
      );

      await tester.tap(find.text('El caso de la mina'));
      await tester.pump();

      // Devuelve el caso, no sólo su id: el host decide qué hacer con él.
      expect(opened, same(other));
    });

    testWidgets('a related card without a callback does not crash', (
      tester,
    ) async {
      final other = _crimeCase(id: 'caso-mina', title: 'El caso de la mina');
      await _pumpContent(
        tester,
        relatedCases: [(crimeCase: other, relation: 'Misma comarca')],
      );

      await tester.tap(find.text('El caso de la mina'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
