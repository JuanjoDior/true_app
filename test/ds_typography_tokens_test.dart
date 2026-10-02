import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/tokens/tokens.dart';
import 'package:true_app/core/theme/app_theme.dart';

typedef _Spec = ({
  double size,
  double? height,
  FontWeight weight,
  double? letterSpacing,
  String family,
});

_Spec _spec(
  double size,
  String family,
  FontWeight weight, {
  double? height,
  double? letterSpacingEm,
}) => (
  size: size,
  height: height,
  weight: weight,
  letterSpacing: letterSpacingEm == null ? null : letterSpacingEm * size,
  family: family,
);

Map<String, TextStyle> _roles(DsTextStyles t) => {
  'displayHero': t.displayHero,
  'displayPage': t.displayPage,
  'displayCard': t.displayCard,
  'displaySection': t.displaySection,
  'displayPoster': t.displayPoster,
  'displayGhostYear': t.displayGhostYear,
  'bodyLead': t.bodyLead,
  'bodyLarge': t.bodyLarge,
  'body': t.body,
  'uiButton': t.uiButton,
  'monoLabel': t.monoLabel,
  'monoData': t.monoData,
};

const _display = DsFontFamilies.display;
const _sans = DsFontFamilies.sans;
const _mono = DsFontFamilies.mono;

final Map<String, _Spec> _desktop = {
  'displayHero': _spec(
    104,
    _display,
    FontWeight.w700,
    height: 0.95,
    letterSpacingEm: -0.01,
  ),
  'displayPage': _spec(42, _display, FontWeight.w700),
  'displayCard': _spec(35, _display, FontWeight.w700),
  'displaySection': _spec(27, _display, FontWeight.w700),
  'displayPoster': _spec(22, _display, FontWeight.w700),
  'displayGhostYear': _spec(490, _display, FontWeight.w700),
  'bodyLead': _spec(30, _display, FontWeight.w700, height: 1.4),
  'bodyLarge': _spec(18, _sans, FontWeight.w400, height: 1.6),
  'body': _spec(15, _sans, FontWeight.w400, height: 1.6),
  'uiButton': _spec(15, _sans, FontWeight.w600),
  'monoLabel': _spec(11, _mono, FontWeight.w500, letterSpacingEm: 0.18),
  'monoData': _spec(14, _mono, FontWeight.w400),
};

final Map<String, _Spec> _mobile = {
  'displayHero': _spec(
    56,
    _display,
    FontWeight.w700,
    height: 0.95,
    letterSpacingEm: -0.01,
  ),
  'displayPage': _spec(33, _display, FontWeight.w700),
  'displayCard': _spec(31, _display, FontWeight.w700),
  'displaySection': _spec(23, _display, FontWeight.w700),
  'displayPoster': _spec(19, _display, FontWeight.w700),
  'displayGhostYear': _spec(250, _display, FontWeight.w700),
  'bodyLead': _spec(23, _display, FontWeight.w700, height: 1.4),
  'bodyLarge': _spec(15, _sans, FontWeight.w400, height: 1.6),
  'body': _spec(15, _sans, FontWeight.w400, height: 1.6),
  'uiButton': _spec(15, _sans, FontWeight.w600),
  'monoLabel': _spec(11, _mono, FontWeight.w500, letterSpacingEm: 0.18),
  'monoData': _spec(13, _mono, FontWeight.w400),
};

void _expectSpec(String role, TextStyle style, _Spec spec) {
  expect(style.fontSize, spec.size, reason: '$role fontSize');
  expect(style.height, spec.height, reason: '$role height');
  expect(style.fontWeight, spec.weight, reason: '$role fontWeight');
  expect(style.fontFamily, spec.family, reason: '$role fontFamily');
  if (spec.letterSpacing == null) {
    expect(style.letterSpacing, isNull, reason: '$role letterSpacing');
  } else {
    expect(
      style.letterSpacing,
      closeTo(spec.letterSpacing!, 1e-9),
      reason: '$role letterSpacing',
    );
  }
}

List<String> _ibmPlexMonoAssets(String pubspec) {
  final lines = pubspec.split('\n');
  final start = lines.indexWhere(
    (l) => RegExp(r'^\s*-\s*family:\s*IBMPlexMono\s*$').hasMatch(l),
  );
  expect(start, isNonNegative, reason: 'IBMPlexMono family not declared');
  final block = <String>[];
  for (var i = start + 1; i < lines.length; i++) {
    if (RegExp(r'^\s*-\s*family:').hasMatch(lines[i])) break;
    if (lines[i].trim().isNotEmpty && !lines[i].startsWith(' ')) break;
    block.add(lines[i]);
  }
  return block;
}

