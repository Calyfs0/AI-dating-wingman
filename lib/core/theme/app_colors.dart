import 'package:flutter/material.dart';

/// Centralized Wingman color tokens. Never hard-code colors in widgets.
abstract final class AppColors {
  static const Color background = Color(0xFF0B0B0D);
  static const Color backgroundElevated = Color(0xFF111114);
  static const Color surface = Color(0xFF16161A);
  static const Color surfaceElevated = Color(0xFF1C1C22);
  static const Color surfaceHighlight = Color(0xFF22222A);
  static const Color border = Color(0xFF2A2A33);
  static const Color borderSubtle = Color(0xFF1F1F27);

  static const Color accent = Color(0xFFA78BFA);
  static const Color accentSoft = Color(0xFF8B7CF6);
  static const Color accentMuted = Color(0x33A78BFA);
  static const Color accentDeep = Color(0xFF6D5AE6);

  static const Color textPrimary = Color(0xFFF4F4F5);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textTertiary = Color(0xFF71717A);
  static const Color textInverse = Color(0xFF0B0B0D);

  static const Color success = Color(0xFF6EE7B7);
  static const Color successMuted = Color(0x336EE7B7);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningMuted = Color(0x33FBBF24);
  static const Color danger = Color(0xFFF87171);
  static const Color dangerMuted = Color(0x33F87171);

  static const Color shimmerBase = Color(0xFF1A1A20);
  static const Color shimmerHighlight = Color(0xFF26262E);

  static const Color overlay = Color(0xCC0B0B0D);
  static const Color scrim = Color(0x99000000);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF121216), background],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB8A4FF), accentSoft, accentDeep],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A22), Color(0xFF141418)],
  );

  static const LinearGradient fabGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC4B5FD), accent],
  );
}
