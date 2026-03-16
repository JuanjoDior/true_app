import 'package:flutter_test/flutter_test.dart';

import 'package:true_app/main.dart';

void main() {
  testWidgets('renders starter shell', (WidgetTester tester) async {
    await tester.pumpWidget(const TrueApp());

    expect(find.text('true_app'), findsOneWidget);
    expect(find.text('Base lista para empezar.'), findsOneWidget);
  });
}
