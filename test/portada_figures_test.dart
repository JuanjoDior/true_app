import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/home/presentation/portada/portada_figures.dart';

import 'test_support/portada_test_support.dart';

void main() {
  for (final width in [1440.0, 390.0]) {
    testWidgets('cifras reales sin desbordes a $width', (tester) async {
      await setSurface(tester, Size(width, 900));
      final cases = [
        portadaCase(id: 'a', title: 'A', country: 'Noruega', year: 2007),
        portadaCase(
          id: 'b',
          title: 'B',
          country: 'Noruega',
          year: 1888,
          status: CaseStatus.solved,
        ),
        portadaCase(id: 'c', title: 'C', country: 'Portugal', year: 1970),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: PortadaFigures(cases: cases)),
          ),
        ),
      );
      expect(find.text('3'), findsOneWidget);
      expect(find.text('2'), findsNWidgets(2));
      expect(find.text('1888–2007'), findsOneWidget);
      expect(find.text('EXPEDIENTES'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('catálogo vacío no inventa periodo', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PortadaFigures(cases: [])));
    expect(find.text('0'), findsNWidgets(3));
    expect(find.text('—'), findsOneWidget);
  });
}
