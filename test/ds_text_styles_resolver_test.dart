import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

Future<DsTextStyles> _resolveAt(WidgetTester tester, Size size) async {
  late DsTextStyles resolved;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size),
      child: Builder(
        builder: (context) {
          resolved = DsTextStylesResolver.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return resolved;
}

void main() {
  group('DsBreakpoints (flutter-implementation.md F10)', () {
    test('desktop starts at 1200 px', () {
      expect(DsBreakpoints.desktop, 1200);
    });
  });

  group('DsTextStylesResolver', () {
    testWidgets('picks desktop at 1440 px', (tester) async {
      final styles = await _resolveAt(tester, const Size(1440, 900));
      expect(identical(styles, DsTextStyles.desktop), isTrue);
      expect(styles.displayHero.fontSize, 104);
    });

    testWidgets('picks mobile at 390 px', (tester) async {
      final styles = await _resolveAt(tester, const Size(390, 844));
      expect(identical(styles, DsTextStyles.mobile), isTrue);
      expect(styles.displayHero.fontSize, 56);
    });

    testWidgets('1200 px is already desktop', (tester) async {
      final styles = await _resolveAt(
        tester,
        const Size(DsBreakpoints.desktop, 800),
      );
      expect(identical(styles, DsTextStyles.desktop), isTrue);
    });

    testWidgets('1199 px is still mobile', (tester) async {
      final styles = await _resolveAt(
        tester,
        const Size(DsBreakpoints.desktop - 1, 800),
      );
      expect(identical(styles, DsTextStyles.mobile), isTrue);
    });

    testWidgets('only the width decides, not the height', (tester) async {
      final tallNarrow = await _resolveAt(tester, const Size(390, 3000));
      expect(identical(tallNarrow, DsTextStyles.mobile), isTrue);
      final shortWide = await _resolveAt(tester, const Size(1440, 200));
      expect(identical(shortWide, DsTextStyles.desktop), isTrue);
    });
  });
}
