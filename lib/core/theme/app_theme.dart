import 'package:flutter/material.dart';

import '../design/tokens/tokens.dart';

class AppColors {
  static const background = Color(0xFF090A0D);
  static const panel = Color(0xFF14161C);
  static const panelMuted = Color(0xFF1C2029);
  static const border = Color(0xFF2A2F3A);
  static const accent = Color(0xFFB1232E);
  static const textPrimary = Color(0xFFF3F0EA);
  static const textMuted = Color(0xFFB4AFAB);
  static const textSoft = Color(0xFF8A8681);
  static const gold = Color(0xFFD6B26E);

  // --- Tokens de la "Sala de Situación" (diseño Sala de Situación.dc.html) ---
  /// Fondo más profundo del lienzo (mapa y base general).
  static const bgDeep = Color(0xFF070A0D);

  /// Barras y paneles cromados (top bar, rail, panel lateral).
  static const bar = Color(0xFF0A0C11);

  /// Barra del ticker de actualizaciones.
  static const tickerBar = Color(0xFF080A0E);

  /// Campos de entrada y píldoras sobre barras.
  static const inputFill = Color(0xFF13151B);

  /// Tarjetas internas (fuentes, relacionados, métricas).
  static const card = Color(0xFF0C0E13);

  /// Línea divisoria tenue entre barras.
  static const hairlineSoft = Color(0xFF14171D);

  // Texto en gradiente editorial.
  static const textBody = Color(0xFFE7E3DC);
  static const textSub = Color(0xFF9A948C);
  static const textSub2 = Color(0xFFC7C2BB);
  static const textFaint = Color(0xFF7D7468);
  static const textFaint2 = Color(0xFF6E6A65);

  // Estado de investigación.
  static const statusOpen = Color(0xFF5E7891);
  static const statusSolved = Color(0xFF8FA68A);
  static const statusProgress = Color(0xFFC79A4A);

  // Categorías (alineadas exactamente al diseño).
  static const catSerie = accent; // #B1232E
  static const catIsolated = Color(0xFF8A2A30);
  static const catKidnapping = Color(0xFFB98A3C);
  static const catUnsolved = Color(0xFF5E7891);
}

/// Familia monoespaciada para etiquetas y coordenadas (IBM Plex Mono empaquetada).
const String kMonoFamily = DsFontFamilies.mono;
