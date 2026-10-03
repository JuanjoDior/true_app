import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

const _mobile = Size(390, 844);
const _ringKey = ValueKey('ds-focus-ring');
const _outside = Offset(385, 840);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double textScale = 1,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = _mobile;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DsTheme.build(),
      home: MediaQuery(
        data: MediaQueryData(
          size: _mobile,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: Scaffold(
          body: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    ),
  );
}

const _segments = [
  DsSegment<String>(value: 'a', label: 'Globo'),
  DsSegment<String>(value: 'b', label: 'Mapa'),
  DsSegment<String>(value: 'c', label: 'Lista'),
];

Widget _make({String value = 'a', required ValueChanged<String> onChanged}) =>
    DsSegmented<String>(
      segments: _segments,
      value: value,
      onChanged: onChanged,
    );

Finder get _group => find.byType(DsSegmented<String>);

// El contenedor animado del segmento (la píldora de color)
Finder _segment(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(AnimatedContainer),
);

BoxDecoration _decoration(WidgetTester tester, String label) =>
    tester.widget<AnimatedContainer>(_segment(label)).decoration!
        as BoxDecoration;

TextStyle _labelStyle(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!;

Finder _scaleOf(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(AnimatedScale));

Finder _ringIn(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(AnimatedScale)),
  matching: find.byKey(_ringKey),
);

Future<TestGesture> _hoverWithMouse(WidgetTester tester, String label) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: _outside);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(tester.getCenter(find.text(label)));
  await tester.pump();
  return gesture;
}

void main() {
  group('layout and colors', () {
    testWidgets('segments are 44 px tall inside a control-radius container', (
      tester,
    ) async {
      await _pump(tester, _make(onChanged: (_) {}));

      expect(tester.getSize(_segment('Globo')).height, 44);
      final container = tester.widget<DecoratedBox>(
        find.descendant(of: _group, matching: find.byType(DecoratedBox)).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, DsRadii.controlBorder);
      expect(decoration.color, DsColors.surfaceCard);
    });

    testWidgets('selected segment uses ctaBg / ctaFg, others stay flat', (
      tester,
    ) async {
      await _pump(tester, _make(value: 'b', onChanged: (_) {}));

      expect(_decoration(tester, 'Mapa').color, DsColors.ctaBg);
      expect(_labelStyle(tester, 'Mapa').color, DsColors.ctaFg);
      expect(_decoration(tester, 'Globo').color, const Color(0x00000000));
      expect(_labelStyle(tester, 'Globo').color, DsColors.textBody);
    });

    testWidgets('survives text scale 2.0 without exceptions', (tester) async {
      await _pump(tester, _make(onChanged: (_) {}), textScale: 2);

      expect(tester.takeException(), isNull);
    });
  });

  group('selection and semantics', () {
    testWidgets('tapping another segment reports its value', (tester) async {
      final values = <String>[];
      await _pump(tester, _make(onChanged: values.add));

      await tester.tap(find.text('Lista'));

      expect(values, ['c']);
    });

    testWidgets('tapping the selected segment does not report a change', (
      tester,
    ) async {
      final values = <String>[];
      await _pump(tester, _make(onChanged: values.add));

      await tester.tap(find.text('Globo'));

      expect(values, isEmpty);
    });

    testWidgets('semantics: mutually exclusive group with selected state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _make(value: 'b', onChanged: (_) {}));

      expect(
        tester.getSemantics(find.text('Mapa')),
        isSemantics(
          label: 'Mapa',
          isButton: true,
          isInMutuallyExclusiveGroup: true,
          hasSelectedState: true,
          isSelected: true,
        ),
      );
      expect(
        tester.getSemantics(find.text('Globo')),
        isSemantics(
          label: 'Globo',
          isButton: true,
          isInMutuallyExclusiveGroup: true,
          hasSelectedState: true,
          isSelected: false,
        ),
      );
      handle.dispose();
    });
  });

  group('motion', () {
    testWidgets('press scales a segment to 0.97 in 160 ms with easeUi', (
      tester,
    ) async {
      await _pump(tester, _make(onChanged: (_) {}));

      final press = await tester.startGesture(
        tester.getCenter(find.text('Mapa')),
      );
      await tester.pump();
      await tester.pump(DsMotion.press);

      final scale = tester.widget<AnimatedScale>(_scaleOf('Mapa'));
      expect(scale.scale, 0.97);
      expect(scale.duration, DsMotion.press);
      expect(scale.curve, DsMotion.easeUi);

      await press.up();
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedScale>(_scaleOf('Mapa')).scale, 1);
    });

    testWidgets('mouse hover tints an unselected segment, no scale', (
      tester,
    ) async {
      await _pump(tester, _make(onChanged: (_) {}));

      final mouse = await _hoverWithMouse(tester, 'Mapa');
      await tester.pump(DsMotion.hover);

      expect(_decoration(tester, 'Mapa').color, DsColors.lineHairline);
      expect(tester.widget<AnimatedScale>(_scaleOf('Mapa')).scale, 1);

      await mouse.moveTo(_outside);
      await tester.pump(DsMotion.hover);
      expect(_decoration(tester, 'Mapa').color, const Color(0x00000000));
    });

    testWidgets('touch never tints a segment', (tester) async {
      await _pump(tester, _make(onChanged: (_) {}));

      final touch = await tester.startGesture(
        tester.getCenter(find.text('Mapa')),
      );
      await tester.pump(DsMotion.hover);
      expect(_decoration(tester, 'Mapa').color, const Color(0x00000000));
      await touch.up();
    });

    testWidgets('reduced motion: no scale movement, zero durations', (
      tester,
    ) async {
      await _pump(tester, _make(onChanged: (_) {}), reduceMotion: true);

      final press = await tester.startGesture(
        tester.getCenter(find.text('Mapa')),
      );
      await tester.pump();

      final scale = tester.widget<AnimatedScale>(_scaleOf('Mapa'));
      expect(scale.scale, 1);
      expect(scale.duration, Duration.zero);
      await press.up();
    });
  });

  group('keyboard', () {
    testWidgets('arrows only move focus, Enter and Space select', (
      tester,
    ) async {
      final values = <String>[];
      await _pump(tester, _make(onChanged: values.add));
      expect(find.byKey(_ringKey), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_ringIn('Globo'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(_ringIn('Mapa'), findsOneWidget);
      expect(_ringIn('Globo'), findsNothing);
      expect(values, isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(values, ['b']);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(_ringIn('Lista'), findsOneWidget);
      expect(values, ['b', 'c']);

      expect(tester.widget<AnimatedScale>(_scaleOf('Lista')).scale, 1);
    });

    testWidgets('arrows stop at both ends of the group', (tester) async {
      await _pump(tester, _make(onChanged: (_) {}));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(_ringIn('Globo'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(_ringIn('Lista'), findsOneWidget);
    });
  });
}
