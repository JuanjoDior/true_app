import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_connection.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';
import 'package:true_app/features/cases/presentation/design/case_connection_design.dart';
import 'package:true_app/features/cases/presentation/design/case_design_mapping.dart';
import 'package:true_app/features/cases/presentation/dossier/dossier_facts_pending.dart';
import 'package:true_app/features/cases/presentation/dossier/dossier_map_band.dart';
import 'package:true_app/features/cases/presentation/dossier/dossier_map_keys.dart';

const Size _desktop = Size(1440, 900);
const Size _phone = Size(360, 780);

TrueCrimeCase _case({
  required String id,
  required String slug,
  required String title,
  CaseCategory category = CaseCategory.serialKiller,
  String city = 'San Francisco',
  String country = 'EE. UU.',
  int year = 1968,
  double latitude = 37.77,
  double longitude = -122.42,
}) {
  return TrueCrimeCase(
    id: id,
    slug: slug,
    title: title,
    category: category,
    country: country,
    countryCode: 'XX',
    regionOrCity: city,
    year: year,
    latitude: latitude,
    longitude: longitude,
    summary: 'Resumen.',
    tags: const [],
    sources: const [],
  );
}

final TrueCrimeCase _zodiac = _case(
  id: 'case-zodiac',
  slug: 'zodiac-killer',
  title: 'Zodiac',
);
final TrueCrimeCase _dahlia = _case(
  id: 'case-dahlia',
  slug: 'black-dahlia',
  title: 'Black Dahlia',
  category: CaseCategory.unsolved,
  city: 'Los Ángeles',
  year: 1947,
  latitude: 34.05,
  longitude: -118.24,
);
final TrueCrimeCase _isdal = _case(
  id: 'case-isdal',
  slug: 'mujer-de-isdal',
  title: 'La mujer de Isdal',
  category: CaseCategory.unsolved,
  city: 'Bergen',
  country: 'Noruega',
  year: 1970,
  latitude: 60.39,
  longitude: 5.32,
);
final TrueCrimeCase _lonely = _case(
  id: 'case-lonely',
  slug: 'caso-solitario',
  title: 'Caso solitario',
  category: CaseCategory.kidnapping,
  city: 'Lima',
  country: 'Perú',
  year: 1990,
  latitude: -12.05,
  longitude: -77.04,
);

final List<TrueCrimeCase> _cases = [_zodiac, _dahlia, _isdal, _lonely];

const List<CaseConnection> _connections = [
  CaseConnection(
    aId: 'case-zodiac',
    bId: 'case-dahlia',
    relation: 'California · sin resolver',
  ),
  CaseConnection(
    aId: 'case-isdal',
    bId: 'case-zodiac',
    relation: 'Cifrados sin descifrar',
  ),
];

Offset _bandPoint(TrueCrimeCase c) =>
    DsMapProjection.project(c.latitude, c.longitude) +
    const Offset(0, DsMapProjection.verticalOffsetDesktopDossierBand);

DsMapCamera _caseCamera(TrueCrimeCase c) => DsMapCameraTargets.focusCase(
  casePoint: _bandPoint(c),
  layout: DsMapLayout.desktop,
);

class _Host {
  final List<String> openedSlugs = [];
  final ScrollController scroll = ScrollController();
}

Future<_Host> _pumpBand(
  WidgetTester tester, {
  TrueCrimeCase? dossier,
  List<TrueCrimeCase>? cases,
  List<CaseConnection> connections = _connections,
  Size size = _desktop,
  bool reduceMotion = false,
  bool productionShell = false,
  DossierPending pending = DossierPending.none,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final host = _Host();
  addTearDown(host.scroll.dispose);
  final content = Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(size: size, disableAnimations: reduceMotion),
      child: SingleChildScrollView(
        controller: host.scroll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DossierMapBand(
              dossierCase: dossier ?? _zodiac,
              cases: cases ?? _cases,
              connections: connections,
              onOpenCase: host.openedSlugs.add,
              pending: pending,
            ),
            const SizedBox(height: 1200),
          ],
        ),
      ),
    ),
  );
  await tester.pumpWidget(
    productionShell
        ? MaterialApp(
            theme: DsTheme.build(),
            home: Scaffold(body: content),
          )
        : content,
  );
  return host;
}

