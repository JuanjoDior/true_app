import 'dart:ui' show PointMode, Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

const Size _desktop = Size(1440, 900);
const Size _phone = Size(390, 844);

// Escena: x = (lon + 180) * 4, y = (80 - lat) * 4
const DsMapMarker _alpha = DsMapMarker(
  id: 'alpha',
  label: 'Alpha',
  latitude: 40,
  longitude: -4,
  color: Color(0xFFE5484D),
  year: 1970,
); // (704, 160)
const DsMapMarker _bravo = DsMapMarker(
  id: 'bravo',
  label: 'Bravo',
  latitude: 0,
  longitude: 0,
  color: Color(0xFF3E63DD),
  year: 1990,
); // (720, 320)
const DsMapMarker _charlie = DsMapMarker(
  id: 'charlie',
  label: 'Charlie',
  latitude: -30,
  longitude: 150,
  color: Color(0xFF30A46C),
  year: 2010,
); // (1320, 440)

const Offset _alphaScene = Offset(704, 160);
const Offset _bravoScene = Offset(720, 320);
const Offset _charlieScene = Offset(1320, 440);

const DsMapCamera _zoomed = DsMapCamera(
  translateX: -400,
  translateY: -100,
  scale: 2,
);
const DsMapCamera _cullingCamera = DsMapCamera(
  translateX: -1500,
  translateY: -300,
  scale: 3,
);

const double _hitRadius = 22;
const int _landCellCount = 884;
const int _landOpacityBuckets = 6;
const double _borderWidth = 2;
const int _mouseDevice = 1;

Widget _scene({
  Size size = _desktop,
  List<DsMapMarker> markers = const [_alpha, _bravo, _charlie],
  DsMapCamera camera = const DsMapCamera.world(),
  String? selectedId,
  Set<String> relatedIds = const {},
  Set<String>? matchingIds,
  int? timelineYear,
  bool mobile = false,
  double verticalOffset = 0,
  ValueChanged<String>? onMarkerTap,
  double? landDotDiameter,
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
        selectedId: selectedId,
        relatedIds: relatedIds,
        matchingIds: matchingIds,
        timelineYear: timelineYear,
        mobile: mobile,
        verticalOffset: verticalOffset,
        onMarkerTap: onMarkerTap,
        landDotDiameter: landDotDiameter,
      ),
    ),
  );
}

Future<void> _pumpScene(
  WidgetTester tester, {
  Size size = _desktop,
  List<DsMapMarker> markers = const [_alpha, _bravo, _charlie],
  DsMapCamera camera = const DsMapCamera.world(),
  String? selectedId,
  Set<String> relatedIds = const {},
  Set<String>? matchingIds,
  int? timelineYear,
  bool mobile = false,
  double verticalOffset = 0,
  ValueChanged<String>? onMarkerTap,
  double? landDotDiameter,
  bool disableAnimations = false,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _scene(
      size: size,
      markers: markers,
      camera: camera,
      selectedId: selectedId,
      relatedIds: relatedIds,
      matchingIds: matchingIds,
      timelineYear: timelineYear,
      mobile: mobile,
      verticalOffset: verticalOffset,
      onMarkerTap: onMarkerTap,
      landDotDiameter: landDotDiameter,
      disableAnimations: disableAnimations,
      textScale: textScale,
    ),
  );
}

T _painterOf<T extends CustomPainter>(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.byWidgetPredicate((w) => w is CustomPaint && w.painter is T),
  );
  return paint.painter! as T;
}

DsMapLandLayerPainter _landPainter(WidgetTester tester) =>
    _painterOf<DsMapLandLayerPainter>(tester);

DsMapMarkerLayerPainter _markerPainter(WidgetTester tester) =>
    _painterOf<DsMapMarkerLayerPainter>(tester);

DsMapMarkerPlacement _placement(WidgetTester tester, String id) =>
    _markerPainter(tester).placements.firstWhere((p) => p.marker.id == id);

List<String> _paintedIds(WidgetTester tester) =>
    _markerPainter(tester).placements.map((p) => p.marker.id).toList();

Iterable<RecordedInvocation> _calls(TestRecordingCanvas canvas, Symbol name) =>
    canvas.invocations.where((i) => i.invocation.memberName == name);

SemanticsOwner _semanticsOwner(WidgetTester tester) =>
    tester.binding.renderViews.first.owner!.semanticsOwner!;

