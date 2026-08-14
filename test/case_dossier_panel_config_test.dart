import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/config/map_config.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_connection.dart';
import 'package:true_app/features/cases/domain/case_source.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';
import 'package:true_app/features/home/presentation/widgets/situation/case_dossier_content.dart';
import 'package:true_app/features/home/presentation/widgets/situation/case_dossier_panel.dart';
import 'package:true_app/features/home/presentation/widgets/situation/dossier_source_group.dart';

import 'test_support/sample_cases.dart';

/// Configuración aditiva del host compacto [diseño D12].
///
/// Cada parámetro nuevo de `CaseDossierPanel` es OPCIONAL y su omisión deja el
/// comportamiento de hoy intacto. Ésa es la única razón por la que la
/// extracción se pudo partir en tres: si `mode` o `relatedCases` fuesen
/// obligatorios, los seis call sites tendrían que cambiar en la misma edición
/// que los introduce y no quedaría ningún estado intermedio que compile.

TrueCrimeCase _crimeCase({
  String id = 'caso-faro',
  String title = 'El caso del faro',
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
    status: CaseStatus.open,
  );
}

Future<ProviderContainer> _pumpPanel(
  WidgetTester tester,
  Widget panel, {
  List<TrueCrimeCase> catalog = const [],
  List<CaseConnection> connections = const [],
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      casesRepositoryProvider.overrideWithValue(FakeCasesRepository(catalog)),
      caseConnectionsProvider.overrideWithValue(connections),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: Scaffold(body: panel)),
    ),
  );
  await tester.pump();
  return container;
}

const _mina = CaseConnection(
  aId: 'caso-faro',
  bId: 'caso-mina',
  relation: 'Misma comarca',
);

