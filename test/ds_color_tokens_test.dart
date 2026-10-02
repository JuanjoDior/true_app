import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/tokens/tokens.dart';

double _linear(double channel) => channel <= 0.03928
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color color) =>
    0.2126 * _linear(color.r) +
    0.7152 * _linear(color.g) +
    0.0722 * _linear(color.b);

double _contrast(Color foreground, Color background) {
  final a = _luminance(foreground);
  final b = _luminance(background);
  final lighter = math.max(a, b);
  final darker = math.min(a, b);
  return (lighter + 0.05) / (darker + 0.05);
}

int _rgb(Color color) => color.toARGB32() & 0xFFFFFF;

void _expectRgba(Color color, int rgb, double alpha) {
  expect(_rgb(color), rgb);
  expect(color.a, closeTo(alpha, 0.005));
}

void main() {
  group('DsColors values (DESIGN.md 3.1)', () {
    test('opaque solids match the documented hex', () {
      expect(DsColors.bgBase, const Color(0xFF05070B));
      expect(DsColors.bgGlow, const Color(0xFF0D1320));
      expect(DsColors.surfaceInput, const Color(0xFF0D1118));
      expect(DsColors.lineInput, const Color(0xFF2A303B));
      expect(DsColors.textStrong, const Color(0xFFFFFFFF));
      expect(DsColors.textPrimary, const Color(0xFFF4F1EB));
      expect(DsColors.textBody, const Color(0xFFD8D3CA));
      expect(DsColors.textMuted, const Color(0xFFB9B4AB));
      expect(DsColors.textFaint, const Color(0xFFA7A29A));
      expect(DsColors.textPlaceholder, const Color(0xFF8B8880));
      expect(DsColors.accentRed, const Color(0xFFE5484D));
      expect(DsColors.accentRedText, const Color(0xFFFF7A7F));
      expect(DsColors.accentGold, const Color(0xFFF0C674));
      expect(DsColors.ctaBg, const Color(0xFFF4F1EB));
      expect(DsColors.ctaFg, const Color(0xFF0B0C10));
      expect(DsColors.landDotFlat, const Color(0xFF33405A));
      expect(DsColors.landDotGlobe, const Color(0xFF5C7399));
    });

    test('translucent tokens match the documented rgba', () {
      _expectRgba(DsColors.surfaceChrome, 0x0A0D13, 0.88);
      _expectRgba(DsColors.surfaceGlass, 0x0E1016, 0.82);
      _expectRgba(DsColors.surfaceGlassStrong, 0x0E1016, 0.94);
      _expectRgba(DsColors.surfaceCard, 0xFFFFFF, 0.04);
      _expectRgba(DsColors.lineHairline, 0xFFFFFF, 0.10);
      _expectRgba(DsColors.ctaGlass, 0xFFFFFF, 0.14);
      _expectRgba(DsColors.ctaGlassBorder, 0xFFFFFF, 0.24);
    });
  });

  group('DsCategoryColors', () {
    test('every category has the documented dot and poster base', () {
      expect(DsCategoryColors.serialKiller.dot, const Color(0xFFE5484D));
      expect(DsCategoryColors.serialKiller.posterBase, const Color(0xFF2A0B10));
      expect(DsCategoryColors.isolatedMurder.dot, const Color(0xFFD9788A));
      expect(
        DsCategoryColors.isolatedMurder.posterBase,
        const Color(0xFF2A1219),
      );
      expect(DsCategoryColors.kidnapping.dot, const Color(0xFFE0A63A));
      expect(DsCategoryColors.kidnapping.posterBase, const Color(0xFF2B1E0A));
      expect(DsCategoryColors.unsolved.dot, const Color(0xFF5AA0D0));
      expect(DsCategoryColors.unsolved.posterBase, const Color(0xFF0B1F2E));
    });
  });

  group('DsStatusColors', () {
    test('every status has the documented color', () {
      expect(DsStatusColors.open, const Color(0xFF6CB0E0));
      expect(DsStatusColors.solved, const Color(0xFF8FCB8A));
      expect(DsStatusColors.inProgress, const Color(0xFFF0B455));
      expect(DsStatusColors.delivered, const Color(0xFFB7A2F0));
    });
  });

  group('contrast on bgBase (WCAG AA, 4.5:1)', () {
    const minimum = 4.5;
    final tokens = <String, Color>{
      'textPrimary': DsColors.textPrimary,
      'textBody': DsColors.textBody,
      'textMuted': DsColors.textMuted,
      'textFaint': DsColors.textFaint,
      'accentRedText': DsColors.accentRedText,
    };

    for (final entry in tokens.entries) {
      test('${entry.key} reaches 4.5:1', () {
        final ratio = _contrast(entry.value, DsColors.bgBase);
        expect(ratio, greaterThanOrEqualTo(minimum));
      });
    }
  });

  group('contrast on surfaceInput', () {
    test('textPlaceholder reaches 4.5:1', () {
      final ratio = _contrast(DsColors.textPlaceholder, DsColors.surfaceInput);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  });

  group('DsColors.landDotOpacity', () {
    test('matches ((col*7 + row*13) % 6)/10 + 0.45', () {
      for (var col = 0; col < 40; col++) {
        for (var row = 0; row < 40; row++) {
          final expected = ((col * 7 + row * 13) % 6) / 10 + 0.45;
          expect(DsColors.landDotOpacity(col, row), closeTo(expected, 1e-12));
        }
      }
    });

    test('stays within 0.45..0.95', () {
      for (var col = 0; col < 40; col++) {
        for (var row = 0; row < 40; row++) {
          final value = DsColors.landDotOpacity(col, row);
          expect(value, inInclusiveRange(0.45, 0.95));
        }
      }
    });
  });

  group('design layer isolation', () {
    test('nothing under lib/core/design imports from features', () {
      final files = Directory('lib/core/design')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();
      expect(files, isNotEmpty);

      final offenders = <String>[];
      for (final file in files) {
        for (final line in file.readAsLinesSync()) {
          final trimmed = line.trimLeft();
          final isDirective =
              trimmed.startsWith('import ') || trimmed.startsWith('export ');
          if (!isDirective) continue;
          final intoFeatures =
              trimmed.contains('package:true_app/features') ||
              RegExp(r'''['"](\.\./)+features/''').hasMatch(trimmed);
          if (intoFeatures) offenders.add('${file.path}: $trimmed');
        }
      }
      expect(offenders, isEmpty);
    });
  });
}
