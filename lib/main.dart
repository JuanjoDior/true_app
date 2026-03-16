import 'package:flutter/material.dart';

void main() {
  runApp(const TrueApp());
}

class TrueApp extends StatelessWidget {
  const TrueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'true_app',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        useMaterial3: true,
      ),
      home: const TrueAppHomePage(),
    );
  }
}

class TrueAppHomePage extends StatelessWidget {
  const TrueAppHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accentColor = Color(0xFF2E7D32);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'true_app',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.18),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.spa_rounded,
                              size: 34,
                              color: accentColor,
                            ),
                            SizedBox(width: 12),
                            Icon(
                              Icons.spa_rounded,
                              size: 34,
                              color: accentColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Bienvenido hijo de puta de caviar',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Reemplaza esta pantalla con la primera funcionalidad de la app.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF355E3B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
