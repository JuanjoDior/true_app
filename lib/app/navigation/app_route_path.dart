import 'package:flutter/foundation.dart';

/// Estado de ruta de la aplicación [diseño §7.1].
///
/// Sellada a propósito: las cuatro son todas las rutas que existen, y el
/// compilador obliga a tratarlas todas en cada `switch`. Una ruta nueva no
/// puede colarse sin que salte cada sitio que decide qué pintar.
@immutable
sealed class AppRoutePath {
  const AppRoutePath();
}

/// La raíz. Qué se ve debajo — mapa o intake — lo decide `workspaceProvider`,
/// no la ruta.
final class SituationRoomPath extends AppRoutePath {
  const SituationRoomPath();

  @override
  bool operator ==(Object other) => other is SituationRoomPath;

  @override
  int get hashCode => (SituationRoomPath).hashCode;
}

/// El mapa a pantalla completa, apilado sobre la raíz como el detalle.
final class MapPath extends AppRoutePath {
  const MapPath();

  @override
  bool operator ==(Object other) => other is MapPath;

  @override
  int get hashCode => (MapPath).hashCode;
}

/// El expediente ampliado de un caso, identificado por su slug público.
final class CaseDetailPath extends AppRoutePath {
  const CaseDetailPath(this.slug);

  final String slug;

  // La igualdad por valor no es cosmética: el controlador compara rutas para
  // no duplicar entradas de historial, y sin ella el botón Atrás se atasca.
  @override
  bool operator ==(Object other) =>
      other is CaseDetailPath && other.slug == slug;

  @override
  int get hashCode => Object.hash(CaseDetailPath, slug);
}

/// Una URI que la aplicación no reconoce.
///
/// Se guarda entera para poder devolverla intacta: la barra de direcciones no
/// debe cambiar sola bajo los pies de quien la escribió.
final class UnknownAppPath extends AppRoutePath {
  const UnknownAppPath(this.uri);

  final Uri uri;

  @override
  bool operator ==(Object other) => other is UnknownAppPath && other.uri == uri;

  @override
  int get hashCode => Object.hash(UnknownAppPath, uri);
}
