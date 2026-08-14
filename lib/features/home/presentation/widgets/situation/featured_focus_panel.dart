import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../cases/application/cases_providers.dart';
import '../../../../cases/domain/true_crime_case.dart';
import '../../../../cases/presentation/case_category_presentation.dart';
import '../../../../cases/presentation/case_status_presentation.dart';
import 'situation_styles.dart';

/// Panel "En el foco": destaca un caso abierto cada semana.
class FeaturedFocusPanel extends ConsumerWidget {
  const FeaturedFocusPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(featuredCaseProvider);

    if (featured == null) {
      return const _EmptyFocus();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SituationDot(
                      color: AppColors.gold,
                      size: 6,
                      glow: false,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'EN EL FOCO',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SituationStyles.mono(
                          size: 10,
                          weight: FontWeight.w600,
                          color: AppColors.gold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'ROTA CADA SEMANA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: SituationStyles.mono(
                    size: 9,
                    color: AppColors.textFaint2,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MiniMap(crimeCase: featured),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SituationBadge(
                label: featured.category.presentation.label,
                color: featured.category.presentation.color,
              ),
              SituationBadge(
                label: featured.statusLabel ?? featured.status.label,
                color: featured.status.color,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            featured.title,
            style: SituationStyles.serif(size: 30, height: 1.05),
          ),
          const SizedBox(height: 6),
          Text(
            '${featured.locationLabel} · ${featured.year}',
            style: SituationStyles.mono(size: 11, color: AppColors.textSub),
          ),
          const SizedBox(height: 16),
          Text(
            featured.summary,
            style: SituationStyles.sans(
              size: 13.5,
              color: AppColors.textMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(color: AppColors.panelMuted, height: 1),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              style: SituationStyles.sans(
                size: 12,
                color: AppColors.textSoft,
                height: 1.6,
              ),
              children: const [
                TextSpan(text: 'Cada ficha incluye '),
                TextSpan(
                  text: 'cronología verificada',
                  style: TextStyle(color: AppColors.textSub2),
                ),
                TextSpan(text: ' y '),
                TextSpan(
                  text: 'fuentes citadas',
                  style: TextStyle(color: AppColors.textSub2),
                ),
                TextSpan(text: '. Las víctimas se nombran con respeto.'),
              ],
            ),
          ),
          const Spacer(),
          _OpenDossierButton(
            onTap: () =>
                ref.read(selectedCaseIdProvider.notifier).state = featured.id,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Selecciona cualquier punto del mapa para investigar',
              style: SituationStyles.sans(
                size: 11,
                color: AppColors.textFaint2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.crimeCase});

  final TrueCrimeCase crimeCase;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.panelMuted),
        gradient: const RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.2,
          colors: [Color(0xFF0E141A), Color(0xFF080A0D)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Center(
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: crimeCase.status.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: crimeCase.status.color.withValues(alpha: 0.7),
                    blurRadius: 16,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 10,
            child: Text(
              crimeCase.coordsLabel,
              style: SituationStyles.mono(size: 9, color: AppColors.textFaint2),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.statusOpen.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    const step = 22.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OpenDossierButton extends StatelessWidget {
  const _OpenDossierButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(
            'Abrir expediente',
            style: SituationStyles.sans(
              size: 13,
              weight: FontWeight.w600,
              color: const Color(0xFF0B0C10),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyFocus extends StatelessWidget {
  const _EmptyFocus();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'EN EL FOCO',
            style: SituationStyles.mono(
              size: 10,
              weight: FontWeight.w600,
              color: AppColors.gold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'El archivo aún no tiene un caso destacado.',
            style: SituationStyles.serif(size: 22, height: 1.1),
          ),
          const SizedBox(height: 10),
          Text(
            'En cuanto se publiquen expedientes, aquí rotará un caso abierto cada semana.',
            style: SituationStyles.sans(
              size: 13,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
