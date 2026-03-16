import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/home/presentation/home_page.dart';

class TrueCrimeApp extends StatelessWidget {
  const TrueCrimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'true_app',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(),
      home: const TrueCrimeHomePage(),
    );
  }
}
