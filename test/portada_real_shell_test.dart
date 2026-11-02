import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/app/navigation/app_navigation.dart';
import 'package:true_app/app/navigation/app_navigation_scope.dart';
import 'package:true_app/core/design/design.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/domain/case_connection.dart';
import 'package:true_app/features/home/presentation/portada/portada_shell.dart';
import 'package:true_app/features/home/presentation/portada/portada_figures.dart';
import 'package:true_app/features/home/presentation/portada/portada_categories.dart';
import 'package:true_app/features/home/presentation/portada/portada_decades.dart';
import 'package:true_app/features/home/presentation/portada/portada_connections.dart';
import 'package:true_app/features/home/presentation/portada/portada_map_invite.dart';
import 'package:true_app/features/home/presentation/portada/portada_unsolved_row.dart';
import 'package:true_app/features/home/presentation/portada/portada_hero.dart';
import 'package:true_app/features/home/presentation/portada/portada_hero_keys.dart';

import 'test_support/portada_test_support.dart';
import 'test_support/sample_cases.dart';

// El héroe llega con el catálogo todavía cargando: el contenido del slide activo
// debe terminar visible, dentro del héroe y con tamaño.
class RecordingNavigation implements AppNavigation {
  final opened = <String>[];
  @override
  void openCase(String slug) => opened.add(slug);
  @override
  void openMap() {}
  @override
  void showSituationRoom() {}
}

const testConnections = [
  CaseConnection(aId: 'isdal', bId: 'somerton', relation: 'Vínculo real'),
  CaseConnection(aId: 'zodiac-killer', bId: 'isdal', relation: 'Otro vínculo'),
];

Future<RecordingNavigation> pumpIntegrationShell(WidgetTester tester) async {
  await setSurface(tester, desktopSize);
  final navigation = RecordingNavigation();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        casesProvider.overrideWith(
          (ref) async => [...sampleCases, ...portadaCases],
        ),
        caseConnectionsProvider.overrideWithValue(testConnections),
      ],
      child: MaterialApp(
        theme: DsTheme.build(),
        home: AppNavigationScope(
          navigation: navigation,
          child: const PortadaShell(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  return navigation;
}

void main() {
  testWidgets('compone secciones con catálogo y conexiones publicados', (
    tester,
  ) async {
    await pumpIntegrationShell(tester);
    final hero = tester.widget<PortadaHero>(find.byType(PortadaHero));
    expect(hero.allCases.length, 9);
    expect(hero.connections, testConnections);
    expect(find.text('1 caso conectado'), findsOneWidget);
    final sections = [
      PortadaHero,
      PortadaFigures,
      PortadaUnsolvedRow,
      PortadaCategories,
      PortadaDecades,
      PortadaConnections,
    ];
    final positions = sections
        .map((type) => tester.getTopLeft(find.byType(type)).dy)
        .toList();
    for (var i = 1; i < positions.length; i++) {
      expect(positions[i], greaterThan(positions[i - 1]));
    }
    expect(find.byType(PortadaMapInvite), findsNothing);
    expect(find.text('Vínculo real'), findsOneWidget);
    expect(find.text('1947–2007'), findsOneWidget);
  });

  testWidgets('categoría abre archivo filtrado y navega al caso', (
    tester,
  ) async {
    final navigation = await pumpIntegrationShell(tester);
    final category = find.descendant(
      of: find.byType(PortadaCategories),
      matching: find.text('Secuestros'),
    );
    await tester.ensureVisible(category);
    await tester.tap(category);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.byKey(const Key('case-directory-row-madeleine')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('case-directory-row-isdal')), findsNothing);
    await tester.tap(find.byKey(const Key('case-directory-row-madeleine')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(navigation.opened, ['madeleine']);
    expect(find.byKey(const Key('case-directory')), findsNothing);
  });

  testWidgets('década abre archivo filtrado y extremo conectado navega', (
    tester,
  ) async {
    final navigation = await pumpIntegrationShell(tester);
    final decade = find.descendant(
      of: find.byType(PortadaDecades),
      matching: find.text('1940s'),
    );
    await tester.ensureVisible(decade);
    await tester.tap(decade);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Década de 1940'), findsOneWidget);
    expect(
      find.byKey(const Key('case-directory-row-somerton')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('case-directory-row-isdal')), findsNothing);
    await tester.tap(find.byKey(const Key('case-directory-close')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final endpoint = find.descendant(
      of: find.byType(PortadaConnections),
      matching: find.text('El hombre de Somerton'),
    );
    await tester.ensureVisible(endpoint);
    await tester.tap(endpoint);
    expect(navigation.opened, ['somerton']);
  });
  for (final size in [desktopSize, phoneSize]) {
    testWidgets(
      'el contenido del slide activo se ve a ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await pumpRealShell(tester, size);

        final hero = tester.getRect(find.byType(PortadaHero));
        final active =
            (sampleCases.where((c) => c.featuredRank != null).toList()
                  ..sort((a, b) => a.featuredRank!.compareTo(b.featuredRank!)))
                .first;

        expect(contentOpacity(tester, active.id), 1);
        for (final key in [
          PortadaHeroKeys.title(active.id),
          PortadaHeroKeys.summary(active.id),
          PortadaHeroKeys.coords(active.id),
        ]) {
          final rect = tester.getRect(find.byKey(key));
          expect(rect.width, greaterThan(0), reason: '$key');
          expect(rect.height, greaterThan(0), reason: '$key');
          expect(rect.left, greaterThanOrEqualTo(hero.left), reason: '$key');
          expect(rect.top, greaterThanOrEqualTo(hero.top), reason: '$key');
          expect(rect.right, lessThanOrEqualTo(hero.right), reason: '$key');
          expect(rect.bottom, lessThanOrEqualTo(hero.bottom), reason: '$key');
        }
      },
    );
  }
}
