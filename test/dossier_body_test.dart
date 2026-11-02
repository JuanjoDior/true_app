import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_chapter.dart';
import 'package:true_app/features/cases/domain/case_photo.dart';
import 'package:true_app/features/cases/domain/case_source.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';
import 'package:true_app/features/cases/presentation/dossier/dossier_body.dart';
import 'package:true_app/features/cases/presentation/dossier/dossier_body_footer.dart';
import 'package:true_app/features/cases/presentation/dossier/dossier_body_keys.dart';
import 'package:true_app/features/cases/presentation/dossier/dossier_facts_pending.dart';

import 'package:true_app/features/cases/presentation/dossier/dossier_related.dart';

const _honestNote =
    'Expediente en curso. Este caso aún no tiene capítulos ni fotografías '
    'documentadas. Se añadirán cuando estén verificados.';

TrueCrimeCase _crimeCase({
  String id = 'faro',
  String title = 'El caso del faro',
  int year = 1974,
  String? victim,
  List<String> tags = const [],
  List<CaseSource> sources = const [],
  List<CasePhoto> photos = const [],
  CaseChapters chapters = const CaseChapters(),
}) {
  return TrueCrimeCase(
    id: id,
    slug: id,
    title: title,
    category: CaseCategory.unsolved,
    country: 'España',
    countryCode: 'ES',
    regionOrCity: 'A Coruña',
    year: year,
    latitude: 43.39,
    longitude: -8.41,
    summary: 'Un farero desaparece durante una noche de temporal.',
    tags: tags,
    sources: sources,
    victim: victim,
    photos: photos,
    chapters: chapters,
  );
}

Future<void> _pump(
  WidgetTester tester,
  TrueCrimeCase crimeCase, {
  List<RelatedCase> relatedCases = const [],
  Size size = const Size(1440, 900),
  DossierPending pending = DossierPending.none,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DsTheme.build(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              DossierBody(
                crimeCase: crimeCase,
                relatedCases: relatedCases,
                onOpenRelatedCase: (_) {},
                pending: pending,
              ),
              const DossierFooter(),
            ],
          ),
        ),
      ),
    ),
  );
}

List<String> _texts(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data)
    .whereType<String>()
    .toList();

