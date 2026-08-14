import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// La frontera entre ruta y estado de la aplicación [diseño §7.3, §7.4].
///
/// **Estos tests leen el código fuente, y es a propósito.** La regla que hay
/// que sostener es una AUSENCIA: el router no escribe `workspaceProvider` ni
/// toca la selección del mapa. Una ausencia no se demuestra ejercitando el
/// router y comprobando que no pasó nada — eso pasaría igual si el camino que
/// escribe simplemente no se recorrió en ese test. Se demuestra probando que
/// el código no puede llegar a esos símbolos.
///
/// El motivo de la regla, resumido del diseño: `workspaceProvider` ya tiene un
/// dueño (`situation_nav_rail.dart`, que lo pone en intake sin cambiar de
/// ruta). Un router que lo reescriba en cada ruta raíz crea un segundo dueño, y
/// dos dueños acaban discrepando sobre qué enseña `/`. Además, escribirlo desde
/// `setNewRoutePath` o desde el `build` del delegate es exactamente el momento
/// que Riverpod rechaza.

const _navigationDir = 'lib/app/navigation';

/// Símbolos que el paquete de navegación no puede nombrar.
const _forbidden = <String>[
  'workspaceProvider',
  'selectedCaseIdProvider',
  'Workspace.',
  'cases_providers.dart',
  'flutter_riverpod',
];

List<File> _navigationFiles() {
  final dir = Directory(_navigationDir);
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList(growable: false);
}

/// El código del fichero, sin comentarios.
///
/// La regla prohíbe alcanzar esos símbolos, no nombrarlos. Explicar en un
/// comentario por qué el router no escribe `workspaceProvider` es exactamente
/// lo que debe hacer el fichero; buscar en el texto crudo convertiría esa
/// documentación en una infracción.
String _codeOf(File file) {
  return file
      .readAsLinesSync()
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');
}

List<String> _mentioning(String symbol) => [
  for (final file in _navigationFiles())
    if (_codeOf(file).contains(symbol)) file.path,
];

void main() {
  test('the navigation package exists and has files to check', () {
    // Sin esto, todo lo de abajo pasaría en verde con el directorio vacío.
    expect(_navigationFiles(), isNotEmpty);
  });

  test('the comment filter does not swallow real code', () {
    // Sin esto, un filtro roto que devolviera cadena vacía dejaría en verde
    // todas las prohibiciones de abajo sin comprobar nada.
    expect(_mentioning('AppRoutePath'), isNotEmpty);
  });

  for (final symbol in _forbidden) {
    test('no navigation file reaches for $symbol', () {
      expect(_mentioning(symbol), isEmpty);
    });
  }

  test('no navigation file reaches for dart:html', () {
    // El diseño fija la estrategia de URL por hash que trae Flutter. Salirse
    // de ella cambiaría las URLs publicadas y obligaría a reescrituras en el
    // servidor que el despliegue actual no tiene.
    expect(_mentioning('dart:html'), isEmpty);
  });

  test('no navigation file changes the url strategy', () {
    expect(_mentioning('usePathUrlStrategy'), isEmpty);
  });

  // La Unit 6 entregó esto dormido y afirmaba aquí que `TrueCrimeApp` seguía
  // en `MaterialApp.home`. La Unit 7 lo activa, así que esas dos afirmaciones
  // se invierten: dejarlas como estaban habría obligado a borrarlas, y una
  // afirmación borrada no protege nada.
  test('the app root is routed', () {
    final source = File('lib/app/true_crime_app.dart').readAsStringSync();

    expect(source.contains('MaterialApp.router'), isTrue);
  });

  test('the app root no longer uses MaterialApp.home', () {
    // Gemelo del anterior: sin él, un fichero que usara las dos formas a la
    // vez pasaría igual.
    final source = File('lib/app/true_crime_app.dart').readAsStringSync();

    expect(source.contains('home: const'), isFalse);
  });

  test('the app root creates its router once, outside build', () {
    // `StatelessWidget` recrearía controlador y delegate en cada
    // reconstrucción, perdiendo la ruta y dejando al motor hablando con un
    // objeto muerto. El diseño lo exige explícitamente.
    final source = File('lib/app/true_crime_app.dart').readAsStringSync();

    expect(source.contains('extends StatefulWidget'), isTrue);
  });
}
