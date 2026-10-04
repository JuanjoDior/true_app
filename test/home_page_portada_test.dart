import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/app/navigation/app_navigation.dart';
import 'package:true_app/app/navigation/app_navigation_scope.dart';
import 'package:true_app/core/design/design.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/application/intake_session_providers.dart';
import 'package:true_app/features/cases/data/cases_repository.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';
import 'package:true_app/features/cases/presentation/intake/intake_workspace_screen.dart';
import 'package:true_app/features/home/presentation/home_page.dart';
import 'package:true_app/features/home/presentation/portada/portada_closing_keys.dart';
import 'package:true_app/features/home/presentation/portada/portada_footer.dart';
import 'package:true_app/features/home/presentation/portada/portada_hero.dart';
import 'package:true_app/features/home/presentation/portada/portada_map_invite.dart';
import 'package:true_app/features/home/presentation/portada/portada_shell_keys.dart';
import 'package:true_app/features/home/presentation/portada/portada_unsolved_keys.dart';
import 'package:true_app/features/home/presentation/portada/portada_unsolved_row.dart';

import 'test_support/fake_intake_auth.dart';
import 'test_support/sample_cases.dart';

class _RecordingNavigation implements AppNavigation {
  final List<String> openedCases = [];
  int mapOpens = 0;

  @override
  void openCase(String slug) => openedCases.add(slug);

  @override
  void openMap() => mapOpens++;

  @override
  void showSituationRoom() {}
}

class _PendingRepository implements CasesRepository {
  final completer = Completer<List<TrueCrimeCase>>();

  @override
  Future<List<TrueCrimeCase>> getCases() => completer.future;
}

class _EmptyRepository implements CasesRepository {
  @override
  Future<List<TrueCrimeCase>> getCases() async => const [];
}

class _FlakyRepository implements CasesRepository {
  bool available = false;
  int calls = 0;

  @override
  Future<List<TrueCrimeCase>> getCases() async {
    calls++;
    if (!available) throw StateError('sin red');
    return sampleCases;
  }
}

class _StaticRepository implements CasesRepository {
  @override
  Future<List<TrueCrimeCase>> getCases() async => sampleCases;
}

const Size _desktop = Size(1440, 900);
const Size _phone = Size(390, 844);

class _Pumped {
  _Pumped(this.container, this.navigation);

  final ProviderContainer container;
  final _RecordingNavigation navigation;
}

