import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

const _mobile = Size(390, 844);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = _mobile,
  double textScale = 1,
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
        ),
        child: app!,
      ),
      home: Scaffold(body: child),
    ),
  );
}

Finder get _tile => find.byKey(DsStateMessage.iconTileKey);

BoxDecoration _tileDecoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.descendant(of: _tile, matching: find.byType(DecoratedBox)),
            )
            .decoration
        as BoxDecoration;

void main() {
  group('DsStateMessage anatomy', () {
    testWidgets('icon tile is 60x60, radius 18, tone at 14% with a tone icon', (
      tester,
    ) async {
      await _pump(
        tester,
        const DsStateMessage(
          icon: Icons.inbox_outlined,
          tone: DsStatusColors.delivered,
          title: 'Title',
        ),
      );

      expect(tester.getSize(_tile), const Size(60, 60));
      final decoration = _tileDecoration(tester);
      expect(decoration.borderRadius, DsRadii.iconBorder);
      expect(
        decoration.color,
        DsStatusColors.delivered.withValues(alpha: 0.14),
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.inbox_outlined)).color,
        DsStatusColors.delivered,
      );
    });

    testWidgets('title is serif section style; message is body textMuted', (
      tester,
    ) async {
      await _pump(
        tester,
        const DsStateMessage(
          icon: Icons.inbox_outlined,
          tone: DsColors.textFaint,
          title: 'No cases yet',
          message: 'Published cases appear here.',
        ),
      );

      final title = tester.widget<Text>(find.text('No cases yet')).style!;
      expect(title.fontFamily, DsFontFamilies.display);
      expect(title.fontSize, DsTextStyles.mobile.displaySection.fontSize);
      final message = tester
          .widget<Text>(find.text('Published cases appear here.'))
          .style!;
      expect(message.color, DsColors.textMuted);
      expect(message.fontSize, 15);
    });

    testWidgets('title is optional', (tester) async {
      await _pump(
        tester,
        const DsStateMessage(
          icon: Icons.inbox_outlined,
          tone: DsColors.textFaint,
          message: 'Only a message',
        ),
      );

      expect(find.text('Only a message'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('requires a title or a message', (tester) async {
      expect(
        () => DsStateMessage(icon: Icons.inbox_outlined, tone: Colors.red),
        throwsAssertionError,
      );
    });

    testWidgets('is a centered column', (tester) async {
      await _pump(
        tester,
        const DsStateMessage(
          icon: Icons.inbox_outlined,
          tone: DsColors.textFaint,
          title: 'No cases yet',
          message: 'Published cases appear here.',
        ),
      );

      expect(tester.getCenter(_tile).dx, closeTo(195, 0.5));
      expect(tester.getCenter(find.text('No cases yet')).dx, closeTo(195, 0.5));
      expect(
        tester.getTopLeft(find.text('No cases yet')).dy,
        greaterThan(tester.getBottomLeft(_tile).dy),
      );
    });

    testWidgets('compact takes less vertical space', (tester) async {
      const regular = DsStateMessage(
        icon: Icons.inbox_outlined,
        tone: DsColors.textFaint,
        title: 'No cases yet',
        message: 'Published cases appear here.',
      );
      await _pump(
        tester,
        const Align(alignment: Alignment.topCenter, child: regular),
      );
      final regularHeight = tester.getSize(find.byType(DsStateMessage)).height;

      await _pump(
        tester,
        const Align(
          alignment: Alignment.topCenter,
          child: DsStateMessage(
            icon: Icons.inbox_outlined,
            tone: DsColors.textFaint,
            title: 'No cases yet',
            message: 'Published cases appear here.',
            compact: true,
          ),
        ),
      );
      final compactHeight = tester.getSize(find.byType(DsStateMessage)).height;

      expect(compactHeight, lessThan(regularHeight));
      expect(tester.getSize(_tile), const Size(60, 60));
    });
  });

  group('DsStateMessage action', () {
    testWidgets('renders a glass DsButton that calls onAction', (tester) async {
      var calls = 0;
      await _pump(
        tester,
        DsStateMessage(
          icon: Icons.inbox_outlined,
          tone: DsColors.textFaint,
          title: 'Title',
          actionLabel: 'Retry',
          onAction: () => calls++,
        ),
      );

      final button = tester.widget<DsButton>(find.byType(DsButton));
      expect(button.variant, DsButtonVariant.glass);
      expect(button.label, 'Retry');

      await tester.tap(find.text('Retry'));
      expect(calls, 1);
    });

    testWidgets('no button without both label and callback', (tester) async {
      await _pump(
        tester,
        const DsStateMessage(
          icon: Icons.inbox_outlined,
          tone: DsColors.textFaint,
          title: 'Title',
          actionLabel: 'Retry',
        ),
      );
      expect(find.byType(DsButton), findsNothing);

      await _pump(
        tester,
        DsStateMessage(
          icon: Icons.inbox_outlined,
          tone: DsColors.textFaint,
          title: 'Title',
          onAction: () {},
        ),
      );
      expect(find.byType(DsButton), findsNothing);
    });
  });

  group('DsStateMessage variants', () {
    testWidgets('empty is gray (textFaint) and not a live region', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const DsStateMessage.empty(
          title: 'Nothing here',
          message: 'No cases yet.',
        ),
      );

      expect(
        _tileDecoration(tester).color,
        DsColors.textFaint.withValues(alpha: 0.14),
      );
      expect(
        tester.getSemantics(find.text('Nothing here')),
        isNot(isSemantics(isLiveRegion: true)),
      );
      handle.dispose();
    });

    testWidgets('error is amber (inProgress) and announces itself', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const DsStateMessage.error(
          title: 'The file could not be read',
          message: 'Try again in a moment.',
        ),
      );

      expect(
        _tileDecoration(tester).color,
        DsStatusColors.inProgress.withValues(alpha: 0.14),
      );
      expect(
        tester.getSemantics(find.text('The file could not be read')),
        isSemantics(isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('notFound is blue (open) and not a live region', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const DsStateMessage.notFound(title: 'That case does not exist'),
      );

      expect(
        _tileDecoration(tester).color,
        DsStatusColors.open.withValues(alpha: 0.14),
      );
      expect(
        tester.getSemantics(find.text('That case does not exist')),
        isNot(isSemantics(isLiveRegion: true)),
      );
      handle.dispose();
    });

    testWidgets('variants accept an icon override and an action', (
      tester,
    ) async {
      var calls = 0;
      await _pump(
        tester,
        DsStateMessage.error(
          icon: Icons.cloud_off_rounded,
          title: 'Offline',
          actionLabel: 'Retry',
          onAction: () => calls++,
        ),
      );

      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(calls, 1);
    });

    testWidgets('each variant ships a default icon', (tester) async {
      await _pump(
        tester,
        const Column(
          children: [
            DsStateMessage.empty(title: 'A'),
            DsStateMessage.error(title: 'B'),
            DsStateMessage.notFound(title: 'C'),
          ],
        ),
        size: const Size(390, 2400),
      );

      expect(find.byType(Icon), findsNWidgets(3));
    });
  });

  group('DsStateMessage layout robustness', () {
    testWidgets('survives text scale 2.0 with a long title and action', (
      tester,
    ) async {
      await _pump(
        tester,
        SingleChildScrollView(
          child: DsStateMessage.error(
            title: 'The file could not be read right now',
            message: 'The case may still be there. Try again in a moment.',
            actionLabel: 'Retry',
            onAction: () {},
          ),
        ),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow at 390 px', (tester) async {
      await _pump(
        tester,
        DsStateMessage.notFound(
          title: 'This address does not lead anywhere ' * 3,
          message: 'The address does not match any published case. ' * 3,
          actionLabel: 'Back to the archive',
          onAction: () {},
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(DsStateMessage)).width,
        lessThanOrEqualTo(390),
      );
    });
  });
}