List<SemanticsNode> _buttonNodes(WidgetTester tester) {
  final nodes = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    if (node.getSemanticsData().flagsCollection.isButton) nodes.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(_semanticsOwner(tester).rootSemanticsNode!);
  return nodes;
}

Rect _globalRect(SemanticsNode node) {
  var rect = node.rect;
  for (SemanticsNode? n = node; n != null; n = n.parent) {
    final transform = n.transform;
    if (transform != null) rect = MatrixUtils.transformRect(transform, rect);
  }
  return rect;
}

void main() {
  group('DsMapScene constants', () {
    test('land dot diameter is 5 on desktop and 6 on mobile', () {
      expect(DsMapScene.landDotDiameterDesktop, 5);
      expect(DsMapScene.landDotDiameterMobile, 6);
    });
  });

  group('land layer', () {
    test('draws all 884 dots in 6 opacity buckets at world camera', () {
      final canvas = TestRecordingCanvas();
      const DsMapLandLayerPainter(
        camera: DsMapCamera.world(),
        verticalOffset: 0,
        dotDiameter: 5,
      ).paint(canvas, _desktop);

      final draws = _calls(canvas, #drawPoints).toList();
      expect(draws, hasLength(_landOpacityBuckets));
      final dots = draws.fold<int>(
        0,
        (sum, call) =>
            sum + (call.invocation.positionalArguments[1] as List).length,
      );
      expect(dots, _landCellCount);
      expect(_calls(canvas, #drawCircle), isEmpty);
    });

    test('each bucket is one round paint with the dot diameter', () {
      final canvas = TestRecordingCanvas();
      const DsMapLandLayerPainter(
        camera: DsMapCamera.world(),
        verticalOffset: 0,
        dotDiameter: 5,
      ).paint(canvas, _desktop);

      final opacities = <double>{};
      for (final call in _calls(canvas, #drawPoints)) {
        final args = call.invocation.positionalArguments;
        expect(args[0], PointMode.points);
        final paint = args[2] as Paint;
        expect(paint.strokeWidth, 5);
        expect(paint.strokeCap, StrokeCap.round);
        expect(paint.color.toARGB32() & 0x00FFFFFF, 0x0033405A);
        opacities.add(paint.color.a);
      }
      expect(opacities, hasLength(_landOpacityBuckets));
      for (final opacity in opacities) {
        expect(opacity, inInclusiveRange(0.44, 0.96));
      }
    });

    test('applies the camera matrix to the canvas', () {
      final canvas = TestRecordingCanvas();
      const DsMapLandLayerPainter(
        camera: _zoomed,
        verticalOffset: 0,
        dotDiameter: 5,
      ).paint(canvas, _desktop);

      final transforms = _calls(canvas, #transform).toList();
      expect(transforms, hasLength(1));
      expect(
        transforms.single.invocation.positionalArguments.single as List,
        orderedEquals(_zoomed.toMatrix().storage),
      );
    });

    test('dots are in scene units: the points are not pre-scaled', () {
      final canvas = TestRecordingCanvas();
      const DsMapLandLayerPainter(
        camera: DsMapCamera.world(),
        verticalOffset: 0,
        dotDiameter: 5,
      ).paint(canvas, _desktop);
      final first = DsLandGrid.cells.first;
      final scenePoint = DsMapProjection.project(
        first.latitude,
        first.longitude,
      );
      final allPoints = _calls(
        canvas,
        #drawPoints,
      ).expand((c) => c.invocation.positionalArguments[1] as List<Offset>);
      expect(allPoints, contains(scenePoint));
    });

    test('vertical offset shifts every dot down in scene space', () {
      final base = DsMapLandLayerPainter.dotBuckets(
        camera: const DsMapCamera.world(),
        size: _desktop,
        verticalOffset: 0,
        dotDiameter: 5,
      );
      final shifted = DsMapLandLayerPainter.dotBuckets(
        camera: const DsMapCamera.world(),
        size: _desktop,
        verticalOffset: 180,
        dotDiameter: 5,
      );
      expect(shifted.keys, base.keys);
      for (final opacity in base.keys) {
        final a = base[opacity]!;
        final b = shifted[opacity]!;
        expect(b, hasLength(a.length));
        expect(b.first, a.first + const Offset(0, 180));
      }
    });

    test('culls cells outside the viewport when the camera is zoomed', () {
      final world = DsMapLandLayerPainter.visibleCells(
        camera: const DsMapCamera.world(),
        size: _desktop,
        verticalOffset: 0,
        dotDiameter: 5,
      );
      final zoomed = DsMapLandLayerPainter.visibleCells(
        camera: _cullingCamera,
        size: _desktop,
        verticalOffset: 0,
        dotDiameter: 5,
      );
      expect(world, hasLength(_landCellCount));
      expect(zoomed, isNotEmpty);
      expect(zoomed.length, lessThan(_landCellCount));

      final viewport = (Offset.zero & _desktop).inflate(
        5 / 2 * _cullingCamera.scale,
      );
      bool inside(DsLandCell cell) => viewport.contains(
        _cullingCamera.apply(
          DsMapProjection.project(cell.latitude, cell.longitude),
        ),
      );
      expect(zoomed.every(inside), isTrue);
      final excluded = DsLandGrid.cells.where((c) => !zoomed.contains(c));
      expect(excluded.any(inside), isFalse);
    });

    test('paint only draws the visible cells', () {
      final canvas = TestRecordingCanvas();
      const DsMapLandLayerPainter(
        camera: _cullingCamera,
        verticalOffset: 0,
        dotDiameter: 5,
      ).paint(canvas, _desktop);
      final dots = _calls(canvas, #drawPoints).fold<int>(
        0,
        (sum, call) =>
            sum + (call.invocation.positionalArguments[1] as List).length,
      );
      final expected = DsMapLandLayerPainter.visibleCells(
        camera: _cullingCamera,
        size: _desktop,
        verticalOffset: 0,
        dotDiameter: 5,
      );
      expect(dots, expected.length);
    });

    test('vertical offset pushes cells out of the viewport', () {
      final cells = DsMapLandLayerPainter.visibleCells(
        camera: const DsMapCamera.world(),
        size: const Size(1440, 400),
        verticalOffset: 180,
        dotDiameter: 5,
      );
      expect(cells.length, lessThan(_landCellCount));
    });

    test('repaints only when camera, offset or diameter change', () {
      const base = DsMapLandLayerPainter(
        camera: DsMapCamera.world(),
        verticalOffset: 0,
        dotDiameter: 5,
      );
      expect(
        base.shouldRepaint(
          const DsMapLandLayerPainter(
            camera: DsMapCamera.world(),
            verticalOffset: 0,
            dotDiameter: 5,
          ),
        ),
        isFalse,
      );
      expect(
        base.shouldRepaint(
          const DsMapLandLayerPainter(
            camera: _zoomed,
            verticalOffset: 0,
            dotDiameter: 5,
          ),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          const DsMapLandLayerPainter(
            camera: DsMapCamera.world(),
            verticalOffset: 10,
            dotDiameter: 5,
          ),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          const DsMapLandLayerPainter(
            camera: DsMapCamera.world(),
            verticalOffset: 0,
            dotDiameter: 6,
          ),
        ),
        isTrue,
      );
    });

    testWidgets('lives in its own RepaintBoundary and is a single painter', (
      tester,
    ) async {
      await _pumpScene(tester);
      final land = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is DsMapLandLayerPainter,
      );
      expect(land, findsOneWidget);
      expect(
        find.ancestor(of: land, matching: find.byType(RepaintBoundary)),
        findsWidgets,
      );
      final boundary = find.ancestor(
        of: land,
        matching: find.byType(RepaintBoundary),
      );
      // La capa de tierra es el hijo directo de su propio RepaintBoundary.
      expect(
        find.descendant(of: boundary.first, matching: land),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: boundary.first,
          matching: find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is DsMapMarkerLayerPainter,
          ),
        ),
        findsNothing,
      );
    });

    testWidgets('uses 5 px on desktop and 6 px on mobile by default', (
      tester,
    ) async {
      await _pumpScene(tester);
      expect(_landPainter(tester).dotDiameter, 5);
      await _pumpScene(tester, mobile: true);
      expect(_landPainter(tester).dotDiameter, 6);
    });

    testWidgets('an explicit landDotDiameter wins over the default', (
      tester,
    ) async {
      await _pumpScene(tester, landDotDiameter: 7.5);
      expect(_landPainter(tester).dotDiameter, 7.5);
    });

    testWidgets('forwards camera and vertical offset to the painter', (
      tester,
    ) async {
      await _pumpScene(tester, camera: _zoomed, verticalOffset: 40);
      expect(_landPainter(tester).camera, _zoomed);
      expect(_landPainter(tester).verticalOffset, 40);
    });

    testWidgets('fills its parent', (tester) async {
      await _pumpScene(tester, size: _phone, mobile: true);
      expect(tester.getSize(find.byType(DsMapScene)), _phone);
    });
  });

  group('marker positions', () {
    testWidgets('are projected through the camera at world camera', (
      tester,
    ) async {
      await _pumpScene(tester);
      expect(_placement(tester, 'alpha').center, _alphaScene);
      expect(_placement(tester, 'bravo').center, _bravoScene);
      expect(_placement(tester, 'charlie').center, _charlieScene);
    });

    testWidgets('are projected through a zoomed camera', (tester) async {
      await _pumpScene(tester, camera: _zoomed);
      // 2 * scene + (-400, -100)
      expect(_placement(tester, 'alpha').center, const Offset(1008, 220));
      expect(_placement(tester, 'bravo').center, const Offset(1040, 540));
      expect(_placement(tester, 'charlie').center, const Offset(2240, 780));
    });

    testWidgets('include the vertical offset before the camera', (
      tester,
    ) async {
      await _pumpScene(tester, verticalOffset: 180);
      expect(_placement(tester, 'alpha').center, const Offset(704, 340));

      await _pumpScene(tester, camera: _zoomed, verticalOffset: 180);
      await tester.pumpAndSettle();
      // 2 * (704, 160 + 180) + (-400, -100)
      expect(_placement(tester, 'alpha').center, const Offset(1008, 580));
    });

    testWidgets('keep their on-screen diameter when the camera scale changes', (
      tester,
    ) async {
      await _pumpScene(tester);
      final atWorld = _placement(tester, 'alpha').visual.diameter;
      await _pumpScene(tester, camera: _zoomed);
      await tester.pumpAndSettle();
      final atZoom = _placement(tester, 'alpha').visual.diameter;
      expect(atZoom, atWorld);
      expect(atWorld, 12);

      final canvas = TestRecordingCanvas();
      _markerPainter(tester).paint(canvas, _desktop);
      final rings = _calls(canvas, #drawCircle)
          .map((c) => c.invocation.positionalArguments)
          .where((a) => (a[2] as Paint).style == PaintingStyle.stroke);
      for (final args in rings) {
        final paint = args[2] as Paint;
        expect((args[1] as double) + paint.strokeWidth / 2, atZoom / 2);
      }
      expect(rings, isNotEmpty);
    });

    testWidgets('use the mobile diameters on mobile', (tester) async {
      await _pumpScene(tester, mobile: true, selectedId: 'alpha');
      expect(_placement(tester, 'alpha').visual.diameter, 20);
      expect(_placement(tester, 'bravo').visual.diameter, 14);
    });
  });

  group('marker visuals', () {
    testWidgets('without selection every marker is fully visible', (
      tester,
    ) async {
      await _pumpScene(tester);
      for (final p in _markerPainter(tester).placements) {
        expect(p.visual.opacity, 1);
        expect(p.visual.goldBorder, isFalse);
      }
    });

    testWidgets('selected marker is bigger and the rest are dimmed', (
      tester,
    ) async {
      await _pumpScene(tester, selectedId: 'alpha');
      final selected = _placement(tester, 'alpha');
      expect(selected.selected, isTrue);
      expect(selected.visual.diameter, 18);
      expect(selected.visual.glowRadius, 26);
      expect(selected.visual.opacity, 1);
      expect(_placement(tester, 'bravo').visual.opacity, 0.4);
      expect(_placement(tester, 'charlie').visual.opacity, 0.4);
    });

    testWidgets('related markers keep full opacity and a gold border', (
      tester,
    ) async {
      await _pumpScene(
        tester,
        selectedId: 'alpha',
        relatedIds: const {'bravo'},
      );
      final related = _placement(tester, 'bravo');
      expect(related.related, isTrue);
      expect(related.visual.opacity, 1);
      expect(related.visual.goldBorder, isTrue);
      expect(related.visual.showLabel, isTrue);
      expect(_placement(tester, 'charlie').visual.opacity, 0.4);
      expect(_placement(tester, 'charlie').related, isFalse);
    });

    testWidgets('a selected marker is never treated as related', (
      tester,
    ) async {
      await _pumpScene(
        tester,
        selectedId: 'alpha',
        relatedIds: const {'alpha'},
      );
      expect(_placement(tester, 'alpha').related, isFalse);
      expect(_placement(tester, 'alpha').visual.goldBorder, isFalse);
    });

    testWidgets('markers outside the filter are nearly transparent', (
      tester,
    ) async {
      await _pumpScene(tester, matchingIds: const {'alpha'});
      expect(_placement(tester, 'alpha').visual.opacity, 1);
      expect(_placement(tester, 'bravo').visual.opacity, 0.12);
      expect(_placement(tester, 'charlie').visual.opacity, 0.12);
    });

    testWidgets('a null matchingIds means everything matches', (tester) async {
      await _pumpScene(tester, matchingIds: null);
      expect(_placement(tester, 'bravo').visual.opacity, 1);
    });

    testWidgets('markers after the timeline year are not placed at all', (
      tester,
    ) async {
      await _pumpScene(tester, timelineYear: 1990);
      expect(_paintedIds(tester), ['alpha', 'bravo']);
    });

    testWidgets('a null timelineYear shows every marker', (tester) async {
      await _pumpScene(tester, timelineYear: null);
      expect(_paintedIds(tester), hasLength(3));
    });

    testWidgets('hidden markers issue no draw calls', (tester) async {
      await _pumpScene(tester, timelineYear: 1900);
      final canvas = TestRecordingCanvas();
      _markerPainter(tester).paint(canvas, _desktop);
      expect(canvas.invocations, isEmpty);
    });

    testWidgets('a regular marker draws a glow, a bgBase ring and a body', (
      tester,
    ) async {
      await _pumpScene(tester, markers: const [_alpha]);
      final canvas = TestRecordingCanvas();
      _markerPainter(tester).paint(canvas, _desktop);
      final circles = _calls(
        canvas,
        #drawCircle,
      ).map((c) => c.invocation.positionalArguments).toList();
      expect(circles, hasLength(3));
      for (final args in circles) {
        expect(args[0], _alphaScene);
      }

      final glow = circles.firstWhere(
        (a) => (a[2] as Paint).maskFilter != null,
      );
      final glowPaint = glow[2] as Paint;
      expect(
        glowPaint.color.toARGB32() & 0x00FFFFFF,
        _alpha.color.toARGB32() & 0x00FFFFFF,
      );
      expect(glowPaint.color.a, lessThan(1));
      expect(glowPaint.color.a, greaterThan(0));

      final ring =
          circles.firstWhere(
                (a) => (a[2] as Paint).style == PaintingStyle.stroke,
              )[2]
              as Paint;
      expect(ring.strokeWidth, _borderWidth);
      expect(ring.color.toARGB32(), DsColors.bgBase.toARGB32());

      final body = circles.firstWhere(
        (a) =>
            (a[2] as Paint).style == PaintingStyle.fill &&
            (a[2] as Paint).maskFilter == null,
      );
      expect((body[2] as Paint).color.toARGB32(), _alpha.color.toARGB32());
    });

    testWidgets('a related marker draws the gold ring instead', (tester) async {
      await _pumpScene(
        tester,
        markers: const [_alpha, _bravo],
        selectedId: 'alpha',
        relatedIds: const {'bravo'},
      );
      final canvas = TestRecordingCanvas();
      _markerPainter(tester).paint(canvas, _desktop);
      final rings = _calls(canvas, #drawCircle)
          .map((c) => c.invocation.positionalArguments)
          .where((a) => (a[2] as Paint).style == PaintingStyle.stroke)
          .toList();
      final goldRing =
          rings.singleWhere((a) => a[0] == _bravoScene)[2] as Paint;
      expect(goldRing.color.toARGB32(), DsColors.accentGold.toARGB32());
      expect(goldRing.strokeWidth, _borderWidth);
      final baseRing =
          rings.singleWhere((a) => a[0] == _alphaScene)[2] as Paint;
      expect(baseRing.color.a, closeTo(1, 0.01));
      expect(baseRing.color.toARGB32(), DsColors.bgBase.toARGB32());
    });

    testWidgets('opacity is applied to the painted colors', (tester) async {
      await _pumpScene(tester, markers: const [_alpha], matchingIds: const {});
      final canvas = TestRecordingCanvas();
      _markerPainter(tester).paint(canvas, _desktop);
      final body = _calls(canvas, #drawCircle)
          .map((c) => c.invocation.positionalArguments)
          .firstWhere(
            (a) =>
                (a[2] as Paint).style == PaintingStyle.fill &&
                (a[2] as Paint).maskFilter == null,
          );
      expect((body[2] as Paint).color.a, closeTo(0.12, 0.01));
    });
  });

  group('marker paint order', () {
    testWidgets('keeps list order when nothing is selected', (tester) async {
      await _pumpScene(tester);
      expect(_paintedIds(tester), ['alpha', 'bravo', 'charlie']);
    });

    testWidgets('selected is painted last, related just before it', (
      tester,
    ) async {
      await _pumpScene(
        tester,
        selectedId: 'alpha',
        relatedIds: const {'bravo'},
      );
      expect(_paintedIds(tester), ['charlie', 'bravo', 'alpha']);
    });

    testWidgets('selected alone goes to the end', (tester) async {
      await _pumpScene(tester, selectedId: 'bravo');
      expect(_paintedIds(tester), ['alpha', 'charlie', 'bravo']);
    });

    testWidgets('the canvas receives the selected marker last', (tester) async {
      await _pumpScene(tester, selectedId: 'alpha');
      final canvas = TestRecordingCanvas();
      _markerPainter(tester).paint(canvas, _desktop);
      final centers = _calls(
        canvas,
        #drawCircle,
      ).map((c) => c.invocation.positionalArguments[0] as Offset).toList();
      expect(centers.last, _alphaScene);
      expect(centers.take(centers.length - 3), isNot(contains(_alphaScene)));
    });
  });

  group('tap', () {
    testWidgets('hits the marker when the tap is on its center', (
      tester,
    ) async {
      final taps = <String>[];
      await _pumpScene(tester, onMarkerTap: taps.add);
      await tester.tapAt(_alphaScene);
      expect(taps, ['alpha']);
    });

    testWidgets('hits within 22 px of the center', (tester) async {
      final taps = <String>[];
      await _pumpScene(tester, onMarkerTap: taps.add);
      await tester.tapAt(_alphaScene + const Offset(_hitRadius, 0));
      await tester.tapAt(_bravoScene + const Offset(0, -_hitRadius));
      expect(taps, ['alpha', 'bravo']);
    });

    testWidgets('misses at 23 px or more', (tester) async {
      final taps = <String>[];
      await _pumpScene(tester, onMarkerTap: taps.add);
      await tester.tapAt(_alphaScene + const Offset(_hitRadius + 1, 0));
      await tester.tapAt(_alphaScene + const Offset(0, _hitRadius + 1));
      await tester.tapAt(const Offset(10, 800));
      expect(taps, isEmpty);
    });

    testWidgets('hit zone follows the camera', (tester) async {
      final taps = <String>[];
      await _pumpScene(tester, camera: _zoomed, onMarkerTap: taps.add);
      await tester.tapAt(_alphaScene); // en la cámara de mundo estaría aquí
      expect(taps, isEmpty);
      await tester.tapAt(const Offset(1008, 220));
      expect(taps, ['alpha']);
    });

    testWidgets('hit zone includes the vertical offset', (tester) async {
      final taps = <String>[];
      await _pumpScene(tester, verticalOffset: 180, onMarkerTap: taps.add);
      await tester.tapAt(_alphaScene);
      expect(taps, isEmpty);
      await tester.tapAt(const Offset(704, 340));
      expect(taps, ['alpha']);
    });

    testWidgets('picks the nearest of two close markers', (tester) async {
      const near = DsMapMarker(
        id: 'near',
        label: 'Near',
        latitude: 40,
        longitude: -4 + 2.5, // +10 px en x
        color: Color(0xFF123456),
        year: 1970,
      );
      final taps = <String>[];
      await _pumpScene(
        tester,
        markers: const [_alpha, near],
        onMarkerTap: taps.add,
      );
      await tester.tapAt(_alphaScene + const Offset(3, 0));
      await tester.tapAt(_alphaScene + const Offset(8, 0));
      expect(taps, ['alpha', 'near']);
    });

    testWidgets('ties go to the later marker in paint order', (tester) async {
      const twin = DsMapMarker(
        id: 'twin',
        label: 'Twin',
        latitude: 40,
        longitude: -4,
        color: Color(0xFF123456),
        year: 1970,
      );
      final taps = <String>[];
      await _pumpScene(
        tester,
        markers: const [_alpha, twin],
        onMarkerTap: taps.add,
      );
      await tester.tapAt(_alphaScene);
      expect(taps, ['twin']);

      taps.clear();
      await _pumpScene(
        tester,
        markers: const [_alpha, twin],
        selectedId: 'alpha',
        onMarkerTap: taps.add,
      );
      await tester.tapAt(_alphaScene);
      expect(taps, ['alpha']);
    });

    testWidgets('ignores markers hidden by the timeline year', (tester) async {
      final taps = <String>[];
      await _pumpScene(tester, timelineYear: 1980, onMarkerTap: taps.add);
      await tester.tapAt(_charlieScene);
      expect(taps, isEmpty);
      await tester.tapAt(_bravoScene);
      expect(taps, isEmpty);
      await tester.tapAt(_alphaScene);
      expect(taps, ['alpha']);
    });

    testWidgets('does not throw without a callback', (tester) async {
      await _pumpScene(tester);
      await tester.tapAt(_alphaScene);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows a click cursor only over a marker', (tester) async {
      await _pumpScene(tester, onMarkerTap: (_) {});
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(10, 800));
      addTearDown(mouse.removePointer);
      await tester.pump();
      MouseCursor cursor() => RendererBinding.instance.mouseTracker
          .debugDeviceActiveCursor(_mouseDevice)!;
      expect(cursor(), isNot(SystemMouseCursors.click));

      await mouse.moveTo(_alphaScene);
      await tester.pump();
      expect(cursor(), SystemMouseCursors.click);

      await mouse.moveTo(const Offset(10, 800));
      await tester.pump();
      expect(cursor(), isNot(SystemMouseCursors.click));
    });
  });

  group('semantics', () {
    testWidgets('each interactive marker is a labelled button', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpScene(tester, onMarkerTap: (_) {});
      final nodes = _buttonNodes(tester);
      expect(
        nodes.map((n) => n.getSemanticsData().label),
        unorderedEquals(['Alpha', 'Bravo', 'Charlie']),
      );
      handle.dispose();
    });

    testWidgets('node rect is 44x44 centered on the marker', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpScene(tester, camera: _zoomed, onMarkerTap: (_) {});
      final alpha = _buttonNodes(
        tester,
      ).firstWhere((n) => n.getSemanticsData().label == 'Alpha');
      final rect = _globalRect(alpha);
      expect(rect.size, const Size(44, 44));
      expect(rect.center, const Offset(1008, 220));
      handle.dispose();
    });

    testWidgets('only the selected marker is selected', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpScene(tester, selectedId: 'bravo', onMarkerTap: (_) {});
      for (final node in _buttonNodes(tester)) {
        final data = node.getSemanticsData();
        expect(
          data.flagsCollection.isSelected == Tristate.isTrue,
          data.label == 'Bravo',
          reason: data.label,
        );
      }
      handle.dispose();
    });

    testWidgets('tap action calls onMarkerTap with the marker id', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final taps = <String>[];
      await _pumpScene(tester, onMarkerTap: taps.add);
      final charlie = _buttonNodes(
        tester,
      ).firstWhere((n) => n.getSemanticsData().label == 'Charlie');
      expect(charlie.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      _semanticsOwner(tester).performAction(charlie.id, SemanticsAction.tap);
      expect(taps, ['charlie']);
      handle.dispose();
    });

    testWidgets('hidden markers expose nothing', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpScene(tester, timelineYear: 1990, onMarkerTap: (_) {});
      expect(
        _buttonNodes(tester).map((n) => n.getSemanticsData().label),
        unorderedEquals(['Alpha', 'Bravo']),
      );
      handle.dispose();
    });

    testWidgets('the land layer and the scene add no other tap targets', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpScene(tester, markers: const [], onMarkerTap: (_) {});
      expect(_buttonNodes(tester), isEmpty);
      final root = _semanticsOwner(tester).rootSemanticsNode!;
      var tappable = 0;
      void visit(SemanticsNode node) {
        if (node.getSemanticsData().hasAction(SemanticsAction.tap)) tappable++;
        node.visitChildren((c) {
          visit(c);
          return true;
        });
      }

      visit(root);
      expect(tappable, 0);
      handle.dispose();
    });
  });

  group('camera animation', () {
    const target = DsMapCamera(translateX: -800, translateY: -200, scale: 3);
    const interrupting = DsMapCamera(
      translateX: 100,
      translateY: 50,
      scale: 1.5,
    );

    testWidgets('the first build shows the camera immediately', (tester) async {
      await _pumpScene(tester, camera: target);
      expect(_landPainter(tester).camera, target);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('flies from the old camera to the new one in 1800 ms', (
      tester,
    ) async {
      await _pumpScene(tester);
      await tester.pumpWidget(_scene(camera: target));
      await tester.pump();
      expect(_landPainter(tester).camera, const DsMapCamera.world());

      await tester.pump(const Duration(milliseconds: 900));
      final mid = _landPainter(tester).camera;
      expect(mid.scale, greaterThan(1));
      expect(mid.scale, lessThan(target.scale));
      expect(mid.translateX, lessThan(0));
      expect(mid.translateX, greaterThan(target.translateX));
      expect(mid.translateY, lessThan(0));
      expect(mid.translateY, greaterThan(target.translateY));

      await tester.pump(const Duration(milliseconds: 900));
      expect(_landPainter(tester).camera, target);
      await tester.pumpAndSettle();
      expect(_landPainter(tester).camera, target);
    });

    testWidgets('markers follow the animated camera', (tester) async {
      await _pumpScene(tester);
      await tester.pumpWidget(_scene(camera: target));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      final displayed = _landPainter(tester).camera;
      expect(_placement(tester, 'alpha').center, displayed.apply(_alphaScene));
      await tester.pumpAndSettle();
      expect(_placement(tester, 'alpha').center, target.apply(_alphaScene));
    });

    testWidgets('an interruption restarts from the current camera', (
      tester,
    ) async {
      await _pumpScene(tester);
      await tester.pumpWidget(_scene(camera: target));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      final current = _landPainter(tester).camera;
      expect(current, isNot(const DsMapCamera.world()));
      expect(current, isNot(target));

      await tester.pumpWidget(_scene(camera: interrupting));
      await tester.pump();
      expect(_landPainter(tester).camera, current);

      await tester.pump(const Duration(milliseconds: 1800));
      expect(_landPainter(tester).camera, interrupting);
    });

    testWidgets('rebuilding with the same camera does not restart the fly', (
      tester,
    ) async {
      await _pumpScene(tester);
      await tester.pumpWidget(_scene(camera: target));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      final mid = _landPainter(tester).camera;
      await tester.pumpWidget(_scene(camera: target, selectedId: 'alpha'));
      expect(_landPainter(tester).camera, mid);
    });

    testWidgets('reduced motion cuts to the new camera instantly', (
      tester,
    ) async {
      await _pumpScene(tester, disableAnimations: true);
      await tester.pumpWidget(_scene(camera: target, disableAnimations: true));
      expect(_landPainter(tester).camera, target);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets(
      'pumpAndSettle ends and nothing leaks when disposed in flight',
      (tester) async {
        await _pumpScene(tester);
        await tester.pumpWidget(_scene(camera: target));
        await tester.pumpAndSettle();
        expect(tester.hasRunningAnimations, isFalse);

        await tester.pumpWidget(_scene(camera: const DsMapCamera.world()));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('robustness', () {
    testWidgets('renders at 1440x900 without exceptions', (tester) async {
      await _pumpScene(
        tester,
        selectedId: 'alpha',
        relatedIds: const {'bravo'},
        verticalOffset: 180,
        onMarkerTap: (_) {},
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders at 390x844 mobile without exceptions', (tester) async {
      await _pumpScene(
        tester,
        size: _phone,
        mobile: true,
        camera: const DsMapCamera(
          translateX: -100,
          translateY: 20,
          scale: 0.62,
        ),
        selectedId: 'bravo',
        onMarkerTap: (_) {},
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with text scale 2.0 without exceptions', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpScene(
        tester,
        size: _phone,
        mobile: true,
        textScale: 2,
        onMarkerTap: (_) {},
      );
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('survives an empty marker list and a marker swap', (
      tester,
    ) async {
      await _pumpScene(tester, markers: const []);
      await tester.pumpWidget(_scene(markers: const [_alpha]));
      expect(tester.takeException(), isNull);
      expect(_paintedIds(tester), ['alpha']);
    });
  });
}
