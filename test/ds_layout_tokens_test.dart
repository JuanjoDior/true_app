import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/tokens/tokens.dart';

void main() {
  group('DsSpacing (DESIGN.md 3.3)', () {
    const scale = <double>[
      DsSpacing.s4,
      DsSpacing.s8,
      DsSpacing.s10,
      DsSpacing.s12,
      DsSpacing.s14,
      DsSpacing.s16,
      DsSpacing.s18,
      DsSpacing.s20,
      DsSpacing.s24,
      DsSpacing.s28,
      DsSpacing.s32,
      DsSpacing.s40,
      DsSpacing.s48,
      DsSpacing.s80,
    ];

    test('matches the documented scale', () {
      expect(scale, <double>[
        4, 8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 40, 48, 80, //
      ]);
    });

    test('is strictly increasing', () {
      for (var i = 1; i < scale.length; i++) {
        expect(scale[i], greaterThan(scale[i - 1]));
      }
    });

    test('every step is a multiple of 2', () {
      for (final step in scale) {
        expect(step % 2, 0);
      }
    });

    test('page margins', () {
      expect(DsSpacing.pageMarginDesktop, 80);
      expect(DsSpacing.pageMarginMobile, 16);
    });
  });

  group('DsRadii', () {
    test('uses the midpoint of each documented range', () {
      expect(DsRadii.badge, 6);
      expect(DsRadii.control, 12);
      expect(DsRadii.card, 14);
      expect(DsRadii.sheet, 22);
      expect(DsRadii.pill, 999);
      expect(DsRadii.icon, 18);
    });

    test('pill is the largest radius', () {
      final others = <double>[
        DsRadii.badge,
        DsRadii.control,
        DsRadii.card,
        DsRadii.sheet,
        DsRadii.icon,
      ];
      for (final radius in others) {
        expect(DsRadii.pill, greaterThan(radius));
      }
    });

    test('BorderRadius helpers use the matching radius', () {
      expect(DsRadii.badgeBorder, BorderRadius.circular(DsRadii.badge));
      expect(DsRadii.controlBorder, BorderRadius.circular(DsRadii.control));
      expect(DsRadii.cardBorder, BorderRadius.circular(DsRadii.card));
      expect(DsRadii.sheetBorder, BorderRadius.circular(DsRadii.sheet));
      expect(DsRadii.pillBorder, BorderRadius.circular(DsRadii.pill));
      expect(DsRadii.iconBorder, BorderRadius.circular(DsRadii.icon));
    });
  });

  group('DsShadows', () {
    test('glass is 0 30px 80px rgba(0,0,0,.6)', () {
      expect(DsShadows.glass, hasLength(1));
      final shadow = DsShadows.glass.single;
      expect(shadow.offset, const Offset(0, 30));
      expect(shadow.blurRadius, 80);
      expect(shadow.color.toARGB32() & 0xFFFFFF, 0x000000);
      expect(shadow.color.a, closeTo(0.6, 0.005));
    });

    test('modal is 0 50px 120px rgba(0,0,0,.7)', () {
      expect(DsShadows.modal, hasLength(1));
      final shadow = DsShadows.modal.single;
      expect(shadow.offset, const Offset(0, 50));
      expect(shadow.blurRadius, 120);
      expect(shadow.color.toARGB32() & 0xFFFFFF, 0x000000);
      expect(shadow.color.a, closeTo(0.7, 0.005));
    });

    test('posterHover is 0 34px 70px rgba(0,0,0,.65)', () {
      expect(DsShadows.posterHover, hasLength(1));
      final shadow = DsShadows.posterHover.single;
      expect(shadow.offset, const Offset(0, 34));
      expect(shadow.blurRadius, 70);
      expect(shadow.color.toARGB32() & 0xFFFFFF, 0x000000);
      expect(shadow.color.a, closeTo(0.65, 0.005));
    });
  });
}
