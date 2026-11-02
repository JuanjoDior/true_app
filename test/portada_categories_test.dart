import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/home/presentation/portada/portada_categories.dart';

import 'test_support/portada_test_support.dart';

void main() {
  testWidgets('recuentos reales y selección por categoría', (tester) async {
    final selected = <CaseCategory>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PortadaCategories(
            cases: portadaAllCases,
            onSelectCategory: selected.add,
          ),
        ),
      ),
    );
    expect(find.text('Por categoría'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(3));
    await tester.tap(find.text('Casos sin resolver'));
    expect(selected, [CaseCategory.unsolved]);
  });

  testWidgets('en móvil ninguna palabra de categoría se parte', (tester) async {
    final loader = FontLoader('NotoSerifDisplay')
      ..addFont(rootBundle.load('assets/fonts/NotoSerif-Bold.ttf'));
    await loader.load();
    for (final width in [360.0, 390.0]) {
      await setSurface(tester, Size(width, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PortadaCategories(
                cases: portadaAllCases,
                onSelectCategory: (_) {},
              ),
            ),
          ),
        ),
      );
      for (final category in CaseCategory.values) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(category.label),
        );
        for (final match in RegExp(r'\S+').allMatches(category.label)) {
          final boxes = paragraph.getBoxesForSelection(
            TextSelection(baseOffset: match.start, extentOffset: match.end),
          );
          expect(
            boxes.length,
            1,
            reason: '${category.label}: ${match.group(0)} a $width px',
          );
        }
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('catálogo vacío no dibuja sección', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PortadaCategories(cases: const [], onSelectCategory: (_) {}),
        ),
      ),
    );
    expect(find.text('Por categoría'), findsNothing);
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets('disposición adaptable a $width', (tester) async {
      await setSurface(tester, Size(width, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PortadaCategories(
                cases: portadaAllCases,
                onSelectCategory: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Secuestros'), findsOneWidget);
    });
  }
}
