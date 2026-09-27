import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/app/true_crime_app.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/data/cases_repository.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';

import 'test_support/sample_cases.dart';

/// Estado del catálogo en la Sala de Situación (CRP-02).
///
/// Desde que los casos llegan por red, el mapa puede estar esperando o sin
/// datos. Ninguno de los dos casos puede parecer un archivo vacío de verdad.
class _PendingRepository implements CasesRepository {
  final completer = Completer<List<TrueCrimeCase>>();

  @override
  Future<List<TrueCrimeCase>> getCases() => completer.future;
}

/// Falla hasta que se marca como disponible; cuenta cada intento.
class _FlakyRepository implements CasesRepository {
  bool available = false;
  int calls = 0;

  @override
  Future<List<TrueCrimeCase>> getCases() async {
    calls++;
    if (!available) {
      throw StateError('sin red');
    }
    return sampleCases;
  }
}

Future<void> _pumpHome(WidgetTester tester, CasesRepository repository) async {
  tester.view.physicalSize = const Size(1300, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [casesRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const TrueCrimeApp(),
    ),
  );
  await tester.pump();
}

final _loading = find.byKey(const Key('catalog-loading'));
final _error = find.byKey(const Key('catalog-error'));
final _retry = find.byKey(const Key('catalog-retry'));

void main() {
  testWidgets('says the archive is loading while the cases arrive', (
    tester,
  ) async {
    final repository = _PendingRepository();
    await _pumpHome(tester, repository);

    expect(_loading, findsOneWidget);
    expect(_error, findsNothing);

    repository.completer.complete(sampleCases);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(_loading, findsNothing);
    expect(find.byKey(Key('marker-${sampleCases.first.id}')), findsOneWidget);
  });

  testWidgets('says the cases could not be loaded instead of an empty map', (
    tester,
  ) async {
    await _pumpHome(tester, _FlakyRepository());
    await tester.pump(const Duration(milliseconds: 50));

    expect(_error, findsOneWidget);
    expect(find.text('No se pudieron cargar los casos.'), findsOneWidget);
    expect(_loading, findsNothing);
  });

  testWidgets('retrying loads the archive once it is reachable again', (
    tester,
  ) async {
    final repository = _FlakyRepository();
    await _pumpHome(tester, repository);
    await tester.pump(const Duration(milliseconds: 50));
    expect(_error, findsOneWidget);

    repository.available = true;
    final callsBefore = repository.calls;
    await tester.tap(_retry);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // El intento sale del botón, no del reintento automático, que espera más.
    expect(repository.calls, callsBefore + 1);
    expect(_error, findsNothing);
    expect(find.byKey(Key('marker-${sampleCases.first.id}')), findsOneWidget);
  });
}
