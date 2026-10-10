import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class WingmanBrandHeader extends StatelessWidget {
  const WingmanBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wingman', style: AppTypography.brandScript),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Icon(
                Icons.favorite_rounded,
                size: 16,
                color: AppColors.neonPink.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            style: body.bodyLarge?.copyWith(
              color: const Color(0xFFC9B8D4),
              fontSize: 16,
            ),
            children: const [
              TextSpan(text: 'Your next reply, '),
              TextSpan(
                text: 'figured out.',
                style: TextStyle(
                  color: AppColors.neonPink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MoodChipRow extends StatelessWidget {
  const MoodChipRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _MoodChip(Icons.favorite_rounded, 'Flirt better'),
        ),
        SizedBox(width: 6),
        Expanded(
          child: _MoodChip(
            Icons.local_fire_department_rounded,
            'Keep the vibe',
          ),
        ),
        SizedBox(width: 6),
        Expanded(
          child: _MoodChip(Icons.calendar_month_outlined, 'Get the date'),
        ),
      ],
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x990A0610),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.neonPink.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: AppColors.neonPink),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashedUploadZone extends StatelessWidget {
  const DashedUploadZone({
    super.key,
    this.onTap,
    this.onCameraTap,
    this.onTypeMessageTap,
  });

  final VoidCallback? onTap;
  final VoidCallback? onCameraTap;
  final VoidCallback? onTypeMessageTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return CustomPaint(
      painter: _GlowDashPainter(
        color: AppColors.neonPink,
        radius: 24,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xCC1A1016),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.neonPink.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: AppColors.accentGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.neonPink
                                          .withValues(alpha: 0.4),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.image_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              Positioned(
                                right: -4,
                                bottom: -4,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.accentGradient,
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Upload a screenshot of your chat',
                            textAlign: TextAlign.center,
                            style: text.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "I'll help you figure out what to say.",
                            textAlign: TextAlign.center,
                            style: text.bodyMedium?.copyWith(
                              color: const Color(0xFFB9AEC8),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'iMessage · WhatsApp · Tinder · Hinge',
                            textAlign: TextAlign.center,
                            style: text.labelSmall?.copyWith(
                              color: const Color(0xFF7E738F),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _UploadZoneDivider(),
                _UploadZoneRow(
                  icon: Icons.photo_camera_outlined,
                  title: 'Take a photo',
                  subtitle: 'Snap the chat from another phone',
                  onTap: onCameraTap,
                ),
                _UploadZoneDivider(),
                _UploadZoneRow(
                  icon: Icons.keyboard_alt_outlined,
                  title: 'Type a message instead',
                  subtitle: 'Paste or enter the message you received',
                  onTap: onTypeMessageTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadZoneDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.neonPink.withValues(alpha: 0.18),
      ),
    );
  }
}

class _UploadZoneRow extends StatelessWidget {
  const _UploadZoneRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: AppColors.neonPink.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: text.bodySmall?.copyWith(
                        color: const Color(0xFF9A8FA8),
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.neonPink.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NeonGenerateButton extends StatelessWidget {
  const NeonGenerateButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final labelColor = enabled ? Colors.white : const Color(0xFFB9AEC8);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled ? AppColors.accentGradient : null,
        color: enabled ? null : const Color(0xFF2A1C28),
        borderRadius: BorderRadius.circular(999),
        border: enabled
            ? null
            : Border.all(color: AppColors.neonPink.withValues(alpha: 0.28)),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.neonPink.withValues(alpha: 0.42),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed?.call();
                }
              : null,
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: labelColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Generate replies',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: labelColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: labelColor,
                          size: 26,
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

class _GlowDashPainter extends CustomPainter {
  _GlowDashPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      Radius.circular(radius),
    );

    final glow = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(rrect, glow);

    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path()..addRRect(rrect);
    const dash = 6.0;
    const gap = 4.5;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final end = math.min(d + dash, metric.length);
        canvas.drawPath(metric.extractPath(d, end), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GlowDashPainter oldDelegate) =>
      oldDelegate.color != color;
}
