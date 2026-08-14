import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:true_app/app/true_crime_app.dart';
import 'package:true_app/core/config/map_config.dart';
import 'package:true_app/core/layout/breakpoints.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/home/presentation/widgets/situation/situation_nav_rail.dart';
import 'package:true_app/features/home/presentation/widgets/situation/situation_side_panel.dart';

import 'test_support/sample_cases.dart';

/// Characterization lock for the Sala de Situación's responsive layout
/// selection, captured BEFORE migrating `home_page.dart`'s inline width
/// literals (880/980/1024/1100) to the shared `Breakpoints` module. Every
/// assertion here MUST stay GREEN after the migration — that is what proves
/// the migration is behavior-preserving, byte-for-byte.
///
/// **La tolerancia de desbordamiento se ha retirado, y ésa es la noticia.**
///
/// Este fichero documentaba un defecto preexistente de `SituationTopBar`, medido
/// banda a banda: desbordaba 21px a 980, 1.2px a 1000, y entre 59 y 9.4px en el
/// tramo 1030–1080. Se toleraba SÓLO en esos anchos, con la instrucción expresa
/// de retirar la tolerancia el día que el defecto se arreglara.
///
/// Ese día fue el del directorio del archivo. Subir `topBarFull` de 980 a 1040
/// —hecho para que cupiera el acceso al directorio— recorta las métricas justo
/// en el tramo donde la fila no daba de sí, y con eso el desbordamiento
/// desaparece en todos los anchos medidos. El arreglo fue un efecto secundario
/// buscando otra cosa, pero es un arreglo real y la lista de tolerancias se
/// queda vacía.
///
/// A partir de aquí, CUALQUIER ancho debe pintar limpio. Un desbordamiento
/// nuevo en cualquier punto es una regresión, no un conocido.
void main() {
  /// Ya ninguno. Un desbordamiento a cualquier ancho es ahora una regresión.
  const overflowingWidths = <double>[];

  /// Returns `true` when this pump reported the known overflow. The defect is
  /// raised during layout, so a later pump that does not relayout the top bar
  /// legitimately reports nothing — hence "at least once per width" below,
  /// rather than "on every pump".
  bool drainExpectedException(WidgetTester tester, double width) {
    final exception = tester.takeException();
    if (exception == null) return false;

    expect(
      overflowingWidths.contains(width),
      isTrue,
      reason:
          'Width $width px pumps clean today. A new exception here is a '
          'regression, not the known SituationTopBar defect.',
    );
    expect(
      exception.toString(),
      contains('RenderFlex overflowed'),
      reason:
          'Only the known pre-existing SituationTopBar overflow is '
          'tolerated at width $width px; any other exception must fail.',
    );
    return true;
  }

  Future<ProviderContainer> pumpAt(WidgetTester tester, double width) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 1200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [
        casesRepositoryProvider.overrideWithValue(
          const FakeCasesRepository(sampleCases),
        ),
        mapConfigProvider.overrideWithValue(MapConfig.testing()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TrueCrimeApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    var sawKnownOverflow = drainExpectedException(tester, width);

    // Selecciona un caso para poder comprobar la hoja móvil del expediente
    // por debajo del umbral `sidePanel`.
    container.read(selectedCaseIdProvider.notifier).state = 'zodiac-killer';
    await tester.pump(const Duration(milliseconds: 400));
    sawKnownOverflow |= drainExpectedException(tester, width);

    if (overflowingWidths.contains(width)) {
      expect(
        sawKnownOverflow,
        isTrue,
        reason:
            'Width $width px is pinned as overflowing but pumped clean. If '
            'the SituationTopBar defect was fixed, remove $width from '
            'overflowingWidths so this tolerance disappears with it.',
      );
    }

    return container;
  }

  group('Sala threshold values are pinned, not merely bracketed', () {
    // Los tests de abajo muestrean 1440/1050/1000/900/800, lo que ACOTA cada
    // umbral dentro de un rango pero no lo FIJA. Medido: mover `navRail` de
    // 1100 a 1200 dejaba los 164 tests en verde, y con ello el rail lateral
    // desaparecía en silencio para todo el rango 1100-1199 en la pantalla
    // pública. Mover el mismo umbral a 1000 sí fallaba, sólo porque cruzaba la
    // muestra de 1050 — o sea que la cobertura dependía de dónde cayeran las
    // muestras, no del valor.
    //
    // Estas cuatro igualdades son lo que satisface de verdad el Requisito
    // "Existing threshold values are preserved unchanged": la migración de la
    // fase 1 tenía que ser byte a byte, y un cambio de valor es exactamente la
    // deriva que debía impedir.
    //
    // `intakeThreePane` y `formRowStack` NO se fijan aquí a propósito: son
    // constantes nuevas de este cambio, no valores heredados que preservar, y
    // ya están ancladas por comportamiento en `intake_desktop_layout_test.dart`
    // y en las medidas de ancho de las secciones (ambas verificadas por
    // mutación).
    test('the migrated Sala thresholds keep their original values', () {
      expect(Breakpoints.sidePanel, 880);
      expect(Breakpoints.widePanel, 1024);
      expect(Breakpoints.navRail, 1100);
    });

    // `topBarFull` SÍ cambió, de 980 a 1040, y este test se actualiza en vez de
    // borrarse. El motivo: el acceso al directorio del archivo añadió 44px a la
    // barra, que a 1000px desbordaba 45. Entre 880 y 1100 no hay rail donde
    // poner ese acceso, así que ceden las métricas — decorativas — y no el
    // acceso, que es funcional. El coste, declarado: en el tramo 980–1040 las
    // métricas ya no se ven, y antes sí.
    test('topBarFull moved to make room for the directory entry point', () {
      expect(Breakpoints.topBarFull, 1040);
    });
  });

  group('Sala de Situación layout selection is locked at each threshold', () {
    testWidgets(
      '1440px: nav rail + 362px panel + metrics visible, no mobile sheet',
      (tester) async {
        await pumpAt(tester, 1440);

        expect(find.byType(SituationNavRail), findsOneWidget);
        expect(tester.getSize(find.byType(SituationSidePanel)).width, 362);
        expect(find.byKey(const Key('mobile-case-sheet')), findsNothing);
        expect(find.text('DOCUMENTADOS'), findsOneWidget);
        expect(find.text('Global ▾'), findsOneWidget);
      },
    );

    testWidgets(
      '1050px: no nav rail, 362px panel, metrics visible, no mobile sheet',
      (tester) async {
        await pumpAt(tester, 1050);

        expect(find.byType(SituationNavRail), findsNothing);
        expect(tester.getSize(find.byType(SituationSidePanel)).width, 362);
        expect(find.byKey(const Key('mobile-case-sheet')), findsNothing);
        expect(find.text('DOCUMENTADOS'), findsOneWidget);
        expect(find.text('Global ▾'), findsOneWidget);
      },
    );

    testWidgets(
      '1000px: no nav rail, 320px panel, metrics now hidden, no mobile sheet',
      (tester) async {
        await pumpAt(tester, 1000);

        expect(find.byType(SituationNavRail), findsNothing);
        expect(tester.getSize(find.byType(SituationSidePanel)).width, 320);
        expect(find.byKey(const Key('mobile-case-sheet')), findsNothing);
        // Cambió con `topBarFull`: a 1000px las métricas ya no caben junto al
        // acceso al directorio. Es la consecuencia declarada de ese umbral.
        expect(find.text('DOCUMENTADOS'), findsNothing);
        expect(find.text('Global ▾'), findsNothing);
      },
    );

    testWidgets('1000px still renders the whole bar without overflowing', (
      tester,
    ) async {
      // El desbordamiento que provocó el cambio de umbral. Sin este test
      // volvería a colarse en cuanto la barra gane otro control.
      await pumpAt(tester, 1000);

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '900px: no nav rail, 320px panel, compact top bar, no mobile sheet',
      (tester) async {
        await pumpAt(tester, 900);

        expect(find.byType(SituationNavRail), findsNothing);
        expect(tester.getSize(find.byType(SituationSidePanel)).width, 320);
        expect(find.byKey(const Key('mobile-case-sheet')), findsNothing);
        expect(find.text('DOCUMENTADOS'), findsNothing);
        expect(find.text('Global ▾'), findsNothing);
      },
    );

    testWidgets(
      '800px: mobile body with floating dossier sheet, compact top bar',
      (tester) async {
        await pumpAt(tester, 800);

        expect(find.byType(SituationNavRail), findsNothing);
        expect(find.byType(SituationSidePanel), findsNothing);
        expect(find.byKey(const Key('mobile-case-sheet')), findsOneWidget);
        expect(find.text('DOCUMENTADOS'), findsNothing);
        expect(find.text('Global ▾'), findsNothing);
      },
    );
  });
}
