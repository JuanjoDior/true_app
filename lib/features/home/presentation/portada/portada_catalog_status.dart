import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/design.dart';
import '../../../cases/domain/true_crime_case.dart';
import 'portada_closing_keys.dart';

/// Estado del catálogo en la portada: carga, error con reintento y archivo vacío.
///
/// Con casos disponibles no pinta nada. Un error se mantiene mientras se
/// reintenta, para que el aviso no parpadee; el reintento en sí lo hace quien
/// recibe `onRetry` (hoy, invalidar `casesProvider`).
class PortadaCatalogStatus extends StatelessWidget {
  const PortadaCatalogStatus({
    super.key,
    required this.catalog,
    required this.onRetry,
  });

  final AsyncValue<List<TrueCrimeCase>> catalog;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (catalog.hasValue) {
      if (catalog.requireValue.isNotEmpty) return const SizedBox.shrink();
      return const DsStateMessage.empty(
        key: PortadaClosingKeys.statusEmpty,
        title: 'Todavía no hay expedientes publicados.',
      );
    }
    if (catalog.hasError) {
      final retrying = catalog.isLoading;
      // DsStateMessage solo dibuja el botón con callback: durante el reintento
      // sigue visible («Reintentando…») pero no dispara otro.
      return DsStateMessage.error(
        key: PortadaClosingKeys.statusError,
        message: 'No se pudieron cargar los casos.',
        actionLabel: retrying ? 'Reintentando…' : 'Reintentar',
        onAction: () {
          if (!retrying) onRetry();
        },
      );
    }
    return const DsStateMessage(
      key: PortadaClosingKeys.statusLoading,
      icon: Icons.hourglass_top_rounded,
      tone: DsColors.textFaint,
      message: 'Cargando el archivo…',
    );
  }
}
