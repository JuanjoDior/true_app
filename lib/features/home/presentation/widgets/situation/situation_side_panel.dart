import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../cases/application/cases_providers.dart';
import 'case_dossier_panel.dart';
import 'featured_focus_panel.dart';

/// Panel lateral derecho: alterna entre el caso destacado y el expediente del
/// caso seleccionado, igual que el diseño.
class SituationSidePanel extends ConsumerWidget {
  const SituationSidePanel({super.key, this.width = 362});

  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCaseProvider).value;

    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.bar,
        border: Border(left: BorderSide(color: AppColors.panelMuted)),
      ),
      clipBehavior: Clip.hardEdge,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: selected == null
            ? const FeaturedFocusPanel(key: ValueKey('focus'))
            : CaseDossierPanel(
                key: ValueKey('dossier-${selected.id}'),
                crimeCase: selected,
              ),
      ),
    );
  }
}
