import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/navigation/app_navigation.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/presentation/widgets/situation/situation_styles.dart';
import '../application/cases_providers.dart';
import '../domain/true_crime_case.dart';
import '../domain/case_category.dart';
import 'case_category_presentation.dart';

/// Abre el directorio del archivo sobre lo que haya en pantalla.
///
/// Es una capa superpuesta y no una ruta: entrar y salir del índice no debería
/// dejar rastro en el historial del navegador ni cambiar la dirección. Lo que
/// sí cambia la ruta es abrir un caso desde él.
/// [initialDecade] es el primer año de una década; ambos filtros, si se
/// proporcionan, se aplican juntos y solo afectan a esta hoja.
Future<void> showCaseDirectory(
  BuildContext context,
  AppNavigation navigation, {
  CaseCategory? initialCategory,
  int? initialDecade,
}) {
  final isCompact = MediaQuery.sizeOf(context).width < Breakpoints.sidePanel;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      final content = _CaseDirectory(
        category: initialCategory,
        decade: initialDecade,
        onOpenCase: (slug) {
          // Se cierra primero: dejar el índice abierto detrás de la ficha haría
          // que volver del caso aterrizara en una hoja que ya no viene a cuento.
          Navigator.of(sheetContext).pop();
          navigation.openCase(slug);
        },
        onClose: () => Navigator.of(sheetContext).pop(),
      );

      // En móvil ocupa el ancho entero y respeta el área segura de abajo; en
      // pantalla ancha se acota, porque una lista de 1300px de ancho se escanea
      // pero no se lee.
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 0 : 24,
            vertical: isCompact ? 0 : 32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isCompact ? double.infinity : 720,
                maxHeight: MediaQuery.sizeOf(context).height * 0.85,
              ),
              child: content,
            ),
          ),
        ),
      );
    },
  );
}

class _CaseDirectory extends ConsumerWidget {
  const _CaseDirectory({
    required this.onOpenCase,
    required this.onClose,
    this.category,
    this.decade,
  });

  final CaseCategory? category;
  final int? decade;
  final ValueChanged<String> onOpenCase;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directory = ref.watch(publishedDirectoryProvider);

    return Container(
      key: const Key('case-directory'),
      decoration: BoxDecoration(
        color: AppColors.bar,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.panelMuted),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DirectoryHeader(onClose: onClose),
          if (category != null || decade != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category != null) Text(category!.presentation.label),
                  if (decade != null) Text('Década de $decade'),
                ],
              ),
            ),
          Flexible(
            child: directory.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
              // Archivo vacío y archivo ilegible son cosas distintas y se dicen
              // distinto, igual que en la ficha de un caso.
              error: (_, _) => const _DirectoryMessage(
                messageKey: Key('case-directory-error'),
                text: 'No se pudo leer el archivo. Inténtalo en un momento.',
              ),
              data: (cases) {
                if (cases.isEmpty) {
                  return const _DirectoryMessage(
                    messageKey: Key('case-directory-empty'),
                    text: 'Todavía no hay expedientes publicados.',
                  );
                }
                final visible = cases.where((crimeCase) =>
                    (category == null || crimeCase.category == category) &&
                    (decade == null ||
                        (crimeCase.year >= decade! && crimeCase.year < decade! + 10)))
                    .toList(growable: false);
                if (visible.isEmpty) {
                  return const _DirectoryMessage(
                    messageKey: Key('case-directory-filter-empty'),
                    text: 'No hay expedientes para este filtro.',
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: visible.length,
                  itemBuilder: (context, index) => _DirectoryRow(
                    crimeCase: visible[index],
                    onTap: () => onOpenCase(visible[index].slug),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectoryHeader extends StatelessWidget {
  const _DirectoryHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'El archivo',
              style: SituationStyles.serif(size: 20, height: 1.1),
            ),
          ),
          IconButton(
            key: const Key('case-directory-close'),
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.textSoft,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _DirectoryRow extends StatelessWidget {
  const _DirectoryRow({required this.crimeCase, required this.onTap});

  final TrueCrimeCase crimeCase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('case-directory-row-${crimeCase.slug}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: crimeCase.category.presentation.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crimeCase.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SituationStyles.sans(
                      size: 13,
                      weight: FontWeight.w600,
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    crimeCase.locationLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SituationStyles.mono(
                      size: 10,
                      color: AppColors.textFaint2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${crimeCase.year}',
              style: SituationStyles.mono(
                size: 11,
                weight: FontWeight.w600,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectoryMessage extends StatelessWidget {
  const _DirectoryMessage({required this.messageKey, required this.text});

  final Key messageKey;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: messageKey,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Text(
        text,
        style: SituationStyles.sans(
          size: 13,
          color: AppColors.textMuted,
          height: 1.5,
        ),
      ),
    );
  }
}
