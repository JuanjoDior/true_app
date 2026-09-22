import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/data/published_catalog_source.dart';

/// `PublishedCatalogSource` lee el texto crudo del catálogo publicado, sin
/// decodificarlo — a diferencia de `LocalCasesRepository`, que sí decodifica
/// [design.md §4, §9].

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this.payload);

  final String payload;

  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(utf8.encode(payload));
    return ByteData.view(bytes.buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => payload;
}

void main() {
  group('loadPayload', () {
    test('returns the raw asset text untouched', () async {
      const payload = '[{"slug":"el-caso","title":"El caso"}]';
      final source = PublishedCatalogSource(bundle: _FakeAssetBundle(payload));

      final result = await source.loadPayload();

      expect(result, payload);
    });

    test('does not decode the payload into a Dart structure', () async {
      // Si `loadPayload` decodificara, este texto con una coma colgante
      // lanzaría al construir el `PublishedCatalogSource`... pero
      // `loadPayload` sólo lee texto: debe devolverlo tal cual, inválido y
      // todo, y dejar la decodificación a `decodeCatalogPayload`.
      const malformedPayload = '[{"slug":"el-caso",}]';
      final source = PublishedCatalogSource(
        bundle: _FakeAssetBundle(malformedPayload),
      );

      final result = await source.loadPayload();

      expect(result, malformedPayload);
    });
  });
}
