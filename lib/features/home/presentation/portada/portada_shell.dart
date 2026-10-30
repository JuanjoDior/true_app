import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/navigation/app_navigation_scope.dart';
import '../../../../core/design/design.dart';
import '../../../cases/application/cases_providers.dart';
import '../../../cases/domain/true_crime_case.dart';
import '../../../cases/presentation/case_directory.dart';
import 'portada_bottom_bar.dart';
import 'portada_catalog_status.dart';
import 'portada_footer.dart';
import 'portada_hero.dart';
import 'portada_map_invite.dart';
import 'portada_top_bar.dart';
import 'portada_unsolved_row.dart';

/// Portada: héroe con la barra superior encima, «Sin resolver», invitación al
/// mapa y pie, en un único desplazamiento. En anchos estrechos añade la barra
/// inferior fija.
class PortadaShell extends ConsumerStatefulWidget {
  const PortadaShell({super.key});

  static const double desktopHeroHeight = 740;
  static const double mobileHeroHeight = 640;

  @override
  ConsumerState<PortadaShell> createState() => _PortadaShellState();
}

class _PortadaShellState extends ConsumerState<PortadaShell> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (!_scroll.hasClients) return;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = DsMotion.resolve(DsMotion.fly, reduceMotion: reduceMotion);
    if (duration == Duration.zero) {
      _scroll.jumpTo(0);
    } else {
      _scroll.animateTo(0, duration: duration, curve: DsMotion.easeFly);
    }
  }

  void _openForm() =>
      ref.read(workspaceProvider.notifier).state = Workspace.intake;

  @override
  Widget build(BuildContext context) {
    final navigation = AppNavigationScope.maybeOf(context);
    final catalog = ref.watch(casesProvider);
    final featured = ref.watch(featuredCasesProvider);
    final unsolved = ref.watch(unsolvedCasesProvider);
    final narrow = MediaQuery.sizeOf(context).width < DsBreakpoints.desktop;

    // Es la lista del propio provider: la invitación al mapa y el héroe
    // reindexan marcadores al cambiar su identidad, así que no se copia.
    final cases = catalog.hasValue ? catalog.requireValue : null;

    // El explorador del mapa llega en F5: hasta entonces no se pasan sus
    // callbacks (búsqueda y enlaces al mapa), así que sus controles no se ven.
    void openCase(TrueCrimeCase crimeCase) =>
        navigation?.openCase(crimeCase.slug);
    final openArchive = navigation == null
        ? null
        : () => showCaseDirectory(context, navigation);

    return Scaffold(
      backgroundColor: DsColors.bgBase,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scroll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: narrow
                        ? PortadaShell.mobileHeroHeight
                        : PortadaShell.desktopHeroHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        PortadaHero(
                          featured: featured,
                          allCases: cases ?? const <TrueCrimeCase>[],
                          onOpenCase: openCase,
                        ),
                        if (cases == null || cases.isEmpty)
                          Center(
                            child: PortadaCatalogStatus(
                              catalog: catalog,
                              onRetry: () => ref.invalidate(casesProvider),
                            ),
                          ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: PortadaTopBar(
                            initialQuery: ref.read(searchQueryProvider),
                            onHome: _scrollToTop,
                            onOpenArchive: openArchive,
                            onOpenForm: _openForm,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (cases != null && cases.isNotEmpty) ...[
                    const SizedBox(height: DsSpacing.s24),
                    PortadaUnsolvedRow(cases: unsolved, onOpenCase: openCase),
                    PortadaMapInvite(cases: cases),
                  ],
                  const PortadaFooter(),
                  if (narrow)
                    SizedBox(height: PortadaBottomBar.heightOf(context)),
                ],
              ),
            ),
          ),
          if (narrow)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: PortadaBottomBar(
                onHome: _scrollToTop,
                onOpenArchive: openArchive,
                onOpenForm: _openForm,
              ),
            ),
        ],
      ),
    );
  }
}
