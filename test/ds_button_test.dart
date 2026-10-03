import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

const _mobile = Size(390, 844);
const _desktop = Size(1280, 800);
const _ringKey = ValueKey('ds-focus-ring');
// Fuera del botón: el puntero de ratón entra desde aquí
const _outside = Offset(385, 840);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = _mobile,
  double textScale = 1,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DsTheme.build(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
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

Finder get _button => find.byType(DsButton);

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

Border _border(WidgetTester tester) => _decoration(tester).border! as Border;

TextStyle _labelStyle(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!;

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
  group('variants', () {
    testWidgets('primary uses ctaBg / ctaFg with no visible border', (
      tester,
    ) async {
      await _pump(tester, DsButton(label: 'Open', onPressed: () {}));

      expect(_decoration(tester).color, DsColors.ctaBg);
      expect(_labelStyle(tester, 'Open').color, DsColors.ctaFg);
      expect(_border(tester).top.color, const Color(0x00000000));
    });

    testWidgets('glass uses ctaGlass with a ctaGlassBorder 1 px border', (
      tester,
    ) async {
      await _pump(
        tester,
        DsButton(
          label: 'Open',
          variant: DsButtonVariant.glass,
          onPressed: () {},
        ),
      );

      expect(_decoration(tester).color, DsColors.ctaGlass);
      expect(_border(tester).top.color, DsColors.ctaGlassBorder);
      expect(_border(tester).top.width, 1);
      expect(_labelStyle(tester, 'Open').color, DsColors.textPrimary);
    });

    testWidgets('outline is transparent with a 1 px ctaOutlineBorder', (
      tester,
    ) async {
      await _pump(
        tester,
        DsButton(
          label: 'Open',
          variant: DsButtonVariant.outline,
          onPressed: () {},
        ),
      );

      expect(_decoration(tester).color, const Color(0x00000000));
      expect(_border(tester).top.color, DsColors.ctaOutlineBorder);
      expect(_border(tester).top.width, 1);
      expect(_labelStyle(tester, 'Open').color, DsColors.textPrimary);
    });

    testWidgets('label uses the uiButton style and control radius', (
      tester,
    ) async {
      await _pump(tester, DsButton(label: 'Open', onPressed: () {}));

      final style = _labelStyle(tester, 'Open');
      expect(style.fontSize, DsTextStyles.mobile.uiButton.fontSize);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.fontFamily, DsFontFamilies.sans);
      expect(_decoration(tester).borderRadius, DsRadii.controlBorder);
    });
  });

  group('layout', () {
    testWidgets('is 56 px tall on mobile', (tester) async {
      await _pump(tester, DsButton(label: 'Open', onPressed: () {}));

      expect(tester.getSize(_button).height, 56);
    });

    testWidgets('is 52 px tall from the desktop breakpoint', (tester) async {
      await _pump(
        tester,
        DsButton(label: 'Open', onPressed: () {}),
        size: _desktop,
      );

      expect(tester.getSize(_button).height, 52);
    });

    testWidgets('hugs its content unless expand is set', (tester) async {
      await _pump(tester, DsButton(label: 'Open', onPressed: () {}));
      expect(tester.getSize(_button).width, lessThan(200));

      await _pump(
        tester,
        DsButton(label: 'Open', onPressed: () {}, expand: true),
      );
      expect(tester.getSize(_button).width, _mobile.width);
    });

    testWidgets('shows the trailing icon only when given', (tester) async {
      await _pump(tester, DsButton(label: 'Open', onPressed: () {}));
      expect(find.byType(Icon), findsNothing);

      await _pump(
        tester,
        DsButton(
          label: 'Open',
          onPressed: () {},
          trailingIcon: Icons.arrow_forward,
        ),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.arrow_forward);
      expect(icon.color, DsColors.ctaFg);
    });

    testWidgets('grows with text scale 2.0 without overflowing', (
      tester,
    ) async {
      await _pump(
        tester,
        DsButton(
          label: 'Abrir el expediente completo',
          onPressed: () {},
          trailingIcon: Icons.arrow_forward,
        ),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_button).height, greaterThanOrEqualTo(56));
    });
  });

  group('tap and disabled', () {
    testWidgets('tapping calls onPressed once', (tester) async {
      var calls = 0;
      await _pump(tester, DsButton(label: 'Open', onPressed: () => calls++));

      await tester.tap(_button);

      expect(calls, 1);
    });

    testWidgets('disabled uses placeholder colors on surfaceCard', (
      tester,
    ) async {
      await _pump(tester, const DsButton(label: 'Open', onPressed: null));

      expect(_decoration(tester).color, DsColors.surfaceCard);
      expect(_labelStyle(tester, 'Open').color, DsColors.textPlaceholder);
    });

    testWidgets('disabled does not scale on press or on mouse hover', (
      tester,
    ) async {
      await _pump(tester, const DsButton(label: 'Open', onPressed: null));

      final press = await tester.startGesture(tester.getCenter(_button));
      await tester.pump(DsMotion.press);
      expect(_animatedScale(tester).scale, 1);
      await press.up();
      await tester.pumpAndSettle();

      await _hoverWithMouse(tester);
      await tester.pump(DsMotion.hover);
      expect(_animatedScale(tester).scale, 1);
    });

    testWidgets('disabled is not focusable and ignores the keyboard', (
      tester,
    ) async {
      await _pump(tester, const DsButton(label: 'Open', onPressed: null));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(find.byKey(_ringKey), findsNothing);
    });

    testWidgets('semantics: enabled button vs disabled button', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, DsButton(label: 'Open', onPressed: () {}));
      expect(
        tester.getSemantics(_button),
        isSemantics(
          label: 'Open',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );

      await _pump(tester, const DsButton(label: 'Open', onPressed: null));
      expect(
        tester.getSemantics(_button),
        isSemantics(
          label: 'Open',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });
  });

  group('motion', () {
    testWidgets('press scales to 0.97 in 160 ms with easeUi and releases', (
      tester,
    ) async {
      await _pump(tester, DsButton(label: 'Open', onPressed: () {}));

      final press = await tester.startGesture(tester.getCenter(_button));
      await tester.pump();
      await tester.pump(DsMotion.press);

      final scale = _animatedScale(tester);
      expect(scale.scale, 0.97);
      expect(scale.duration, DsMotion.press);
      expect(scale.curve, DsMotion.easeUi);
      final rendered = tester.widget<ScaleTransition>(
        find.descendant(of: _button, matching: find.byType(ScaleTransition)),
      );
      expect(rendered.scale.value, closeTo(0.97, 0.001));

      await press.up();
      await tester.pumpAndSettle();
      expect(_animatedScale(tester).scale, 1);
    });

    testWidgets('mouse hover scales to 1.04 over the hover duration', (
      tester,
    ) async {
      await _pump(tester, DsButton(label: 'Open', onPressed: () {}));

      final mouse = await _hoverWithMouse(tester);
      await tester.pump(DsMotion.hover);

      final scale = _animatedScale(tester);
      expect(scale.scale, 1.04);
      expect(scale.duration, DsMotion.hover);
      expect(scale.curve, DsMotion.easeUi);

      await mouse.moveTo(_outside);
      await tester.pump(DsMotion.hover);
      expect(_animatedScale(tester).scale, 1);
    });

    testWidgets('a non-mouse hovering pointer (stylus) does not scale', (
      tester,
    ) async {
      await _pump(tester, DsButton(label: 'Open', onPressed: () {}));

      final stylus = await tester.createGesture(kind: PointerDeviceKind.stylus);
      await stylus.addPointer(location: _outside);
      addTearDown(stylus.removePointer);
      await stylus.moveTo(tester.getCenter(_button));
      await tester.pump();
      await tester.pump(DsMotion.hover);

      expect(_animatedScale(tester).scale, 1);
    });

    testWidgets('touch never triggers hover scale', (tester) async {
      await _pump(tester, DsButton(label: 'Open', onPressed: () {}));

      final touch = await tester.startGesture(tester.getCenter(_button));
      await tester.pump(DsMotion.press);
      expect(_animatedScale(tester).scale, 0.97);
      await touch.up();
      await tester.pumpAndSettle();

      expect(_animatedScale(tester).scale, 1);
    });

    testWidgets('mouse press wins over hover and returns to hover', (
      tester,
    ) async {
      await _pump(tester, DsButton(label: 'Open', onPressed: () {}));

      final mouse = await _hoverWithMouse(tester);
      await mouse.down(tester.getCenter(_button));
      await tester.pump(DsMotion.press);
      expect(_animatedScale(tester).scale, 0.97);

      await mouse.up();
      await tester.pump(DsMotion.hover);
      expect(_animatedScale(tester).scale, 1.04);
    });

    testWidgets('reduced motion: no scale movement and zero durations', (
      tester,
    ) async {
      var calls = 0;
      await _pump(
        tester,
        DsButton(label: 'Open', onPressed: () => calls++),
        reduceMotion: true,
      );

      await _hoverWithMouse(tester);
      await tester.pump();
      expect(_animatedScale(tester).scale, 1);
      expect(_animatedScale(tester).duration, Duration.zero);

      final press = await tester.startGesture(tester.getCenter(_button));
      await tester.pump();
      expect(_animatedScale(tester).scale, 1);
      await press.up();
      await tester.pump();

      expect(calls, 1);
    });
  });

  group('keyboard', () {
    testWidgets('Tab shows a 2 px accentRedText focus ring', (tester) async {
      await _pump(tester, DsButton(label: 'Open', onPressed: () {}));
      expect(find.byKey(_ringKey), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final ring = tester.widget<DecoratedBox>(find.byKey(_ringKey));
      final border = (ring.decoration as BoxDecoration).border! as Border;
      expect(border.top.color, DsColors.accentRedText);
      expect(border.top.width, 2);
    });

    testWidgets('pointer interaction does not show the focus ring', (
      tester,
    ) async {
      await _pump(tester, DsButton(label: 'Open', onPressed: () {}));

      await tester.tap(_button);
      await tester.pumpAndSettle();

      expect(find.byKey(_ringKey), findsNothing);
    });

    testWidgets('Enter and Space activate without any scale animation', (
      tester,
    ) async {
      var calls = 0;
      await _pump(tester, DsButton(label: 'Open', onPressed: () => calls++));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(calls, 1);
      expect(_animatedScale(tester).scale, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(calls, 2);
      expect(_animatedScale(tester).scale, 1);
    });
  });
}
