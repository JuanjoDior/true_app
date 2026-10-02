import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(390, 844),
  double textScale = 1,
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
        ),
        child: Scaffold(
          body: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    ),
  );
}

Finder get _dot => find.descendant(
  of: find.byType(DsStatusLabel),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is DecoratedBox &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).shape == BoxShape.circle,
  ),
);

void main() {
  group('DsStatusLabel', () {
    testWidgets('renders the label in the status color, 13 px / 500', (
      tester,
    ) async {
      await _pump(
        tester,
        const DsStatusLabel(label: 'Abierto', color: DsStatusColors.open),
      );

      final style = tester.widget<Text>(find.text('Abierto')).style!;
      expect(style.color, DsStatusColors.open);
      expect(style.fontSize, 13);
      expect(style.fontWeight, FontWeight.w500);
      expect(style.fontFamily, DsFontFamilies.sans);
    });

    testWidgets('dot is an 8x8 circle in the status color', (tester) async {
      await _pump(
        tester,
        const DsStatusLabel(label: 'Resuelto', color: DsStatusColors.solved),
      );

      expect(tester.getSize(_dot), const Size(8, 8));
      final decoration =
          tester.widget<DecoratedBox>(_dot).decoration as BoxDecoration;
      expect(decoration.color, DsStatusColors.solved);
    });

    testWidgets('gap between dot and text is 8 px', (tester) async {
      await _pump(
        tester,
        const DsStatusLabel(label: 'Resuelto', color: DsStatusColors.solved),
      );

      final dot = tester.getRect(_dot);
      final text = tester.getRect(find.text('Resuelto'));
      expect(text.left - dot.right, DsSpacing.s8);
    });

    testWidgets('reads the text only; the dot is excluded', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const DsStatusLabel(
          label: 'En curso',
          color: DsStatusColors.inProgress,
        ),
      );

      expect(find.bySemanticsLabel('En curso'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DsStatusLabel),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('ellipsizes a long label inside 160 px without overflow', (
      tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 160,
          child: DsStatusLabel(
            label: 'Un estado con una descripción extraordinariamente larga',
            color: DsStatusColors.delivered,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(DsStatusLabel)).width,
        lessThanOrEqualTo(160),
      );
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('survives text scale 2.0', (tester) async {
      await _pump(
        tester,
        const DsStatusLabel(label: 'Abierto', color: DsStatusColors.open),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
