import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/domain/case_connection.dart';
import 'package:true_app/features/home/presentation/portada/portada_hero.dart';
import 'package:true_app/features/home/presentation/portada/portada_hero_keys.dart';

import 'test_support/portada_test_support.dart';

void main() {
  testWidgets(
    'cuenta casos conectados publicados, sin duplicados ni extremos ausentes',
    (tester) async {
      await setSurface(tester, desktopSize);
      const connections = [
        CaseConnection(aId: 'zodiac', bId: 'isdal', relation: 'a'),
        CaseConnection(aId: 'isdal', bId: 'zodiac', relation: 'a'),
        CaseConnection(aId: 'zodiac', bId: 'somerton', relation: 'b'),
        CaseConnection(aId: 'zodiac', bId: 'missing', relation: 'c'),
        CaseConnection(aId: 'zodiac', bId: 'zodiac', relation: 'd'),
      ];
      Widget hero(List cases) => MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: desktopSize,
            disableAnimations: true,
          ),
          child: SizedBox.fromSize(
            size: desktopSize,
            child: PortadaHero(
              featured: portadaCases,
              allCases: cases.cast(),
              connections: connections,
              onOpenCase: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpWidget(hero(portadaAllCases));
      expect(find.text('2 casos conectados'), findsOneWidget);
      await tester.pumpWidget(hero([portadaCases[0], portadaCases[1]]));
      expect(find.text('1 caso conectado'), findsOneWidget);
      await tester.pumpWidget(hero([portadaCases[0]]));
      expect(find.text('0 casos conectados'), findsOneWidget);
    },
  );

  testWidgets(
    'flechas con foco en el héroe recorren y envuelven sin autoavance reducido',
    (tester) async {
      await pumpPortadaHero(tester, reduceMotion: true);
      final focus = find
          .descendant(
            of: find.byKey(PortadaHeroKeys.tab(0)),
            matching: find.byType(Focus),
          )
          .first;
      Focus.of(tester.element(focus)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(globeScene(tester).selectedId, 'dyatlov');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(globeScene(tester).selectedId, 'zodiac');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(globeScene(tester).selectedId, 'isdal');
      await pumpStep(tester, const Duration(seconds: 8));
      expect(globeScene(tester).selectedId, 'isdal');
    },
  );
}
