import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../cases/application/cases_providers.dart';
import 'widgets/situation/case_dossier_panel.dart';
import 'widgets/situation/situation_map_stage.dart';
import 'widgets/situation/situation_nav_rail.dart';
import 'widgets/situation/situation_side_panel.dart';
import 'widgets/situation/situation_top_bar.dart';
import 'widgets/situation/updates_ticker.dart';

/// Sala de Situación: shell a pantalla completa con cabecera, ticker, rail,
/// mapa central y panel lateral de expediente/destacado.
class TrueCrimeHomePage extends ConsumerWidget {
  const TrueCrimeHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final showRail = width >= 1100;
    final showSidePanel = width >= 880;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Column(
        children: [
          SituationTopBar(compact: width < 980),
          const UpdatesTicker(),
          Expanded(
            child: showSidePanel
                ? _DesktopBody(showRail: showRail)
                : const _MobileBody(),
          ),
        ],
      ),
    );
  }
}

class _DesktopBody extends StatelessWidget {
  const _DesktopBody({required this.showRail});

  final bool showRail;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final panelWidth = width < 1024 ? 320.0 : 362.0;

    return Row(
      children: [
        if (showRail) const SituationNavRail(),
        const Expanded(child: SituationMapStage()),
        SituationSidePanel(width: panelWidth),
      ],
    );
  }
}

/// En pantallas estrechas: mapa a pantalla completa y, al seleccionar un caso,
/// el expediente aparece como hoja inferior.
class _MobileBody extends ConsumerWidget {
  const _MobileBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCaseProvider).value;
    final height = MediaQuery.sizeOf(context).height;

    return Stack(
      children: [
        const Positioned.fill(child: SituationMapStage()),
        if (selected != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              key: const Key('mobile-case-sheet'),
              height: height * 0.6,
              decoration: BoxDecoration(
                color: AppColors.bar,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.panelMuted),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: CaseDossierPanel(crimeCase: selected),
            ),
          ),
      ],
    );
  }
}
