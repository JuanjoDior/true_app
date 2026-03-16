import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/map_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/section_heading.dart';
import '../../cases/application/cases_providers.dart';
import '../../cases/domain/true_crime_case.dart';
import 'widgets/case_detail_panel.dart';
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
  final GlobalKey _featuredSectionKey = GlobalKey();
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= 1180;
    final isMobile = size.width < 900;

    final casesAsync = ref.watch(casesProvider);
    final featuredAsync = ref.watch(featuredCasesProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final selectedCaseAsync = ref.watch(selectedCaseProvider);
    final relevantAsync = ref.watch(relevantSuggestionsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final mapConfig = ref.watch(mapConfigProvider);
    final mapGradient = ref.watch(mapSectionGradientProvider);

    ref.listen<AsyncValue<List<TrueCrimeCase>>>(searchResultsProvider, (
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

    final suggestionCases = searchQuery.trim().isEmpty
        ? (relevantAsync.value ?? const <TrueCrimeCase>[])
        : (searchResultsAsync.value ?? const <TrueCrimeCase>[])
              .take(6)
              .toList(growable: false);

    final selectedCase = selectedCaseAsync.value;
    final featuredCases = featuredAsync.value ?? const <TrueCrimeCase>[];
    final filteredCases = searchResultsAsync.value ?? const <TrueCrimeCase>[];

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
                            _HeroIntro(totalCases: allCases.length),
                            const SizedBox(height: 42),
                            Container(
                              key: _featuredSectionKey,
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
                                    eyebrow: 'Cartelera',
                                    title: 'Casos que marcan el mapa editorial',
                                    description:
                                        'Una selección manual de expedientes, desapariciones y homicidios que definieron épocas, territorios o coberturas mediáticas.',
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
                            const SizedBox(height: 34),
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
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: SectionHeading(
                                          eyebrow: 'Mapa',
                                          title:
                                              'Explora los puntos calientes del true crime',
                                          description: searchQuery.isEmpty
                                              ? 'El mapa reúne una primera capa de casos reales curados, con acceso rápido a contexto, investigaciones y escucha relacionada.'
                                              : 'Búsqueda activa: "$searchQuery". Los marcadores y resultados se filtran en tiempo real por nombre, lugar o tags.',
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      if (!isMobile)
                                        _MapMetaPanel(
                                          totalVisible: filteredCases.length,
                                          hasFilter: searchQuery.isNotEmpty,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  if (isDesktop)
                                    SizedBox(
                                      height: 680,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 7,
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
                                          const SizedBox(width: 22),
                                          SizedBox(
                                            width: 360,
                                            child: selectedCase == null
                                                ? const _EmptyCasePanel()
                                                : CaseDetailPanel(
                                                    crimeCase: selectedCase,
                                                    onClose: () {
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
                                        ],
                                      ),
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
              onCarteleraTap: () => _scrollToKey(_featuredSectionKey),
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

class _HeroIntro extends StatelessWidget {
  const _HeroIntro({required this.totalCases});

  final int totalCases;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRUE APP',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.gold,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Una biblioteca cartografiada del crimen real.',
            style: theme.textTheme.displayMedium,
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Text(
              'Una experiencia web centrada en descubrir casos históricos y contemporáneos desde el mapa, con cartelera editorial, búsqueda contextual y fuentes visibles para seguir cada investigación.',
              style: theme.textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatChip(label: '$totalCases casos curados'),
              const _StatChip(label: 'Fuentes visibles'),
              const _StatChip(label: 'Podcasts enlazados'),
              const _StatChip(label: 'Escalable a CMS'),
            ],
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

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.panelMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _MapMetaPanel extends StatelessWidget {
  const _MapMetaPanel({required this.totalVisible, required this.hasFilter});

  final int totalVisible;
  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
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
            hasFilter ? 'Filtro activo' : 'Vista global',
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

class _EmptyCasePanel extends StatelessWidget {
  const _EmptyCasePanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.public_rounded, color: AppColors.gold),
          ),
          const SizedBox(height: 18),
          Text('Selecciona un caso', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(
            'Pulsa un marcador del mapa o una tarjeta de la cartelera para abrir la ficha editorial con contexto, fuentes y enlaces de escucha.',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
