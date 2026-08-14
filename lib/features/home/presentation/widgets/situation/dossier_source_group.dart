import 'package:flutter/foundation.dart';

import '../../../../cases/domain/case_source.dart';

/// Un bloque de fuentes con su propio encabezado, aportado por el host.
///
/// Existe para que la previsualización de intake pueda enseñar los enlaces del
/// borrador agrupados por tipo usando el MISMO renderizador de fuentes que un
/// caso publicado, en vez de añadir una segunda lista debajo del expediente
/// [diseño §9.3].
@immutable
final class DossierSourceGroup {
  const DossierSourceGroup({required this.label, required this.sources});

  /// Encabezado del grupo, ya resuelto por el host. El contenido no reetiqueta
  /// nada: si un enlace sin tipo debe leerse "Sin clasificar" en vez de "Otro",
  /// esa decisión es de quien construye el grupo.
  final String label;

  final List<CaseSource> sources;
}
