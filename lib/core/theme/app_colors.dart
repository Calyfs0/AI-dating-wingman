import 'package:flutter/material.dart';

/// Neon dating-assistant palette matching the Wingman mockup.
abstract final class AppColors {
  static const Color background = Color(0xFF07050C);
  static const Color backgroundElevated = Color(0xFF100C18);
  static const Color surface = Color(0xFF17121F);
  static const Color surfaceElevated = Color(0xFF1F1829);
  static const Color surfaceHighlight = Color(0xFF2A2136);
  static const Color border = Color(0xFF3A2F4A);
  static const Color borderSubtle = Color(0xFF2A2235);

  /// Neon pink primary.
  static const Color accent = Color(0xFFFF4EAB);
  static const Color accentSoft = Color(0xFFFF7AC2);
  static const Color accentMuted = Color(0x33FF4EAB);
  static const Color accentDeep = Color(0xFF8E44AD);
  static const Color accentGlow = Color(0x66FF4EAB);

  static const Color neonPink = Color(0xFFFF4EAB);
  static const Color neonPurple = Color(0xFF8E44AD);
  static const Color glass = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x33FF4EAB);

  static const Color natural = Color(0xFF6FCF97);
  static const Color playful = Color(0xFFFF4EAB);
  static const Color confident = Color(0xFFF2C94C);

  static const Color textPrimary = Color(0xFFF7F2FA);
  static const Color textSecondary = Color(0xFFB9AEC8);
  static const Color textTertiary = Color(0xFF7E738F);
  static const Color textInverse = Color(0xFFFFF7FB);

  static const Color success = Color(0xFF6FCF97);
  static const Color successMuted = Color(0x336FCF97);
  static const Color warning = Color(0xFFF2C94C);
  static const Color warningMuted = Color(0x33F2C94C);
  static const Color danger = Color(0xFFFF6B8A);
  static const Color dangerMuted = Color(0x33FF6B8A);
  static const Color info = Color(0xFFC9A0FF);

  static const Color statusActive = Color(0xFF6FCF97);
  static const Color statusWaiting = Color(0xFFF2C94C);
  static const Color statusQuiet = Color(0xFF7E738F);

  static const Color shimmerBase = Color(0xFF14101A);
  static const Color shimmerHighlight = Color(0xFF241C30);

  static const Color overlay = Color(0xCC07050C);
  static const Color scrim = Color(0x9907050C);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1024), background],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFF4EAB), Color(0xFF8E44AD)],
  );

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8AC8), neonPink, neonPurple],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xCC1A1324), Color(0xAA0D0A14)],
  );

  static const LinearGradient fabGradient = accentGradient;

  static const LinearGradient heroAtmosphere = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x66241438),
      Color(0xCC0A0612),
      Color(0xF207050C),
    ],
  );
}