Future<_Pumped> _pumpHome(
  WidgetTester tester, {
  CasesRepository? repository,
  Size size = _desktop,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      casesRepositoryProvider.overrideWithValue(
        repository ?? _StaticRepository(),
      ),
      intakeAuthProvider.overrideWithValue(FakeIntakeAuth.signedIn()),
    ],
    retry: (_, _) => null,
  );
  addTearDown(container.dispose);
  final navigation = _RecordingNavigation();

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: DsTheme.build(),
        home: AppNavigationScope(
          navigation: navigation,
          child: const TrueCrimeHomePage(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  return _Pumped(container, navigation);
}

Finder _shell(Key key) => find.byKey(key);

void main() {
  group('portada', () {
    testWidgets('shows hero, unsolved row, map invite and footer in order', (
      tester,
    ) async {
      await _pumpHome(tester);

      final tops = [
        for (final type in [
          PortadaHero,
          PortadaUnsolvedRow,
          PortadaMapInvite,
          PortadaFooter,
        ])
          tester.getTopLeft(find.byType(type)).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(tops.toSet(), hasLength(4));
    });

    testWidgets('the top bar offers the logo, search and the links', (
      tester,
    ) async {
      await _pumpHome(tester);

      expect(_shell(PortadaShellKeys.topBar), findsOneWidget);
      expect(_shell(PortadaShellKeys.searchField), findsOneWidget);
      for (final label in ['Inicio', 'Mapa', 'Archivo', 'Formulario']) {
        expect(
          find.descendant(
            of: _shell(PortadaShellKeys.topBar),
            matching: find.text(label),
          ),
          findsOneWidget,
          reason: label,
        );
      }
      expect(find.text('TRUE'), findsWidgets);
    });

    testWidgets('keeps «Novedades» hidden', (tester) async {
      await _pumpHome(tester);

      expect(find.text('Novedades'), findsNothing);
    });

    testWidgets('has no bottom bar on desktop', (tester) async {
      await _pumpHome(tester);

      expect(_shell(PortadaShellKeys.bottomBar), findsNothing);
    });

    testWidgets('passes the provider list itself to the map invite', (
      tester,
    ) async {
      final pumped = await _pumpHome(tester);
      final loaded = pumped.container.read(casesProvider).requireValue;

      PortadaMapInvite invite() =>
          tester.widget<PortadaMapInvite>(find.byType(PortadaMapInvite));
      expect(identical(invite().cases, loaded), isTrue);

      // Un rebuild del shell no debe fabricar otra lista.
      tester.view.physicalSize = const Size(1500, 900);
      await tester.pump();
      expect(identical(invite().cases, loaded), isTrue);
    });
  });

  group('catalog states', () {
    testWidgets('loading shows the status and no rows', (tester) async {
      final repository = _PendingRepository();
      await _pumpHome(tester, repository: repository);

      expect(_shell(PortadaClosingKeys.statusLoading), findsOneWidget);
      expect(find.byType(PortadaUnsolvedRow), findsNothing);
      expect(find.byType(PortadaMapInvite), findsNothing);
      expect(find.byType(PortadaFooter), findsOneWidget);

      repository.completer.complete(sampleCases);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(_shell(PortadaClosingKeys.statusLoading), findsNothing);
      expect(find.byType(PortadaUnsolvedRow), findsOneWidget);
    });

    testWidgets('error says so and offers a retry', (tester) async {
      await _pumpHome(tester, repository: _FlakyRepository());

      expect(_shell(PortadaClosingKeys.statusError), findsOneWidget);
      expect(find.text('No se pudieron cargar los casos.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.byType(PortadaUnsolvedRow), findsNothing);
    });

    testWidgets('an empty archive says so', (tester) async {
      await _pumpHome(tester, repository: _EmptyRepository());

      expect(_shell(PortadaClosingKeys.statusEmpty), findsOneWidget);
      expect(
        find.text('Todavía no hay expedientes publicados.'),
        findsOneWidget,
      );
      expect(find.byType(PortadaMapInvite), findsNothing);
    });

    testWidgets('retry invalidates the cases and reloads them', (tester) async {
      final repository = _FlakyRepository();
      await _pumpHome(tester, repository: repository);
      expect(_shell(PortadaClosingKeys.statusError), findsOneWidget);

      repository.available = true;
      final callsBefore = repository.calls;
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(repository.calls, callsBefore + 1);
      expect(_shell(PortadaClosingKeys.statusError), findsNothing);
      expect(find.byType(PortadaUnsolvedRow), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('tapping a case opens it by slug', (tester) async {
      final pumped = await _pumpHome(tester);

      final poster = _shell(PortadaUnsolvedKeys.poster('zodiac-killer'));
      await tester.ensureVisible(poster);
      await tester.pump();
      await tester.tap(poster);

      expect(pumped.navigation.openedCases, ['zodiac-killer']);
    });

    testWidgets('the map invitation opens the map', (tester) async {
      final pumped = await _pumpHome(tester);

      final button = find.text('Abrir el mapa');
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);

      expect(pumped.navigation.mapOpens, 1);
    });

    testWidgets('the top bar «Mapa» link opens the map', (tester) async {
      final pumped = await _pumpHome(tester);

      await tester.tap(_shell(PortadaShellKeys.topBarMap));

      expect(pumped.navigation.mapOpens, 1);
    });

    testWidgets('submitting a search sets the query and opens the map', (
      tester,
    ) async {
      final pumped = await _pumpHome(tester);

      await tester.enterText(_shell(PortadaShellKeys.searchField), 'isdal');
      expect(pumped.navigation.mapOpens, 0);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(pumped.container.read(searchQueryProvider), 'isdal');
      expect(pumped.navigation.mapOpens, 1);
    });

    testWidgets('«Archivo» opens the directory', (tester) async {
      await _pumpHome(tester);

      await tester.tap(_shell(PortadaShellKeys.topBarArchive));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('El archivo'), findsOneWidget);
    });

    testWidgets('the form link switches to intake', (tester) async {
      final pumped = await _pumpHome(tester);

      await tester.tap(_shell(PortadaShellKeys.topBarForm));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(pumped.container.read(workspaceProvider), Workspace.intake);
      expect(find.byType(IntakeWorkspaceScreen), findsOneWidget);
      expect(find.byType(PortadaHero), findsNothing);
    });
  });

  group('narrow widths', () {
    testWidgets('show the bottom bar with its four destinations', (
      tester,
    ) async {
      await _pumpHome(tester, size: _phone);

      final bar = _shell(PortadaShellKeys.bottomBar);
      expect(bar, findsOneWidget);
      for (final label in ['Inicio', 'Mapa', 'Archivo', 'Formulario']) {
        expect(
          find.descendant(of: bar, matching: find.text(label)),
          findsOneWidget,
          reason: label,
        );
      }
      expect(
        tester.getBottomLeft(bar).dy,
        tester.view.physicalSize.height,
        reason: 'pegada al borde inferior',
      );
    });

    testWidgets('use the compact top bar without text links', (tester) async {
      await _pumpHome(tester, size: _phone);

      expect(_shell(PortadaShellKeys.topBar), findsOneWidget);
      expect(_shell(PortadaShellKeys.topBarMap), findsNothing);
    });

    testWidgets('bottom bar «Inicio» scrolls back to the top', (tester) async {
      await _pumpHome(tester, size: _phone);
      final scrollable = find.byType(Scrollable).first;
      ScrollPosition position() =>
          tester.state<ScrollableState>(scrollable).position;

      position().jumpTo(900);
      await tester.pump();
      expect(position().pixels, 900);

      await tester.tap(_shell(PortadaShellKeys.bottomBarHome));
      await tester.pump();
      await tester.pump(DsMotion.fly);
      await tester.pump(DsMotion.fly);

      expect(position().pixels, 0);
    });

    testWidgets('bottom bar «Mapa» opens the map', (tester) async {
      final pumped = await _pumpHome(tester, size: _phone);

      await tester.tap(_shell(PortadaShellKeys.bottomBarMap));

      expect(pumped.navigation.mapOpens, 1);
    });

    testWidgets('bottom bar «Formulario» switches to intake', (tester) async {
      final pumped = await _pumpHome(tester, size: _phone);

      await tester.tap(_shell(PortadaShellKeys.bottomBarForm));
      await tester.pump();

      expect(pumped.container.read(workspaceProvider), Workspace.intake);
    });

    testWidgets('bottom bar «Archivo» opens the directory', (tester) async {
      await _pumpHome(tester, size: _phone);

      await tester.tap(_shell(PortadaShellKeys.bottomBarArchive));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('El archivo'), findsOneWidget);
    });

    testWidgets('the search icon reveals a field that opens the map', (
      tester,
    ) async {
      final pumped = await _pumpHome(tester, size: _phone);
      expect(_shell(PortadaShellKeys.searchField), findsNothing);

      await tester.tap(_shell(PortadaShellKeys.searchToggle));
      await tester.pump();
      await tester.enterText(_shell(PortadaShellKeys.searchField), '1970');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(pumped.container.read(searchQueryProvider), '1970');
      expect(pumped.navigation.mapOpens, 1);
    });
  });
}
