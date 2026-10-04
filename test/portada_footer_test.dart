import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/home/presentation/portada/portada_closing_keys.dart';

import 'test_support/portada_test_support.dart';

const String _note =
    'Crímenes reales · documentados con respeto. '
    'Las víctimas se nombran con respeto.';

void main() {
  testWidgets('marca y nota del prototipo', (tester) async {
    await pumpPortadaFooter(tester);

    expect(find.text('TRUE'), findsOneWidget);
    expect(find.text(_note), findsOneWidget);
  });

  testWidgets(
    'escritorio: 120 de alto, marca a la izquierda y nota a la derecha',
    (tester) async {
      await pumpPortadaFooter(tester);

      expect(tester.getSize(find.byKey(PortadaClosingKeys.footer)).height, 120);
      expect(tester.getTopLeft(find.text('TRUE')).dx, 80);
      expect(tester.getTopRight(find.text(_note)).dx, desktopSize.width - 80);
      expect(
        tester.getCenter(find.text('TRUE')).dy,
        tester.getCenter(find.text(_note)).dy,
      );
    },
  );

  testWidgets('móvil: marca sobre la nota con margen de 16', (tester) async {
    await pumpPortadaFooter(tester, size: phoneSize);

    final brand = tester.getRect(find.text('TRUE'));
    final note = tester.getRect(find.text(_note));
    expect(brand.left, 16);
    expect(note.left, 16);
    expect(note.top, greaterThan(brand.bottom));
    expect(note.right, lessThanOrEqualTo(phoneSize.width - 16));
  });

  testWidgets('con texto grande no desborda', (tester) async {
    await pumpPortadaFooter(tester, size: laptopSize, textScale: 2);
    expect(tester.takeException(), isNull);

    await pumpPortadaFooter(tester, size: phoneSize, textScale: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('línea superior fina que lo separa del contenido', (
    tester,
  ) async {
    await pumpPortadaFooter(tester);

    final box = tester.widget<DecoratedBox>(
      find.byKey(PortadaClosingKeys.footer),
    );
    final border = (box.decoration as BoxDecoration).border! as Border;
    expect(border.top.width, 1);
    expect(border.bottom, BorderSide.none);
  });
}
