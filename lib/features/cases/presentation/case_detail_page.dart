import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/navigation/app_navigation.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/presentation/widgets/situation/case_dossier_content.dart';
import '../../home/presentation/widgets/situation/situation_styles.dart';
import '../application/cases_providers.dart';
import '../domain/true_crime_case.dart';

/// Página pública de un expediente, la que vive en su propia URL
/// [spec: expanded-case-dossier].
///
/// **Cuatro estados y ninguno se confunde con otro**: cargando, catálogo
/// caído, slug desconocido y caso encontrado. Que los dos del medio se vieran
/// igual sería el peor fallo posible aquí — quien comparte un enlace pensaría
/// que le hemos borrado el caso cuando lo único que pasó es que el archivo no
/// se pudo leer [diseño D10].
///
/// El expediente en sí lo pinta [CaseDossierContent], el mismo renderizador que
/// el panel compacto. Esta página no reimplementa ningún bloque editorial: pone
/// la caja, el ancho de lectura y las acciones propias de estar en una URL.
class CaseDetailPage extends ConsumerWidget {
  const CaseDetailPage({
    super.key,
    required this.slug,
    required this.navigation,
  });

  final String slug;

  /// Se inyecta el contrato, no el controlador: la página puede pedir ir a un
  /// sitio, no husmear en qué ruta está.
  final AppNavigation navigation;

  /// Ancho de lectura. Una columna de prosa a 1600px no se lee, se escanea.
  static const _readingWidth = 760.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crimeCase = ref.watch(caseBySlugProvider(slug));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fuera del scroll a propósito: volver no puede irse pantalla
            // abajo con el contenido en un expediente largo.
            _ReturnBar(onReturn: navigation.showSituationRoom),
            Expanded(
              child: crimeCase.when(
                loading: () =>
                    const _Centered(child: CircularProgressIndicator()),
                error: (_, _) => const _Message(
                  messageKey: Key('case-detail-error'),
                  title: 'No se pudo leer el archivo',
                  body:
                      'El expediente puede seguir ahí. Vuelve a intentarlo en '
                      'un momento.',
                ),
                data: (found) => found == null
                    ? const _Message(
                        messageKey: Key('case-detail-not-found'),
                        title: 'Ese expediente no existe',
                        body:
                            'La dirección no corresponde a ningún caso '
                            'publicado.',
                      )
                    : _Dossier(crimeCase: found, navigation: navigation),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El expediente encontrado, dentro de su propio scroll y ancho de lectura.
class _Dossier extends ConsumerWidget {
  const _Dossier({required this.crimeCase, required this.navigation});

  final TrueCrimeCase crimeCase;
  final AppNavigation navigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: CaseDetailPage._readingWidth,
          ),
          child: CaseDossierContent(
            crimeCase: crimeCase,
            relatedCases: ref.watch(relatedCasesProvider(crimeCase.id)),
            // Sin mapa detrás: el cromo de mapa no tiene sentido en una URL
            // pública, y volver ya lo ofrece la barra de arriba.
            mode: CaseDossierMode.preview,
            presentation: DossierPresentation.expanded,
            // Se navega por SLUG, no por id: es la dirección pública del caso.
            onOpenRelatedCase: (related) => navigation.openCase(related.slug),
          ),
        ),
      ),
    );
  }
}

class _ReturnBar extends StatelessWidget {
  const _ReturnBar({required this.onReturn});

  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: const Key('case-detail-return'),
          onPressed: onReturn,
          icon: const Icon(Icons.arrow_back, size: 14),
          label: Text(
            'Volver al archivo',
            style: SituationStyles.mono(
              size: 10,
              weight: FontWeight.w600,
              color: AppColors.textSoft,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.messageKey,
    required this.title,
    required this.body,
  });

  final Key messageKey;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _Centered(
      child: Padding(
        key: messageKey,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: SituationStyles.serif(size: 22, height: 1.15),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: SituationStyles.sans(
                size: 13,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(child: child);
}
