import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/config/map_config.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/data/reverse_geocoder.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/resolved_place.dart';
import 'package:true_app/features/cases/presentation/intake/sections/location_section.dart';

class _FakeCaseDraftsStore implements CaseDraftsStore {
  List<CaseDraft> saved = const <CaseDraft>[];

  @override
  Future<List<CaseDraft>> loadDrafts() async => saved;

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async {
    saved = drafts;
  }
}

/// Geocodificador de mentira: responde lo que le digan, sin salir a la red.
class _FakeReverseGeocoder implements ReverseGeocoder {
  _FakeReverseGeocoder({this.place, this.gate, List<ResolvedPlace?>? places})
      : _places = places;

  final ResolvedPlace? place;

  /// Respuestas en orden, para encadenar varias marcas de punto.
  final List<ResolvedPlace?>? _places;

  /// Permite dejar la respuesta en el aire para observar el estado "buscando".
  final Completer<void>? gate;

  final calls = <(double, double)>[];

  @override
  Future<ResolvedPlace?> resolve(double latitude, double longitude) async {
    calls.add((latitude, longitude));
    if (gate != null) {
      await gate!.future;
    }
    final queued = _places;
    if (queued == null) {
      return place;
    }
    return queued[(calls.length - 1).clamp(0, queued.length - 1)];
  }
}

Future<(ProviderContainer, _FakeCaseDraftsStore)> _pumpSection(
  WidgetTester tester, {
  CaseDraft Function(String draftId)? draft,
  ReverseGeocoder? geocoder,
  double? width,
}) async {
  final store = _FakeCaseDraftsStore();
  final container = ProviderContainer(
    overrides: [
      caseDraftsStoreProvider.overrideWithValue(store),
      // Sin teselas: el mapa no sale a la red en los tests.
      mapConfigProvider.overrideWithValue(MapConfig.testing()),
      if (geocoder != null)
        reverseGeocoderProvider.overrideWithValue(geocoder),
    ],
  );
  addTearDown(container.dispose);

  await container.read(caseDraftsProvider.future);
  final draftId = await container.read(caseDraftsProvider.notifier).createDraft();
  if (draft != null) {
    await container.read(caseDraftsProvider.notifier).updateDraft(draft(draftId));
  }
  container.read(editingDraftIdProvider.notifier).state = draftId;

  final section = width == null
      ? const LocationSection()
      : SizedBox(width: width, child: const LocationSection());

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: section),
        ),
      ),
    ),
  );
  await tester.pump();
  return (container, store);
}

