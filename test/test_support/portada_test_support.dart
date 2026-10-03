import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';
import 'package:true_app/features/home/presentation/portada/portada_hero.dart';
import 'package:true_app/features/home/presentation/portada/portada_hero_keys.dart';

const Size laptopSize = Size(1280, 720);
const Size desktopSize = Size(1440, 900);
const Size fullHdSize = Size(1920, 1080);

const Duration slideInterval = Duration(seconds: 7);
const Duration exitDuration = Duration(milliseconds: 350);
const Duration enterDelay = Duration(milliseconds: 450);
const Duration enterDuration = Duration(milliseconds: 900);

TrueCrimeCase portadaCase({
  required String id,
  required String title,
  CaseCategory category = CaseCategory.serialKiller,
  CaseStatus status = CaseStatus.open,
  String? statusLabel,
  String city = 'San Francisco',
  String country = 'United States',
  int year = 1968,
  double latitude = 37.77,
  double longitude = -122.42,
  String summary = 'Resumen breve del caso.',
}) {
  return TrueCrimeCase(
    id: id,
    slug: id,
    title: title,
    category: category,
    country: country,
    countryCode: 'XX',
    regionOrCity: city,
    year: year,
    latitude: latitude,
    longitude: longitude,
    summary: summary,
    tags: const [],
    sources: const [],
    status: status,
    statusLabel: statusLabel,
  );
}

final List<TrueCrimeCase> portadaCases = [
  portadaCase(id: 'zodiac', title: 'Zodiac Killer'),
  portadaCase(
    id: 'isdal',
    title: 'La mujer de Isdal',
    category: CaseCategory.unsolved,
    status: CaseStatus.inProgress,
    city: 'Bergen',
    country: 'Noruega',
    year: 1970,
    latitude: 60.39,
    longitude: 5.32,
    summary: 'Una mujer sin identificar hallada en un valle de Noruega.',
  ),
  portadaCase(
    id: 'somerton',
    title: 'El hombre de Somerton',
    category: CaseCategory.unsolved,
    city: 'Adelaida',
    country: 'Australia',
    year: 1948,
    latitude: -34.92,
    longitude: 138.6,
    summary: 'Un hombre sin identificar en una playa australiana.',
  ),
  portadaCase(
    id: 'madeleine',
    title: 'Madeleine McCann',
    category: CaseCategory.kidnapping,
    status: CaseStatus.inProgress,
    statusLabel: 'Reabierto (2020)',
    city: 'Praia da Luz',
    country: 'Portugal',
    year: 2007,
    latitude: 37.09,
    longitude: -8.72,
    summary: 'La desaparición de una niña británica en vacaciones.',
  ),
  portadaCase(
    id: 'dyatlov',
    title: 'Paso Diátlov',
    category: CaseCategory.isolatedMurder,
    status: CaseStatus.solved,
    city: 'Urales',
    country: 'Rusia',
    year: 1959,
    latitude: 61.75,
    longitude: 59.45,
    summary: 'Nueve excursionistas muertos en los Urales.',
  ),
];

final TrueCrimeCase portadaExtraCase = portadaCase(
  id: 'dahlia',
  title: 'Black Dahlia',
  category: CaseCategory.unsolved,
  city: 'Los Angeles',
  year: 1947,
  latitude: 34.05,
  longitude: -118.24,
);

final List<TrueCrimeCase> portadaAllCases = [
  ...portadaCases,
  portadaExtraCase,
];

// Dos destacados a ambos lados del antimeridiano: el giro debe ir por el camino corto.
final List<TrueCrimeCase> antimeridianCases = [
  portadaCase(id: 'east', title: 'Este', latitude: 10, longitude: 170),
  portadaCase(id: 'west', title: 'Oeste', latitude: 10, longitude: -170),
];

class PortadaCallbacks {
  final List<TrueCrimeCase> opened = [];
  final List<TrueCrimeCase> explored = [];
}

Widget buildPortadaHero({
  required PortadaCallbacks callbacks,
  List<TrueCrimeCase>? featured,
  List<TrueCrimeCase>? allCases,
  Size size = desktopSize,
  double textScale = 1,
  bool reduceMotion = false,
  int initialIndex = 0,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(
        size: size,
        disableAnimations: reduceMotion,
        textScaler: TextScaler.linear(textScale),
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox.fromSize(
          size: size,
          child: PortadaHero(
            featured: featured ?? portadaCases,
            allCases: allCases ?? portadaAllCases,
            initialIndex: initialIndex,
            onOpenCase: callbacks.opened.add,
            onExploreCase: callbacks.explored.add,
          ),
        ),
      ),
    ),
  );
}

Future<PortadaCallbacks> pumpPortadaHero(
  WidgetTester tester, {
  List<TrueCrimeCase>? featured,
  List<TrueCrimeCase>? allCases,
  Size size = desktopSize,
  double textScale = 1,
  bool reduceMotion = false,
  int initialIndex = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final callbacks = PortadaCallbacks();
  await tester.pumpWidget(
    buildPortadaHero(
      callbacks: callbacks,
      featured: featured,
      allCases: allCases,
      size: size,
      textScale: textScale,
      reduceMotion: reduceMotion,
      initialIndex: initialIndex,
    ),
  );
  return callbacks;
}

Future<void> disposePortadaHero(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox.shrink());

Future<void> tapTab(WidgetTester tester, int index) async {
  await tester.tap(find.byKey(PortadaHeroKeys.tab(index)));
  await tester.pump();
}

double contentOpacity(WidgetTester tester, String caseId) => tester
    .widget<FadeTransition>(find.byKey(PortadaHeroKeys.content(caseId)))
    .opacity
    .value;

double ghostOpacity(WidgetTester tester, String caseId) => tester
    .widget<FadeTransition>(find.byKey(PortadaHeroKeys.ghostYear(caseId)))
    .opacity
    .value;

Finder contentOf(String caseId) => find.byKey(PortadaHeroKeys.content(caseId));

// Fracción rellenada de la barra de una pestaña: ancho transformado / ancho de la pista.
double tabFill(WidgetTester tester, int index) {
  final fill = find.byKey(PortadaHeroKeys.tabFill(index));
  final track = find.ancestor(of: fill, matching: find.byType(ClipRRect));
  final filled = tester.getBottomRight(fill).dx - tester.getTopLeft(fill).dx;
  final full = tester.getSize(track.first).width;
  return filled / full;
}

DsGlobeScene globeScene(WidgetTester tester) =>
    tester.widget<DsGlobeScene>(find.byType(DsGlobeScene));

// Cámara de portada esperada para un caso, partiendo de `currentGy`.
DsGlobeCamera expectedCamera(TrueCrimeCase crimeCase, double currentGy) =>
    DsGlobeCameraTargets.cover(
      latitude: crimeCase.latitude,
      longitude: crimeCase.longitude,
      currentGy: currentGy,
    );

Future<void> pumpStep(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 50);
  var elapsed = Duration.zero;
  while (elapsed < total) {
    final next = total - elapsed < step ? total - elapsed : step;
    await tester.pump(next);
    elapsed += next;
  }
}
