import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

import 'test_support/ds_globe_scene_test_support.dart';

const int _mouseDevice = 1;
const double _labelGap = 18;
const Color _red = Color(0xFFE5484D);
const Color _blue = Color(0xFF3E63DD);
// Fuera de la silueta de la esfera y lejos de cualquier marcador.
const Offset _emptySpot = Offset(60, 860);

DsGlobeCamera get _target =>
    DsGlobeCameraTargets.explore(latitude: 30, longitude: 40, currentGy: 0);
DsGlobeCamera get _interrupting =>
    DsGlobeCameraTargets.cover(latitude: -20, longitude: -60, currentGy: 0);

Offset _screenOf(DsMapMarker marker, [DsGlobeCamera? camera]) =>
    projectMarker(marker, camera ?? coverCamera).screen;

void main() {
  group('layers', () {
    testWidgets('are ordered halo, body, land, shading, markers, labels', (
      tester,
    ) async {
      await pumpGlobeScene(tester);
      final order = [
        for (final paint in tester.widgetList<CustomPaint>(
          find.descendant(
            of: find.byType(DsGlobeScene),
            matching: find.byType(CustomPaint),
          ),
        ))
          paint.painter.runtimeType,
      ];
      expect(order, [
        DsGlobeHaloPainter,
        DsGlobeBodyPainter,
        DsGlobeLandPainter,
        DsGlobeShadingPainter,
        DsMapMarkerLayerPainter,
        DsGlobeLabelPainter,
      ]);
    });

    testWidgets('the land layer is a single painter in its own boundary', (
      tester,
    ) async {
      await pumpGlobeScene(tester);
      final land = painterFinder<DsGlobeLandPainter>();
      expect(land, findsOneWidget);
      final boundary = find.ancestor(
        of: land,
        matching: find.byType(RepaintBoundary),
      );
      expect(
        find.descendant(of: boundary.first, matching: land),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: boundary.first,
          matching: painterFinder<DsMapMarkerLayerPainter>(),
        ),
        findsNothing,
      );
      expect(
        find.ancestor(of: land, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
    });

    testWidgets('halo, shading and labels ignore pointers and semantics', (
      tester,
    ) async {
      await pumpGlobeScene(tester);
      for (final finder in [
        painterFinder<DsGlobeHaloPainter>(),
        painterFinder<DsGlobeBodyPainter>(),
        painterFinder<DsGlobeShadingPainter>(),
        painterFinder<DsGlobeLabelPainter>(),
      ]) {
        expect(
          find.ancestor(of: finder, matching: find.byType(IgnorePointer)),
          findsWidgets,
        );
        expect(
          find.ancestor(of: finder, matching: find.byType(ExcludeSemantics)),
          findsWidgets,
        );
      }
    });

    testWidgets('the marker layer is neither ignored nor excluded', (
      tester,
    ) async {
      await pumpGlobeScene(tester);
      final markers = painterFinder<DsMapMarkerLayerPainter>();
      expect(
        find.ancestor(of: markers, matching: find.byType(IgnorePointer)),
        findsNothing,
      );
      expect(
        find.ancestor(of: markers, matching: find.byType(ExcludeSemantics)),
        findsNothing,
      );
    });

    testWidgets('fills its parent and has a transparent background', (
      tester,
    ) async {
      await pumpGlobeScene(tester, size: fullHd);
      expect(tester.getSize(find.byType(DsGlobeScene)), fullHd);
      expect(
        find.descendant(
          of: find.byType(DsGlobeScene),
          matching: find.byType(ColoredBox),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(DsGlobeScene),
          matching: find.byType(DecoratedBox),
        ),
        findsNothing,
      );
    });

    testWidgets('forwards the camera and the halo color to the painters', (
      tester,
    ) async {
      await pumpGlobeScene(tester, camera: exploreCamera, haloColor: _red);
      expect(painterOf<DsGlobeHaloPainter>(tester).camera, exploreCamera);
      expect(painterOf<DsGlobeHaloPainter>(tester).color, _red);
      expect(painterOf<DsGlobeBodyPainter>(tester).camera, exploreCamera);
      expect(painterOf<DsGlobeShadingPainter>(tester).camera, exploreCamera);
      expect(displayedCamera(tester), exploreCamera);
    });
  });

  group('markers', () {
    testWidgets('are projected through the globe camera', (tester) async {
      await pumpGlobeScene(tester);
      expect(placementOf(tester, 'facing').center, _screenOf(facing));
      expect(
        (placementOf(tester, 'east').center - _screenOf(east)).distance,
        lessThan(tolerance),
      );
    });

    testWidgets('a back-facing marker is not painted', (tester) async {
      await pumpGlobeScene(tester);
      expect(paintedIds(tester), isNot(contains('back')));
      expect(paintedIds(tester), containsAll(['facing', 'east']));
    });

    testWidgets('paint order is plain, related, selected', (tester) async {
      await pumpGlobeScene(
        tester,
        selectedId: 'facing',
        relatedIds: const {'east'},
      );
      expect(paintedIds(tester), ['near-limb', 'limb', 'east', 'facing']);
    });

    testWidgets('timeline year and filter follow the flat rules', (
      tester,
    ) async {
      await pumpGlobeScene(
        tester,
        timelineYear: 1990,
        matchingIds: const {'facing'},
      );
      expect(paintedIds(tester), ['facing', 'east']);
      expect(placementOf(tester, 'facing').visual.opacity, 1);
      expect(placementOf(tester, 'east').visual.opacity, 0.12);
    });
  });

  group('tap', () {
    testWidgets('hits the marker at its center and within 22 px', (
      tester,
    ) async {
      final taps = <String>[];
      await pumpGlobeScene(tester, onMarkerTap: taps.add);
      final center = _screenOf(facing);
      await tester.tapAt(center);
      await tester.tapAt(center + const Offset(hitRadius, 0));
      await tester.tapAt(center + const Offset(0, -hitRadius));
      expect(taps, ['facing', 'facing', 'facing']);
    });

    testWidgets('misses at 23 px or more', (tester) async {
      final taps = <String>[];
      await pumpGlobeScene(tester, onMarkerTap: taps.add);
      final center = _screenOf(facing);
      await tester.tapAt(center + const Offset(hitRadius + 1, 0));
      await tester.tapAt(center + const Offset(0, hitRadius + 1));
      await tester.tapAt(_emptySpot);
      expect(taps, isEmpty);
    });

    testWidgets('a back-facing marker is not interactive', (tester) async {
      final taps = <String>[];
      await pumpGlobeScene(tester, onMarkerTap: taps.add);
      await tester.tapAt(_screenOf(back));
      expect(taps, isEmpty);
    });

    testWidgets('hit zone follows the camera', (tester) async {
      final taps = <String>[];
      final turned = coverCamera.copyWith(gy: -30);
      await pumpGlobeScene(tester, camera: turned, onMarkerTap: taps.add);
      // East ocupa ahora el centro y Facing se desplazó a la izquierda.
      await tester.tapAt(_screenOf(facing));
      await tester.tapAt(_screenOf(facing, turned));
      expect(taps, ['east', 'facing']);
    });

    testWidgets('markers hidden by the timeline year are ignored', (
      tester,
    ) async {
      final taps = <String>[];
      await pumpGlobeScene(tester, timelineYear: 1980, onMarkerTap: taps.add);
      await tester.tapAt(_screenOf(east));
      expect(taps, isEmpty);
      await tester.tapAt(_screenOf(facing));
      expect(taps, ['facing']);
    });

    testWidgets('does not throw without a callback', (tester) async {
      await pumpGlobeScene(tester);
      await tester.tapAt(_screenOf(facing));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows a click cursor only over a front marker', (
      tester,
    ) async {
      await pumpGlobeScene(tester, onMarkerTap: (_) {});
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: _emptySpot);
      addTearDown(mouse.removePointer);
      await tester.pump();
      MouseCursor cursor() => RendererBinding.instance.mouseTracker
          .debugDeviceActiveCursor(_mouseDevice)!;
      expect(cursor(), isNot(SystemMouseCursors.click));

      await mouse.moveTo(_screenOf(facing));
      await tester.pump();
      expect(cursor(), SystemMouseCursors.click);

      await mouse.moveTo(_screenOf(back));
      await tester.pump();
      expect(cursor(), isNot(SystemMouseCursors.click));
    });
  });

  group('semantics', () {
    testWidgets('only front markers are labelled buttons', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpGlobeScene(tester, onMarkerTap: (_) {});
      expect(
        buttonNodes(tester).map((n) => n.getSemanticsData().label),
        unorderedEquals(['Facing', 'East', 'Near limb', 'Limb']),
      );
      handle.dispose();
    });

    testWidgets('node rect is 44x44 centered on the marker', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpGlobeScene(tester, onMarkerTap: (_) {});
      final node = buttonNodes(
        tester,
      ).firstWhere((n) => n.getSemanticsData().label == 'Facing');
      final rect = globalRect(node);
      expect(rect.size, const Size(44, 44));
      expect(rect.center, _screenOf(facing));
      handle.dispose();
    });

    testWidgets('only the selected marker is selected', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpGlobeScene(tester, selectedId: 'east', onMarkerTap: (_) {});
      for (final node in buttonNodes(tester)) {
        final data = node.getSemanticsData();
        expect(
          data.flagsCollection.isSelected == Tristate.isTrue,
          data.label == 'East',
          reason: data.label,
        );
      }
      handle.dispose();
    });

    testWidgets('the tap action calls onMarkerTap with the id', (tester) async {
      final handle = tester.ensureSemantics();
      final taps = <String>[];
      await pumpGlobeScene(tester, onMarkerTap: taps.add);
      final node = buttonNodes(
        tester,
      ).firstWhere((n) => n.getSemanticsData().label == 'East');
      semanticsOwner(tester).performAction(node.id, SemanticsAction.tap);
      expect(taps, ['east']);
      handle.dispose();
    });

    testWidgets('labels, halo and land add no semantics nodes', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpGlobeScene(
        tester,
        markers: const [],
        haloColor: _red,
        onMarkerTap: (_) {},
      );
      var tappable = 0;
      void visit(SemanticsNode node) {
        if (node.getSemanticsData().hasAction(SemanticsAction.tap)) tappable++;
        node.visitChildren((c) {
          visit(c);
          return true;
        });
      }

      visit(semanticsOwner(tester).rootSemanticsNode!);
      expect(buttonNodes(tester), isEmpty);
      expect(tappable, 0);
      handle.dispose();
    });
  });

  group('labels', () {
    testWidgets('only related and selected markers get a label', (
      tester,
    ) async {
      await pumpGlobeScene(
        tester,
        selectedId: 'facing',
        relatedIds: const {'east'},
      );
      final specs = painterOf<DsGlobeLabelPainter>(tester).specs();
      expect(specs.map((s) => s.text), unorderedEquals(['Facing', 'East']));
    });

    testWidgets('nothing is labelled without selection or relation', (
      tester,
    ) async {
      await pumpGlobeScene(tester);
      expect(painterOf<DsGlobeLabelPainter>(tester).specs(), isEmpty);
    });

    testWidgets('sit 18 px to the right of the marker', (tester) async {
      await pumpGlobeScene(tester, selectedId: 'facing');
      final spec = painterOf<DsGlobeLabelPainter>(tester).specs().single;
      expect(spec.anchor, _screenOf(facing) + const Offset(_labelGap, 0));
      expect(spec.kind, DsMapLabelKind.marker);
    });

    testWidgets('are hidden near the limb (z2 <= 40) and shown when z2 > 40', (
      tester,
    ) async {
      await pumpGlobeScene(
        tester,
        selectedId: 'facing',
        relatedIds: const {'near-limb', 'limb'},
      );
      final texts = painterOf<DsGlobeLabelPainter>(
        tester,
      ).specs().map((s) => s.text);
      expect(texts, containsAll(['Facing', 'Near limb']));
      expect(texts, isNot(contains('Limb')));
    });

    testWidgets('are not drawn for back-facing markers', (tester) async {
      await pumpGlobeScene(tester, relatedIds: const {'back'});
      expect(painterOf<DsGlobeLabelPainter>(tester).specs(), isEmpty);
    });

    testWidgets('showLabels false draws nothing', (tester) async {
      await pumpGlobeScene(
        tester,
        selectedId: 'facing',
        relatedIds: const {'east'},
        showLabels: false,
      );
      final painter = painterOf<DsGlobeLabelPainter>(tester);
      expect(painter.specs(), isEmpty);
      final canvas = TestRecordingCanvas();
      painter.paint(canvas, desktop);
      expect(canvas.invocations, isEmpty);
    });

    testWidgets('draw a pill per label at the anchor', (tester) async {
      await pumpGlobeScene(tester, selectedId: 'facing');
      final canvas = TestRecordingCanvas();
      painterOf<DsGlobeLabelPainter>(tester).paint(canvas, desktop);
      final pills = [
        for (final args in calls(canvas, #drawRRect))
          if ((args[1]! as Paint).style == PaintingStyle.fill)
            (args[0]! as RRect).outerRect,
      ];
      expect(pills, hasLength(1));
      expect(pills.single.left, _screenOf(facing).dx + _labelGap);
      expect(pills.single.center.dy, closeTo(_screenOf(facing).dy, 0.001));
    });

    testWidgets('never intercept taps', (tester) async {
      final taps = <String>[];
      await pumpGlobeScene(tester, selectedId: 'facing', onMarkerTap: taps.add);
      final spec = painterOf<DsGlobeLabelPainter>(tester).specs().single;
      await tester.tapAt(spec.anchor + const Offset(_labelGap * 2, 0));
      expect(taps, isEmpty);
    });
  });

  group('camera animation', () {
    testWidgets('the first build shows the camera immediately', (tester) async {
      await pumpGlobeScene(tester, camera: _target, markers: const []);
      expect(displayedCamera(tester), _target);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('flies from the old camera to the new one in 1900 ms', (
      tester,
    ) async {
      await pumpGlobeScene(tester);
      await tester.pumpWidget(buildGlobeScene(camera: _target));
      await tester.pump();
      expect(displayedCamera(tester), coverCamera);

      await tester.pump(flyDuration ~/ 2);
      final mid = displayedCamera(tester);
      expect(mid.scale, lessThan(coverCamera.scale));
      expect(mid.scale, greaterThan(_target.scale));
      expect(mid.gx, allOf(greaterThan(_target.gx), lessThan(coverCamera.gx)));
      expect(mid.gy, allOf(greaterThan(_target.gy), lessThan(coverCamera.gy)));
      expect(mid.center.dx, lessThan(coverCamera.center.dx));
      expect(mid.center.dx, greaterThan(_target.center.dx));

      await tester.pump(flyDuration ~/ 2);
      expect(displayedCamera(tester), _target);
      // La simulación termina estrictamente después de su duración.
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('does not finish before 1900 ms', (tester) async {
      await pumpGlobeScene(tester);
      await tester.pumpWidget(buildGlobeScene(camera: _target));
      await tester.pump();
      await tester.pump(flyDuration - const Duration(milliseconds: 1));
      expect(displayedCamera(tester), isNot(_target));
      await tester.pump(const Duration(milliseconds: 1));
      expect(displayedCamera(tester), _target);
    });

    testWidgets('every layer and the markers follow the displayed camera', (
      tester,
    ) async {
      await pumpGlobeScene(tester, haloColor: _red);
      await tester.pumpWidget(
        buildGlobeScene(camera: _target, haloColor: _red),
      );
      await tester.pump();
      await tester.pump(flyDuration ~/ 2);
      final shown = displayedCamera(tester);
      expect(painterOf<DsGlobeBodyPainter>(tester).camera, shown);
      expect(painterOf<DsGlobeShadingPainter>(tester).camera, shown);
      expect(painterOf<DsGlobeHaloPainter>(tester).camera, shown);
      final expected = projectMarker(facing, shown);
      expect(placementOf(tester, 'facing').center, expected.screen);
    });

    testWidgets('an interruption restarts from the current camera', (
      tester,
    ) async {
      await pumpGlobeScene(tester);
      await tester.pumpWidget(buildGlobeScene(camera: _target));
      await tester.pump();
      await tester.pump(flyDuration ~/ 2);
      final current = displayedCamera(tester);
      expect(current, isNot(coverCamera));

      await tester.pumpWidget(buildGlobeScene(camera: _interrupting));
      await tester.pump();
      expect(displayedCamera(tester), current);

      await tester.pump(flyDuration);
      expect(displayedCamera(tester), _interrupting);
    });

    testWidgets('reduced motion cuts to the new camera', (tester) async {
      await pumpGlobeScene(tester, disableAnimations: true);
      await tester.pumpWidget(
        buildGlobeScene(camera: _target, disableAnimations: true),
      );
      expect(displayedCamera(tester), _target);
      await tester.pump();
      expect(displayedCamera(tester), _target);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('an unchanged camera does not animate', (tester) async {
      await pumpGlobeScene(tester);
      await tester.pumpWidget(buildGlobeScene(selectedId: 'east'));
      expect(tester.hasRunningAnimations, isFalse);
      expect(displayedCamera(tester), coverCamera);
    });

    testWidgets('pumpAndSettle terminates after a flight and a halo change', (
      tester,
    ) async {
      await pumpGlobeScene(tester, haloColor: _red);
      await tester.pumpWidget(
        buildGlobeScene(camera: _target, haloColor: _blue),
      );
      await tester.pumpAndSettle();
      expect(displayedCamera(tester), _target);
      expect(painterOf<DsGlobeHaloPainter>(tester).color, _blue);
    });

    testWidgets('disposing mid-flight leaves no running tickers', (
      tester,
    ) async {
      await pumpGlobeScene(tester, haloColor: _red);
      await tester.pumpWidget(
        buildGlobeScene(camera: _target, haloColor: _blue),
      );
      await tester.pump();
      await tester.pump(flyDuration ~/ 3);
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
    });
  });

  group('halo', () {
    testWidgets('fades between categories in 1400 ms', (tester) async {
      await pumpGlobeScene(tester, haloColor: _red);
      expect(painterOf<DsGlobeHaloPainter>(tester).color, _red);
      await tester.pumpWidget(buildGlobeScene(haloColor: _blue));
      await tester.pump();
      expect(painterOf<DsGlobeHaloPainter>(tester).color, _red);
      await tester.pump(haloFade ~/ 2);
      final mid = painterOf<DsGlobeHaloPainter>(tester).color;
      expect(mid, isNot(_red));
      expect(mid, isNot(_blue));
      await tester.pump(haloFade ~/ 2);
      expect(painterOf<DsGlobeHaloPainter>(tester).color, _blue);
    });

    testWidgets('snaps under reduced motion', (tester) async {
      await pumpGlobeScene(tester, haloColor: _red, disableAnimations: true);
      await tester.pumpWidget(
        buildGlobeScene(haloColor: _blue, disableAnimations: true),
      );
      expect(painterOf<DsGlobeHaloPainter>(tester).color, _blue);
    });

    testWidgets('no halo color draws nothing', (tester) async {
      await pumpGlobeScene(tester);
      final canvas = TestRecordingCanvas();
      painterOf<DsGlobeHaloPainter>(tester).paint(canvas, desktop);
      expect(canvas.invocations, isEmpty);
    });
  });

  group('robustness', () {
    for (final size in [desktop, fullHd]) {
      testWidgets('lays out and paints at ${size.width}x${size.height}', (
        tester,
      ) async {
        await pumpGlobeScene(
          tester,
          size: size,
          selectedId: 'facing',
          relatedIds: const {'east', 'near-limb'},
          haloColor: _red,
          onMarkerTap: (_) {},
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(DsGlobeScene)), size);
      });
    }

    testWidgets('ignores the text scale', (tester) async {
      await pumpGlobeScene(
        tester,
        selectedId: 'facing',
        relatedIds: const {'east'},
        textScale: 2,
      );
      final canvas = TestRecordingCanvas();
      painterOf<DsGlobeLabelPainter>(tester).paint(canvas, desktop);
      final pills = [
        for (final args in calls(canvas, #drawRRect))
          if ((args[1]! as Paint).style == PaintingStyle.fill)
            (args[0]! as RRect).outerRect,
      ];
      final normal = TestRecordingCanvas();
      await pumpGlobeScene(
        tester,
        selectedId: 'facing',
        relatedIds: const {'east'},
      );
      painterOf<DsGlobeLabelPainter>(tester).paint(normal, desktop);
      final reference = [
        for (final args in calls(normal, #drawRRect))
          if ((args[1]! as Paint).style == PaintingStyle.fill)
            (args[0]! as RRect).outerRect,
      ];
      expect(tester.takeException(), isNull);
      expect(pills, reference);
    });

    testWidgets('an empty marker list paints the sphere only', (tester) async {
      await pumpGlobeScene(tester, markers: const [], haloColor: _red);
      expect(tester.takeException(), isNull);
      expect(markerPainter(tester).placements, isEmpty);
    });
  });
}
