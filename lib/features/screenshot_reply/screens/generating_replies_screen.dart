import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/reply_flow_controller.dart';
import '../widgets/desire_backdrop.dart';

class GeneratingRepliesScreen extends StatelessWidget {
  const GeneratingRepliesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReplyFlowController>();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesireBackdrop(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _SparkleLoader(),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      controller.loadingMessage,
                      key: ValueKey(controller.loadingMessage),
                      textAlign: TextAlign.center,
                      style: text.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Keeping the vibe hot…',
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.neonPink,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextButton(
                    onPressed: controller.cancelGeneration,
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
      ),
    );
  }
}

/// Gradient orbit + pulsing sparkles — matches the Wingman accent look.
class _SparkleLoader extends StatefulWidget {
  const _SparkleLoader();

  @override
  State<_SparkleLoader> createState() => _SparkleLoaderState();
}

class _SparkleLoaderState extends State<_SparkleLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
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
      builder: (context, child) {
        final t = _controller.value;
        final pulse = 0.88 + 0.12 * math.sin(t * math.pi * 2);

        return SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: t * math.pi * 2,
                child: CustomPaint(
                  size: const Size(96, 96),
                  painter: _OrbitPainter(
                    progress: t,
                    color: AppColors.neonPink,
                    secondary: AppColors.neonPurple,
                  ),
                ),
              ),
              Transform.scale(
                scale: pulse,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.accentGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonPink.withValues(alpha: 0.5),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white.withValues(alpha: 0.95),
                    size: 30,
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
  });

  final double progress;
  final Color color;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = color.withValues(alpha: 0.18);
    canvas.drawCircle(center, radius, track);

    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          secondary.withValues(alpha: 0),
          color,
          secondary,
          secondary.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 1.35,
      false,
      sweep,
    );

    // Soft sparkle dots on the ring.
    for (var i = 0; i < 3; i++) {
      final angle = (progress * math.pi * 2) + (i * (math.pi * 2 / 3));
      final dot = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final glow = Paint()
        ..color = color.withValues(alpha: 0.55 - i * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(dot, 3.2 - i * 0.4, glow);
      canvas.drawCircle(
        dot,
        2.2 - i * 0.3,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
