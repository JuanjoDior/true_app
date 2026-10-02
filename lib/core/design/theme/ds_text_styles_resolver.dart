import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';

abstract final class DsTextStylesResolver {
  // sizeOf: solo se reconstruye al cambiar el tamaño, no con otros datos de MediaQuery
  static DsTextStyles of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= DsBreakpoints.desktop
        ? DsTextStyles.desktop
        : DsTextStyles.mobile;
  }
}
