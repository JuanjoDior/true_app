import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/config/map_config.dart';
import '../../../../cases/application/cases_providers.dart';
import '../../../../cases/domain/true_crime_case.dart';
import 'case_dossier_content.dart';

/// Expediente del caso seleccionado dentro de la Sala de Situación.
///
/// El renderizado entero vive en [CaseDossierContent]; este panel es sólo el
/// host que lo ata al estado del mapa: resuelve los casos relacionados y
/// traduce las acciones del contenido en escrituras sobre los providers.
///
/// Separarlos es lo que permite que la página de detalle ampliada reutilice el
/// mismo renderizador con otro host [diseño D7]. El constructor no cambia, así
/// que ningún sitio que use el panel se entera de esta extracción.
class CaseDossierPanel extends ConsumerWidget {
  const CaseDossierPanel({super.key, required this.crimeCase});

  final TrueCrimeCase crimeCase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CaseDossierContent(
      crimeCase: crimeCase,
      related: ref.watch(relatedCasesProvider(crimeCase.id)),
      onBack: () => ref.read(selectedCaseIdProvider.notifier).state = null,
      onRelatedTap: (caseId) =>
          ref.read(selectedCaseIdProvider.notifier).state = caseId,
      onCenter: () => ref.read(mapRecenterTickProvider.notifier).state++,
    );
  }
}
