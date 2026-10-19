import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import 'desire_backdrop.dart';

/// Shared Reply / Openers generating chrome — status, subtle motion, skeleton cards.
class GeneratingStatusView extends StatelessWidget {
  const GeneratingStatusView({
    super.key,
    required this.statusMessage,
    required this.subtitle,
    required this.onCancel,
    this.heroIcon = Icons.auto_awesome_rounded,
  });

  final String statusMessage;
  final String subtitle;
  final VoidCallback onCancel;
  final IconData heroIcon;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesireBackdrop(
        readabilityScrim: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Column(
              children: [
                const Spacer(flex: 2),
                _OrbitHero(
                  icon: heroIcon,
                  reduceMotion: reduceMotion,
                ),
                const SizedBox(height: 28),
                AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) {
                    if (reduceMotion) return child;
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    statusMessage,
                    key: ValueKey(statusMessage),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.neonPink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Usually a few seconds — hang tight.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF7E738F),
                  ),
                ),
                const SizedBox(height: 28),
                _SkeletonReplyCards(reduceMotion: reduceMotion),
                const Spacer(flex: 3),
                TextButton(
                  onPressed: onCancel,
                  child: Text(
                    'Cancel',
                    style: text.labelLarge?.copyWith(
                      color: const Color(0xFFB9AEC8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitHero extends StatefulWidget {
  const _OrbitHero({
    required this.icon,
    required this.reduceMotion,
  });

  final IconData icon;
  final bool reduceMotion;

  @override
  State<_OrbitHero> createState() => _OrbitHeroState();
}

class _OrbitHeroState extends State<_OrbitHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (!widget.reduceMotion) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _OrbitHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion != oldWidget.reduceMotion) {
      if (widget.reduceMotion) {
        _controller.stop();
        _controller.value = 0;
      } else {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = widget.reduceMotion ? 0.15 : _controller.value;
        final pulse = widget.reduceMotion
            ? 1.0
            : 0.92 + 0.08 * math.sin(t * math.pi * 2);

        return SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(100, 100),
                painter: _OrbitPainter(
                  progress: t,
                  color: AppColors.neonPink,
                  secondary: AppColors.neonPurple,
                  animate: !widget.reduceMotion,
                ),
              ),
              Transform.scale(
                scale: pulse,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.accentGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonPink.withValues(
                          alpha: widget.reduceMotion ? 0.28 : 0.45,
                        ),
                        blurRadius: widget.reduceMotion ? 14 : 26,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    color: Colors.white.withValues(alpha: 0.95),
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({
    required this.progress,
    required this.color,
    required this.secondary,
    required this.animate,
  });

  final double progress;
  final Color color;
  final Color secondary;
  final bool animate;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = color.withValues(alpha: 0.16);
    canvas.drawCircle(center, radius, track);

    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          secondary.withValues(alpha: 0),
          color.withValues(alpha: 0.85),
          secondary.withValues(alpha: 0.9),
          secondary.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 1.25,
      false,
      sweep,
    );

    if (!animate) return;
    for (var i = 0; i < 3; i++) {
      final angle = (progress * math.pi * 2) + (i * (math.pi * 2 / 3));
      final dot = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawCircle(
        dot,
        2.4 - i * 0.35,
        Paint()..color = Colors.white.withValues(alpha: 0.85 - i * 0.15),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.animate != animate;
}

class _SkeletonReplyCards extends StatefulWidget {
  const _SkeletonReplyCards({required this.reduceMotion});

  final bool reduceMotion;

  @override
  State<_SkeletonReplyCards> createState() => _SkeletonReplyCardsState();
}

class _SkeletonReplyCardsState extends State<_SkeletonReplyCards>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (!widget.reduceMotion) {
      _shimmer.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _SkeletonReplyCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion != oldWidget.reduceMotion) {
      if (widget.reduceMotion) {
        _shimmer.stop();
        _shimmer.value = 0.35;
      } else {
        _shimmer.repeat();
      }
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        final t = widget.reduceMotion ? 0.4 : _shimmer.value;
        return Column(
          children: [
            _SkeletonCard(
              accent: AppColors.neonPink,
              progress: t,
            ),
            const SizedBox(height: 12),
            _SkeletonCard(
              accent: const Color(0xFF6FCF97),
              progress: (t + 0.35) % 1.0,
            ),
          ],
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({
    required this.accent,
    required this.progress,
  });

  final Color accent;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final shimmer = 0.08 + 0.1 * (0.5 + 0.5 * math.sin(progress * math.pi * 2));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xCC1A1016),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.22 + shimmer),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bone(width: 72, height: 10, opacity: 0.22 + shimmer),
                    const SizedBox(height: 6),
                    _Bone(width: 120, height: 8, opacity: 0.12 + shimmer * 0.6),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Bone(height: 11, opacity: 0.18 + shimmer),
          const SizedBox(height: 8),
          _Bone(width: 180, height: 11, opacity: 0.12 + shimmer * 0.7),
        ],
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    this.width,
    required this.height,
    required this.opacity,
  });

  final double? width;
  final double height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.white.withValues(alpha: opacity.clamp(0.08, 0.35)),
      ),
    );
  }
}