void main() {
  group('víctimas', () {
    testWidgets('names the victims with the respect line', (tester) async {
      await _pump(tester, _crimeCase(victim: 'Un farero de 54 años'));

      expect(find.text('VÍCTIMAS'), findsOneWidget);
      expect(find.text('Un farero de 54 años'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(DossierBodyKeys.victims),
          matching: find.text('Las víctimas se nombran con respeto.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('omits the block when there is no victim', (tester) async {
      await _pump(tester, _crimeCase());

      expect(find.text('VÍCTIMAS'), findsNothing);
      expect(find.byKey(DossierBodyKeys.victims), findsNothing);
    });

    testWidgets('omits the block when the victim is blank', (tester) async {
      await _pump(tester, _crimeCase(victim: '   '));

      expect(find.byKey(DossierBodyKeys.victims), findsNothing);
    });
  });

  group('capítulos', () {
    testWidgets('labels are uppercase and in editorial order', (tester) async {
      await _pump(
        tester,
        _crimeCase(
          chapters: const CaseChapters(
            currentStatus: 'Ahora',
            investigation: 'La pesquisa',
            background: 'Antes',
          ),
        ),
      );

      expect(
        _texts(
          tester,
        ).where({'ANTECEDENTES', 'LA INVESTIGACIÓN', 'ESTADO ACTUAL'}.contains),
        orderedEquals(const [
          'ANTECEDENTES',
          'LA INVESTIGACIÓN',
          'ESTADO ACTUAL',
        ]),
      );
      expect(find.text('Antes'), findsOneWidget);
      expect(find.text('La pesquisa'), findsOneWidget);
      expect(find.text('Ahora'), findsOneWidget);
    });
  });

  group('nota honesta', () {
    testWidgets('appears with no chapters and no photos', (tester) async {
      await _pump(tester, _crimeCase());

      expect(find.text(_honestNote, findRichText: true), findsOneWidget);
    });

    testWidgets('is absent when a chapter exists', (tester) async {
      await _pump(
        tester,
        _crimeCase(chapters: const CaseChapters(background: 'Antes')),
      );

      expect(find.text(_honestNote, findRichText: true), findsNothing);
    });

    testWidgets('is absent when a photo exists', (tester) async {
      await _pump(
        tester,
        _crimeCase(
          photos: const [CasePhoto(url: 'https://example.com/faro.jpg')],
        ),
      );

      expect(find.text(_honestNote, findRichText: true), findsNothing);
    });
  });

  group('fotografías', () {
    testWidgets('keeps the photo keys and survives a broken image', (
      tester,
    ) async {
      await _pump(
        tester,
        _crimeCase(
          photos: const [
            CasePhoto(url: 'https://example.com/rota.jpg', caption: 'El faro'),
            CasePhoto(url: 'https://example.com/otra.jpg'),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('case-photos')), findsOneWidget);
      expect(find.byKey(const Key('case-photo-0')), findsOneWidget);
      expect(find.byKey(const Key('case-photo-1')), findsOneWidget);
      expect(find.text('El faro'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hides the row when there are no photos', (tester) async {
      await _pump(tester, _crimeCase());

      expect(find.byKey(const Key('case-photos')), findsNothing);
    });
  });

  group('etiquetas', () {
    testWidgets('shows every tag as a pill', (tester) async {
      await _pump(tester, _crimeCase(tags: const ['1970s', 'galicia']));

      expect(find.text('ETIQUETAS'), findsOneWidget);
      expect(find.text('1970s'), findsOneWidget);
      expect(find.text('galicia'), findsOneWidget);
    });

    testWidgets('hides the section without tags', (tester) async {
      await _pump(tester, _crimeCase());

      expect(find.text('ETIQUETAS'), findsNothing);
    });
  });

  group('lateral', () {
    testWidgets('shows the year and the number of connections', (tester) async {
      await _pump(
        tester,
        _crimeCase(year: 1974),
        relatedCases: [
          (crimeCase: _crimeCase(id: 'a', year: 1901), relation: 'Comarca'),
          (crimeCase: _crimeCase(id: 'b', year: 1902), relation: 'Época'),
        ],
      );

      final aside = find.byKey(DossierBodyKeys.aside);
      expect(
        find.descendant(of: aside, matching: find.text('AÑO')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: aside, matching: find.text('1974')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: aside, matching: find.text('CONEXIONES')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: aside, matching: find.text('2')),
        findsOneWidget,
      );
    });
  });

  group('disposición', () {
    testWidgets('bounds the reading column below the window at 1440', (
      tester,
    ) async {
      await _pump(tester, _crimeCase());

      final panel = tester.getSize(find.byKey(DossierBodyKeys.detailPanel));
      expect(panel.width, lessThan(1440));
      // Columna principal y lateral, lado a lado.
      expect(
        tester.getTopLeft(find.byKey(DossierBodyKeys.aside)).dx,
        greaterThan(
          tester.getTopRight(find.byKey(DossierBodyKeys.detailPanel)).dx,
        ),
      );
      expect(
        tester.getSize(find.byKey(DossierBodyKeys.aside)).width,
        DossierBodyMetrics.asideWidth,
      );
    });

    testWidgets('stacks the aside after the main column below 1200', (
      tester,
    ) async {
      await _pump(tester, _crimeCase(), size: const Size(1199, 900));

      expect(
        tester.getTopLeft(find.byKey(DossierBodyKeys.aside)).dy,
        greaterThan(
          tester.getBottomLeft(find.byKey(DossierBodyKeys.detailPanel)).dy,
        ),
      );
    });

    for (final size in const [Size(360, 780), Size(1440, 900)]) {
      testWidgets('every related poster fills the aside at $size', (
        tester,
      ) async {
        await _pump(
          tester,
          _crimeCase(),
          relatedCases: [
            (crimeCase: _crimeCase(id: 'a', title: 'A'), relation: 'Cerca'),
            (
              crimeCase: _crimeCase(id: 'b', title: 'Un título distinto'),
              relation: 'Otra relación',
            ),
          ],
          size: size,
        );

        final asideWidth = tester
            .getSize(find.byKey(DossierBodyKeys.aside))
            .width;
        for (final id in ['a', 'b']) {
          expect(
            tester.getSize(find.byKey(DossierRelatedKeys.poster(id))).width,
            asideWidth,
          );
        }
      });

      testWidgets('long content does not overflow at $size', (tester) async {
        final longText = List.filled(80, 'Texto largo del capítulo.').join(' ');
        await _pump(
          tester,
          _crimeCase(
            victim: List.filled(20, 'Víctima nombrada').join(', '),
            tags: List.filled(12, 'etiqueta-muy-larga-del-caso'),
            chapters: CaseChapters(
              background: longText,
              events: longText,
              investigation: longText,
              currentStatus: longText,
            ),
            photos: const [CasePhoto(url: 'https://example.com/a.jpg')],
            sources: [
              CaseSource(
                id: 's1',
                title: List.filled(10, 'Título muy largo').join(' '),
                url:
                    'https://www.una-direccion-muy-larga-de-ejemplo.example.com/x',
                kind: CaseSourceKind.investigation,
              ),
            ],
          ),
          relatedCases: [
            (
              crimeCase: _crimeCase(
                id: 'r',
                title: List.filled(8, 'Relacionado').join(' '),
              ),
              relation: List.filled(10, 'misma comarca').join(' '),
            ),
          ],
          size: size,
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('pie', () {
    testWidgets('shows the brand and the respect note', (tester) async {
      await _pump(tester, _crimeCase());

      expect(find.byKey(DossierBodyKeys.footer), findsOneWidget);
      expect(find.text('TRUE'), findsOneWidget);
      expect(
        find.text(
          'Crímenes reales · documentados con respeto. '
          'Las víctimas se nombran con respeto.',
        ),
        findsOneWidget,
      );
    });
  });

  group('datos pendientes', () {
    testWidgets('por defecto el lateral muestra el año del caso', (
      tester,
    ) async {
      await _pump(tester, _crimeCase());

      expect(find.text('1974'), findsOneWidget);
      expect(find.text('pendiente'), findsNothing);
    });

    testWidgets('sin año el lateral dice pendiente', (tester) async {
      await _pump(
        tester,
        _crimeCase(year: 0),
        pending: const DossierPending(year: true),
      );

      expect(find.text('pendiente'), findsOneWidget);
      expect(find.text('0'), findsOneWidget, reason: 'sólo las conexiones');
    });
  });
}
