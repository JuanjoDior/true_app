import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';


const Size desktop = Size(1440, 900);
const Size phone = Size(390, 844);

// Escena: x = (lon + 180) * 4, y = (80 - lat) * 4
const DsMapMarker markerAlpha = DsMapMarker(
  id: 'alpha',
  label: 'Alpha',
  latitude: 40,
  longitude: -4,
  color: Color(0xFFE5484D),
  year: 1970,
); // (704, 160)
const DsMapMarker markerBravo = DsMapMarker(
  id: 'bravo',
  label: 'Bravo',
  latitude: 0,
  longitude: 0,
  color: Color(0xFF3E63DD),
  year: 1990,
); // (720, 320)
const DsMapMarker markerCharlie = DsMapMarker(
  id: 'charlie',
  label: 'Charlie',
  latitude: -30,
  longitude: 150,
  color: Color(0xFF30A46C),
  year: 2010,
); // (1320, 440)
const DsMapMarker markerBravoMoved = DsMapMarker(
  id: 'bravo',
  label: 'Bravo',
  latitude: -10,
  longitude: 10,
  color: Color(0xFF3E63DD),
  year: 1990,
);

const Offset alphaScene = Offset(704, 160);
const Offset bravoScene = Offset(720, 320);
const Offset charlieScene = Offset(1320, 440);

const DsMapConnection alphaBravo = DsMapConnection(
  fromId: 'alpha',
  toId: 'bravo',
  label: 'Same region',
);
const DsMapConnection bravoCharlie = DsMapConnection(
  fromId: 'bravo',
  toId: 'charlie',
  label: 'Press link',
);
const DsMapCamera world = DsMapCamera.world();
const DsMapCamera zoomed = DsMapCamera(
  translateX: -2000,
  translateY: -400,
  scale: 3.4,
);

const double alphaRadius = 6;
const double selectedRadius = 9;
const double pulseStartAlpha = 0.6;
const double tolerance = 0.001;
const double dashOn = 7;
// Skia vuelve a medir los subtramos de la curva con un error de hasta ~2 %.
const double dashTolerance = 0.25;

Duration ms(int value) => Duration(milliseconds: value);

Widget buildScene({
  Size size = desktop,
  List<DsMapMarker> markers = const [markerAlpha, markerBravo, markerCharlie],
  DsMapCamera camera = world,
  List<DsMapConnection> connections = const [],
  bool showConnectionLabels = false,
  String? selectedId,
  Set<String> relatedIds = const {},
  int? timelineYear,
  bool mobile = false,
  double verticalOffset = 0,
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
      child: DsMapScene(
        markers: markers,
        camera: camera,
        connections: connections,
        showConnectionLabels: showConnectionLabels,
        selectedId: selectedId,
        relatedIds: relatedIds,
        timelineYear: timelineYear,
        mobile: mobile,
        verticalOffset: verticalOffset,
        onMarkerTap: onMarkerTap,
      ),
    ),
  );
}

Future<void> pumpScene(
  WidgetTester tester, {
  Size size = desktop,
  List<DsMapMarker> markers = const [markerAlpha, markerBravo, markerCharlie],
  DsMapCamera camera = world,
  List<DsMapConnection> connections = const [],
  bool showConnectionLabels = false,
  String? selectedId,
  Set<String> relatedIds = const {},
  int? timelineYear,
  bool mobile = false,
  double verticalOffset = 0,
  ValueChanged<String>? onMarkerTap,
  bool disableAnimations = false,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    buildScene(
      size: size,
      markers: markers,
      camera: camera,
      connections: connections,
      showConnectionLabels: showConnectionLabels,
      selectedId: selectedId,
      relatedIds: relatedIds,
      timelineYear: timelineYear,
      mobile: mobile,
      verticalOffset: verticalOffset,
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

TestRecordingCanvas paintEffects(WidgetTester tester) {
  final canvas = TestRecordingCanvas();
  painterOf<DsMapEffectsPainter>(tester).paint(canvas, desktop);
  return canvas;
}

TestRecordingCanvas paintLabels(WidgetTester tester) {
  final canvas = TestRecordingCanvas();
  painterOf<DsMapLabelLayerPainter>(tester).paint(canvas, desktop);
  return canvas;
}

List<List<Object?>> calls(TestRecordingCanvas canvas, Symbol name) => canvas
    .invocations
    .where((i) => i.invocation.memberName == name)
    .map((i) => i.invocation.positionalArguments)
    .toList();

List<Paint> arcPaints(TestRecordingCanvas canvas) => [
  for (final args in calls(canvas, #drawPath)) args[1]! as Paint,
];

List<Path> arcPaths(TestRecordingCanvas canvas) => [
  for (final args in calls(canvas, #drawPath)) args[0]! as Path,
];

class PulseRing {
  PulseRing(this.center, this.radius, this.paint);
  final Offset center;
  final double radius;
  final Paint paint;
}

List<PulseRing> rings(TestRecordingCanvas canvas) => [
  for (final args in calls(canvas, #drawCircle))
    PulseRing(args[0]! as Offset, args[1]! as double, args[2]! as Paint),
];

PulseRing ringAt(TestRecordingCanvas canvas, Offset center) =>
    rings(canvas).singleWhere((r) => (r.center - center).distance < 0.01);

List<double> contourLengths(Path path) => [
  for (final metric in path.computeMetrics()) metric.length,
];

DsMapArc screenArc(
  Offset a,
  Offset b, {
  DsMapCamera camera = world,
  double verticalOffset = 0,
}) => DsMapArc.between(
  a + Offset(0, verticalOffset),
  b + Offset(0, verticalOffset),
).mapPoints(camera.apply);

List<Rect> fillRects(TestRecordingCanvas canvas) => [
  for (final args in calls(canvas, #drawRRect))
    if ((args[1]! as Paint).style == PaintingStyle.fill)
      (args[0]! as RRect).outerRect,
];

SemanticsOwner semanticsOwner(WidgetTester tester) =>
    tester.binding.renderViews.first.owner!.semanticsOwner!;

List<String> semanticLabels(WidgetTester tester) {
  final labels = <String>[];
  void visit(SemanticsNode node) {
    final label = node.getSemanticsData().label;
    if (label.isNotEmpty) labels.add(label);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(semanticsOwner(tester).rootSemanticsNode!);
  return labels;
}
