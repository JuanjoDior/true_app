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