/// Toca el centro del mapa, que es como Iván sitúa el caso.
///
/// `pumpAndSettle` no vale aquí: el reconocedor de gestos de flutter_map
/// espera para distinguir el tap del doble tap, así que hay que dejar correr
/// el reloj explícitamente.
Future<void> _tapMap(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('intake-location-map')));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Deja resolver la búsqueda del lugar, que es asíncrona.
Future<void> _settleLookup(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

/// Abre el bloque de ajuste manual, plegado por defecto.
Future<void> _openFineTuning(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('intake-location-fine-tuning')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('marking a point on the map stores the coordinates',
      (tester) async {
    final (container, store) = await _pumpSection(
      tester,
      geocoder: _FakeReverseGeocoder(),
    );

    await _tapMap(tester);
    await _settleLookup(tester);

    final saved = container.read(editingDraftProvider)!;
    expect(saved.latitude, isNotNull);
    expect(saved.longitude, isNotNull);
    // El autoguardado persiste el punto.
    expect(store.saved.single.latitude, saved.latitude);
  });

  testWidgets('the marked point fills in country, city and ISO code',
      (tester) async {
    final geocoder = _FakeReverseGeocoder(
      place: const ResolvedPlace(
        country: 'España',
        countryCode: 'ES',
        regionOrCity: 'A Coruña',
      ),
    );
    final (container, _) = await _pumpSection(tester, geocoder: geocoder);

    await _tapMap(tester);
    await _settleLookup(tester);

    final saved = container.read(editingDraftProvider)!;
    expect(saved.country, 'España');
    expect(saved.regionOrCity, 'A Coruña');
    expect(saved.countryCode, 'ES');
    // Se consultó el punto que se marcó.
    expect(geocoder.calls, hasLength(1));
  });

  testWidgets('a new point without a town clears the previous one',
      (tester) async {
    // Marcar A Coruña y luego un punto remoto que sólo resuelve país no debe
    // dejar la ciudad de un sitio junto al país de otro.
    final (container, _) = await _pumpSection(
      tester,
      geocoder: _FakeReverseGeocoder(places: const [
        ResolvedPlace(
          country: 'España',
          countryCode: 'ES',
          regionOrCity: 'A Coruña',
        ),
        ResolvedPlace(country: 'Chad', countryCode: 'TD'),
      ]),
    );

    await _tapMap(tester);
    await _settleLookup(tester);
    expect(container.read(editingDraftProvider)!.regionOrCity, 'A Coruña');

    await _tapMap(tester);
    await _settleLookup(tester);

    final saved = container.read(editingDraftProvider)!;
    expect(saved.country, 'Chad');
    expect(saved.countryCode, 'TD');
    expect(saved.regionOrCity, isNull);
  });

  testWidgets('the filled-in place is shown in the fields, not just stored',
      (tester) async {
    await _pumpSection(
      tester,
      geocoder: _FakeReverseGeocoder(
        place: const ResolvedPlace(
          country: 'España',
          countryCode: 'ES',
          regionOrCity: 'A Coruña',
        ),
      ),
    );

    await _tapMap(tester);
    await _settleLookup(tester);

    expect(find.text('España'), findsOneWidget);
    expect(find.text('A Coruña'), findsOneWidget);
  });

  testWidgets('keeps the coordinates when the place cannot be resolved',
      (tester) async {
    // Servicio caído o punto en mitad del mar: no debe perderse el punto ni
    // bloquearse el formulario.
    final (container, _) = await _pumpSection(
      tester,
      geocoder: _FakeReverseGeocoder(place: null),
    );

    await _tapMap(tester);
    await _settleLookup(tester);

    final saved = container.read(editingDraftProvider)!;
    expect(saved.latitude, isNotNull);
    expect(saved.country, isNull);
    expect(find.text('El país es obligatorio'), findsOneWidget);
  });

  testWidgets('shows that it is looking the place up while it waits',
      (tester) async {
    final gate = Completer<void>();
    await _pumpSection(
      tester,
      geocoder: _FakeReverseGeocoder(
        gate: gate,
        place: const ResolvedPlace(country: 'España', countryCode: 'ES'),
      ),
    );

    await _tapMap(tester);
    await tester.pump();

    expect(find.byKey(const Key('intake-geocoding-status')), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('intake-geocoding-status')), findsNothing);
  });

  testWidgets('shows the coordinates of the marked point', (tester) async {
    await _pumpSection(
      tester,
      draft: (draftId) => CaseDraft(
        draftId: draftId,
        latitude: 43.39,
        longitude: -8.41,
      ),
      geocoder: _FakeReverseGeocoder(),
    );

    expect(find.text('43.39° N · 8.41° O'), findsOneWidget);
  });

  testWidgets('says when no point has been marked yet', (tester) async {
    await _pumpSection(tester, geocoder: _FakeReverseGeocoder());

    expect(find.text('Sin punto marcado'), findsOneWidget);
  });

  testWidgets('still allows correcting the place by hand', (tester) async {
    final (container, _) = await _pumpSection(
      tester,
      geocoder: _FakeReverseGeocoder(),
    );

    await tester.enterText(
      find.byKey(const Key('intake-field-country-0')),
      'España',
    );
    await tester.enterText(
      find.byKey(const Key('intake-field-region-or-city-0')),
      'Cuenca',
    );
    await tester.pump();

    final saved = container.read(editingDraftProvider)!;
    expect(saved.country, 'España');
    expect(saved.regionOrCity, 'Cuenca');
  });

  testWidgets('keeps coordinates editable by hand under fine tuning',
      (tester) async {
    final (container, _) = await _pumpSection(
      tester,
      geocoder: _FakeReverseGeocoder(),
    );

    await _openFineTuning(tester);
    await tester.enterText(
      find.byKey(const Key('intake-field-latitude-0')),
      '43.39',
    );
    await tester.enterText(
      find.byKey(const Key('intake-field-country-code-0')),
      'ES',
    );
    await tester.pump();

    final saved = container.read(editingDraftProvider)!;
    expect(saved.latitude, 43.39);
    expect(saved.countryCode, 'ES');
  });

  testWidgets('reports the required-field errors on an empty location',
      (tester) async {
    await _pumpSection(tester, geocoder: _FakeReverseGeocoder());

    expect(find.text('El país es obligatorio'), findsOneWidget);
    expect(find.text('La región o ciudad es obligatoria'), findsOneWidget);

    await _openFineTuning(tester);
    expect(find.text('El código de país es obligatorio'), findsOneWidget);
    expect(find.text('La latitud es obligatoria'), findsOneWidget);
    expect(find.text('La longitud es obligatoria'), findsOneWidget);
  });

  testWidgets(
      'the coordinates line wraps instead of overflowing at 336px while resolving',
      (tester) async {
    final gate = Completer<void>();
    await _pumpSection(
      tester,
      width: 336,
      draft: (draftId) => CaseDraft(
        draftId: draftId,
        latitude: 43.39,
        longitude: -8.41,
      ),
      geocoder: _FakeReverseGeocoder(
        gate: gate,
        place: const ResolvedPlace(country: 'España', countryCode: 'ES'),
      ),
    );

    // Se dispara una búsqueda para forzar el estado "resolving: true" sin
    // que la respuesta llegue todavía.
    await _tapMap(tester);
    await tester.pump();

    expect(find.byKey(const Key('intake-coordinates-label')), findsOneWidget);
    expect(find.byKey(const Key('intake-geocoding-status')), findsOneWidget);
    expect(tester.takeException(), isNull);

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets(
      'the fine-tuning fields do not overflow at the minimum supported width 360x640',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pumpSection(
      tester,
      draft: (draftId) => CaseDraft(
        draftId: draftId,
        latitude: 43.39,
        longitude: -8.41,
        countryCode: 'ES',
      ),
      geocoder: _FakeReverseGeocoder(),
    );

    await _openFineTuning(tester);

    expect(tester.takeException(), isNull);

    // El "sin desborde" por sí solo NO prueba nada aquí: los tres campos de
    // ajuste fino son `IntakeFieldSlot.flexible`, así que en la rama `Row` se
    // vuelven `Expanded` y ENCOGEN en lugar de desbordar. Sin esta medida de
    // ancho el test pasa igual con la fila sin apilar, que es justo la
    // regresión que debe cazar.
    final latitudeField = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>)
              .value
              .startsWith('intake-field-latitude-'),
    );
    expect(latitudeField, findsOneWidget);
    expect(
      tester.getSize(latitudeField).width,
      360,
      reason: 'Below Breakpoints.formRowStack the fine-tuning row must stack, '
          'giving each field the full width — not merely avoid an overflow.',
    );
  });
}
