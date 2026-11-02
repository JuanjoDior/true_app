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
import 'portada_categories.dart';
import 'portada_connections.dart';
import 'portada_decades.dart';
import 'portada_figures.dart';
import 'portada_footer.dart';
import 'portada_hero.dart';
import 'portada_top_bar.dart';
import 'portada_unsolved_row.dart';

/// Portada editorial en un único desplazamiento, con barra inferior en móvil.
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
    final connections = ref.watch(caseConnectionsProvider);
    final narrow = MediaQuery.sizeOf(context).width < DsBreakpoints.desktop;

    // El héroe reindexa marcadores al cambiar la identidad de la lista.
    // Se conserva la lista del provider sin copiarla.
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
                          connections: connections,
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
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: narrow ? DsSpacing.pageMarginMobile : DsSpacing.pageMarginDesktop,
                        vertical: DsSpacing.s24,
                      ),
                      child: PortadaFigures(cases: cases),
                    ),
                    PortadaUnsolvedRow(cases: unsolved, onOpenCase: openCase),
                    PortadaCategories(
                      cases: cases,
                      onSelectCategory: (category) {
                        if (navigation != null) {
                          showCaseDirectory(context, navigation, initialCategory: category);
                        }
                      },
                    ),
                    const SizedBox(height: DsSpacing.s80),
                    PortadaDecades(
                      cases: cases,
                      onSelectDecade: (decade) {
                        if (navigation != null) {
                          showCaseDirectory(context, navigation, initialDecade: decade);
                        }
                      },
                    ),
                    const SizedBox(height: DsSpacing.s80),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: narrow ? DsSpacing.pageMarginMobile : DsSpacing.pageMarginDesktop,
                      ),
                      child: PortadaConnections(
                        cases: cases,
                        connections: connections,
                        onOpenCase: openCase,
                      ),
                    ),
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
