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

Finder get _chip => find.byType(DsFilterChip);

DsFilterChip _make({bool selected = false, ValueChanged<bool>? onSelected}) =>
    DsFilterChip(label: 'Abiertos', selected: selected, onSelected: onSelected);

Finder get _visual =>
    find.descendant(of: _chip, matching: find.byType(AnimatedContainer));

AnimatedScale _animatedScale(WidgetTester tester) =>
    tester.widget<AnimatedScale>(
      find.descendant(of: _chip, matching: find.byType(AnimatedScale)),
    );

BoxDecoration _decoration(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(_visual).decoration! as BoxDecoration;

TextStyle _labelStyle(WidgetTester tester) =>
    tester.widget<Text>(find.text('Abiertos')).style!;

double _shiftX(WidgetTester tester) => tester
    .widgetList<Transform>(
      find.descendant(of: _chip, matching: find.byType(Transform)),
    )
    .fold<double>(0, (sum, t) => sum + t.transform.getTranslation().x);

Future<TestGesture> _hoverWithMouse(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: _outside);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(tester.getCenter(_chip));
  await tester.pump();
  return gesture;
}

void main() {
  group('layout and colors', () {
    testWidgets('is a 40 px pill with a 44 px tap area', (tester) async {
      await _pump(tester, _make(onSelected: (_) {}));

      expect(tester.getSize(_visual).height, 40);
      expect(tester.getSize(_chip).height, 44);
      expect(_decoration(tester).borderRadius, DsRadii.pillBorder);
    });

    testWidgets('a tap in the 2 px band above the pill still selects', (
      tester,
    ) async {
      final values = <bool>[];
      await _pump(tester, _make(onSelected: values.add));

      final top = tester.getTopLeft(_visual);
      await tester.tapAt(top + const Offset(10, -1));

      expect(values, [true]);
    });

    testWidgets('inactive uses surfaceCard with a hairline border', (
      tester,
    ) async {
      await _pump(tester, _make(onSelected: (_) {}));

      final decoration = _decoration(tester);
      expect(decoration.color, DsColors.surfaceCard);
      expect((decoration.border! as Border).top.color, DsColors.lineHairline);
      expect(_labelStyle(tester).color, DsColors.textBody);
    });

    testWidgets('active uses ctaBg / ctaFg at weight 600', (tester) async {
      await _pump(tester, _make(selected: true, onSelected: (_) {}));

      expect(_decoration(tester).color, DsColors.ctaBg);
      expect(_labelStyle(tester).color, DsColors.ctaFg);
      expect(_labelStyle(tester).fontWeight, FontWeight.w600);
    });

    testWidgets('disabled uses placeholder colors on surfaceCard', (
      tester,
    ) async {
      await _pump(tester, _make(selected: true));

      expect(_decoration(tester).color, DsColors.surfaceCard);
      expect(_labelStyle(tester).color, DsColors.textPlaceholder);
    });

    testWidgets('survives text scale 2.0 without exceptions', (tester) async {
      await _pump(tester, _make(onSelected: (_) {}), textScale: 2);

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_visual).height, greaterThanOrEqualTo(40));
    });
  });

  group('selection and semantics', () {
    testWidgets('tapping reports the toggled value', (tester) async {
      final values = <bool>[];
      await _pump(tester, _make(onSelected: values.add));
      await tester.tap(_chip);

      await _pump(tester, _make(selected: true, onSelected: values.add));
      await tester.tap(_chip);

      expect(values, [true, false]);
    });

    testWidgets('semantics: button with selected and enabled state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _make(selected: true, onSelected: (_) {}));
      expect(
        tester.getSemantics(_chip),
        isSemantics(
          label: 'Abiertos',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );

      await _pump(tester, _make());
      expect(
        tester.getSemantics(_chip),
        isSemantics(
          label: 'Abiertos',
          isButton: true,
          hasSelectedState: true,
          isSelected: false,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });
  });

  group('motion', () {
    testWidgets('mouse hover shifts 4 px on X and does not scale', (
      tester,
    ) async {
      await _pump(tester, _make(onSelected: (_) {}));
      expect(_shiftX(tester), 0);

      final mouse = await _hoverWithMouse(tester);
      await tester.pump(DsMotion.hover);

      expect(_shiftX(tester), 4);
      expect(_animatedScale(tester).scale, 1);

      await mouse.moveTo(_outside);
      await tester.pump();
      await tester.pump(DsMotion.hover);
      expect(_shiftX(tester), 0);
    });

    testWidgets('touch never shifts the chip', (tester) async {
      await _pump(tester, _make(onSelected: (_) {}));

      final touch = await tester.startGesture(tester.getCenter(_chip));
      await tester.pump(DsMotion.hover);
      expect(_shiftX(tester), 0);
      await touch.up();
      await tester.pumpAndSettle();

      expect(_shiftX(tester), 0);
    });

    testWidgets('press scales to 0.97 in 160 ms with easeUi', (tester) async {
      await _pump(tester, _make(onSelected: (_) {}));

      final press = await tester.startGesture(tester.getCenter(_chip));
      await tester.pump();
      await tester.pump(DsMotion.press);

      final scale = _animatedScale(tester);
      expect(scale.scale, 0.97);
      expect(scale.duration, DsMotion.press);
      expect(scale.curve, DsMotion.easeUi);

      await press.up();
      await tester.pumpAndSettle();
      expect(_animatedScale(tester).scale, 1);
    });

    testWidgets('disabled: no shift and no press scale', (tester) async {
      await _pump(tester, _make());

      final press = await tester.startGesture(tester.getCenter(_chip));
      await tester.pump(DsMotion.press);
      expect(_animatedScale(tester).scale, 1);
      await press.up();
      await tester.pumpAndSettle();

      await _hoverWithMouse(tester);
      await tester.pump(DsMotion.hover);
      expect(_shiftX(tester), 0);
    });

    testWidgets('reduced motion: no shift, no scale, zero durations', (
      tester,
    ) async {
      await _pump(tester, _make(onSelected: (_) {}), reduceMotion: true);

      await _hoverWithMouse(tester);
      await tester.pump();
      expect(_shiftX(tester), 0);

      final press = await tester.startGesture(tester.getCenter(_chip));
      await tester.pump();
      expect(_animatedScale(tester).scale, 1);
      expect(_animatedScale(tester).duration, Duration.zero);
      await press.up();
    });
  });

  group('keyboard', () {
    testWidgets('Tab shows the focus ring and Enter / Space toggle', (
      tester,
    ) async {
      final values = <bool>[];
      await _pump(tester, _make(onSelected: values.add));
      expect(find.byKey(_ringKey), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(find.byKey(_ringKey), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(values, [true, true]);
      expect(_animatedScale(tester).scale, 1);
    });

    testWidgets('disabled is not focusable', (tester) async {
      await _pump(tester, _make());

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(find.byKey(_ringKey), findsNothing);
    });
  });
}
