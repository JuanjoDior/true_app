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
  group('DsMonoLabel', () {
    testWidgets('uppercases and keeps Spanish accents', (tester) async {
      await _pump(
        tester,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [DsMonoLabel('Año'), DsMonoLabel('Última actualización')],
        ),
      );

      expect(find.text('AÑO'), findsOneWidget);
      expect(find.text('ÚLTIMA ACTUALIZACIÓN'), findsOneWidget);
    });

    testWidgets('uses monoLabel with textMuted by default', (tester) async {
      await _pump(tester, const DsMonoLabel('Fecha'));

      final style = tester.widget<Text>(find.text('FECHA')).style!;
      expect(style.fontFamily, DsFontFamilies.mono);
      expect(style.fontWeight, FontWeight.w500);
      expect(style.color, DsColors.textMuted);
    });

    testWidgets('accepts a custom color', (tester) async {
      await _pump(
        tester,
        const DsMonoLabel('Fecha', color: DsColors.accentGold),
      );

      expect(
        tester.widget<Text>(find.text('FECHA')).style?.color,
        DsColors.accentGold,
      );
    });

    testWidgets('letter spacing defaults to 0.18 em of 11 px', (tester) async {
      await _pump(tester, const DsMonoLabel('Fecha'));

      expect(
        tester.widget<Text>(find.text('FECHA')).style?.letterSpacing,
        closeTo(0.18 * 11, 1e-9),
      );
    });

    testWidgets('letter spacing follows letterSpacingEm', (tester) async {
      await _pump(tester, const DsMonoLabel('Fecha', letterSpacingEm: 0.22));

      expect(
        tester.widget<Text>(find.text('FECHA')).style?.letterSpacing,
        closeTo(0.22 * 11, 1e-9),
      );
    });

    for (final width in [390.0, 1440.0]) {
      testWidgets('never goes below 11 px at ${width.toInt()} px wide', (
        tester,
      ) async {
        await _pump(tester, const DsMonoLabel('Fecha'), size: Size(width, 900));

        expect(
          tester.widget<Text>(find.text('FECHA')).style!.fontSize,
          greaterThanOrEqualTo(11),
        );
      });
    }

    test('rejects letterSpacingEm outside 0.14..0.24', () {
      expect(
        () => DsMonoLabel('x', letterSpacingEm: 0.1),
        throwsAssertionError,
      );
      expect(
        () => DsMonoLabel('x', letterSpacingEm: 0.3),
        throwsAssertionError,
      );
      expect(() => DsMonoLabel('x', letterSpacingEm: 0.14), returnsNormally);
      expect(() => DsMonoLabel('x', letterSpacingEm: 0.24), returnsNormally);
    });

    testWidgets('semantics reads the original text once', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const DsMonoLabel('Última actualización'));

      expect(find.bySemanticsLabel('Última actualización'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('wraps a long label inside 160 px without overflow', (
      tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 160,
          child: DsMonoLabel(
            'Una etiqueta de sección extraordinariamente larga',
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('survives text scale 2.0', (tester) async {
      await _pump(tester, const DsMonoLabel('Fecha'), textScale: 2);

      expect(tester.takeException(), isNull);
    });
  });
}
