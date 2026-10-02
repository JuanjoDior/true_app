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
  group('DsStatCell', () {
    testWidgets('shows the uppercase mono label above the value', (
      tester,
    ) async {
      await _pump(tester, const DsStatCell(label: 'Año', value: '1974'));

      expect(find.byType(DsMonoLabel), findsOneWidget);
      expect(find.text('AÑO'), findsOneWidget);
      expect(find.text('1974'), findsOneWidget);
      expect(
        tester.getBottomLeft(find.text('AÑO')).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.text('1974')).dy),
      );
    });

    testWidgets('mono value (default) uses monoData in accentGold', (
      tester,
    ) async {
      await _pump(tester, const DsStatCell(label: 'Víctimas', value: '12'));

      final style = tester.widget<Text>(find.text('12')).style!;
      expect(style.fontFamily, DsFontFamilies.mono);
      expect(style.color, DsColors.accentGold);
      expect(style.fontSize, DsTextStyles.mobile.monoData.fontSize);
    });

    testWidgets('mono value picks the desktop size at 1440 px', (tester) async {
      await _pump(
        tester,
        const DsStatCell(label: 'Víctimas', value: '12'),
        size: const Size(1440, 900),
      );

      expect(
        tester.widget<Text>(find.text('12')).style?.fontSize,
        DsTextStyles.desktop.monoData.fontSize,
      );
    });

    testWidgets('serif value uses serif 24 in textStrong', (tester) async {
      await _pump(
        tester,
        const DsStatCell(
          label: 'Estado',
          value: 'Abierto',
          valueStyle: DsStatValueStyle.serif,
        ),
      );

      final style = tester.widget<Text>(find.text('Abierto')).style!;
      expect(style.fontFamily, DsFontFamilies.display);
      expect(style.fontSize, 24);
      expect(style.color, DsColors.textStrong);
    });

    testWidgets('announces one merged "label: value" node', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const DsStatCell(label: 'Año', value: '1974'));

      expect(find.bySemanticsLabel('Año: 1974'), findsOneWidget);
      expect(find.bySemanticsLabel('Año'), findsNothing);
      expect(find.bySemanticsLabel('AÑO'), findsNothing);
      expect(find.bySemanticsLabel('1974'), findsNothing);
      handle.dispose();
    });

    testWidgets('no overflow with long content in 160 px', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 160,
          child: DsStatCell(
            label: 'Una etiqueta extraordinariamente larga',
            value: 'Un valor extraordinariamente largo para la celda',
            valueStyle: DsStatValueStyle.serif,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('survives text scale 2.0', (tester) async {
      await _pump(
        tester,
        const DsStatCell(label: 'Año', value: '1974'),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
