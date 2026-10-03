import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

const _mobile = Size(390, 844);
const _desktop = Size(1280, 800);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = _mobile,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DsTheme.build(),
      builder: (context, app) => MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: app!,
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Align(alignment: Alignment.topCenter, child: child),
        ),
      ),
    ),
  );
}

Finder get _box => find.byKey(DsFormField.boxKey);

BoxDecoration _boxDecoration(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(_box);
  return container.decoration! as BoxDecoration;
}

Border _border(WidgetTester tester) => _boxDecoration(tester).border! as Border;

BoxShadow _halo(WidgetTester tester) =>
    _boxDecoration(tester).boxShadow!.single;

EditableText _editable(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

void _expectHaloOff(WidgetTester tester) {
  expect(_border(tester).top.color, DsColors.lineInput);
  expect(_halo(tester).color.a, 0);
}

void _expectHaloOn(WidgetTester tester) {
  expect(_border(tester).top.color, DsColors.accentRed);
  expect(_border(tester).top.width, 1);
  expect(_halo(tester).spreadRadius, 3);
  expect(_halo(tester).blurRadius, 0);
  expect(_halo(tester).color.toARGB32() & 0xFFFFFF, 0xE5484D);
  expect(_halo(tester).color.a, closeTo(0.25, 0.01));
}

void main() {
  group('DsFormField appearance', () {
    testWidgets('label sits above the field with 13/500 textBody', (
      tester,
    ) async {
      await _pump(tester, const DsFormField(label: 'Email'));

      final style = tester.widget<Text>(find.text('Email')).style!;
      expect(style.fontSize, 13);
      expect(style.fontWeight, FontWeight.w500);
      expect(style.color, DsColors.textBody);
      expect(
        tester.getBottomLeft(find.text('Email')).dy,
        lessThanOrEqualTo(tester.getTopLeft(_box).dy),
      );
    });

    testWidgets('is 48 high with surfaceInput fill, lineInput border, control '
        'radius', (tester) async {
      await _pump(tester, const DsFormField(label: 'Email'));

      expect(tester.getSize(_box).height, 48);
      final decoration = _boxDecoration(tester);
      expect(decoration.color, DsColors.surfaceInput);
      expect(decoration.borderRadius, DsRadii.controlBorder);
      expect(_border(tester).top.width, 1);
      _expectHaloOff(tester);
    });

    testWidgets('hint uses textPlaceholder', (tester) async {
      await _pump(tester, const DsFormField(label: 'Email', hint: 'a@b.c'));

      expect(
        tester.widget<Text>(find.text('a@b.c')).style!.color,
        DsColors.textPlaceholder,
      );
    });

    testWidgets('typed text uses textPrimary body style', (tester) async {
      await _pump(tester, const DsFormField(label: 'Email'));

      expect(_editable(tester).style.color, DsColors.textPrimary);
      expect(_editable(tester).style.fontSize, 15);
    });

    testWidgets('helper text is textFaint 12', (tester) async {
      await _pump(
        tester,
        const DsFormField(label: 'Email', helper: 'We never share it'),
      );

      final style = tester.widget<Text>(find.text('We never share it')).style!;
      expect(style.color, DsColors.textFaint);
      expect(style.fontSize, 12);
    });

    testWidgets('maxLines > 1 makes the field taller and grows with lines', (
      tester,
    ) async {
      await _pump(tester, const DsFormField(label: 'Notes', maxLines: 4));

      expect(tester.getSize(_box).height, greaterThan(48));
      expect(_editable(tester).maxLines, 4);
      expect(_editable(tester).minLines, 4);
    });

    testWidgets('shows the initial text of a provided controller', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'seed');
      addTearDown(controller.dispose);
      await _pump(tester, DsFormField(label: 'Email', controller: controller));

      expect(find.text('seed'), findsOneWidget);
    });
  });

  group('DsFormField focus', () {
    testWidgets('tap shows the red border and 3 px halo without resizing', (
      tester,
    ) async {
      await _pump(tester, const DsFormField(label: 'Email'));
      final before = tester.getSize(find.byType(DsFormField));
      final boxBefore = tester.getSize(_box);

      await tester.tap(_box);
      await tester.pumpAndSettle();

      _expectHaloOn(tester);
      expect(tester.getSize(find.byType(DsFormField)), before);
      expect(tester.getSize(_box), boxBefore);
    });

    testWidgets('keyboard traversal shows the halo', (tester) async {
      await _pump(tester, const DsFormField(label: 'Email'));
      _expectHaloOff(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      _expectHaloOn(tester);
    });

    testWidgets('losing focus removes the halo', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await _pump(tester, DsFormField(label: 'Email', focusNode: node));

      node.requestFocus();
      await tester.pumpAndSettle();
      _expectHaloOn(tester);

      node.unfocus();
      await tester.pumpAndSettle();
      _expectHaloOff(tester);
    });

    testWidgets('an external focus node is used and left alive', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await _pump(tester, DsFormField(label: 'Email', focusNode: node));

      await tester.tap(_box);
      await tester.pump();
      expect(node.hasFocus, isTrue);

      await tester.pumpWidget(const SizedBox());
      // Un nodo liberado lanza al añadirle oyentes
      expect(() => node.addListener(() {}), returnsNormally);
    });

    testWidgets('tapping the vertical padding of the box focuses the field', (
      tester,
    ) async {
      await _pump(tester, const DsFormField(label: 'Email'));

      final rect = tester.getRect(_box);
      await tester.tapAt(Offset(rect.left + 20, rect.top + 3));
      await tester.pump();

      expect(_editable(tester).focusNode.hasFocus, isTrue);
    });
  });

  group('DsFormField error', () {
    testWidgets('shows the error in accentRedText with an alert icon', (
      tester,
    ) async {
      await _pump(
        tester,
        const DsFormField(label: 'Email', errorText: 'Invalid email'),
      );

      final style = tester.widget<Text>(find.text('Invalid email')).style!;
      expect(style.color, DsColors.accentRedText);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.error_outline_rounded)).color,
        DsColors.accentRedText,
      );
      expect(_border(tester).top.color, DsColors.accentRedText);
      expect(_border(tester).top.width, 1);
    });

    testWidgets('the error is announced as a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const DsFormField(label: 'Email', errorText: 'Invalid email'),
      );

      expect(
        tester.getSemantics(find.text('Invalid email')),
        isSemantics(label: 'Invalid email', isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('without an error there is no alert icon or live region', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const DsFormField(label: 'Email', helper: 'We never share it'),
      );

      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
      expect(
        tester.getSemantics(find.text('We never share it')),
        isNot(isSemantics(isLiveRegion: true)),
      );
      handle.dispose();
    });

    testWidgets('the error replaces the helper text', (tester) async {
      await _pump(
        tester,
        const DsFormField(
          label: 'Email',
          helper: 'We never share it',
          errorText: 'Invalid email',
        ),
      );

      expect(find.text('We never share it'), findsNothing);
      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('keeps the red error border while focused, halo included', (
      tester,
    ) async {
      await _pump(
        tester,
        const DsFormField(label: 'Email', errorText: 'Invalid email'),
      );

      await tester.tap(_box);
      await tester.pumpAndSettle();

      expect(_border(tester).top.color, DsColors.accentRedText);
      expect(_halo(tester).spreadRadius, 3);
      expect(_halo(tester).color.a, closeTo(0.25, 0.01));
    });

    testWidgets('the field box does not change size when the error appears', (
      tester,
    ) async {
      await _pump(tester, const DsFormField(label: 'Email'));
      final boxSize = tester.getSize(_box);
      final boxTop = tester.getTopLeft(_box);

      await _pump(
        tester,
        const DsFormField(label: 'Email', errorText: 'Invalid email'),
      );

      expect(tester.getSize(_box), boxSize);
      expect(tester.getTopLeft(_box), boxTop);
    });
  });

  group('DsFormField semantics', () {
    testWidgets('exposes the label as a text field semantic label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const DsFormField(label: 'Email'));

      expect(find.bySemanticsLabel('Email'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Email')),
        isSemantics(label: 'Email', isTextField: true),
      );
      handle.dispose();
    });

    testWidgets('an enabled field reports itself as enabled', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const DsFormField(label: 'Email'));

      expect(
        tester.getSemantics(find.bySemanticsLabel('Email')),
        isSemantics(
          label: 'Email',
          isTextField: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a disabled field reports itself as not enabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const DsFormField(label: 'Email', enabled: false));

      expect(
        tester.getSemantics(find.bySemanticsLabel('Email')),
        isSemantics(
          label: 'Email',
          isTextField: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });
  });

  group('DsFormField enabled state', () {
    testWidgets('disabled uses textPlaceholder text and never focuses', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'locked');
      addTearDown(controller.dispose);
      await _pump(
        tester,
        DsFormField(label: 'Email', controller: controller, enabled: false),
      );

      expect(_editable(tester).style.color, DsColors.textPlaceholder);

      await tester.tap(_box);
      await tester.pumpAndSettle();
      expect(_editable(tester).focusNode.hasFocus, isFalse);
      _expectHaloOff(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      _expectHaloOff(tester);
    });

    testWidgets('enabled is the default and accepts typing', (tester) async {
      final changes = <String>[];
      await _pump(tester, DsFormField(label: 'Email', onChanged: changes.add));

      await tester.enterText(find.byType(EditableText), 'ana@x.io');
      await tester.pump();

      expect(changes, ['ana@x.io']);
      expect(find.text('ana@x.io'), findsOneWidget);
    });
  });

  group('DsFormField input behavior', () {
    testWidgets('typing updates the controller and calls onChanged', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final changes = <String>[];
      await _pump(
        tester,
        DsFormField(
          label: 'Email',
          controller: controller,
          onChanged: changes.add,
        ),
      );

      await tester.enterText(find.byType(EditableText), 'a');
      await tester.enterText(find.byType(EditableText), 'ab');

      expect(controller.text, 'ab');
      expect(changes, ['a', 'ab']);
    });

    testWidgets('submitting calls onSubmitted with the text', (tester) async {
      final submitted = <String>[];
      await _pump(
        tester,
        DsFormField(
          label: 'Email',
          onSubmitted: submitted.add,
          textInputAction: TextInputAction.done,
        ),
      );

      await tester.tap(_box);
      await tester.enterText(find.byType(EditableText), 'ana');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submitted, ['ana']);
    });

    testWidgets('obscureText hides the input; default does not', (
      tester,
    ) async {
      await _pump(
        tester,
        const DsFormField(label: 'Password', obscureText: true),
      );
      expect(_editable(tester).obscureText, isTrue);

      await _pump(tester, const DsFormField(label: 'Password'));
      expect(_editable(tester).obscureText, isFalse);
    });

    testWidgets('forwards keyboard type, input action and autofill hints', (
      tester,
    ) async {
      await _pump(
        tester,
        const DsFormField(
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: [AutofillHints.email],
        ),
      );

      final editable = _editable(tester);
      expect(editable.keyboardType, TextInputType.emailAddress);
      expect(editable.textInputAction, TextInputAction.next);
      expect(editable.autofillHints, [AutofillHints.email]);
    });
  });

  group('DsFormField layout robustness', () {
    testWidgets('survives text scale 2.0 and the box only grows', (
      tester,
    ) async {
      await _pump(
        tester,
        const DsFormField(
          label: 'Email address of the person in the file',
          hint: 'name@example.com',
          helper: 'We never share it with anyone outside the archive',
        ),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_box).height, greaterThanOrEqualTo(48));
    });

    testWidgets('does not overflow at 390 px with long texts', (tester) async {
      await _pump(
        tester,
        DsFormField(
          label: 'Label ' * 20,
          errorText: 'Error message ' * 20,
          maxLines: 3,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(DsFormField)).width, 390 - 32);
    });

    testWidgets('lays out on desktop', (tester) async {
      await _pump(
        tester,
        const SizedBox(width: 320, child: DsFormField(label: 'Email')),
        size: _desktop,
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_box).width, 320);
    });
  });
}
