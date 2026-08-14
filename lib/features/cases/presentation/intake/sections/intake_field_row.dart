import 'package:flutter/material.dart';

import '../../../../../core/layout/breakpoints.dart';

/// Un campo dentro de una [IntakeFieldRow]: ancho fijo (`SizedBox`) o
/// flexible (`Expanded`) cuando la fila cabe en línea.
class IntakeFieldSlot {
  const IntakeFieldSlot.fixed(this.child, {required this.width})
    : isFlexible = false;

  const IntakeFieldSlot.flexible(this.child) : width = null, isFlexible = true;

  final Widget child;
  final double? width;
  final bool isFlexible;
}

/// Fila de campos de formulario que se muestra en línea (`Row`) cuando hay
/// sitio y se apila en columna cuando no lo hay.
///
/// El umbral no depende del ancho de pantalla: depende del ancho disponible
/// donde se coloca la fila (`LayoutBuilder`), porque las secciones viven
/// dentro de una columna de ancho variable [Diseño D5].
class IntakeFieldRow extends StatelessWidget {
  const IntakeFieldRow({
    super.key,
    required this.fields,
    this.trailing,
    this.minRowWidth = Breakpoints.formRowStack,
  });

  final List<IntakeFieldSlot> fields;
  final Widget? trailing;
  final double minRowWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return constraints.maxWidth >= minRowWidth
            ? _buildRow()
            : _buildColumn();
      },
    );
  }

  /// Layout de hoy, sin cambios: fijo -> `SizedBox`, flexible -> `Expanded`,
  /// huecos de 10px entre campos.
  Widget _buildRow() {
    final children = <Widget>[];
    for (var i = 0; i < fields.length; i++) {
      if (i > 0) {
        children.add(const SizedBox(width: 10));
      }
      final slot = fields[i];
      children.add(
        slot.isFlexible
            ? Expanded(child: slot.child)
            : SizedBox(width: slot.width, child: slot.child),
      );
    }
    final trailingWidget = trailing;
    if (trailingWidget != null) {
      children.add(trailingWidget);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// El trailing (normalmente borrar) va primero y alineado a la derecha,
  /// para que nunca quede pegado al botón "Añadir…" de debajo. Los campos
  /// van después, a ancho completo.
  Widget _buildColumn() {
    final trailingWidget = trailing;
    final children = <Widget>[
      if (trailingWidget != null) ...[
        Align(alignment: Alignment.centerRight, child: trailingWidget),
        const SizedBox(height: 4),
      ],
      for (var i = 0; i < fields.length; i++) ...[
        if (i > 0) const SizedBox(height: 12),
        fields[i].child,
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
