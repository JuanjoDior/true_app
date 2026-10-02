import 'dart:ui';

abstract final class DsColors {
  static const Color bgBase = Color(0xFF05070B);
  static const Color bgGlow = Color(0xFF0D1320);

  static const Color surfaceChrome = Color.fromRGBO(10, 13, 19, 0.88);
  static const Color surfaceGlass = Color.fromRGBO(14, 16, 22, 0.82);
  static const Color surfaceGlassStrong = Color.fromRGBO(14, 16, 22, 0.94);
  // Punto medio del rango 0,03–0,05 del diseño
  static const Color surfaceCard = Color.fromRGBO(255, 255, 255, 0.04);
  static const Color surfaceInput = Color(0xFF0D1118);

  // Punto medio del rango 0,08–0,14 del diseño
  static const Color lineHairline = Color.fromRGBO(255, 255, 255, 0.10);
  static const Color lineInput = Color(0xFF2A303B);

  static const Color textStrong = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFFF4F1EB);
  static const Color textBody = Color(0xFFD8D3CA);
  static const Color textMuted = Color(0xFFB9B4AB);
  static const Color textFaint = Color(0xFFA7A29A);
  static const Color textPlaceholder = Color(0xFF8B8880);

  static const Color accentRed = Color(0xFFE5484D);
  static const Color accentRedText = Color(0xFFFF7A7F);
  static const Color accentGold = Color(0xFFF0C674);

  static const Color ctaBg = Color(0xFFF4F1EB);
  static const Color ctaFg = Color(0xFF0B0C10);
  static const Color ctaGlass = Color.fromRGBO(255, 255, 255, 0.14);
  static const Color ctaGlassBorder = Color.fromRGBO(255, 255, 255, 0.24);

  static const Color landDotFlat = Color(0xFF33405A);
  static const Color landDotGlobe = Color(0xFF5C7399);

  static const int _landDotPrimeCol = 7;
  static const int _landDotPrimeRow = 13;
  static const int _landDotLevels = 6;
  static const double _landDotStep = 0.1;
  static const double _landDotMin = 0.45;

  static double landDotOpacity(int col, int row) {
    final level =
        (col * _landDotPrimeCol + row * _landDotPrimeRow) % _landDotLevels;
    return level * _landDotStep + _landDotMin;
  }
}

class DsCategoryColor {
  const DsCategoryColor({required this.dot, required this.posterBase});

  final Color dot;
  final Color posterBase;
}

abstract final class DsCategoryColors {
  static const DsCategoryColor serialKiller = DsCategoryColor(
    dot: Color(0xFFE5484D),
    posterBase: Color(0xFF2A0B10),
  );
  static const DsCategoryColor isolatedMurder = DsCategoryColor(
    dot: Color(0xFFD9788A),
    posterBase: Color(0xFF2A1219),
  );
  static const DsCategoryColor kidnapping = DsCategoryColor(
    dot: Color(0xFFE0A63A),
    posterBase: Color(0xFF2B1E0A),
  );
  static const DsCategoryColor unsolved = DsCategoryColor(
    dot: Color(0xFF5AA0D0),
    posterBase: Color(0xFF0B1F2E),
  );
}

abstract final class DsStatusColors {
  static const Color open = Color(0xFF6CB0E0);
  static const Color solved = Color(0xFF8FCB8A);
  static const Color inProgress = Color(0xFFF0B455);
  static const Color delivered = Color(0xFFB7A2F0);
}
