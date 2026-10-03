import 'package:flutter/material.dart';

import '../../../app/navigation/app_navigation.dart';
import '../../../core/design/design.dart';

/// Cascarón temporal de la página del mapa, a la espera de su contenido.
class MapPage extends StatelessWidget {
  const MapPage({super.key = const Key('map-page'), required this.navigation});

  final AppNavigation navigation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DsColors.bgBase,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DsMonoLabel('EL MAPA'),
              const SizedBox(height: DsSpacing.s24),
              DsButton(
                label: 'Volver a la portada',
                variant: DsButtonVariant.outline,
                onPressed: navigation.showSituationRoom,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
