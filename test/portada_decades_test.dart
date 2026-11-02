import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/home/presentation/portada/portada_decades.dart';

import 'test_support/portada_test_support.dart';

void main() {
  testWidgets('décadas ocupadas ordenadas, recuentos y selección', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PortadaDecades(
            cases: portadaAllCases,
            onSelectDecade: selected.add,
          ),
        ),
      ),
    );
    expect(find.text('Recorre el tiempo'), findsOneWidget);
    expect(find.text('1940s'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1930s'), findsNothing);
    expect(
      tester.getTopLeft(find.text('1940s')).dx,
      lessThan(tester.getTopLeft(find.text('1970s')).dx),
    );
    await tester.tap(find.text('1940s'));
    expect(selected, [1940]);
  });

  testWidgets('catálogo vacío no dibuja sección', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PortadaDecades(cases: const [], onSelectDecade: (_) {}),
        ),
      ),
    );
    expect(find.text('Recorre el tiempo'), findsNothing);
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets('disposición adaptable a $width', (tester) async {
      await setSurface(tester, Size(width, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PortadaDecades(
                cases: portadaAllCases,
                onSelectDecade: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('1940s'), findsOneWidget);
    });
  }
}
