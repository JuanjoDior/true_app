import 'package:flutter/painting.dart';

abstract final class DsShadows {
  static const List<BoxShadow> glass = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.6),
      offset: Offset(0, 30),
      blurRadius: 80,
    ),
  ];

  static const List<BoxShadow> modal = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.7),
      offset: Offset(0, 50),
      blurRadius: 120,
    ),
  ];

  static const List<BoxShadow> posterHover = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.65),
      offset: Offset(0, 34),
      blurRadius: 70,
    ),
  ];
}
