import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';

class WingmanLogoMark extends StatelessWidget {
  const WingmanLogoMark({
    super.key,
    this.size = 88,
    this.showGlow = true,
  });

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.logoGradient,
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: size * 0.45,
                  spreadRadius: 2,
                ),
                ...AppShadows.soft,
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        'W',
        style: TextStyle(
          color: AppColors.textInverse,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          height: 1,
          letterSpacing: -1,
        ),
      ),
    );
  }
}

class WingmanThinProgressBar extends StatelessWidget {
  const WingmanThinProgressBar({
    super.key,
    required this.value,
    this.height = 3,
  });

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: AppColors.surfaceHighlight,
        color: AppColors.accent,
      ),
    );
  }
}

class WingmanCircularProgress extends StatelessWidget {
  const WingmanCircularProgress({
    super.key,
    this.size = 120,
    this.progress,
    this.child,
  });

  final double size;
  final double? progress;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 5,
              backgroundColor: AppColors.surfaceHighlight,
              color: AppColors.accent,
              strokeCap: StrokeCap.round,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class WingmanDashedDropZone extends StatelessWidget {
  const WingmanDashedDropZone({
    super.key,
    this.onTap,
    this.label = 'Drop screenshots here',
    this.subtitle = 'or choose an option below',
    this.height = 160,
  });

  final VoidCallback? onTap;
  final String label;
  final String subtitle;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: AppColors.border,
            radius: 20,
          ),
          child: Container(
            height: height,
            width: double.infinity,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppColors.accent,
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );
    final metrics = path.computeMetrics().first;
    const dash = 7.0;
    const gap = 5.0;
    var distance = 0.0;
    while (distance < metrics.length) {
      final next = distance + dash;
      canvas.drawPath(
        metrics.extractPath(distance, next.clamp(0, metrics.length)),
        paint,
      );
      distance = next + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class WingmanStatusDot extends StatelessWidget {
  const WingmanStatusDot({super.key, required this.color, this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}

class WingmanMockNotificationCard extends StatelessWidget {
  const WingmanMockNotificationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          const WingmanLogoMark(size: 36, showGlow: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'KEHLO',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textPrimary,
                            letterSpacing: 0.6,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      'now',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Emma replied to you.',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  'Want a quick read before you answer?',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
