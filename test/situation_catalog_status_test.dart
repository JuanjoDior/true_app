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

class _EmptyRepository implements CasesRepository {
  @override
  Future<List<TrueCrimeCase>> getCases() async => const [];
}

/// Falla una vez y el siguiente intento se queda esperando.
class _SlowRetryRepository implements CasesRepository {
  int calls = 0;

  @override
  Future<List<TrueCrimeCase>> getCases() {
    calls++;
    if (calls == 1) {
      return Future.error(StateError('sin red'));
    }
    return Completer<List<TrueCrimeCase>>().future;
  }
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
    // Sin el reintento automático de Riverpod: cada intento de estos tests
    // sale del botón, no de un temporizador.
    retry: (_, _) => null,
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
final _empty = find.byKey(const Key('catalog-empty'));

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

  testWidgets('an empty archive says so instead of showing a blank map', (
    tester,
  ) async {
    await _pumpHome(tester, _EmptyRepository());
    await tester.pump(const Duration(milliseconds: 50));

    expect(_empty, findsOneWidget);
    expect(find.text('Todavía no hay expedientes publicados.'), findsOneWidget);
    expect(_loading, findsNothing);
    expect(_error, findsNothing);
  });

  testWidgets('keeps the error and disables the button while retrying', (
    tester,
  ) async {
    await _pumpHome(tester, _SlowRetryRepository());
    await tester.pump(const Duration(milliseconds: 50));
    expect(_error, findsOneWidget);

    await tester.tap(_retry);
    await tester.pump();

    // El aviso no parpadea a «cargando»: sigue el error, con el botón ocupado.
    expect(_error, findsOneWidget);
    expect(_loading, findsNothing);
    expect(find.text('Reintentando…'), findsOneWidget);
    expect(tester.widget<TextButton>(_retry).onPressed, isNull);
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

    expect(repository.calls, callsBefore + 1);
    expect(_error, findsNothing);
    expect(find.byKey(Key('marker-${sampleCases.first.id}')), findsOneWidget);
  });
}
