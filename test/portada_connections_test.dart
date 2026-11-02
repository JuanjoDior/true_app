import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/domain/case_connection.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';
import 'package:true_app/features/home/presentation/portada/portada_connections.dart';

import 'test_support/portada_test_support.dart';

void main() {
  final cases = [
    for (final id in [
      'isdal',
      'somerton',
      'zodiac',
      'goldenstate',
      'kercher',
      'mccann',
      'ripper',
    ])
      portadaCase(id: id, title: id, city: 'Ciudad', year: 2001),
  ];
  const connections = [
    CaseConnection(aId: 'somerton', bId: 'isdal', relation: 'Relación uno'),
    CaseConnection(aId: 'zodiac', bId: 'goldenstate', relation: 'Relación dos'),
    CaseConnection(aId: 'kercher', bId: 'mccann', relation: 'Relación tres'),
    CaseConnection(aId: 'zodiac', bId: 'ripper', relation: 'No curada'),
  ];
  for (final width in [1440.0, 390.0]) {
    testWidgets('pares curados, datos y callbacks a $width', (tester) async {
      await setSurface(tester, Size(width, 1400));
      final opened = <TrueCrimeCase>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PortadaConnections(
                cases: cases,
                connections: connections,
                onOpenCase: opened.add,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Conexiones del archivo'), findsOneWidget);
      expect(find.text('Relación uno'), findsOneWidget);
      expect(find.text('Relación dos'), findsOneWidget);
      expect(find.text('Relación tres'), findsOneWidget);
      expect(find.text('No curada'), findsNothing);
      expect(find.text('Ciudad · 2001'), findsNWidgets(6));
      await tester.ensureVisible(find.text('isdal'));
      await tester.tap(find.text('isdal'));
      await tester.ensureVisible(find.text('somerton'));
      await tester.tap(find.text('somerton'));
      expect(opened.map((c) => c.id), ['isdal', 'somerton']);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('sin conexión o sin extremo publicado no muestra el par', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PortadaConnections(
          cases: [cases.first],
          connections: connections,
          onOpenCase: (_) {},
        ),
      ),
    );
    expect(find.text('Relación uno'), findsNothing);
    expect(find.text('Conexiones del archivo'), findsNothing);
    await tester.pumpWidget(
      MaterialApp(
        home: PortadaConnections(
          cases: cases,
          connections: const [],
          onOpenCase: (_) {},
        ),
      ),
    );
    expect(find.text('Conexiones del archivo'), findsNothing);
  });
}
