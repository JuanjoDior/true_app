import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/config/map_config.dart';
import '../../../../cases/application/cases_providers.dart';
import '../../../../cases/domain/true_crime_case.dart';
import 'case_dossier_content.dart';
import 'dossier_source_group.dart';

/// Expediente compacto: el host que ata [CaseDossierContent] al estado del
/// mapa de la Sala de Situación.
///
/// El renderizado entero vive en el contenido; aquí sólo se resuelven los casos
/// relacionados y se traducen sus acciones en escrituras sobre los providers.
/// Separarlos es lo que permite que la página de detalle ampliada reutilice el
/// mismo renderizador con otro host [diseño D7].
///
/// **Todos los parámetros más allá del caso son opcionales, y omitirlos deja el
/// comportamiento de hoy intacto** [diseño D12]. No es cosmética: si `mode` o
/// `relatedCases` fuesen obligatorios, los seis call sites tendrían que cambiar
/// en la misma edición que los introduce y no quedaría ningún estado intermedio
/// que compile. Eso es lo que permite entregar la extracción por partes.
class CaseDossierPanel extends ConsumerWidget {
  const CaseDossierPanel({
    super.key,
    required this.crimeCase,
    this.mode = CaseDossierMode.map,
    this.relatedCases,
    this.onReturnToMap,
    this.onCenterMap,
    this.onOpenRelatedCase,
    this.sourceGroups,
  });

  final TrueCrimeCase crimeCase;

  /// Por defecto el preajuste de mapa, así los call sites existentes compilan
  /// sin tocarlos y se siguen viendo igual.
  final CaseDossierMode mode;

  /// `null` significa "derívalos tú", que es lo que el panel ha hecho siempre.
  /// Sólo lo pasan los hosts que ya tienen la lista en la mano.
  final List<RelatedCase>? relatedCases;

  /// Si el host no dice otra cosa, estas acciones hacen lo de siempre: limpiar
  /// la selección, recentrar el mapa y seleccionar el caso relacionado.
  final VoidCallback? onReturnToMap;
  final VoidCallback? onCenterMap;
  final ValueChanged<TrueCrimeCase>? onOpenRelatedCase;

  final List<DossierSourceGroup>? sourceGroups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CaseDossierContent(
      crimeCase: crimeCase,
      relatedCases:
          relatedCases ?? ref.watch(relatedCasesProvider(crimeCase.id)),
      mode: mode,
      onReturnToMap:
          onReturnToMap ??
          () => ref.read(selectedCaseIdProvider.notifier).state = null,
      onCenterMap:
          onCenterMap ??
          () => ref.read(mapRecenterTickProvider.notifier).state++,
      onOpenRelatedCase:
          onOpenRelatedCase ??
          (related) =>
              ref.read(selectedCaseIdProvider.notifier).state = related.id,
      sourceGroups: sourceGroups,
    );
  }
}
