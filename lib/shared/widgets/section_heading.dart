import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: textTheme.labelLarge?.copyWith(
            color: AppColors.gold,
            letterSpacing: 2.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(title, style: textTheme.displaySmall),
        const SizedBox(height: 10),
        Text(
          description,
          style: textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
