import 'package:flutter/material.dart';

import '../../../cases/domain/true_crime_case.dart';
import 'case_featured_card.dart';

class FeaturedCaseRail extends StatelessWidget {
  const FeaturedCaseRail({
    super.key,
    required this.cases,
    required this.selectedCaseId,
    required this.onCaseTap,
  });

  final List<TrueCrimeCase> cases;
  final String? selectedCaseId;
  final ValueChanged<TrueCrimeCase> onCaseTap;

  @override
  Widget build(BuildContext context) {
    if (cases.isEmpty) {
      return const _EmptyFeaturedRail();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCompact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cartelera editorial',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${cases.length} seleccionados',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              )
            else
              Row(
                children: [
                  Text(
                    'Cartelera editorial',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Text(
                    '${cases.length} seleccionados',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            const SizedBox(height: 18),
            SizedBox(
              height: 300,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cases.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final crimeCase = cases[index];
                  return CaseFeaturedCard(
                    crimeCase: crimeCase,
                    isSelected: selectedCaseId == crimeCase.id,
                    onTap: () => onCaseTap(crimeCase),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyFeaturedRail extends StatelessWidget {
  const _EmptyFeaturedRail();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      key: const Key('featured-rail-empty-state'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Casos destacados', style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Este espacio mostrará la primera selección editorial cuando empecemos a cargar el catálogo.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 276,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return const _FeaturedPlaceholderCard();
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedPlaceholderCard extends StatelessWidget {
  const _FeaturedPlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1D24), Color(0xFF101217)],
        ),
        border: Border.all(color: const Color(0xFF2A2F3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _PlaceholderLine(width: 92, height: 28),
          Spacer(),
          _PlaceholderLine(width: 170, height: 22),
          SizedBox(height: 12),
          _PlaceholderLine(width: 130, height: 14),
          SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PlaceholderLine(width: 70, height: 26),
              _PlaceholderLine(width: 84, height: 26),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceholderLine extends StatelessWidget {
  const _PlaceholderLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
