import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/presentation/intake/sections/intake_field_row.dart';

/// Encierra la fila en un ancho fijo, como haría una sección real dentro de
/// una columna con `LayoutBuilder`.
Widget _harness(double width, Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: width, child: child),
    ),
  );
}

void main() {
  testWidgets('renders fields in a single row above the stack threshold',
      (tester) async {
    await tester.pumpWidget(
      _harness(
        800,
        IntakeFieldRow(
          fields: [
            IntakeFieldSlot.fixed(const Text('date'), width: 120),
            IntakeFieldSlot.flexible(const Text('title')),
          ],
          trailing: const Icon(Icons.close, key: Key('trailing')),
        ),
      ),
    );

    final rowInField = find.descendant(
      of: find.byType(IntakeFieldRow),
      matching: find.byType(Row),
    );
    final columnInField = find.descendant(
      of: find.byType(IntakeFieldRow),
      matching: find.byType(Column),
    );
    expect(rowInField, findsOneWidget);
    expect(columnInField, findsNothing);

    // Los campos están uno junto a otro: misma línea vertical.
    expect(
      tester.getTopLeft(find.text('date')).dy,
      tester.getTopLeft(find.text('title')).dy,
    );
    // "date" queda a la izquierda de "title" en la misma fila.
    expect(
      tester.getTopLeft(find.text('date')).dx,
      lessThan(tester.getTopLeft(find.text('title')).dx),
    );
  });

  testWidgets('stacks fields in a column below the stack threshold',
      (tester) async {
    await tester.pumpWidget(
      _harness(
        360,
        IntakeFieldRow(
          fields: [
            IntakeFieldSlot.fixed(const Text('date'), width: 120),
            IntakeFieldSlot.flexible(const Text('title')),
          ],
          trailing: const Icon(Icons.close, key: Key('trailing')),
        ),
      ),
    );

    final rowInField = find.descendant(
      of: find.byType(IntakeFieldRow),
      matching: find.byType(Row),
    );
    final columnInField = find.descendant(
      of: find.byType(IntakeFieldRow),
      matching: find.byType(Column),
    );
    expect(rowInField, findsNothing);
    expect(columnInField, findsOneWidget);

    // El trailing va arriba, antes que los campos.
    expect(
      tester.getTopLeft(find.byKey(const Key('trailing'))).dy,
      lessThan(tester.getTopLeft(find.text('date')).dy),
    );
    // Cada campo ocupa el ancho completo disponible (360).
    expect(tester.getSize(find.text('date')).width, closeTo(360, 0.5));
    expect(tester.getSize(find.text('title')).width, closeTo(360, 0.5));

    expect(tester.takeException(), isNull);
  });
}
