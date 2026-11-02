import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';
import 'package:true_app/features/cases/presentation/dossier/dossier_facts.dart';
import 'package:true_app/features/cases/presentation/dossier/dossier_facts_keys.dart';
import 'package:true_app/features/cases/presentation/dossier/dossier_facts_pending.dart';

const Size _desktop = Size(1440, 900);
const Size _tablet = Size(1100, 800);
const Size _phone = Size(360, 780);

const String _victim = 'Al menos 5 víctimas confirmadas';

TrueCrimeCase _case({
  String? victim = _victim,
  CaseStatus status = CaseStatus.open,
  String? statusLabel,
}) {
  return TrueCrimeCase(
    id: 'zodiac',
    slug: 'zodiac',
    title: 'Zodiac',
    category: CaseCategory.serialKiller,
    country: 'EE. UU.',
    countryCode: 'US',
    regionOrCity: 'San Francisco',
    year: 1968,
    latitude: 37.77,
    longitude: -122.42,
    summary: 'Resumen.',
    tags: const [],
    sources: const [],
    status: status,
    statusLabel: statusLabel,
    victim: victim,
  );
}

Future<void> _pumpFacts(
  WidgetTester tester,
  TrueCrimeCase crimeCase, {
  int connections = 3,
  Size size = _desktop,
  DossierPending pending = DossierPending.none,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(size: size),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DossierFacts(
              crimeCase: crimeCase,
              connectionsCount: connections,
              pending: pending,
            ),
          ),
        ),
      ),
    ),
  );
}

Rect _rectOf(WidgetTester tester, Key key) => tester.getRect(find.byKey(key));

void main() {
  group('celdas', () {
    testWidgets('muestra año, lugar, víctimas, estado y conexiones', (
      tester,
    ) async {
      await _pumpFacts(tester, _case(), connections: 4);

      for (final label in [
        'AÑO',
        'LUGAR',
        'VÍCTIMAS',
        'ESTADO',
        'CONEXIONES',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('1968'), findsOneWidget);
      expect(find.text('San Francisco\nEE. UU.'), findsOneWidget);
      expect(find.text(_victim), findsOneWidget);
      expect(find.text('Sin resolver'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(DossierFactsKeys.connections),
          matching: find.text('4'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('prefiere el estado editorial libre al del enum', (
      tester,
    ) async {
      await _pumpFacts(tester, _case(statusLabel: 'Reabierto (2019)'));

      expect(
        find.descendant(
          of: find.byKey(DossierFactsKeys.status),
          matching: find.text('Reabierto (2019)'),
        ),
        findsOneWidget,
      );
      expect(find.text('Sin resolver'), findsNothing);
    });

    for (final victim in [null, '', '   ']) {
      testWidgets('sin víctima documentada («$victim») conserva la celda', (
        tester,
      ) async {
        await _pumpFacts(tester, _case(victim: victim));

        expect(find.text('VÍCTIMAS'), findsOneWidget);
        expect(find.byKey(DossierFactsKeys.victims), findsOneWidget);
        expect(find.text('No documentadas'), findsOneWidget);
        expect(find.text('AÑO'), findsOneWidget);
        expect(find.text('CONEXIONES'), findsOneWidget);
      });
    }

    testWidgets('las etiquetas mono miden al menos 11 px', (tester) async {
      await _pumpFacts(tester, _case(), size: _phone);

      for (final label in [
        'AÑO',
        'LUGAR',
        'VÍCTIMAS',
        'ESTADO',
        'CONEXIONES',
      ]) {
        final size = tester.widget<Text>(find.text(label)).style!.fontSize!;
        expect(size, greaterThanOrEqualTo(11), reason: label);
      }
    });
  });

  testWidgets('usa las familias tipográficas empaquetadas', (tester) async {
    await _pumpFacts(tester, _case());
    expect(
      tester.widget<Text>(find.text('AÑO')).style!.fontFamily,
      'IBMPlexMono',
    );
    expect(
      tester.widget<Text>(find.text('1968')).style!.fontFamily,
      'NotoSerifDisplay',
    );
  });

  group('rejilla', () {
    testWidgets('en escritorio las cinco celdas van en una fila', (
      tester,
    ) async {
      await _pumpFacts(tester, _case());

      final keys = [
        DossierFactsKeys.year,
        DossierFactsKeys.place,
        DossierFactsKeys.victims,
        DossierFactsKeys.status,
        DossierFactsKeys.connections,
      ];
      final tops = keys.map((key) => _rectOf(tester, key).top).toSet();
      expect(tops, hasLength(1));
      for (var i = 1; i < keys.length; i++) {
        expect(
          _rectOf(tester, keys[i]).left,
          greaterThan(_rectOf(tester, keys[i - 1]).left),
        );
      }
    });

    for (final size in [_tablet, _phone]) {
      testWidgets('por debajo de 1200 px pasa a dos columnas '
          '(${size.width.toInt()} px)', (tester) async {
        await _pumpFacts(tester, _case(), size: size);

        final year = _rectOf(tester, DossierFactsKeys.year);
        final place = _rectOf(tester, DossierFactsKeys.place);
        final victims = _rectOf(tester, DossierFactsKeys.victims);
        final status = _rectOf(tester, DossierFactsKeys.status);

        expect(place.top, year.top);
        expect(place.left, greaterThan(year.left));
        expect(victims.left, year.left);
        expect(victims.top, greaterThanOrEqualTo(year.bottom));
        expect(status.left, place.left);
        expect(status.top, victims.top);
      });
    }
  });

  group('sin desbordes', () {
    final longCase = _case(
      victim: List.filled(6, 'Víctimas nombradas con respeto.').join(' '),
      statusLabel: 'Reabierto por la fiscalía regional (2019)',
    );

    for (final size in [_phone, _desktop]) {
      testWidgets('a ${size.width.toInt()} × ${size.height.toInt()}', (
        tester,
      ) async {
        await _pumpFacts(tester, longCase, connections: 128, size: size);

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('datos pendientes', () {
    testWidgets('por defecto no hay ninguna celda pendiente', (tester) async {
      await _pumpFacts(tester, _case());

      expect(find.text('pendiente'), findsNothing);
    });

    testWidgets('las celdas sin dato dicen pendiente, sin valores inventados', (
      tester,
    ) async {
      await _pumpFacts(
        tester,
        _case(),
        pending: const DossierPending(
          year: true,
          region: true,
          country: true,
          status: true,
          victims: true,
        ),
      );

      expect(find.text('1968'), findsNothing);
      expect(find.text('San Francisco\nEE. UU.'), findsNothing);
      expect(find.text('Sin resolver'), findsNothing);
      expect(find.text('pendiente\npendiente'), findsOneWidget);
      expect(find.text('pendiente'), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  });
}