void main() {
  group('DsFontFamilies', () {
    test('expone los nombres de familia declarados en pubspec', () {
      expect(DsFontFamilies.sans, 'NotoSans');
      expect(DsFontFamilies.display, 'NotoSerifDisplay');
      expect(DsFontFamilies.mono, 'IBMPlexMono');
    });

    test('kMonoFamily apunta a IBM Plex Mono', () {
      expect(kMonoFamily, DsFontFamilies.mono);
    });
  });

  group('DsTextStyles', () {
    test('desktop coincide con la tabla de DESIGN.md 3.2', () {
      final roles = _roles(DsTextStyles.desktop);
      expect(roles.keys, _desktop.keys);
      for (final entry in roles.entries) {
        _expectSpec(entry.key, entry.value, _desktop[entry.key]!);
      }
    });

    test('mobile coincide con la tabla de DESIGN.md 3.2', () {
      final roles = _roles(DsTextStyles.mobile);
      expect(roles.keys, _mobile.keys);
      for (final entry in roles.entries) {
        _expectSpec(entry.key, entry.value, _mobile[entry.key]!);
      }
    });

    test('monoLabel nunca baja de 11 px', () {
      expect(DsTextStyles.desktop.monoLabel.fontSize, greaterThanOrEqualTo(11));
      expect(DsTextStyles.mobile.monoLabel.fontSize, greaterThanOrEqualTo(11));
    });

    test('los tamaños móviles no superan a los de escritorio', () {
      final desktop = _roles(DsTextStyles.desktop);
      final mobile = _roles(DsTextStyles.mobile);
      for (final role in desktop.keys) {
        expect(
          mobile[role]!.fontSize!,
          lessThanOrEqualTo(desktop[role]!.fontSize!),
          reason: role,
        );
      }
    });

    test('los roles de cuerpo tienen interlineado >= 1.4', () {
      for (final t in [DsTextStyles.desktop, DsTextStyles.mobile]) {
        for (final style in [t.bodyLead, t.bodyLarge, t.body]) {
          expect(style.height, greaterThanOrEqualTo(1.4));
        }
      }
    });

    test('colores por rol', () {
      for (final t in [DsTextStyles.desktop, DsTextStyles.mobile]) {
        expect(t.displayHero.color, DsColors.textStrong);
        expect(t.displayPage.color, DsColors.textStrong);
        expect(t.displayCard.color, DsColors.textPrimary);
        expect(t.displaySection.color, DsColors.textPrimary);
        expect(t.displayPoster.color, DsColors.textPrimary);
        expect(t.bodyLead.color, DsColors.textBody);
        expect(t.bodyLarge.color, DsColors.textBody);
        expect(t.body.color, DsColors.textBody);
        expect(t.uiButton.color, DsColors.textBody);
        expect(t.monoLabel.color, DsColors.textMuted);
        expect(t.monoData.color, DsColors.accentGold);
      }
    });

    test('displayGhostYear es blanco al 4.75 % de opacidad', () {
      for (final t in [DsTextStyles.desktop, DsTextStyles.mobile]) {
        final color = t.displayGhostYear.color!;
        expect(color.r, 1.0);
        expect(color.g, 1.0);
        expect(color.b, 1.0);
        expect(color.a, closeTo(0.0475, 0.003));
      }
    });
  });

  group('pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    test('declara IBMPlexMono con pesos 400 y 500', () {
      final block = _ibmPlexMonoAssets(pubspec).join('\n');
      expect(RegExp(r'weight:\s*400\b').hasMatch(block), isTrue);
      expect(RegExp(r'weight:\s*500\b').hasMatch(block), isTrue);
    });

    test('todos los assets de IBMPlexMono existen en disco', () {
      final assets = _ibmPlexMonoAssets(pubspec)
          .map((l) => RegExp(r'asset:\s*(\S+)').firstMatch(l)?.group(1))
          .whereType<String>()
          .toList();
      expect(assets, hasLength(2));
      for (final path in assets) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });

    test('la licencia OFL se conserva junto a las fuentes', () {
      expect(File('assets/fonts/IBMPlexMono-OFL.txt').existsSync(), isTrue);
    });
  });
}