void main() {
  group('los defectos preservan el comportamiento de hoy', () {
    testWidgets('an unconfigured panel still derives its related cases', (
      tester,
    ) async {
      await _pumpPanel(
        tester,
        CaseDossierPanel(crimeCase: _crimeCase()),
        catalog: [_crimeCase(id: 'caso-mina', title: 'El caso de la mina')],
        connections: const [_mina],
      );

      expect(find.text('El caso de la mina'), findsOneWidget);
    });

    testWidgets('an unconfigured panel still clears the map selection', (
      tester,
    ) async {
      final container = await _pumpPanel(
        tester,
        CaseDossierPanel(crimeCase: _crimeCase()),
      );
      container.read(selectedCaseIdProvider.notifier).state = 'caso-faro';

      await tester.tap(find.text('VOLVER AL MAPA'));
      await tester.pump();

      expect(container.read(selectedCaseIdProvider), isNull);
    });

    testWidgets('an unconfigured panel still bumps the recenter tick', (
      tester,
    ) async {
      final container = await _pumpPanel(
        tester,
        CaseDossierPanel(crimeCase: _crimeCase()),
      );
      final before = container.read(mapRecenterTickProvider);

      await tester.tap(find.text('Centrar'));
      await tester.pump();

      expect(container.read(mapRecenterTickProvider), before + 1);
    });

    testWidgets('an unconfigured panel still selects a related case', (
      tester,
    ) async {
      final container = await _pumpPanel(
        tester,
        CaseDossierPanel(crimeCase: _crimeCase()),
        catalog: [_crimeCase(id: 'caso-mina', title: 'El caso de la mina')],
        connections: const [_mina],
      );

      await tester.tap(find.text('El caso de la mina'));
      await tester.pump();

      expect(container.read(selectedCaseIdProvider), 'caso-mina');
    });
  });

  group('configuración explícita', () {
    testWidgets('a supplied related list wins over the derived one', (
      tester,
    ) async {
      final supplied = _crimeCase(id: 'caso-rio', title: 'El caso del río');
      await _pumpPanel(
        tester,
        CaseDossierPanel(
          crimeCase: _crimeCase(),
          relatedCases: [(crimeCase: supplied, relation: 'Mismo autor')],
        ),
        // El catálogo y las conexiones apuntan a OTRO caso: si el panel
        // siguiera derivando, aparecería la mina y no el río.
        catalog: [_crimeCase(id: 'caso-mina', title: 'El caso de la mina')],
        connections: const [_mina],
      );

      expect(find.text('El caso del río'), findsOneWidget);
    });

    testWidgets('a supplied related list suppresses the derived one', (
      tester,
    ) async {
      final supplied = _crimeCase(id: 'caso-rio', title: 'El caso del río');
      await _pumpPanel(
        tester,
        CaseDossierPanel(
          crimeCase: _crimeCase(),
          relatedCases: [(crimeCase: supplied, relation: 'Mismo autor')],
        ),
        catalog: [_crimeCase(id: 'caso-mina', title: 'El caso de la mina')],
        connections: const [_mina],
      );

      expect(find.text('El caso de la mina'), findsNothing);
    });

    testWidgets('an empty supplied list hides the related section', (
      tester,
    ) async {
      await _pumpPanel(
        tester,
        CaseDossierPanel(crimeCase: _crimeCase(), relatedCases: const []),
        catalog: [_crimeCase(id: 'caso-mina', title: 'El caso de la mina')],
        connections: const [_mina],
      );

      expect(find.text('CASOS RELACIONADOS'), findsNothing);
    });

    testWidgets('preview mode suppresses the map chrome', (tester) async {
      await _pumpPanel(
        tester,
        CaseDossierPanel(
          crimeCase: _crimeCase(),
          mode: CaseDossierMode.preview,
        ),
      );

      expect(find.text('VOLVER AL MAPA'), findsNothing);
    });

    testWidgets('preview mode still renders the dossier itself', (
      tester,
    ) async {
      final crimeCase = _crimeCase();
      await _pumpPanel(
        tester,
        CaseDossierPanel(crimeCase: crimeCase, mode: CaseDossierMode.preview),
      );

      expect(find.text(crimeCase.title), findsOneWidget);
    });

    testWidgets('preview mode does not touch the map selection', (
      tester,
    ) async {
      final container = await _pumpPanel(
        tester,
        CaseDossierPanel(
          crimeCase: _crimeCase(),
          mode: CaseDossierMode.preview,
        ),
      );
      container.read(selectedCaseIdProvider.notifier).state = 'caso-faro';
      await tester.pump();

      // Sin cromo de mapa no hay forma de tocarlo, pero el test fija la
      // consecuencia y no el mecanismo: la previsualización no escribe.
      expect(container.read(selectedCaseIdProvider), 'caso-faro');
    });

    testWidgets('a host callback replaces the default map write', (
      tester,
    ) async {
      var called = 0;
      final container = await _pumpPanel(
        tester,
        CaseDossierPanel(
          crimeCase: _crimeCase(),
          onReturnToMap: () => called++,
        ),
      );
      container.read(selectedCaseIdProvider.notifier).state = 'caso-faro';

      await tester.tap(find.text('VOLVER AL MAPA'));
      await tester.pump();

      expect(container.read(selectedCaseIdProvider), 'caso-faro');
    });

    testWidgets('that host callback is the one that runs', (tester) async {
      var called = 0;
      await _pumpPanel(
        tester,
        CaseDossierPanel(
          crimeCase: _crimeCase(),
          onReturnToMap: () => called++,
        ),
      );

      await tester.tap(find.text('VOLVER AL MAPA'));
      await tester.pump();

      expect(called, 1);
    });

    testWidgets('source groups reach the shared renderer', (tester) async {
      await _pumpPanel(
        tester,
        CaseDossierPanel(
          crimeCase: _crimeCase(
            sources: const [
              CaseSource(
                id: 's1',
                title: 'Publicada',
                url: 'https://elpais.com/a',
                kind: CaseSourceKind.investigation,
              ),
            ],
          ),
          sourceGroups: const [
            DossierSourceGroup(
              label: 'Sin clasificar',
              sources: [
                CaseSource(
                  id: 's2',
                  title: 'Del borrador',
                  url: 'https://ivoox.com/b',
                  kind: CaseSourceKind.podcast,
                ),
              ],
            ),
          ],
        ),
      );

      expect(find.text('Publicada'), findsNothing);
    });
  });
}
