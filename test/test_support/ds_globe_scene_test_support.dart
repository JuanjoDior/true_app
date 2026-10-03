import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

const Size desktop = Size(1440, 900);
const Size fullHd = Size(1920, 1080);

// Cámara de portada de frente al origen: el marcador `facing` queda en el centro.
final DsGlobeCamera coverCamera = DsGlobeCameraTargets.cover(
  latitude: 0,
  longitude: 0,
  currentGy: 0,
);
final DsGlobeCamera exploreCamera = DsGlobeCameraTargets.explore(
  latitude: 30,
  longitude: 40,
  currentGy: 0,
);

const double hitRadius = 22;
const double tolerance = 1e-6;
const Duration flyDuration = Duration(milliseconds: 1900);
const Duration haloFade = Duration(milliseconds: 1400);

// Con la cámara de portada: (1010, 520), z2 = 403.
const DsMapMarker facing = DsMapMarker(
  id: 'facing',
  label: 'Facing',
  latitude: 0,
  longitude: 0,
  color: Color(0xFFE5484D),
  year: 1970,
);
// (1249.4932, 520), z2 = 349.01.
const DsMapMarker east = DsMapMarker(
  id: 'east',
  label: 'East',
  latitude: 0,
  longitude: 30,
  color: Color(0xFF3E63DD),
  year: 1990,
);
// z2 = 69.98: delante y con etiqueta visible.
const DsMapMarker nearLimb = DsMapMarker(
  id: 'near-limb',
  label: 'Near limb',
  latitude: 0,
  longitude: 80,
  color: Color(0xFF30A46C),
  year: 2000,
);
// z2 = 35.12: delante pero sin etiqueta (umbral 40).
const DsMapMarker limb = DsMapMarker(
  id: 'limb',
  label: 'Limb',
  latitude: 0,
  longitude: 85,
  color: Color(0xFFF5A623),
  year: 2005,
);
// z2 = -343.7: cara trasera.
const DsMapMarker back = DsMapMarker(
  id: 'back',
  label: 'Back',
  latitude: 30,
  longitude: 170,
  color: Color(0xFF8E4EC6),
  year: 2010,
);

const List<DsMapMarker> sampleMarkers = [facing, east, nearLimb, limb, back];

DsGlobeProjection projectMarker(DsMapMarker marker, DsGlobeCamera camera) =>
    DsGlobeMath.project(
      DsGlobeMath.surfacePoint(
        latitude: marker.latitude,
        longitude: marker.longitude,
        radius: DsGlobeMath.radius + DsGlobeMath.markerElevation,
      ),
      gx: camera.gx,
      gy: camera.gy,
      center: camera.center,
      scale: camera.scale,
    );

Widget buildGlobeScene({
  Size size = desktop,
  List<DsMapMarker> markers = sampleMarkers,
  DsGlobeCamera? camera,
  String? selectedId,
  Set<String> relatedIds = const {},
  Set<String>? matchingIds,
  int? timelineYear,
  Color? haloColor,
  bool showLabels = true,
  ValueChanged<String>? onMarkerTap,
  bool disableAnimations = false,
  double textScale = 1,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(
        size: size,
        disableAnimations: disableAnimations,
        textScaler: TextScaler.linear(textScale),
      ),
      child: DsGlobeScene(
        markers: markers,
        camera: camera ?? coverCamera,
        selectedId: selectedId,
        relatedIds: relatedIds,
        matchingIds: matchingIds,
        timelineYear: timelineYear,
        haloColor: haloColor,
        showLabels: showLabels,
        onMarkerTap: onMarkerTap,
      ),
    ),
  );
}

Future<void> pumpGlobeScene(
  WidgetTester tester, {
  Size size = desktop,
  List<DsMapMarker> markers = sampleMarkers,
  DsGlobeCamera? camera,
  String? selectedId,
  Set<String> relatedIds = const {},
  Set<String>? matchingIds,
  int? timelineYear,
  Color? haloColor,
  bool showLabels = true,
  ValueChanged<String>? onMarkerTap,
  bool disableAnimations = false,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    buildGlobeScene(
      size: size,
      markers: markers,
      camera: camera,
      selectedId: selectedId,
      relatedIds: relatedIds,
      matchingIds: matchingIds,
      timelineYear: timelineYear,
      haloColor: haloColor,
      showLabels: showLabels,
      onMarkerTap: onMarkerTap,
      disableAnimations: disableAnimations,
      textScale: textScale,
    ),
  );
}

T painterOf<T extends CustomPainter>(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.byWidgetPredicate((w) => w is CustomPaint && w.painter is T),
            )
            .painter!
        as T;

Finder painterFinder<T extends CustomPainter>() =>
    find.byWidgetPredicate((w) => w is CustomPaint && w.painter is T);

DsGlobeCamera displayedCamera(WidgetTester tester) =>
    painterOf<DsGlobeLandPainter>(tester).camera;

DsMapMarkerLayerPainter markerPainter(WidgetTester tester) =>
    painterOf<DsMapMarkerLayerPainter>(tester);

DsMapMarkerPlacement placementOf(WidgetTester tester, String id) =>
    markerPainter(tester).placements.firstWhere((p) => p.marker.id == id);

List<String> paintedIds(WidgetTester tester) =>
    markerPainter(tester).placements.map((p) => p.marker.id).toList();

List<List<Object?>> calls(TestRecordingCanvas canvas, Symbol name) => canvas
    .invocations
    .where((i) => i.invocation.memberName == name)
    .map((i) => i.invocation.positionalArguments)
    .toList();

SemanticsOwner semanticsOwner(WidgetTester tester) =>
    tester.binding.renderViews.first.owner!.semanticsOwner!;

List<SemanticsNode> buttonNodes(WidgetTester tester) {
  final nodes = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    if (node.getSemanticsData().flagsCollection.isButton) nodes.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(semanticsOwner(tester).rootSemanticsNode!);
  return nodes;
}

Rect globalRect(SemanticsNode node) {
  var rect = node.rect;
  for (SemanticsNode? n = node; n != null; n = n.parent) {
    final transform = n.transform;
    if (transform != null) rect = MatrixUtils.transformRect(transform, rect);
  }
  return rect;
}
