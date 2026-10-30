import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';
import 'package:true_app/features/home/presentation/portada/portada_bottom_bar.dart';
import 'package:true_app/features/home/presentation/portada/portada_shell_keys.dart';
import 'package:true_app/features/home/presentation/portada/portada_top_bar.dart';

import 'test_support/portada_test_support.dart';

Future<void> _pumpBar(WidgetTester tester, Size size, Widget bar) async {
  await setSurface(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      theme: DsTheme.build(),
      home: Material(
        child: Align(alignment: Alignment.topCenter, child: bar),
      ),
    ),
  );
}

class _BarCalls {
  int mapOpens = 0;
  final List<String> queries = [];
}

PortadaTopBar _topBar(_BarCalls? calls, {String initialQuery = ''}) =>
    PortadaTopBar(
      initialQuery: initialQuery,
      onSubmitSearch: calls?.queries.add,
      onHome: () {},
      onOpenMap: calls == null ? null : () => calls.mapOpens++,
      onOpenArchive: () {},
      onOpenForm: () {},
    );

PortadaBottomBar _bottomBar(_BarCalls? calls) => PortadaBottomBar(
  onHome: () {},
  onOpenMap: calls == null ? null : () => calls.mapOpens++,
  onOpenArchive: () {},
  onOpenForm: () {},
);

Finder _in(Key bar, String label) =>
    find.descendant(of: find.byKey(bar), matching: find.text(label));

void main() {
  group('barra superior', () {
    testWidgets('con callbacks: «Mapa» abre el mapa y el buscador entrega '
        'la consulta', (tester) async {
      final calls = _BarCalls();
      await _pumpBar(tester, desktopSize, _topBar(calls, initialQuery: 'zod'));

      final field = find.byKey(PortadaShellKeys.searchField);
      expect(tester.widget<TextField>(field).controller!.text, 'zod');
      await tester.tap(find.byKey(PortadaShellKeys.topBarMap));
      await tester.enterText(field, '  isdal ');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(calls.mapOpens, 1);
      expect(calls.queries, ['isdal']);
    });

    testWidgets('con callbacks en móvil: la lupa despliega el buscador', (
      tester,
    ) async {
      final calls = _BarCalls();
      await _pumpBar(tester, phoneSize, _topBar(calls));

      await tester.tap(find.byKey(PortadaShellKeys.searchToggle));
      await tester.pump();
      await tester.enterText(find.byKey(PortadaShellKeys.searchField), '1970');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(calls.queries, ['1970']);
    });

    testWidgets('sin onOpenMap ni onSubmitSearch no hay «Mapa» ni buscador', (
      tester,
    ) async {
      await _pumpBar(tester, desktopSize, _topBar(null));

      expect(find.byKey(PortadaShellKeys.topBarMap), findsNothing);
      expect(find.byKey(PortadaShellKeys.searchField), findsNothing);
      expect(find.text('Mapa'), findsNothing);
      for (final label in ['Inicio', 'Archivo', 'Formulario']) {
        expect(
          _in(PortadaShellKeys.topBar, label),
          findsOneWidget,
          reason: label,
        );
      }
    });

    testWidgets('sin onSubmitSearch en móvil no hay lupa', (tester) async {
      await _pumpBar(tester, phoneSize, _topBar(null));

      expect(find.byKey(PortadaShellKeys.searchToggle), findsNothing);
      expect(find.byKey(PortadaShellKeys.searchField), findsNothing);
    });
  });

  group('barra inferior', () {
    testWidgets('con onOpenMap: cuatro pestañas y «Mapa» abre el mapa', (
      tester,
    ) async {
      final calls = _BarCalls();
      await _pumpBar(tester, phoneSize, _bottomBar(calls));

      for (final label in ['Inicio', 'Mapa', 'Archivo', 'Formulario']) {
        expect(
          _in(PortadaShellKeys.bottomBar, label),
          findsOneWidget,
          reason: label,
        );
      }
      await tester.tap(find.byKey(PortadaShellKeys.bottomBarMap));
      expect(calls.mapOpens, 1);
    });

    testWidgets('sin onOpenMap no hay pestaña «Mapa»', (tester) async {
      await _pumpBar(tester, phoneSize, _bottomBar(null));

      expect(find.byKey(PortadaShellKeys.bottomBarMap), findsNothing);
      expect(find.text('Mapa'), findsNothing);
      for (final label in ['Inicio', 'Archivo', 'Formulario']) {
        expect(
          _in(PortadaShellKeys.bottomBar, label),
          findsOneWidget,
          reason: label,
        );
      }
    });
  });
}
