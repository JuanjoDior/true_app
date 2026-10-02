import 'package:flutter/painting.dart';

// Valores: punto medio de los rangos de DESIGN.md 3.3 (control 10–14, tarjeta 12–16, hoja 18–26)
abstract final class DsRadii {
  static const double badge = 6;
  static const double control = 12;
  static const double card = 14;
  static const double sheet = 22;
  static const double pill = 999;
  static const double icon = 18;

  static const BorderRadius badgeBorder = BorderRadius.all(
    Radius.circular(badge),
  );
  static const BorderRadius controlBorder = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius cardBorder = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius sheetBorder = BorderRadius.all(
    Radius.circular(sheet),
  );
  static const BorderRadius pillBorder = BorderRadius.all(
    Radius.circular(pill),
  );
  static const BorderRadius iconBorder = BorderRadius.all(
    Radius.circular(icon),
  );
}
