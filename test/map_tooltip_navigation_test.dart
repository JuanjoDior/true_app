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

/// Pulsar la tarjeta del caso seleccionado en el mapa abre su expediente.
///
/// Se monta la aplicación ENTERA porque lo que se prueba es la composición: que
/// el tooltip alcance la navegación real y que la ruta cambie de verdad.

TrueCrimeCase _crimeCase({
  required String id,
  required String slug,
  required String title,
}) {
  return TrueCrimeCase(
    id: id,
    slug: slug,
    title: title,
    category: CaseCategory.unsolved,
    country: 'Noruega',
    countryCode: 'NO',
    regionOrCity: 'Bergen',
    year: 1970,
    latitude: 60.39,
    longitude: 5.32,
    summary: 'Un cuerpo sin nombre.',
    tags: const <String>[],
    sources: const [],
    status: CaseStatus.open,
  );
}

class _StubRepository implements CasesRepository {
  const _StubRepository(this._cases);

  final List<TrueCrimeCase> _cases;

  @override
  Future<List<TrueCrimeCase>> getCases() async => _cases;
}

/// `id` distinto de `slug` a propósito: con `id == slug` este test no podría
/// distinguir "navega por slug" de "navega por id", que es justo lo que hay que
/// fijar — la URL pública es la del slug.
final _catalog = [
  _crimeCase(
    id: 'legacy-7',
    slug: 'mujer-de-isdal',
    title: 'La mujer de Isdal',
  ),
];

/// Bombeo acotado: la Sala de Situación nunca se queda quieta.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

Future<ProviderContainer> _pumpWithSelection(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      casesRepositoryProvider.overrideWithValue(_StubRepository(_catalog)),
    ],
  );
  addTearDown(container.dispose);
  // La selección se siembra ANTES de montar: escribirla con la Sala ya en el
  // árbol dispara el recentrado del mapa antes de que su visor exista.
  container.read(selectedCaseIdProvider.notifier).state = 'legacy-7';

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const TrueCrimeApp(),
    ),
  );
  await _settle(tester);
  return container;
}

void main() {
  testWidgets('the selected case card is on screen to begin with', (
    tester,
  ) async {
    // Gemelo de presencia: sin él, "no existe la tarjeta" pasaría los tests de
    // abajo sin que nadie se enterara de que desapareció.
    await _pumpWithSelection(tester);

    expect(find.byKey(const Key('selected-marker-tooltip')), findsOneWidget);
  });

  testWidgets('tapping it opens the case detail page', (tester) async {
    await _pumpWithSelection(tester);
    expect(find.byType(CaseDetailPage), findsNothing);

    await tester.tap(find.byKey(const Key('selected-marker-tooltip')));
    await _settle(tester);

    expect(find.byType(CaseDetailPage), findsOneWidget);
  });

  testWidgets('it opens that case, not a substitute', (tester) async {
    await _pumpWithSelection(tester);

    await tester.tap(find.byKey(const Key('selected-marker-tooltip')));
    await _settle(tester);

    expect(find.byKey(const Key('case-detail-not-found')), findsNothing);
  });

  testWidgets('opening it does not disturb the map selection', (tester) async {
    final container = await _pumpWithSelection(tester);

    await tester.tap(find.byKey(const Key('selected-marker-tooltip')));
    await _settle(tester);

    // La ficha se apila ENCIMA del mapa; al volver, el mapa sigue como estaba
    // [diseño §7.4].
    expect(container.read(selectedCaseIdProvider), 'legacy-7');
  });
}
