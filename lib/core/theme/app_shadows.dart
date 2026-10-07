import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Soft shadow tokens for elevated surfaces.
abstract final class AppShadows {
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get fab => [
        BoxShadow(
          color: AppColors.accent.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get glow => [
        BoxShadow(
          color: AppColors.accent.withValues(alpha: 0.18),
          blurRadius: 32,
          spreadRadius: 2,
        ),
      ];
}
