import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/kehlo_logo.dart';
import '../../you/controllers/you_preferences_controller.dart';
import '../models/suggested_replies.dart';

class KehloBrandHeader extends StatelessWidget {
  const KehloBrandHeader({
    super.key,
    this.outcome = 'Upload a chat → get 2 replies you can send.',
  });

  final String outcome;

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KehloLogo(fontSize: 48),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            style: body.bodyLarge?.copyWith(
              color: const Color(0xFFC9B8D4),
              fontSize: 16,
            ),
            children: const [
              TextSpan(text: 'Stuck on a reply? '),
              TextSpan(
                text: 'Kehlo.',
                style: TextStyle(
                  color: AppColors.neonPink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (outcome.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            outcome,
            style: body.bodyMedium?.copyWith(
              color: const Color(0xFFB9AEC8),
              height: 1.35,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}

/// Privacy trust line near upload CTAs.
class UploadTrustLine extends StatelessWidget {
  const UploadTrustLine({
    super.key,
    this.text =
        'Screenshots stay in memory — not stored on your Kehlo account.',
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 15,
          color: AppColors.neonPink.withValues(alpha: 0.85),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF9A8FA8),
                  height: 1.35,
                  fontSize: 12,
                ),
          ),
        ),
      ],
    );
  }
}

/// Quiet tip under the upload zone — what a good shot looks like.
class UploadHintLine extends StatelessWidget {
  const UploadHintLine({
    super.key,
    this.text =
        'Tip: crop to the latest messages so the last bubble is easy to read.',
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF7E738F),
            height: 1.35,
            fontSize: 12,
          ),
    );
  }
}

/// Quick vibe picker — writes to You prefs (used on generate).
class MoodChipRow extends StatelessWidget {
  const MoodChipRow({super.key});

  @override
  Widget build(BuildContext context) {
    final you = context.watch<YouPreferencesController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _MoodChip(
                Icons.favorite_rounded,
                'Natural',
                selected: you.defaultVibe == ReplyTone.natural,
                onTap: () => you.setDefaultVibe(ReplyTone.natural),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MoodChip(
                Icons.local_fire_department_rounded,
                'Playful',
                selected: you.defaultVibe == ReplyTone.playful,
                onTap: () => you.setDefaultVibe(ReplyTone.playful),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Sets your default vibe in You.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: const Color(0xFF9A8FA8),
          ),
        ),
      ],
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip(
    this.icon,
    this.label, {
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label vibe',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.neonPink.withValues(alpha: 0.22)
                  : const Color(0x990A0610),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? AppColors.neonPink
                    : AppColors.neonPink.withValues(alpha: 0.45),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: selected ? Colors.white : AppColors.neonPink,
                ),
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
          ),
        ),
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
    this.title = 'Upload a screenshot',
    this.subtitle = 'Get 2 sendable replies in your tone.',
    this.footer = 'iMessage · WhatsApp · Tinder · Hinge',
    this.cameraTitle = 'Take a photo',
    this.cameraSubtitle = 'Snap the chat from another phone',
    this.typeMessageTitle = 'Type a message instead',
    this.typeMessageSubtitle = 'Paste what they sent — no screenshot needed',
    this.showTypeMessage = true,
    this.showCamera = true,
  });

  final VoidCallback? onTap;
  final VoidCallback? onCameraTap;
  final VoidCallback? onTypeMessageTap;
  final String title;
  final String subtitle;
  final String footer;
  final String cameraTitle;
  final String cameraSubtitle;
  final String typeMessageTitle;
  final String typeMessageSubtitle;
  final bool showTypeMessage;
  final bool showCamera;

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
                            title,
                            textAlign: TextAlign.center,
                            style: text.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: text.bodyMedium?.copyWith(
                              color: const Color(0xFFB9AEC8),
                            ),
                          ),
                          if (footer.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              footer,
                              textAlign: TextAlign.center,
                              style: text.labelSmall?.copyWith(
                                color: const Color(0xFF7E738F),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (showCamera) ...[
                  _UploadZoneDivider(),
                  _UploadZoneRow(
                    icon: Icons.photo_camera_outlined,
                    title: cameraTitle,
                    subtitle: cameraSubtitle,
                    onTap: onCameraTap,
                  ),
                ],
                if (showTypeMessage) ...[
                  _UploadZoneDivider(),
                  _UploadZoneRow(
                    icon: Icons.keyboard_alt_outlined,
                    title: typeMessageTitle,
                    subtitle: typeMessageSubtitle,
                    onTap: onTypeMessageTap,
                  ),
                ],
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
    this.label = 'Generate replies',
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

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
                          label,
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
