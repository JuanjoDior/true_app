import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';
import 'package:true_app/features/cases/presentation/dossier/dossier_facts_pending.dart';
import 'package:true_app/features/cases/presentation/dossier/dossier_hero.dart';
import 'package:true_app/features/cases/presentation/dossier/dossier_hero_keys.dart';

const Size _desktop = Size(1440, 900);
const Size _phone = Size(360, 780);

TrueCrimeCase _case({
  String title = 'Zodiac',
  String summary = 'Un agresor sin identificar que envió cartas cifradas.',
  CaseStatus status = CaseStatus.open,
  String? statusLabel,
}) {
  return TrueCrimeCase(
    id: 'zodiac',
    slug: 'zodiac',
    title: title,
    category: CaseCategory.serialKiller,
    country: 'EE. UU.',
    countryCode: 'US',
    regionOrCity: 'San Francisco',
    year: 1968,
    latitude: 37.77,
    longitude: -122.42,
    summary: summary,
    tags: const [],
    sources: const [],
    status: status,
    statusLabel: statusLabel,
  );
}

Future<void> _pumpHero(
  WidgetTester tester,
  TrueCrimeCase crimeCase, {
  Size size = _desktop,
  DossierPending pending = DossierPending.none,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  // Como en la página: la cabecera vive dentro de un scroll vertical.
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(size: size),
        child: SingleChildScrollView(
          child: DossierHero(crimeCase: crimeCase, pending: pending),
        ),
      ),
    ),
  );
}

double _fontSizeOf(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).style!.fontSize!;

void main() {
  group('contenido', () {
    testWidgets('muestra título, resumen, categoría y lugar en mayúsculas', (
      tester,
    ) async {
      final crimeCase = _case();
      await _pumpHero(tester, crimeCase);

      expect(find.text('Zodiac'), findsOneWidget);
      expect(find.text(crimeCase.summary), findsOneWidget);
      expect(find.text('Asesinos en serie'), findsOneWidget);
      expect(find.text('· SAN FRANCISCO · EE. UU. · 1968'), findsOneWidget);
    });

    testWidgets('prefiere el estado editorial libre al del enum', (
      tester,
    ) async {
      await _pumpHero(tester, _case(statusLabel: 'Reabierto (2019)'));

      expect(find.text('Reabierto (2019)'), findsOneWidget);
      expect(find.text('Sin resolver'), findsNothing);
    });

    testWidgets('sin estado editorial muestra la etiqueta del estado', (
      tester,
    ) async {
      await _pumpHero(tester, _case(status: CaseStatus.solved));

      expect(
        find.descendant(
          of: find.byKey(DossierHeroKeys.status),
          matching: find.text('Resuelto'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('dibuja el año fantasma', (tester) async {
      await _pumpHero(tester, _case());

      expect(
        find.descendant(
          of: find.byKey(DossierHeroKeys.ghostYear),
          matching: find.text('1968'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('no lleva enlace de volver: lo pone la barra fija', (
      tester,
    ) async {
      await _pumpHero(tester, _case());

      expect(find.textContaining('VOLVER'), findsNothing);
      expect(find.textContaining('Volver'), findsNothing);
    });
  });

  testWidgets('usa las familias tipográficas empaquetadas', (tester) async {
    await _pumpHero(tester, _case());
    for (final key in [DossierHeroKeys.title, DossierHeroKeys.summary]) {
      expect(
        tester.widget<Text>(find.byKey(key)).style!.fontFamily,
        'NotoSerifDisplay',
      );
    }
    expect(
      tester.widget<Text>(find.byKey(DossierHeroKeys.place)).style!.fontFamily,
      'IBMPlexMono',
    );
    expect(
      tester.widget<Text>(find.text('1968')).style!.fontFamily,
      'NotoSerifDisplay',
    );
  });

  group('medidas', () {
    testWidgets('en escritorio el título es serif grande y el resumen 24', (
      tester,
    ) async {
      await _pumpHero(tester, _case());

      expect(
        _fontSizeOf(tester, DossierHeroKeys.title),
        inInclusiveRange(120, 128),
      );
      expect(_fontSizeOf(tester, DossierHeroKeys.summary), 24);
      expect(
        tester.getSize(find.byKey(DossierHeroKeys.summary)).width,
        lessThanOrEqualTo(DossierHero.summaryMaxWidth),
      );
    });

    testWidgets('en pantallas estrechas el título es más pequeño', (
      tester,
    ) async {
      await _pumpHero(tester, _case(), size: _phone);

      expect(_fontSizeOf(tester, DossierHeroKeys.title), lessThan(120));
    });

    testWidgets('deja hueco al pie para la ficha técnica superpuesta', (
      tester,
    ) async {
      await _pumpHero(tester, _case());

      final heroBottom = tester.getBottomLeft(find.byType(DossierHero)).dy;
      final summaryBottom = tester
          .getBottomLeft(find.byKey(DossierHeroKeys.summary))
          .dy;
      expect(
        heroBottom - summaryBottom,
        greaterThanOrEqualTo(DossierHero.factsOverlap),
      );
    });
  });

  group('sin desbordes', () {
    final longCase = _case(
      title: 'Asesinatos del Paso Diátlov en los montes Urales del norte',
      summary: List.filled(8, 'Un resumen largo del caso.').join(' '),
      statusLabel: 'Reabierto por la fiscalía regional (2019)',
    );

    for (final size in [_phone, _desktop]) {
      testWidgets('a ${size.width.toInt()} × ${size.height.toInt()}', (
        tester,
      ) async {
        await _pumpHero(tester, longCase, size: size);

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('datos pendientes', () {
    testWidgets('por defecto pinta el caso exactamente como siempre', (
      tester,
    ) async {
      await _pumpHero(tester, _case());

      expect(find.byKey(DossierHeroKeys.ghostYear), findsOneWidget);
      expect(find.text('pendiente'), findsNothing);
      expect(find.text('Resumen pendiente.'), findsNothing);
    });

    testWidgets('dice pendiente donde falta el dato y no pinta año fantasma', (
      tester,
    ) async {
      await _pumpHero(
        tester,
        _case(),
        pending: const DossierPending(
          year: true,
          category: true,
          status: true,
          region: true,
          country: true,
          summary: true,
        ),
      );

      expect(find.byKey(DossierHeroKeys.ghostYear), findsNothing);
      expect(find.text('Asesinos en serie'), findsNothing);
      expect(find.text('Sin resolver'), findsNothing);
      expect(find.text('1968'), findsNothing);
      expect(find.text('· PENDIENTE · PENDIENTE · PENDIENTE'), findsOneWidget);
      expect(find.text('Resumen pendiente.'), findsOneWidget);
      expect(find.text('pendiente'), findsNWidgets(2));
    });
  });
}
