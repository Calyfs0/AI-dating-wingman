import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../screenshot_reply/widgets/desire_backdrop.dart';
import '../controllers/openers_flow_controller.dart';

class OpenersGeneratingScreen extends StatelessWidget {
  const OpenersGeneratingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OpenersFlowController>();
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
                    'Making the first move count…',
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.neonPink,
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
      builder: (context, _) {
        final t = _controller.value;
        return SizedBox(
          width: 88,
          height: 88,
          child: CustomPaint(
            painter: _OrbitPainter(progress: t),
            child: Center(
              child: Transform.scale(
                scale: 0.92 + 0.08 * math.sin(t * math.pi * 2),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.accentGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonPink.withValues(alpha: 0.45),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.waving_hand_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final track = Paint()
      ..color = AppColors.neonPink.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, track);

    final angle = progress * math.pi * 2;
    final dot = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    canvas.drawCircle(
      dot,
      5,
      Paint()..color = AppColors.neonPink,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
