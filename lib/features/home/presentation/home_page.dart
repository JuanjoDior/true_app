import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/map_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/section_heading.dart';
import '../../cases/application/cases_providers.dart';
import '../../cases/domain/case_category.dart';
import '../../cases/domain/true_crime_case.dart';
import '../../cases/presentation/case_category_presentation.dart';
import 'widgets/case_detail_panel.dart';
import 'widgets/case_type_filter_bar.dart';
import 'widgets/case_world_map.dart';
import 'widgets/featured_case_rail.dart';
import 'widgets/home_header.dart';

class TrueCrimeHomePage extends ConsumerStatefulWidget {
  const TrueCrimeHomePage({super.key});

  @override
  ConsumerState<TrueCrimeHomePage> createState() => _TrueCrimeHomePageState();
}

class _TrueCrimeHomePageState extends ConsumerState<TrueCrimeHomePage> {
  final ScrollController _scrollController = ScrollController();
  final MapController _mapController = MapController();
  final GlobalKey _mapSectionKey = GlobalKey();

  String? _hoveredCaseId;

  @override
  void dispose() {
    _scrollController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _scrollToKey(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) {
      return;
    }

    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  void _focusCase(TrueCrimeCase crimeCase, {bool scrollToMap = false}) {
    ref.read(selectedCaseIdProvider.notifier).state = crimeCase.id;
    final config = ref.read(mapConfigProvider);
    _mapController.move(crimeCase.location, config.focusZoom);

    if (scrollToMap) {
      _scrollToKey(_mapSectionKey);
    }
  }

  void _handleCategorySelected(CaseCategory? category) {
    ref.read(activeCategoryProvider.notifier).state = category;
    ref.read(selectedCaseIdProvider.notifier).state = null;

    final config = ref.read(mapConfigProvider);
    _mapController.move(config.initialCenter, config.initialZoom);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= 1180;
    final isMobile = size.width < 900;

    final casesAsync = ref.watch(casesProvider);
    final featuredAsync = ref.watch(featuredCasesProvider);
    final filteredCasesAsync = ref.watch(filteredCasesProvider);
    final selectedCaseAsync = ref.watch(selectedCaseProvider);
    final relevantAsync = ref.watch(relevantSuggestionsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final activeCategory = ref.watch(activeCategoryProvider);
    final categoryCounts = ref.watch(categoryCountsProvider);
    final emptyCatalog = ref.watch(emptyCatalogProvider);
    final mapConfig = ref.watch(mapConfigProvider);
    final mapGradient = ref.watch(mapSectionGradientProvider);

    ref.listen<AsyncValue<List<TrueCrimeCase>>>(filteredCasesProvider, (
      _,
      next,
    ) {
      next.whenData((results) {
        final selectedId = ref.read(selectedCaseIdProvider);
        if (selectedId != null &&
            !results.any((crimeCase) => crimeCase.id == selectedId)) {
          ref.read(selectedCaseIdProvider.notifier).state = null;
        }
      });
    });

    final suggestionCases = emptyCatalog
        ? const <TrueCrimeCase>[]
        : searchQuery.trim().isEmpty
        ? (relevantAsync.value ?? const <TrueCrimeCase>[])
        : (filteredCasesAsync.value ?? const <TrueCrimeCase>[])
              .take(6)
              .toList(growable: false);

    final selectedCase = selectedCaseAsync.value;
    final featuredCases = featuredAsync.value ?? const <TrueCrimeCase>[];
    final filteredCases = filteredCasesAsync.value ?? const <TrueCrimeCase>[];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF121317),
                    Color(0xFF090A0D),
                    Color(0xFF06070A),
                  ],
                ),
              ),
            ),
          ),
          _AmbientGlow(
            top: -200,
            right: -120,
            size: 520,
            color: AppColors.accent.withValues(alpha: 0.18),
          ),
          _AmbientGlow(
            top: 280,
            left: -140,
            size: 420,
            color: AppColors.gold.withValues(alpha: 0.08),
          ),
          SingleChildScrollView(
            controller: _scrollController,
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      isMobile ? 148 : 136,
                      20,
                      40,
                    ),
                    child: casesAsync.when(
                      loading: _buildLoadingState,
                      error: (error, _) => _buildErrorState(error),
                      data: (allCases) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(
                                  alpha: 0.86,
                                ),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SectionHeading(
                                    eyebrow: 'Destacados',
                                    title: 'Casos destacados en preparación',
                                    description:
                                        'Este espacio mostrará los casos editoriales destacados cuando empecemos a cargar el catálogo.',
                                  ),
                                  const SizedBox(height: 26),
                                  FeaturedCaseRail(
                                    cases: featuredCases,
                                    selectedCaseId: selectedCase?.id,
                                    onCaseTap: (crimeCase) => _focusCase(
                                      crimeCase,
                                      scrollToMap: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                            Container(
                              key: _mapSectionKey,
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                gradient: mapGradient,
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SectionHeading(
                                    eyebrow: 'Mapa',
                                    title:
                                        'Mapa mundial listo para recibir casos',
                                    description: _buildMapDescription(
                                      totalCases: allCases.length,
                                      searchQuery: searchQuery,
                                      activeCategory: activeCategory,
                                    ),
                                  ),
                                  const SizedBox(height: 26),
                                  CaseTypeFilterBar(
                                    counts: categoryCounts,
                                    activeCategory: activeCategory,
                                    onCategorySelected: _handleCategorySelected,
                                  ),
                                  const SizedBox(height: 24),
                                  if (isDesktop)
                                    _DesktopMapLayout(
                                      selectedCase: selectedCase,
                                      filteredCases: filteredCases,
                                      hoveredCaseId: _hoveredCaseId,
                                      mapController: _mapController,
                                      mapConfig: mapConfig,
                                      onCaseTap: _focusCase,
                                      onHoverChanged: (value) {
                                        setState(() {
                                          _hoveredCaseId = value;
                                        });
                                      },
                                      onBackgroundTap: () {
                                        ref
                                                .read(
                                                  selectedCaseIdProvider
                                                      .notifier,
                                                )
                                                .state =
                                            null;
                                      },
                                      metaPanel: _MapMetaPanel(
                                        totalVisible: filteredCases.length,
                                        totalCases: allCases.length,
                                        activeCategory: activeCategory,
                                        hasFilter: searchQuery.isNotEmpty,
                                      ),
                                      onClose: () {
                                        ref
                                                .read(
                                                  selectedCaseIdProvider
                                                      .notifier,
                                                )
                                                .state =
                                            null;
                                      },
                                    )
                                  else
                                    Stack(
                                      children: [
                                        SizedBox(
                                          height: 620,
                                          child: CaseWorldMap(
                                            mapController: _mapController,
                                            mapConfig: mapConfig,
                                            cases: filteredCases,
                                            selectedCaseId: selectedCase?.id,
                                            hoveredCaseId: _hoveredCaseId,
                                            onCaseTap: _focusCase,
                                            onHoverChanged: (value) {
                                              setState(() {
                                                _hoveredCaseId = value;
                                              });
                                            },
                                            onBackgroundTap: () {
                                              ref
                                                      .read(
                                                        selectedCaseIdProvider
                                                            .notifier,
                                                      )
                                                      .state =
                                                  null;
                                            },
                                          ),
                                        ),
                                        Positioned(
                                          top: 16,
                                          right: 16,
                                          child: _MapMetaPanel(
                                            totalVisible: filteredCases.length,
                                            totalCases: allCases.length,
                                            activeCategory: activeCategory,
                                            hasFilter: searchQuery.isNotEmpty,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeHeader(
              suggestions: suggestionCases,
              catalogIsEmpty: emptyCatalog,
              onMapTap: () => _scrollToKey(_mapSectionKey),
              onCaseSelected: (crimeCase) =>
                  _focusCase(crimeCase, scrollToMap: true),
            ),
          ),
          if (!isDesktop && selectedCase != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SizedBox(
                height: size.height * 0.46,
                child: CaseDetailPanel(
                  compact: true,
                  crimeCase: selectedCase,
                  onClose: () {
                    ref.read(selectedCaseIdProvider.notifier).state = null;
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _buildMapDescription({
    required int totalCases,
    required String searchQuery,
    required CaseCategory? activeCategory,
  }) {
    if (totalCases == 0) {
      return 'La navegación por tipo, color y ubicación ya está preparada para cuando publiquemos la primera selección de expedientes.';
    }

    if (searchQuery.isNotEmpty && activeCategory != null) {
      return 'Vista filtrada por "${activeCategory.presentation.label}" y búsqueda activa: "$searchQuery".';
    }

    if (searchQuery.isNotEmpty) {
      return 'Búsqueda activa: "$searchQuery". El mapa y la selección editorial se ajustan en tiempo real.';
    }

    if (activeCategory != null) {
      return 'Mostrando la categoría "${activeCategory.presentation.label}" en el mapa y en la navegación editorial.';
    }

    return 'Explora los casos publicados por ubicación y filtra por tipología editorial.';
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 420,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 44),
            const SizedBox(height: 16),
            const Text('No se pudieron cargar los casos.'),
            const SizedBox(height: 8),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(casesProvider),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopMapLayout extends StatelessWidget {
  const _DesktopMapLayout({
    required this.selectedCase,
    required this.filteredCases,
    required this.hoveredCaseId,
    required this.mapController,
    required this.mapConfig,
    required this.onCaseTap,
    required this.onHoverChanged,
    required this.onBackgroundTap,
    required this.metaPanel,
    required this.onClose,
  });

  final TrueCrimeCase? selectedCase;
  final List<TrueCrimeCase> filteredCases;
  final String? hoveredCaseId;
  final MapController mapController;
  final MapConfig mapConfig;
  final ValueChanged<TrueCrimeCase> onCaseTap;
  final ValueChanged<String?> onHoverChanged;
  final VoidCallback onBackgroundTap;
  final Widget metaPanel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    if (selectedCase == null) {
      return Stack(
        children: [
          SizedBox(
            height: 680,
            child: CaseWorldMap(
              mapController: mapController,
              mapConfig: mapConfig,
              cases: filteredCases,
              selectedCaseId: null,
              hoveredCaseId: hoveredCaseId,
              onCaseTap: onCaseTap,
              onHoverChanged: onHoverChanged,
              onBackgroundTap: onBackgroundTap,
            ),
          ),
          Positioned(top: 16, right: 16, child: metaPanel),
        ],
      );
    }

    return SizedBox(
      height: 680,
      child: Row(
        children: [
          Expanded(
            flex: 7,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CaseWorldMap(
                    mapController: mapController,
                    mapConfig: mapConfig,
                    cases: filteredCases,
                    selectedCaseId: selectedCase?.id,
                    hoveredCaseId: hoveredCaseId,
                    onCaseTap: onCaseTap,
                    onHoverChanged: onHoverChanged,
                    onBackgroundTap: onBackgroundTap,
                  ),
                ),
                Positioned(top: 16, right: 16, child: metaPanel),
              ],
            ),
          ),
          const SizedBox(width: 22),
          SizedBox(
            width: 360,
            child: CaseDetailPanel(crimeCase: selectedCase!, onClose: onClose),
          ),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    this.top,
    this.left,
    this.right,
    required this.size,
    required this.color,
  });

  final double? top;
  final double? left;
  final double? right;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapMetaPanel extends StatelessWidget {
  const _MapMetaPanel({
    required this.totalVisible,
    required this.totalCases,
    required this.activeCategory,
    required this.hasFilter,
  });

  final int totalVisible;
  final int totalCases;
  final CaseCategory? activeCategory;
  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    final status = switch ((totalCases == 0, activeCategory, hasFilter)) {
      (true, _, _) => 'Catálogo en preparación',
      (false, CaseCategory category, _) => category.presentation.shortLabel,
      (false, null, true) => 'Filtro activo',
      _ => 'Vista global',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 6),
          Text(
            '$totalVisible marcadores visibles',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
