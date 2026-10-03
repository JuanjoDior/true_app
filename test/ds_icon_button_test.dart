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

Finder get _button => find.byType(DsIconButton);

DsIconButton _make({VoidCallback? onPressed}) => DsIconButton(
  icon: Icons.close,
  semanticLabel: 'Close',
  onPressed: onPressed,
);

AnimatedScale _animatedScale(WidgetTester tester) =>
    tester.widget<AnimatedScale>(
      find.descendant(of: _button, matching: find.byType(AnimatedScale)),
    );

BoxDecoration _decoration(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(of: _button, matching: find.byType(AnimatedContainer)),
  );
  return container.decoration! as BoxDecoration;
}

Future<TestGesture> _hoverWithMouse(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: _outside);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(tester.getCenter(_button));
  await tester.pump();
  return gesture;
}

void main() {
  group('layout and colors', () {
    testWidgets('is 44x44 with control radius and a transparent background', (
      tester,
    ) async {
      await _pump(tester, _make(onPressed: () {}));

      expect(tester.getSize(_button), const Size(44, 44));
      expect(_decoration(tester).borderRadius, DsRadii.controlBorder);
      expect(_decoration(tester).color, const Color(0x00000000));
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.close);
      expect(icon.color, DsColors.textPrimary);
    });

    testWidgets('stays 44x44 at text scale 2.0', (tester) async {
      await _pump(tester, _make(onPressed: () {}), textScale: 2);

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_button), const Size(44, 44));
    });

    testWidgets('tooltip equals the semantic label', (tester) async {
      await _pump(tester, _make(onPressed: () {}));

      expect(tester.widget<Tooltip>(find.byType(Tooltip)).message, 'Close');
    });

    testWidgets('disabled uses the placeholder icon color', (tester) async {
      await _pump(tester, _make());

      expect(
        tester.widget<Icon>(find.byType(Icon)).color,
        DsColors.textPlaceholder,
      );
    });
  });

  group('tap and semantics', () {
    testWidgets('tapping calls onPressed once', (tester) async {
      var calls = 0;
      await _pump(tester, _make(onPressed: () => calls++));

      await tester.tap(_button);

      expect(calls, 1);
    });

    testWidgets('semantics expose the label, button role and enabled state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _make(onPressed: () {}));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Close')),
        isSemantics(
          label: 'Close',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );

      await _pump(tester, _make());
      expect(
        tester.getSemantics(find.bySemanticsLabel('Close')),
        isSemantics(
          label: 'Close',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });
  });

  group('motion', () {
    testWidgets(
      'mouse hover paints a white 10% background and does not scale',
      (tester) async {
        await _pump(tester, _make(onPressed: () {}));

        final mouse = await _hoverWithMouse(tester);
        await tester.pump(DsMotion.hover);

        expect(_decoration(tester).color, DsColors.lineHairline);
        expect(_animatedScale(tester).scale, 1);

        await mouse.moveTo(_outside);
        await tester.pump(DsMotion.hover);
        expect(_decoration(tester).color, const Color(0x00000000));
      },
    );

    testWidgets('touch never paints the hover background', (tester) async {
      await _pump(tester, _make(onPressed: () {}));

      final touch = await tester.startGesture(tester.getCenter(_button));
      await tester.pump(DsMotion.hover);
      expect(_decoration(tester).color, const Color(0x00000000));
      await touch.up();
      await tester.pumpAndSettle();

      expect(_decoration(tester).color, const Color(0x00000000));
    });

    testWidgets('press scales to 0.97 in 160 ms with easeUi', (tester) async {
      await _pump(tester, _make(onPressed: () {}));

      final press = await tester.startGesture(tester.getCenter(_button));
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

    testWidgets('disabled: no hover background and no press scale', (
      tester,
    ) async {
      await _pump(tester, _make());

      final press = await tester.startGesture(tester.getCenter(_button));
      await tester.pump(DsMotion.press);
      expect(_animatedScale(tester).scale, 1);
      await press.up();
      await tester.pumpAndSettle();

      await _hoverWithMouse(tester);
      await tester.pump(DsMotion.hover);
      expect(_decoration(tester).color, const Color(0x00000000));
    });

    testWidgets('reduced motion: color still changes, nothing moves', (
      tester,
    ) async {
      await _pump(tester, _make(onPressed: () {}), reduceMotion: true);

      await _hoverWithMouse(tester);
      await tester.pump();
      expect(_decoration(tester).color, DsColors.lineHairline);

      final press = await tester.startGesture(tester.getCenter(_button));
      await tester.pump();
      expect(_animatedScale(tester).scale, 1);
      expect(_animatedScale(tester).duration, Duration.zero);
      await press.up();
    });
  });

  group('keyboard', () {
    testWidgets('Tab shows the focus ring and Enter / Space activate', (
      tester,
    ) async {
      var calls = 0;
      await _pump(tester, _make(onPressed: () => calls++));
      expect(find.byKey(_ringKey), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(find.byKey(_ringKey), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(calls, 2);
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
