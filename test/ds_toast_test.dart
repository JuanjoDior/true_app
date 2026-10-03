import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

const _mobile = Size(390, 844);
const _desktop = Size(1280, 800);

Future<void> _pump(
  WidgetTester tester, {
  Size size = _desktop,
  double textScale = 1,
  bool reduceMotion = false,
  EdgeInsets padding = EdgeInsets.zero,
  Widget? body,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DsTheme.build(),
      builder: (context, app) => MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: padding,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: app!,
      ),
      home: Scaffold(body: body ?? const SizedBox.expand()),
    ),
  );
}

void _show(
  WidgetTester tester,
  String message, {
  Duration duration = const Duration(seconds: 3),
}) {
  DsToast.show(
    tester.element(find.byType(Scaffold)),
    message,
    duration: duration,
  );
}

Finder get _toast => find.byType(DsToast);

FadeTransition _fade(WidgetTester tester) => tester.widget<FadeTransition>(
  find.ancestor(of: _toast, matching: find.byType(FadeTransition)).first,
);

BoxDecoration _decoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.descendant(of: _toast, matching: find.byType(DsGlassPanel)),
          matching: find.byType(Container),
        )
        .first,
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  group('DsToast content', () {
    testWidgets('is a strong glass panel with a solved border at 50%', (
      tester,
    ) async {
      await _pump(
        tester,
        body: const Center(child: DsToast(message: 'Saved')),
      );

      final panel = tester.widget<DsGlassPanel>(find.byType(DsGlassPanel));
      expect(panel.strong, isTrue);
      expect(panel.borderRadius, DsRadii.controlBorder);
      expect(_decoration(tester).color, DsColors.surfaceGlassStrong);
      final border = (_decoration(tester).border! as Border).top;
      expect(border.width, 1);
      expect(
        border.color.toARGB32() & 0xFFFFFF,
        DsStatusColors.solved.toARGB32() & 0xFFFFFF,
      );
      expect(border.color.a, closeTo(0.5, 0.01));
    });

    testWidgets('shows a green check icon and the message', (tester) async {
      await _pump(
        tester,
        body: const Center(child: DsToast(message: 'Saved')),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.check_rounded));
      expect(icon.color, DsStatusColors.solved);
      final style = tester.widget<Text>(find.text('Saved')).style!;
      expect(style.color, DsColors.textPrimary);
      expect(style.fontSize, 14);
    });

    testWidgets('is announced as a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        body: const Center(child: DsToast(message: 'Saved')),
      );

      expect(
        tester.getSemantics(find.text('Saved')),
        isSemantics(label: 'Saved', isLiveRegion: true),
      );
      handle.dispose();
    });
  });

  group('DsToast.show placement', () {
    testWidgets('desktop: top-right corner', (tester) async {
      await _pump(tester);
      _show(tester, 'Saved');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      final rect = tester.getRect(_toast);
      expect(rect.right, 1280 - 24);
      expect(rect.top, 24);
    });

    testWidgets('desktop: respects the top safe area', (tester) async {
      await _pump(tester, padding: const EdgeInsets.only(top: 30));
      _show(tester, 'Saved');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(tester.getRect(_toast).top, 30 + 24);
    });

    testWidgets('mobile: bottom-center above the safe area', (tester) async {
      await _pump(
        tester,
        size: _mobile,
        padding: const EdgeInsets.only(bottom: 20),
      );
      _show(tester, 'Saved');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      final rect = tester.getRect(_toast);
      expect(rect.center.dx, closeTo(195, 0.5));
      expect(rect.bottom, 844 - 20 - 32);
    });

    testWidgets('1199 px counts as mobile, 1200 px as desktop', (tester) async {
      await _pump(tester, size: const Size(1199, 800));
      _show(tester, 'Saved');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.getRect(_toast).center.dx, closeTo(1199 / 2, 0.5));
      await tester.pumpAndSettle();

      await _pump(tester, size: const Size(1200, 800));
      _show(tester, 'Saved');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.getRect(_toast).right, 1200 - 24);
      await tester.pumpAndSettle();
    });

    testWidgets('mobile: stays within the screen with a long message', (
      tester,
    ) async {
      await _pump(tester, size: _mobile);
      _show(tester, 'A very long confirmation message. ' * 8);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(tester.takeException(), isNull);
      final rect = tester.getRect(_toast);
      expect(rect.left, greaterThanOrEqualTo(16));
      expect(rect.right, lessThanOrEqualTo(390 - 16));
    });

    testWidgets('survives text scale 2.0', (tester) async {
      await _pump(tester, size: _mobile, textScale: 2);
      _show(tester, 'Saved. You can now send that file.');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(tester.takeException(), isNull);
      expect(tester.getRect(_toast).right, lessThanOrEqualTo(390 - 16));
    });
  });

  group('DsToast.show motion', () {
    testWidgets('desktop slides in 24 px from the right with opacity', (
      tester,
    ) async {
      await _pump(tester);
      _show(tester, 'Saved');
      await tester.pump();

      expect(tester.getRect(_toast).right, 1280 - 24 + 24);
      expect(_fade(tester).opacity.value, closeTo(0, 0.001));

      await tester.pump(const Duration(milliseconds: 125));
      expect(
        tester.getRect(_toast).right,
        inExclusiveRange(1280 - 24, 1280 - 24 + 24),
      );

      await tester.pump(const Duration(milliseconds: 125));
      expect(tester.getRect(_toast).right, 1280 - 24);
      expect(_fade(tester).opacity.value, 1);
    });

    testWidgets('mobile slides in 24 px from below', (tester) async {
      await _pump(tester, size: _mobile);
      _show(tester, 'Saved');
      await tester.pump();

      expect(tester.getRect(_toast).bottom, 844 - 32 + 24);

      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.getRect(_toast).bottom, 844 - 32);
      expect(tester.getRect(_toast).center.dx, closeTo(195, 0.5));
    });

    testWidgets('with reduced motion it only fades and is instant', (
      tester,
    ) async {
      await _pump(tester, reduceMotion: true);
      _show(tester, 'Saved');
      await tester.pump();
      await tester.pump();

      expect(tester.getRect(_toast).right, 1280 - 24);
      expect(_fade(tester).opacity.value, 1);
    });

    testWidgets('exit is faster than the 250 ms entrance', (tester) async {
      await _pump(tester);
      _show(tester, 'Saved');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_toast, findsOneWidget);

      await tester.pump(const Duration(milliseconds: 51));
      await tester.pump();
      expect(_toast, findsNothing);
    });
  });

  group('DsToast.show lifecycle', () {
    testWidgets('auto-dismisses after 3 seconds', (tester) async {
      await _pump(tester);
      _show(tester, 'Saved');
      await tester.pump();
      expect(find.text('Saved'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2990));
      expect(find.text('Saved'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('honors a custom duration', (tester) async {
      await _pump(tester);
      _show(tester, 'Saved', duration: const Duration(seconds: 1));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('Saved'), findsOneWidget);

      // El temporizador dispara la salida; esta arranca en el siguiente fotograma
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('a new toast replaces the previous one instead of stacking', (
      tester,
    ) async {
      await _pump(tester);
      _show(tester, 'First');
      await tester.pump(const Duration(milliseconds: 300));
      _show(tester, 'Second');
      await tester.pump();

      expect(_toast, findsOneWidget);
      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsNothing);
    });

    testWidgets('the replaced toast timer does not cut the new one short', (
      tester,
    ) async {
      await _pump(tester);
      _show(tester, 'First');
      await tester.pump(const Duration(seconds: 1));
      _show(tester, 'Second');
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 2500));
      expect(find.text('Second'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Second'), findsNothing);
    });

    testWidgets('does not block pointer events anywhere, toast included', (
      tester,
    ) async {
      var taps = 0;
      await _pump(
        tester,
        body: Stack(
          children: [
            Positioned(
              top: 24,
              right: 24,
              width: 200,
              height: 60,
              child: GestureDetector(
                key: const ValueKey('under-toast'),
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              width: 80,
              height: 40,
              child: GestureDetector(
                key: const ValueKey('elsewhere'),
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
              ),
            ),
          ],
        ),
      );
      _show(tester, 'Saved');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.byKey(const ValueKey('elsewhere')));
      expect(taps, 1);
      final toastRect = tester.getRect(_toast);
      final underToast = tester.getRect(
        find.byKey(const ValueKey('under-toast')),
      );
      expect(toastRect.overlaps(underToast), isTrue);
      await tester.tapAt(toastRect.center);
      expect(taps, 2);
      expect(
        tester
            .widget<IgnorePointer>(
              find
                  .ancestor(of: _toast, matching: find.byType(IgnorePointer))
                  .first,
            )
            .ignoring,
        isTrue,
      );
      await tester.pumpAndSettle();
    });

    testWidgets('leaves no timers or animations after settling', (
      tester,
    ) async {
      await _pump(tester);
      _show(tester, 'Saved');
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(_toast, findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('tearing down the app while visible leaves no pending timer', (
      tester,
    ) async {
      await _pump(tester);
      _show(tester, 'Saved');
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(const SizedBox());

      expect(tester.takeException(), isNull);
    });

    testWidgets('can show a toast after a previous overlay was torn down', (
      tester,
    ) async {
      await _pump(tester);
      _show(tester, 'Old');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(const SizedBox());

      await _pump(tester);
      _show(tester, 'New');
      await tester.pump();

      expect(find.text('New'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });
  });
}
