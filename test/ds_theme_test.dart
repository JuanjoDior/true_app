import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

OutlineInputBorder _outline(InputBorder? border) {
  expect(border, isA<OutlineInputBorder>());
  return border! as OutlineInputBorder;
}

RoundedRectangleBorder _rounded(OutlinedBorder? shape) {
  expect(shape, isA<RoundedRectangleBorder>());
  return shape! as RoundedRectangleBorder;
}

void main() {
  late ThemeData theme;

  setUp(() {
    theme = DsTheme.build();
  });

  group('DsTheme base', () {
    test('is a dark Material 3 theme', () {
      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
    });

    test('scaffold uses bgBase', () {
      expect(theme.scaffoldBackgroundColor, DsColors.bgBase);
    });

    test('default font family is NotoSans', () {
      expect(theme.textTheme.bodyMedium?.fontFamily, DsFontFamilies.sans);
      expect(theme.textTheme.titleMedium?.fontFamily, DsFontFamilies.sans);
    });

    test('color scheme maps tokens', () {
      final scheme = theme.colorScheme;
      expect(scheme.brightness, Brightness.dark);
      expect(scheme.primary, DsColors.accentRed);
      expect(scheme.onPrimary, Colors.white);
      expect(scheme.secondary, DsColors.accentGold);
      expect(scheme.onSecondary, DsColors.bgBase);
      expect(scheme.surface, DsColors.bgBase);
      expect(scheme.onSurface, DsColors.textPrimary);
      expect(scheme.error, DsColors.accentRedText);
    });

    test('surface containers are opaque tokens', () {
      final scheme = theme.colorScheme;
      for (final color in [
        scheme.surfaceContainerLowest,
        scheme.surfaceContainerLow,
        scheme.surfaceContainer,
        scheme.surfaceContainerHigh,
        scheme.surfaceContainerHighest,
      ]) {
        expect(color.a, 1.0);
      }
    });

    test('divider uses lineHairline', () {
      expect(theme.dividerColor, DsColors.lineHairline);
      expect(theme.dividerTheme.color, DsColors.lineHairline);
    });
  });

  group('DsTheme textTheme', () {
    test('maps the desktop styles', () {
      const styles = DsTextStyles.desktop;
      final text = theme.textTheme;
      expect(text.displayLarge, styles.displayHero);
      expect(text.displayMedium, styles.displayPage);
      expect(text.displaySmall, styles.displayCard);
      expect(text.headlineMedium, styles.displaySection);
      expect(text.titleLarge, styles.displayPoster);
      expect(text.bodyLarge, styles.bodyLarge);
      expect(text.bodyMedium, styles.body);
      expect(text.labelLarge, styles.uiButton);
      expect(text.labelSmall, styles.monoLabel);
    });

    test('displayLarge is 104 and titleLarge is 22', () {
      expect(theme.textTheme.displayLarge?.fontSize, 104);
      expect(theme.textTheme.titleLarge?.fontSize, 22);
    });
  });

  group('DsTheme inputs', () {
    test('filled with surfaceInput and placeholder hint', () {
      final input = theme.inputDecorationTheme;
      expect(input.filled, isTrue);
      expect(input.fillColor, DsColors.surfaceInput);
      expect(input.hintStyle?.color, DsColors.textPlaceholder);
    });

    test('enabled border uses lineInput with control radius', () {
      final border = _outline(theme.inputDecorationTheme.enabledBorder);
      expect(border.borderSide.color, DsColors.lineInput);
      expect(border.borderRadius, DsRadii.controlBorder);
      final base = _outline(theme.inputDecorationTheme.border);
      expect(base.borderSide.color, DsColors.lineInput);
      expect(base.borderRadius, DsRadii.controlBorder);
    });

    test('focused border is accentRed 1.2 px', () {
      final border = _outline(theme.inputDecorationTheme.focusedBorder);
      expect(border.borderSide.color, DsColors.accentRed);
      expect(border.borderSide.width, 1.2);
      expect(border.borderRadius, DsRadii.controlBorder);
    });

    test('error borders and text use accentRedText', () {
      final input = theme.inputDecorationTheme;
      expect(
        _outline(input.errorBorder).borderSide.color,
        DsColors.accentRedText,
      );
      expect(
        _outline(input.focusedErrorBorder).borderSide.color,
        DsColors.accentRedText,
      );
      expect(input.errorStyle?.color, DsColors.accentRedText);
    });
  });

  group('DsTheme buttons', () {
    test('filled button uses cta colors, control radius, no elevation', () {
      final style = theme.filledButtonTheme.style!;
      expect(style.backgroundColor?.resolve({}), DsColors.ctaBg);
      expect(style.foregroundColor?.resolve({}), DsColors.ctaFg);
      expect(style.elevation?.resolve({}), 0);
      expect(
        _rounded(style.shape?.resolve({})).borderRadius,
        DsRadii.controlBorder,
      );
      final text = style.textStyle?.resolve({});
      expect(text?.fontFamily, DsFontFamilies.sans);
      expect(text?.fontWeight, FontWeight.w600);
      expect(text?.fontSize, DsTextStyles.desktop.uiButton.fontSize);
    });

    test('filled button looks muted when disabled', () {
      final style = theme.filledButtonTheme.style!;
      final disabled = {WidgetState.disabled};
      expect(style.backgroundColor?.resolve(disabled), DsColors.surfaceCard);
      expect(
        style.foregroundColor?.resolve(disabled),
        DsColors.textPlaceholder,
      );
    });

    test('outlined button is glass with ctaGlassBorder', () {
      final style = theme.outlinedButtonTheme.style!;
      expect(style.backgroundColor?.resolve({}), DsColors.ctaGlass);
      expect(style.foregroundColor?.resolve({}), DsColors.textPrimary);
      final side = style.side?.resolve({});
      expect(side?.color, DsColors.ctaGlassBorder);
      expect(
        _rounded(style.shape?.resolve({})).borderRadius,
        DsRadii.controlBorder,
      );
      expect(style.textStyle?.resolve({})?.fontWeight, FontWeight.w600);
    });

    test('text button keeps radius and label style', () {
      final style = theme.textButtonTheme.style!;
      expect(style.foregroundColor?.resolve({}), DsColors.textPrimary);
      expect(
        _rounded(style.shape?.resolve({})).borderRadius,
        DsRadii.controlBorder,
      );
      expect(style.textStyle?.resolve({})?.fontWeight, FontWeight.w600);
    });
  });

  group('DsTheme surfaces', () {
    test('dialog uses sheet radius, strong glass and hairline border', () {
      final dialog = theme.dialogTheme;
      expect(dialog.backgroundColor, DsColors.surfaceGlassStrong);
      final shape = _rounded(dialog.shape as OutlinedBorder?);
      expect(shape.borderRadius, DsRadii.sheetBorder);
      expect(shape.side.color, DsColors.lineHairline);
    });

    test('snackbar is floating with bgGlow and textPrimary', () {
      final snack = theme.snackBarTheme;
      expect(snack.behavior, SnackBarBehavior.floating);
      expect(snack.backgroundColor, DsColors.bgGlow);
      expect(snack.contentTextStyle?.color, DsColors.textPrimary);
      expect(
        snack.contentTextStyle?.fontSize,
        DsTextStyles.desktop.body.fontSize,
      );
      expect(
        _rounded(snack.shape as OutlinedBorder?).borderRadius,
        DsRadii.controlBorder,
      );
    });

    test('chip is a pill with hairline side and surfaceCard', () {
      final chip = theme.chipTheme;
      expect(chip.backgroundColor, DsColors.surfaceCard);
      expect(chip.side?.color, DsColors.lineHairline);
      expect(_rounded(chip.shape).borderRadius, DsRadii.pillBorder);
    });
  });

  group('DsTheme in a running app', () {
    testWidgets('renders button, field, dialog and snackbar', (tester) async {
      final errors = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previous);

      await tester.pumpWidget(
        MaterialApp(
          theme: DsTheme.build(),
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  FilledButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => const AlertDialog(
                          title: Text('Dialog title'),
                          content: Text('Dialog body'),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                  TextButton(
                    onPressed: () => ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Saved'))),
                    child: const Text('Notify'),
                  ),
                  const TextField(
                    decoration: InputDecoration(hintText: 'Search cases'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Search cases'), findsOneWidget);

      final buttonStyle = DefaultTextStyle.of(
        tester.element(find.text('Open')),
      ).style;
      expect(buttonStyle.fontFamily, DsFontFamilies.sans);
      expect(buttonStyle.fontWeight, FontWeight.w600);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Dialog title'), findsOneWidget);
      final dialogMaterial = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(dialogMaterial.color, DsColors.surfaceGlassStrong);

      Navigator.of(tester.element(find.text('Dialog title'))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notify'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Saved'), findsOneWidget);

      expect(errors, isEmpty);
    });
  });
}
