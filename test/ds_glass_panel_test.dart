import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

const _mobile = Size(390, 844);

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
        body: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  );
}

Finder get _panel => find.byType(DsGlassPanel);

Container _surface(WidgetTester tester) => tester.widget<Container>(
  find.descendant(of: _panel, matching: find.byType(Container)).first,
);

BoxDecoration _surfaceDecoration(WidgetTester tester) =>
    _surface(tester).decoration! as BoxDecoration;

BoxDecoration _shadowDecoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(of: _panel, matching: find.byType(DecoratedBox))
                  .first,
            )
            .decoration
        as BoxDecoration;

void main() {
  group('DsGlassPanel', () {
    testWidgets('uses surfaceGlass, a 1 px hairline border and sheet radius', (
      tester,
    ) async {
      await _pump(tester, const DsGlassPanel(child: SizedBox(width: 100)));

      final decoration = _surfaceDecoration(tester);
      expect(decoration.color, DsColors.surfaceGlass);
      expect(decoration.borderRadius, DsRadii.sheetBorder);
      final border = decoration.border! as Border;
      expect(border.top.color, DsColors.lineHairline);
      expect(border.top.width, 1);
      expect(border.left.color, DsColors.lineHairline);
      expect(border.right.width, 1);
      expect(border.bottom.width, 1);
    });

    testWidgets('strong uses surfaceGlassStrong', (tester) async {
      await _pump(
        tester,
        const DsGlassPanel(strong: true, child: SizedBox(width: 100)),
      );

      expect(_surfaceDecoration(tester).color, DsColors.surfaceGlassStrong);
    });

    testWidgets('applies the glass shadow by default', (tester) async {
      await _pump(tester, const DsGlassPanel(child: SizedBox(width: 100)));

      expect(_shadowDecoration(tester).boxShadow, DsShadows.glass);
      expect(_shadowDecoration(tester).borderRadius, DsRadii.sheetBorder);
    });

    testWidgets('custom radius, shadows and border color are honored', (
      tester,
    ) async {
      const radius = BorderRadius.all(Radius.circular(20));
      const shadows = [BoxShadow(color: Color(0xFF000000), blurRadius: 3)];
      await _pump(
        tester,
        const DsGlassPanel(
          borderRadius: radius,
          shadows: shadows,
          borderColor: DsStatusColors.solved,
          child: SizedBox(width: 100),
        ),
      );

      expect(_surfaceDecoration(tester).borderRadius, radius);
      expect(_shadowDecoration(tester).borderRadius, radius);
      expect(_shadowDecoration(tester).boxShadow, shadows);
      expect(
        (_surfaceDecoration(tester).border! as Border).top.color,
        DsStatusColors.solved,
      );
      expect(
        tester.widget<ClipRRect>(find.byType(ClipRRect)).borderRadius,
        radius,
      );
    });

    testWidgets('an empty shadow list removes the shadow', (tester) async {
      await _pump(
        tester,
        const DsGlassPanel(shadows: [], child: SizedBox(width: 100)),
      );

      expect(_shadowDecoration(tester).boxShadow, isEmpty);
    });

    testWidgets('blurs the backdrop with sigma 18', (tester) async {
      await _pump(tester, const DsGlassPanel(child: SizedBox(width: 100)));

      expect(DsGlassPanel.blurSigma, 18);
      final filter = tester
          .widget<BackdropFilter>(
            find.descendant(of: _panel, matching: find.byType(BackdropFilter)),
          )
          .filter;
      expect(filter, ImageFilter.blur(sigmaX: 18, sigmaY: 18));
    });

    testWidgets('clips the blur to the radius inside a repaint boundary', (
      tester,
    ) async {
      await _pump(tester, const DsGlassPanel(child: SizedBox(width: 100)));

      final boundary = find.descendant(
        of: _panel,
        matching: find.byType(RepaintBoundary),
      );
      expect(boundary, findsOneWidget);
      final clip = find.descendant(
        of: boundary,
        matching: find.byType(ClipRRect),
      );
      expect(clip, findsOneWidget);
      expect(
        find.descendant(of: clip, matching: find.byType(BackdropFilter)),
        findsOneWidget,
      );
      expect(tester.widget<ClipRRect>(clip).borderRadius, DsRadii.sheetBorder);
    });

    testWidgets('insets the child by the padding plus the 1 px border', (
      tester,
    ) async {
      await _pump(
        tester,
        const DsGlassPanel(
          padding: EdgeInsets.all(20),
          child: SizedBox(key: ValueKey('child'), width: 50, height: 30),
        ),
      );

      final panel = tester.getTopLeft(_panel);
      final child = tester.getTopLeft(find.byKey(const ValueKey('child')));
      expect(child - panel, const Offset(21, 21));
      expect(tester.getSize(_panel), const Size(92, 72));
    });

    testWidgets('does not overflow at 390 px with long content', (
      tester,
    ) async {
      await _pump(
        tester,
        SizedBox(
          width: 358,
          child: DsGlassPanel(
            padding: const EdgeInsets.all(24),
            child: Text('Expediente ' * 40),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_panel).width, 358);
    });

    testWidgets('survives text scale 2.0', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 358,
          child: DsGlassPanel(
            padding: const EdgeInsets.all(24),
            child: Text('Expediente ' * 10),
          ),
        ),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
