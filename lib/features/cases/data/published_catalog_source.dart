import 'package:flutter/services.dart';

/// Lee el texto crudo del catálogo publicado, sin decodificarlo.
///
/// A diferencia de `LocalCasesRepository`, que decodifica y por tanto es
/// lossy (`design.md §4.1`), este lector sólo devuelve el `String` tal y
/// como está en el asset. La fusión por lotes necesita esos bytes intactos
/// para poder reconstruir el fichero sin perder nada que el modelo tipado no
/// pueda expresar.
class PublishedCatalogSource {
  PublishedCatalogSource({
    AssetBundle? bundle,
    this.assetPath = 'assets/data/cases.json',
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String assetPath;

  /// Texto crudo del catálogo, sin decodificar.
  Future<String> loadPayload() => _bundle.loadString(assetPath);
}
