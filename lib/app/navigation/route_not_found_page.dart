import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../features/home/presentation/widgets/situation/situation_styles.dart';
import 'app_navigation.dart';

/// Una dirección que la aplicación no reconoce.
///
/// **No es lo mismo que "ese caso no existe"**, y por eso es una página aparte
/// con su propia clave: `/ajustes` es sintaxis que no entendemos, mientras que
/// `/casos/no-existe` es una dirección válida a un caso que no está publicado.
/// Confundirlas dejaría a quien escribe mal una URL creyendo que le borramos un
/// caso [diseño §7.3].
///
/// La URI original se enseña tal cual y no se sustituye por nada: la barra de
/// direcciones no debe cambiar sola bajo los pies de quien la escribió.
class RouteNotFoundPage extends StatelessWidget {
  const RouteNotFoundPage({
    super.key,
    required this.uri,
    required this.navigation,
  });

  final Uri uri;
  final AppNavigation navigation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            key: const Key('route-not-found'),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Esta dirección no lleva a ningún sitio',
                  textAlign: TextAlign.center,
                  style: SituationStyles.serif(size: 22, height: 1.15),
                ),
                const SizedBox(height: 10),
                Text(
                  uri.toString(),
                  textAlign: TextAlign.center,
                  style: SituationStyles.mono(
                    size: 11,
                    color: AppColors.textFaint,
                  ),
                ),
                const SizedBox(height: 18),
                TextButton.icon(
                  key: const Key('route-not-found-return'),
                  onPressed: navigation.showSituationRoom,
                  icon: const Icon(Icons.arrow_back, size: 14),
                  label: const Text('Volver al archivo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
