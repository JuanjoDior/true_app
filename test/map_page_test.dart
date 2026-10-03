import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/app/navigation/app_navigation.dart';
import 'package:true_app/core/design/design.dart';
import 'package:true_app/features/map/presentation/map_page.dart';

/// La página del mapa, de momento sólo un cascarón temporal.

class _RecordingNavigation implements AppNavigation {
  var returns = 0;

  @override
  void openCase(String slug) {}

  @override
  void openMap() {}

  @override
  void showSituationRoom() => returns++;
}

Future<_RecordingNavigation> _pumpPage(WidgetTester tester) async {
  final navigation = _RecordingNavigation();
  await tester.pumpWidget(
    MaterialApp(
      theme: DsTheme.build(),
      home: MapPage(navigation: navigation),
    ),
  );
  return navigation;
}

void main() {
  testWidgets('the page is identified by its key', (tester) async {
    await _pumpPage(tester);

    expect(find.byKey(const Key('map-page')), findsOneWidget);
  });

  testWidgets('the page paints the dark base colour', (tester) async {
    await _pumpPage(tester);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, DsColors.bgBase);
  });

  testWidgets('the page shows its mono label', (tester) async {
    await _pumpPage(tester);

    expect(find.text('EL MAPA'), findsOneWidget);
  });

  testWidgets('the page offers a way back to the front page', (tester) async {
    await _pumpPage(tester);

    expect(find.text('Volver a la portada'), findsOneWidget);
  });

  testWidgets('the back button asks to show the Situation Room', (
    tester,
  ) async {
    final navigation = await _pumpPage(tester);

    await tester.tap(find.text('Volver a la portada'));
    await tester.pump();

    expect(navigation.returns, 1);
  });

  testWidgets('the page alone does not navigate', (tester) async {
    final navigation = await _pumpPage(tester);

    expect(navigation.returns, 0);
  });
}