DsMapScene _scene(WidgetTester tester) =>
    tester.widget<DsMapScene>(find.byType(DsMapScene));

Finder _inCard(Finder matching) => find.descendant(
  of: find.byKey(DossierMapKeys.locationCard),
  matching: matching,
);

Future<void> _flyToCase(WidgetTester tester) =>
    tester.pump(DossierMapBand.flyToCaseDelay);

void main() {
  setUpAll(() async {
    final loader = FontLoader('NotoSans')
      ..addFont(rootBundle.load('assets/fonts/NotoSans-SemiBold.ttf'));
    await loader.load();
  });

  group('cámara', () {
    testWidgets('empieza en Mundo y sigue en Mundo justo antes de 1100 ms', (
      tester,
    ) async {
      await _pumpBand(tester);

      expect(
        _scene(tester).camera,
        DsMapCameraTargets.world(view: DsMapWorldView.desktop),
      );
      await tester.pump(const Duration(milliseconds: 1099));
      expect(
        _scene(tester).camera,
        DsMapCameraTargets.world(view: DsMapWorldView.desktop),
      );
    });

    testWidgets('a los 1100 ms vuela a Caso sobre el caso del expediente', (
      tester,
    ) async {
      await _pumpBand(tester);
      await _flyToCase(tester);

      expect(DossierMapBand.flyToCaseDelay, const Duration(milliseconds: 1100));
      expect(_scene(tester).camera, _caseCamera(_zodiac));
      expect(
        _scene(tester).verticalOffset,
        DsMapProjection.verticalOffsetDesktopDossierBand,
      );
    });

    testWidgets('con movimiento reducido va directo a Caso', (tester) async {
      await _pumpBand(tester, reduceMotion: true);

      expect(_scene(tester).camera, _caseCamera(_zodiac));
    });

    testWidgets('en estrecho usa los encuadres móviles de banda', (
      tester,
    ) async {
      await _pumpBand(tester, size: _phone);

      expect(_scene(tester).mobile, isTrue);
      expect(
        _scene(tester).camera,
        DsMapCameraTargets.world(view: DsMapWorldView.mobileBand),
      );
      await _flyToCase(tester);
      expect(
        _scene(tester).camera,
        DsMapCameraTargets.focusCase(
          casePoint: DsMapProjection.project(
            _zodiac.latitude,
            _zodiac.longitude,
          ),
          layout: DsMapLayout.mobile,
        ),
      );
    });
  });

  group('escena', () {
    testWidgets('marcadores de todos los casos y lista estable entre builds', (
      tester,
    ) async {
      await _pumpBand(tester);
      final first = _scene(tester).markers;

      expect(first, [for (final c in _cases) c.toMapMarker()]);
      await tester.tap(find.text('Conexiones'));
      await tester.pump();
      expect(identical(_scene(tester).markers, first), isTrue);
    });

    testWidgets('en Caso resalta el enfocado, sus conectados y sus arcos', (
      tester,
    ) async {
      await _pumpBand(tester);
      await _flyToCase(tester);
      final scene = _scene(tester);

      expect(scene.selectedId, 'case-zodiac');
      expect(scene.relatedIds, {'case-dahlia', 'case-isdal'});
      expect(
        scene.connections,
        connectionsForCase('case-zodiac', _connections),
      );
      expect(scene.showConnectionLabels, isFalse);
    });

    testWidgets('pulsar un marcador enfoca ese caso y vuelve a Caso', (
      tester,
    ) async {
      await _pumpBand(tester);
      await tester.tap(find.text('Mundo'));
      await tester.pump();

      _scene(tester).onMarkerTap!('case-isdal');
      await tester.pump();

      expect(_inCard(find.text('La mujer de Isdal')), findsOneWidget);
      expect(_scene(tester).camera, _caseCamera(_isdal));
      expect(_scene(tester).selectedId, 'case-isdal');
    });

    testWidgets('sin atribución de teselas', (tester) async {
      await _pumpBand(tester);

      expect(find.textContaining('Esri'), findsNothing);
    });
  });

  group('vistas', () {
    for (final size in [_desktop, _phone]) {
      testWidgets(
        'etiquetas renderizadas completas a ${size.width.toInt()} px',
        (tester) async {
          await _pumpBand(tester, size: size, productionShell: true);
          await _flyToCase(tester);
          final switcher = find.byKey(DossierMapKeys.viewSwitcher);
          for (final label in ['Caso', 'Conexiones', 'Mundo']) {
            final text = find.descendant(
              of: switcher,
              matching: find.text(label),
            );
            expect(text, findsOneWidget);
            final paragraph = tester.renderObject<RenderParagraph>(text);
            expect(paragraph.didExceedMaxLines, isFalse, reason: label);
            final measured = TextPainter(
              text: paragraph.text,
              textDirection: TextDirection.ltr,
              textScaler: paragraph.textScaler,
              maxLines: 1,
            )..layout();
            expect(
              paragraph.constraints.maxWidth,
              greaterThanOrEqualTo(measured.width + 12),
              reason:
                  '$label necesita margen para métricas reales del navegador',
            );
            measured.dispose();
            final button = find.ancestor(
              of: text,
              matching: find.byType(DsPressable),
            );
            expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
            expect(tester.getSize(button).width, greaterThanOrEqualTo(44));
          }
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('selector conserva semántica y navegación por teclado', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpBand(tester);
      expect(
        tester.getSemantics(find.text('Conexiones')),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          isInMutuallyExclusiveGroup: true,
          hasSelectedState: true,
          hasTapAction: true,
          label: 'Conexiones',
        ),
      );
      final caseButton = find.ancestor(
        of: find.text('Caso'),
        matching: find.byType(DsPressable),
      );
      tester.widget<DsPressable>(caseButton).focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(_scene(tester).showConnectionLabels, isTrue);
      semantics.dispose();
    });

    testWidgets('el segmentado ofrece Caso · Conexiones · Mundo', (
      tester,
    ) async {
      await _pumpBand(tester);
      final switcher = find.byKey(DossierMapKeys.viewSwitcher);

      for (final label in ['Caso', 'Conexiones', 'Mundo']) {
        expect(
          find.descendant(of: switcher, matching: find.text(label)),
          findsOneWidget,
        );
      }
    });

    testWidgets('Conexiones encuadra el caso y sus conectados con etiquetas', (
      tester,
    ) async {
      await _pumpBand(tester);
      await tester.tap(find.text('Conexiones'));
      await tester.pump();

      expect(
        _scene(tester).camera,
        DsMapCameraTargets.connections(
          points: [
            _bandPoint(_zodiac),
            _bandPoint(_dahlia),
            _bandPoint(_isdal),
          ],
          layout: DsMapLayout.desktop,
        ),
      );
      expect(_scene(tester).showConnectionLabels, isTrue);
    });

    testWidgets('Mundo vuelve al encuadre completo sin arcos', (tester) async {
      await _pumpBand(tester);
      await _flyToCase(tester);
      await tester.tap(find.text('Mundo'));
      await tester.pump();

      expect(
        _scene(tester).camera,
        DsMapCameraTargets.world(view: DsMapWorldView.desktop),
      );
      expect(_scene(tester).connections, isEmpty);
      expect(_scene(tester).relatedIds, isEmpty);
    });

    testWidgets('elegir una vista antes de 1100 ms no se pisa con el vuelo', (
      tester,
    ) async {
      await _pumpBand(tester);
      await tester.tap(find.text('Conexiones'));
      await tester.pump();
      await _flyToCase(tester);

      expect(_scene(tester).showConnectionLabels, isTrue);
    });
  });

  group('ficha de ubicación', () {
    testWidgets('muestra el caso del expediente con lugar, año y coordenadas', (
      tester,
    ) async {
      await _pumpBand(tester);

      expect(_inCard(find.text('UBICACIÓN')), findsOneWidget);
      expect(_inCard(find.text('Zodiac')), findsOneWidget);
      expect(
        _inCard(find.text('San Francisco · EE. UU. · 1968')),
        findsOneWidget,
      );
      expect(_inCard(find.text('LATITUD')), findsOneWidget);
      expect(_inCard(find.text('LONGITUD')), findsOneWidget);
      expect(_inCard(find.text('37.77° N')), findsOneWidget);
      expect(_inCard(find.text('122.42° O')), findsOneWidget);
      expect(_inCard(find.text('CASOS CONECTADOS')), findsOneWidget);
    });

    testWidgets('sin «Abrir expediente» para el caso del expediente', (
      tester,
    ) async {
      await _pumpBand(tester);

      expect(find.byKey(DossierMapKeys.openCase), findsNothing);
      expect(find.text('Abrir expediente'), findsNothing);
    });

    testWidgets(
      'un caso conectado enfoca ese caso y abre su expediente por slug',
      (tester) async {
        final host = await _pumpBand(tester);
        await tester.tap(find.text('Mundo'));
        await tester.pump();

        await tester.tap(
          find.byKey(DossierMapKeys.connectedCase('case-dahlia')),
        );
        await tester.pump();

        expect(_inCard(find.text('Black Dahlia')), findsOneWidget);
        expect(
          _inCard(find.text('Los Ángeles · EE. UU. · 1947')),
          findsOneWidget,
        );
        expect(_scene(tester).camera, _caseCamera(_dahlia));

        await tester.tap(find.byKey(DossierMapKeys.openCase));
        expect(host.openedSlugs, ['black-dahlia']);
      },
    );

    testWidgets('volver al caso del expediente oculta «Abrir expediente»', (
      tester,
    ) async {
      await _pumpBand(tester);
      await tester.tap(find.byKey(DossierMapKeys.connectedCase('case-dahlia')));
      await tester.pump();
      await tester.tap(find.byKey(DossierMapKeys.connectedCase('case-zodiac')));
      await tester.pump();

      expect(_inCard(find.text('Zodiac')), findsOneWidget);
      expect(find.byKey(DossierMapKeys.openCase), findsNothing);
    });

    testWidgets('sin conexiones avisa con el texto del artboard', (
      tester,
    ) async {
      await _pumpBand(tester, dossier: _lonely);

      expect(
        _inCard(find.text('Sin conexiones documentadas.')),
        findsOneWidget,
      );
    });

    testWidgets('ignora conexiones con casos no publicados', (tester) async {
      await _pumpBand(
        tester,
        connections: const [
          CaseConnection(aId: 'case-zodiac', bId: 'case-draft', relation: 'X'),
        ],
      );

      expect(
        _inCard(find.text('Sin conexiones documentadas.')),
        findsOneWidget,
      );
    });
  });

  testWidgets('la ubicación usa la serif empaquetada', (tester) async {
    await _pumpBand(tester);
    expect(
      tester.widget<Text>(_inCard(find.text('Zodiac'))).style!.fontFamily,
      'NotoSerifDisplay',
    );
  });

  group('leyenda', () {
    testWidgets('las cuatro categorías en escritorio', (tester) async {
      await _pumpBand(tester);
      final legend = find.byKey(DossierMapKeys.legend);

      for (final label in [
        'Asesinos en serie',
        'Asesinato aislado',
        'Secuestro',
        'Caso sin resolver',
      ]) {
        expect(
          find.descendant(of: legend, matching: find.text(label)),
          findsOneWidget,
        );
      }
    });
  });

  group('accesibilidad', () {
    testWidgets('los casos conectados son botones accesibles', (tester) async {
      await _pumpBand(tester);
      final button = find.byKey(DossierMapKeys.connectedCase('case-dahlia'));
      expect(
        tester.getSemantics(button),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          label: 'Black Dahlia\nCalifornia · sin resolver',
        ),
      );
    });

    testWidgets('el selector comunica la vista activa', (tester) async {
      await _pumpBand(tester);
      final world = find.ancestor(
        of: find.text('Mundo'),
        matching: find.byType(DsPressable),
      );
      final focused = find.ancestor(
        of: find.text('Caso'),
        matching: find.byType(DsPressable),
      );
      expect(tester.widget<DsPressable>(world).selected, isTrue);
      await tester.tap(find.text('Caso'));
      await tester.pump();
      expect(tester.widget<DsPressable>(focused).selected, isTrue);
    });
  });

  group('gestos', () {
    testWidgets('arrastrar en vertical sobre el mapa desplaza la página', (
      tester,
    ) async {
      final host = await _pumpBand(tester);

      await tester.dragFrom(
        tester.getCenter(find.byType(DsMapScene)),
        const Offset(0, -300),
      );
      await tester.pump();

      expect(host.scroll.offset, greaterThan(0));
    });

    testWidgets('arrastrar en vertical sobre la ficha desplaza la página', (
      tester,
    ) async {
      final host = await _pumpBand(tester);

      await tester.dragFrom(
        tester.getCenter(
          find.byKey(DossierMapKeys.connectedCase('case-dahlia')),
        ),
        const Offset(0, -300),
      );
      await tester.pump();

      expect(host.scroll.offset, greaterThan(0));
      expect(_inCard(find.text('Zodiac')), findsOneWidget);
    });
  });

  group('maquetación', () {
    testWidgets('escritorio: banda de 600 y ficha de 360 sin desbordes', (
      tester,
    ) async {
      await _pumpBand(tester);
      await _flyToCase(tester);

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(DossierMapKeys.band)).height,
        DossierMapBand.heightDesktop,
      );
      expect(
        tester.getSize(find.byKey(DossierMapKeys.locationCard)).width,
        DossierMapBand.cardWidthDesktop,
      );
    });

    testWidgets('360 px: la ficha cabe en el ancho y no hay desbordes', (
      tester,
    ) async {
      await _pumpBand(tester, size: _phone);
      await _flyToCase(tester);

      expect(tester.takeException(), isNull);
      final card = tester.getRect(find.byKey(DossierMapKeys.locationCard));
      expect(card.left, greaterThanOrEqualTo(0));
      expect(card.right, lessThanOrEqualTo(_phone.width));
      expect(
        tester.getSize(find.byKey(DossierMapKeys.viewSwitcher)).width,
        lessThanOrEqualTo(_phone.width),
      );
    });

    testWidgets('los casos conectados miden al menos 44 px de alto', (
      tester,
    ) async {
      await _pumpBand(tester);

      expect(
        tester
            .getSize(find.byKey(DossierMapKeys.connectedCase('case-dahlia')))
            .height,
        greaterThanOrEqualTo(44),
      );
    });

    testWidgets('muchas conexiones en escritorio no desbordan la banda', (
      tester,
    ) async {
      final many = [
        for (var i = 0; i < 12; i++)
          _case(
            id: 'extra-$i',
            slug: 'extra-$i',
            title: 'Caso conectado número $i',
            latitude: 10.0 + i,
            longitude: 20.0 + i,
          ),
      ];
      await _pumpBand(
        tester,
        cases: [..._cases, ...many],
        connections: [
          for (final c in many)
            CaseConnection(aId: 'case-zodiac', bId: c.id, relation: 'Vínculo'),
        ],
      );

      expect(tester.takeException(), isNull);
      final band = tester.getRect(find.byKey(DossierMapKeys.band));
      final card = tester.getRect(find.byKey(DossierMapKeys.locationCard));
      expect(card.bottom, lessThanOrEqualTo(band.bottom));
    });
  });

  group('coordenadas pendientes', () {
    testWidgets('sin coordenadas se queda en Mundo y dice pendiente', (
      tester,
    ) async {
      await _pumpBand(
        tester,
        dossier: _case(
          id: 'draft',
          slug: 'draft',
          title: 'Borrador',
          latitude: 0,
          longitude: 0,
        ),
        cases: _cases,
        connections: const [],
        pending: const DossierPending(
          coordinates: true,
          region: true,
          country: true,
          year: true,
        ),
      );
      await _flyToCase(tester);

      expect(
        _scene(tester).camera,
        DsMapCameraTargets.world(view: DsMapWorldView.desktop),
      );
      expect(_scene(tester).selectedId, isNull);
      expect(_inCard(find.text('pendiente')), findsNWidgets(2));
      expect(_inCard(find.textContaining('0.00')), findsNothing);
      expect(
        _inCard(find.text('pendiente · pendiente · pendiente')),
        findsOneWidget,
      );
    });

    testWidgets('otro caso enfocado muestra sus propias coordenadas', (
      tester,
    ) async {
      await _pumpBand(
        tester,
        dossier: _zodiac,
        pending: const DossierPending(coordinates: true),
      );
      await _flyToCase(tester);
      expect(_inCard(find.text('pendiente')), findsNWidgets(2));

      // Al enfocar otro caso, lo pendiente deja de aplicar: se ven sus datos.
      await tester.tap(find.byKey(DossierMapKeys.connectedCase('case-dahlia')));
      await tester.pump();

      expect(_inCard(find.text('pendiente')), findsNothing);
      expect(_inCard(find.text('34.05° N')), findsOneWidget);
      expect(_inCard(find.text('118.24° O')), findsOneWidget);
    });
  });
}
