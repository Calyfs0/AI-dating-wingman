import 'dart:ui';

import 'package:flutter/material.dart';

/// Sharp romantic backdrop — no blur (matches approved mockups).
class DesireBackdrop extends StatelessWidget {
  const DesireBackdrop({
    super.key,
    required this.child,
    this.readabilityScrim = false,
  });

  final Widget child;

  /// Subtle full-screen dark overlay for denser text screens.
  final bool readabilityScrim;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/desire_bg.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) =>
              const ColoredBox(color: Color(0xFF0A0610)),
        ),
        // Light veil only at the bottom for the CTA — photo stays sharp.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x14050108),
                Color(0x00050108),
                Color(0x66050108),
                Color(0xD9050108),
              ],
              stops: [0.0, 0.28, 0.62, 1.0],
            ),
          ),
        ),
        if (readabilityScrim)
          const ColoredBox(color: Color(0x73050108)),
        child,
      ],
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 20,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: r,
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

typedef GlassPanel = GlassCard;
