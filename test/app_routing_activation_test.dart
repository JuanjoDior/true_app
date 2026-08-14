import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/app/true_crime_app.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/data/cases_repository.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';
import 'package:true_app/features/cases/presentation/case_detail_page.dart';
import 'package:true_app/features/cases/presentation/intake/intake_workspace_screen.dart';
import 'package:true_app/features/home/presentation/home_page.dart';

/// La aplicación entera bajo el Router [diseño §7.3, §7.4].
///
/// Aquí se comprueba lo que ninguna pieza suelta puede: que un enlace directo
/// abre el expediente, que volver revela lo que hubiera debajo — intake
/// incluido — y que el router sigue sin escribir `workspaceProvider`.

TrueCrimeCase _crimeCase({
  String id = 'legacy-7',
  String slug = 'known-case',
  String title = 'El caso del faro',
}) {
  return TrueCrimeCase(
    id: id,
    slug: slug,
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
    sources: const [],
    status: CaseStatus.open,
  );
}

class _StubRepository implements CasesRepository {
  const _StubRepository();

  @override
  Future<List<TrueCrimeCase>> getCases() async => [_crimeCase()];
}

/// Bombeo acotado, no `pumpAndSettle`.
///
/// La Sala de Situación tiene animación perpetua — el mapa y sus transiciones
/// nunca se quedan quietos —, así que `pumpAndSettle` se agota en lugar de
/// converger. Los tests que ya montaban la sala usan este mismo bombeo acotado.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  String location = '/',
  Workspace? workspace,
  String? selectedCaseId,
}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      casesRepositoryProvider.overrideWithValue(const _StubRepository()),
    ],
  );
  addTearDown(container.dispose);
  if (workspace != null) {
    container.read(workspaceProvider.notifier).state = workspace;
    container.read(intakeUnlockedProvider.notifier).state = true;
  }
  // Se siembra ANTES de montar, no después.
  //
  // Escribir `selectedCaseIdProvider` con la Sala ya en el árbol pero tapada
  // por la ruta de detalle revienta: `situation_map_stage.dart` escucha ese
  // provider y llama a `mapController.move`, y el mapa que está debajo aún no
  // ha inicializado su `InteractiveViewer`. Es un defecto real del escenario
  // del mapa, ajeno a las rutas, anotado y no arreglado aquí.
  if (selectedCaseId != null) {
    container.read(selectedCaseIdProvider.notifier).state = selectedCaseId;
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: TrueCrimeApp(initialLocation: location),
    ),
  );
  await _settle(tester);
  return container;
}

void main() {
  group('la ruta real del navegador manda', () {
    testWidgets('without an initialLocation the platform route is used', (
      tester,
    ) async {
      // ESTE TEST NACIÓ DE UN FALLO EN NAVEGADOR REAL, no de una idea.
      //
      // `initialLocation` existe sólo para los tests. Al pasar un
      // `routeInformationProvider` explícito SIEMPRE, la aplicación desplegada
      // ignoraba la barra de direcciones y arrancaba en `/`: cualquier enlace
      // directo aterrizaba en la Sala de Situación con el hash borrado. Los 431
      // tests pasaban porque todos pasan `initialLocation`.
      //
      // `null` aquí significa "usa el de la plataforma", que es el que lee la
      // URL de verdad.
      final container = ProviderContainer(
        overrides: [
          casesRepositoryProvider.overrideWithValue(const _StubRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TrueCrimeApp(),
        ),
      );

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.routeInformationProvider, isNull);
    });

    testWidgets('with an initialLocation the test route wins', (tester) async {
      // Gemelo del anterior: sin él, "nunca hay provider" pasaría el primero y
      // dejaría los otros trece tests sin forma de fijar una ruta.
      final container = ProviderContainer(
        overrides: [
          casesRepositoryProvider.overrideWithValue(const _StubRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TrueCrimeApp(initialLocation: '/casos/known-case'),
        ),
      );

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.routeInformationProvider, isNotNull);
    });
  });

  group('el router es dueño de las rutas', () {
    testWidgets('the root shows the Situation Room', (tester) async {
      await _pumpApp(tester);

      expect(find.byType(TrueCrimeHomePage), findsOneWidget);
    });

    testWidgets('the root does not show a case detail page', (tester) async {
      await _pumpApp(tester);

      expect(find.byType(CaseDetailPage), findsNothing);
    });

    testWidgets('a case deep link opens its detail page', (tester) async {
      await _pumpApp(tester, location: '/casos/known-case');

      expect(find.byType(CaseDetailPage), findsOneWidget);
    });

    testWidgets('a case deep link shows the case itself', (tester) async {
      await _pumpApp(tester, location: '/casos/known-case');

      expect(find.text('El caso del faro'), findsOneWidget);
    });

    testWidgets('an unknown route shows the not-found page', (tester) async {
      await _pumpApp(tester, location: '/ajustes');

      expect(find.byKey(const Key('route-not-found')), findsOneWidget);
    });

    testWidgets('an unknown route is not a missing case', (tester) async {
      // Sintaxis desconocida y caso inexistente son cosas distintas.
      await _pumpApp(tester, location: '/ajustes');

      expect(find.byKey(const Key('case-detail-not-found')), findsNothing);
    });

    testWidgets('a case route with an unknown slug says the case is missing', (
      tester,
    ) async {
      await _pumpApp(tester, location: '/casos/no-existe');

      expect(find.byKey(const Key('case-detail-not-found')), findsOneWidget);
    });
  });

  group('la frontera con el workspace', () {
    testWidgets('a deep link renders the dossier over an open intake', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        location: '/casos/known-case',
        workspace: Workspace.intake,
      );

      expect(find.byType(CaseDetailPage), findsOneWidget);
    });

    testWidgets('the deep link does not rewrite the workspace', (tester) async {
      final container = await _pumpApp(
        tester,
        location: '/casos/known-case',
        workspace: Workspace.intake,
      );

      // Si el router escribiera `workspaceProvider`, dos dueños discutirían
      // sobre qué enseña `/` y el usuario perdería su formulario a medias.
      expect(container.read(workspaceProvider), Workspace.intake);
    });

    testWidgets('returning from that deep link reveals the intake underneath', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        location: '/casos/known-case',
        workspace: Workspace.intake,
      );

      await tester.tap(find.byKey(const Key('case-detail-return')));
      await _settle(tester);

      // La raíz enseña lo que el workspace ya decía, no la Sala de Situación
      // por decreto del router [diseño §7.4].
      expect(find.byType(IntakeWorkspaceScreen), findsOneWidget);
    });

    testWidgets('returning from a deep link with no intake shows the map', (
      tester,
    ) async {
      // Gemelo del anterior: sin él, "siempre enseña intake" pasaría los dos.
      await _pumpApp(tester, location: '/casos/known-case');

      await tester.tap(find.byKey(const Key('case-detail-return')));
      await _settle(tester);

      expect(find.byType(TrueCrimeHomePage), findsOneWidget);
    });

    testWidgets('opening a case does not touch the map selection', (
      tester,
    ) async {
      final container = await _pumpApp(tester, location: '/casos/known-case');

      expect(container.read(selectedCaseIdProvider), isNull);
    });

    testWidgets('returning preserves an existing map selection', (
      tester,
    ) async {
      final container = await _pumpApp(
        tester,
        location: '/casos/known-case',
        selectedCaseId: 'legacy-7',
      );

      await tester.tap(find.byKey(const Key('case-detail-return')));
      await _settle(tester);

      expect(container.read(selectedCaseIdProvider), 'legacy-7');
    });
  });
}
