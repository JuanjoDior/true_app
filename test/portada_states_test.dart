import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';
import 'package:true_app/features/home/presentation/portada/portada_closing_keys.dart';

import 'test_support/portada_test_support.dart';

void main() {
  group('cargando', () {
    testWidgets('dice que carga el archivo', (tester) async {
      await pumpPortadaCatalogStatus(
        tester,
        const AsyncLoading<List<TrueCrimeCase>>(),
      );

      expect(find.byKey(PortadaClosingKeys.statusLoading), findsOneWidget);
      expect(find.text('Cargando el archivo…'), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
    });
  });

  group('error', () {
    testWidgets('muestra el aviso y el botón Reintentar', (tester) async {
      await pumpPortadaCatalogStatus(tester, catalogError());

      expect(find.byKey(PortadaClosingKeys.statusError), findsOneWidget);
      expect(find.text('No se pudieron cargar los casos.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('Reintentar llama a onRetry', (tester) async {
      final callbacks = await pumpPortadaCatalogStatus(tester, catalogError());

      await tester.tap(find.text('Reintentar'));
      expect(callbacks.retries, 1);
    });

    testWidgets(
      'mientras reintenta mantiene el error y no reintenta de nuevo',
      (tester) async {
        final callbacks = await pumpPortadaCatalogStatus(
          tester,
          await catalogReloading(previousFailed: true),
        );

        expect(find.byKey(PortadaClosingKeys.statusError), findsOneWidget);
        expect(find.text('No se pudieron cargar los casos.'), findsOneWidget);
        expect(find.text('Reintentando…'), findsOneWidget);
        expect(find.text('Reintentar'), findsNothing);

        await tester.tap(find.text('Reintentando…'));
        expect(callbacks.retries, 0);
      },
    );

    testWidgets('se anuncia a los lectores de pantalla', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPortadaCatalogStatus(tester, catalogError());

      final live = find.descendant(
        of: find.byKey(PortadaClosingKeys.statusError),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
      );
      expect(live, findsOneWidget);
      handle.dispose();
    });
  });

  group('vacío', () {
    testWidgets('dice que no hay expedientes y no ofrece reintento', (
      tester,
    ) async {
      await pumpPortadaCatalogStatus(
        tester,
        const AsyncData<List<TrueCrimeCase>>([]),
      );

      expect(find.byKey(PortadaClosingKeys.statusEmpty), findsOneWidget);
      expect(
        find.text('Todavía no hay expedientes publicados.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsNothing);
    });
  });

  group('con casos', () {
    testWidgets('no pinta nada', (tester) async {
      await pumpPortadaCatalogStatus(tester, AsyncData(portadaCases));

      expect(find.byType(DsStateMessage), findsNothing);
    });

    testWidgets('una recarga con datos previos tampoco pinta nada', (
      tester,
    ) async {
      final reloading = await catalogReloading(previousFailed: false);
      expect(reloading.isLoading, isTrue);
      await pumpPortadaCatalogStatus(tester, reloading);

      expect(find.byType(DsStateMessage), findsNothing);
    });
  });
}
