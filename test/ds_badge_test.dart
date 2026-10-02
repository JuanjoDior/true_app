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

void main() {
  const color = DsCategoryColors.serialKiller;

  group('DsBadge', () {
    testWidgets('renders the label as-is with the given color', (tester) async {
      await _pump(tester, DsBadge(label: 'Asesino serial', color: color.dot));

      final text = tester.widget<Text>(find.text('Asesino serial'));
      expect(text.style?.color, color.dot);
    });

    testWidgets('text is 12 px / 600 sans', (tester) async {
      await _pump(tester, DsBadge(label: 'Abierto', color: color.dot));

      final style = tester.widget<Text>(find.text('Abierto')).style!;
      expect(style.fontSize, 12);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.fontFamily, DsFontFamilies.sans);
    });

    testWidgets('is 28 px tall with a 1 px outline and badge radius', (
      tester,
    ) async {
      await _pump(tester, DsBadge(label: 'Abierto', color: color.dot));

      expect(tester.getSize(find.byType(DsBadge)).height, 28);

      final decoration = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(DsBadge),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .single;
      final border = decoration.border! as Border;
      expect(border.top.width, 1);
      expect(border.top.color, color.dot);
      expect(decoration.color, isNull);
      expect(decoration.borderRadius, DsRadii.badgeBorder);
    });

    testWidgets('has 10 px horizontal padding', (tester) async {
      await _pump(tester, DsBadge(label: 'Abierto', color: color.dot));

      final badge = tester.getRect(find.byType(DsBadge));
      final text = tester.getRect(find.text('Abierto'));
      // 1 px de borde + 10 px de relleno a cada lado
      expect(text.left - badge.left, DsSpacing.s10 + 1);
      expect(badge.right - text.right, DsSpacing.s10 + 1);
    });

    testWidgets('exposes the label to semantics once', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, DsBadge(label: 'Resuelto', color: color.dot));

      expect(find.bySemanticsLabel('Resuelto'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('ellipsizes a long label inside 160 px without overflow', (
      tester,
    ) async {
      await _pump(
        tester,
        SizedBox(
          width: 160,
          child: Align(
            alignment: Alignment.centerLeft,
            child: DsBadge(
              label: 'Una etiqueta de categoría extraordinariamente larga',
              color: color.dot,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(DsBadge)).width,
        lessThanOrEqualTo(160),
      );
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('survives text scale 2.0', (tester) async {
      await _pump(
        tester,
        DsBadge(label: 'Abierto', color: color.dot),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(DsBadge)).height,
        greaterThanOrEqualTo(28),
      );
    });
  });
}
