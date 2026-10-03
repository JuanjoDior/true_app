import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

const _mobile = Size(390, 844);
const _desktop = Size(1280, 800);

Future<void> _pump(
  WidgetTester tester,
  WidgetBuilder builder, {
  Size size = _desktop,
  double textScale = 1,
  bool reduceMotion = false,
  bool barrierDismissible = true,
  void Function(Future<Object?> result)? onResult,
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
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: app!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            key: const ValueKey('opener'),
            onPressed: () {
              final result = showDsDialog<Object?>(
                context: context,
                builder: builder,
                barrierDismissible: barrierDismissible,
              );
              onResult?.call(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('opener')));
  await tester.pump();
}

Widget _simpleDialog(BuildContext context) => DsDialog(
  title: 'Restore drafts',
  content: const Text('Paste the file contents.'),
  actions: [
    DsButton(
      label: 'Cancel',
      variant: DsButtonVariant.outline,
      onPressed: () => Navigator.of(context).pop('cancel'),
    ),
    DsButton(
      label: 'Restore',
      onPressed: () => Navigator.of(context).pop('restore'),
    ),
  ],
);

Finder get _dialog => find.byType(DsDialog);

Finder get _panel =>
    find.descendant(of: _dialog, matching: find.byType(DsGlassPanel));

ScaleTransition _scale(WidgetTester tester) => tester.widget<ScaleTransition>(
  find.ancestor(of: _dialog, matching: find.byType(ScaleTransition)).first,
);

FadeTransition _fade(WidgetTester tester) => tester.widget<FadeTransition>(
  find.ancestor(of: _dialog, matching: find.byType(FadeTransition)).first,
);

void main() {
  group('DsDialog layout', () {
    testWidgets('is a strong glass panel with radius 20 and the modal shadow', (
      tester,
    ) async {
      await _pump(tester, _simpleDialog);
      await _open(tester);
      await tester.pumpAndSettle();

      final panel = tester.widget<DsGlassPanel>(_panel);
      expect(panel.strong, isTrue);
      expect(panel.borderRadius, BorderRadius.circular(20));
      expect(panel.shadows, DsShadows.modal);
    });

    testWidgets('title is serif 22 textStrong', (tester) async {
      await _pump(tester, _simpleDialog);
      await _open(tester);
      await tester.pumpAndSettle();

      final style = tester.widget<Text>(find.text('Restore drafts')).style!;
      expect(style.fontFamily, DsFontFamilies.display);
      expect(style.fontSize, 22);
      expect(style.color, DsColors.textStrong);
    });

    testWidgets('is at most 480 wide on desktop', (tester) async {
      await _pump(tester, _simpleDialog);
      await _open(tester);
      await tester.pumpAndSettle();

      expect(tester.getSize(_panel).width, 480);
    });

    testWidgets('keeps a margin on mobile', (tester) async {
      await _pump(tester, _simpleDialog, size: _mobile);
      await _open(tester);
      await tester.pumpAndSettle();

      final rect = tester.getRect(_panel);
      expect(rect.width, lessThanOrEqualTo(480));
      expect(rect.left, greaterThanOrEqualTo(16));
      expect(_mobile.width - rect.right, greaterThanOrEqualTo(16));
    });

    testWidgets('is centered and its actions are right-aligned', (
      tester,
    ) async {
      await _pump(tester, _simpleDialog);
      await _open(tester);
      await tester.pumpAndSettle();

      final panel = tester.getRect(_panel);
      expect(panel.center.dx, closeTo(640, 0.5));
      final restore = tester.getRect(find.byType(DsButton).last);
      final cancel = tester.getRect(find.byType(DsButton).first);
      expect(panel.right - restore.right, inInclusiveRange(24, 26));
      expect(restore.left, greaterThan(cancel.right));
      expect(cancel.left, greaterThan(panel.center.dx - 100));
    });

    testWidgets('exposes the dialog role named by the title', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _simpleDialog);
      await _open(tester);
      await tester.pumpAndSettle();

      final namedRoutes = find.semantics.byLabel('Restore drafts');
      expect(namedRoutes, findsWidgets);
      expect(
        tester.getSemantics(find.byType(DsDialog)),
        isSemantics(
          label: 'Restore drafts',
          scopesRoute: true,
          namesRoute: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('hosts form fields: the dialog supplies a Material', (
      tester,
    ) async {
      await _pump(
        tester,
        (context) => const DsDialog(
          title: 'Restore drafts',
          content: DsFormField(label: 'JSON', maxLines: 3),
        ),
      );
      await _open(tester);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), '{}');
      expect(tester.takeException(), isNull);
      expect(find.text('{}'), findsOneWidget);
    });

    testWidgets('renders without actions', (tester) async {
      await _pump(
        tester,
        (context) => const DsDialog(title: 'Notice', content: Text('Hello')),
      );
      await _open(tester);
      await tester.pumpAndSettle();

      expect(find.byType(DsButton), findsNothing);
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('survives text scale 2.0 on a 390 px screen', (tester) async {
      await _pump(
        tester,
        (context) => DsDialog(
          title: 'A long dialog title that must wrap on narrow screens',
          content: Text('Paragraph of content. ' * 30),
          actions: [
            DsButton(label: 'Cancel', onPressed: () {}),
            DsButton(label: 'Restore everything', onPressed: () {}),
          ],
        ),
        size: _mobile,
        textScale: 2,
      );
      await _open(tester);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tester.getRect(_panel).bottom, lessThanOrEqualTo(844));
    });

    testWidgets('does not overflow at 390 px', (tester) async {
      await _pump(tester, _simpleDialog, size: _mobile);
      await _open(tester);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('showDsDialog open and close', () {
    testWidgets('opens and returns the popped value', (tester) async {
      Future<Object?>? result;
      await _pump(tester, _simpleDialog, onResult: (r) => result = r);
      await _open(tester);
      await tester.pumpAndSettle();
      expect(_dialog, findsOneWidget);

      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();

      expect(_dialog, findsNothing);
      expect(await result, 'restore');
    });

    testWidgets('Esc closes when the barrier is dismissible', (tester) async {
      Future<Object?>? result;
      await _pump(tester, _simpleDialog, onResult: (r) => result = r);
      await _open(tester);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(_dialog, findsNothing);
      expect(await result, isNull);
    });

    testWidgets('barrier tap closes when dismissible', (tester) async {
      await _pump(tester, _simpleDialog);
      await _open(tester);
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(_dialog, findsNothing);
    });

    testWidgets('tapping inside the dialog does not close it', (tester) async {
      await _pump(tester, _simpleDialog);
      await _open(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Paste the file contents.'));
      await tester.pumpAndSettle();

      expect(_dialog, findsOneWidget);
    });

    testWidgets('neither Esc nor the barrier close a non-dismissible dialog', (
      tester,
    ) async {
      await _pump(tester, _simpleDialog, barrierDismissible: false);
      await _open(tester);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_dialog, findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(_dialog, findsOneWidget);
    });

    testWidgets('the barrier is black at 60%', (tester) async {
      await _pump(tester, _simpleDialog);
      await _open(tester);
      await tester.pumpAndSettle();

      final barrier = tester.widget<AnimatedModalBarrier>(
        find.byType(AnimatedModalBarrier).last,
      );
      expect(barrier.color.value, const Color.fromRGBO(0, 0, 0, 0.6));
    });

    testWidgets('traps keyboard focus inside the dialog', (tester) async {
      await _pump(tester, _simpleDialog);
      await _open(tester);
      await tester.pumpAndSettle();

      for (var i = 0; i < 6; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final focused = FocusManager.instance.primaryFocus!.context!;
        expect(focused.findAncestorWidgetOfExactType<DsDialog>(), isNotNull);
      }
    });
  });

  group('showDsDialog motion', () {
    testWidgets('enters with fade and a 0.96 to 1 scale over 200 ms', (
      tester,
    ) async {
      await _pump(tester, _simpleDialog);
      await _open(tester);

      expect(_scale(tester).alignment, Alignment.center);
      expect(_scale(tester).scale.value, closeTo(0.96, 0.001));
      expect(_fade(tester).opacity.value, closeTo(0, 0.001));

      await tester.pump(const Duration(milliseconds: 100));
      expect(_scale(tester).scale.value, inExclusiveRange(0.96, 1));
      expect(_fade(tester).opacity.value, inExclusiveRange(0, 1));

      await tester.pump(const Duration(milliseconds: 100));
      expect(_scale(tester).scale.value, 1);
      expect(_fade(tester).opacity.value, 1);
    });

    testWidgets('never scales from zero', (tester) async {
      await _pump(tester, _simpleDialog);
      await _open(tester);

      for (var i = 0; i < 12; i++) {
        expect(_scale(tester).scale.value, greaterThanOrEqualTo(0.96));
        await tester.pump(const Duration(milliseconds: 20));
      }
    });

    testWidgets('exits in 150 ms, faster than it enters', (tester) async {
      await _pump(tester, _simpleDialog);
      await _open(tester);
      await tester.pumpAndSettle();

      Navigator.of(tester.element(_dialog)).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_dialog, findsOneWidget);

      await tester.pump(const Duration(milliseconds: 51));
      await tester.pump();
      expect(_dialog, findsNothing);
    });

    testWidgets('with reduced motion it appears instantly, without scale', (
      tester,
    ) async {
      await _pump(tester, _simpleDialog, reduceMotion: true);
      await _open(tester);
      await tester.pump();

      expect(_dialog, findsOneWidget);
      expect(
        find.ancestor(of: _dialog, matching: find.byType(ScaleTransition)),
        findsNothing,
      );
      expect(_fade(tester).opacity.value, 1);
    });

    testWidgets('with reduced motion it closes instantly', (tester) async {
      await _pump(tester, _simpleDialog, reduceMotion: true);
      await _open(tester);
      await tester.pump();

      Navigator.of(tester.element(_dialog)).pop();
      await tester.pump();
      await tester.pump();

      expect(_dialog, findsNothing);
    });

    testWidgets('leaves no pending animations after closing', (tester) async {
      await _pump(tester, _simpleDialog);
      await _open(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
