import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_route_path.dart';

/// Traduce entre la URI del navegador y el estado de ruta [diseño §7.2].
///
/// Flutter web coloca estas rutas detrás del fragmento, así que `/casos/isdal`
/// se publica como `/#/casos/isdal`. Esa estrategia por hash es la que trae el
/// framework y aquí no se cambia: llamar a `usePathUrlStrategy` obligaría a
/// reescrituras en el servidor que el despliegue actual de Pages no tiene.
class AppRouteInformationParser extends RouteInformationParser<AppRoutePath> {
  static const _casesSegment = 'casos';

  @override
  Future<AppRoutePath> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    return SynchronousFuture(_parse(routeInformation.uri));
  }

  AppRoutePath _parse(Uri uri) {
    // `/casos/isdal/` trae un segmento final vacío; es la misma ruta, no otra.
    final segments = [
      for (final segment in uri.pathSegments)
        if (segment.isNotEmpty) segment,
    ];

    if (segments.isEmpty) {
      return const SituationRoomPath();
    }
    // Exactamente dos segmentos: `/casos/a/b` no abre el caso 'a'.
    if (segments.length == 2 && segments.first == _casesSegment) {
      return CaseDetailPath(segments[1]);
    }
    return UnknownAppPath(uri);
  }

  @override
  RouteInformation? restoreRouteInformation(AppRoutePath configuration) {
    return RouteInformation(uri: _restore(configuration));
  }

  Uri _restore(AppRoutePath configuration) {
    return switch (configuration) {
      SituationRoomPath() => Uri.parse('/'),
      // Se codifica el slug entero: sin eso, un slug con barra inventaría un
      // segmento y la ruta dejaría de reconocerse a sí misma.
      CaseDetailPath(:final slug) => Uri.parse(
        '/$_casesSegment/${Uri.encodeComponent(slug)}',
      ),
      UnknownAppPath(:final uri) => uri,
    };
  }
}
