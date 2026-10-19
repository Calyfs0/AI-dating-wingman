import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../screenshot_reply/models/suggested_replies.dart';
import '../../screenshot_reply/widgets/desire_backdrop.dart';
import '../../screenshot_reply/widgets/tone_icons.dart';
import '../controllers/openers_flow_controller.dart';

class OpenersResultsScreen extends StatelessWidget {
  const OpenersResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OpenersFlowController>();
    final openers = controller.openers;
    if (openers == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesireBackdrop(
        readabilityScrim: true,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: controller.backFromResults,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Openers',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    Text(
                      'First messages that fit their profile',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFFB9AEC8),
                      ),
                    ),
                    if (openers.hook != null && openers.hook!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Hook: ${openers.hook}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.neonPink,
                        ),
                      ),
                    ],
                    if (openers.why != null && openers.why!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        openers.why!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF9A8FA8),
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    for (final tone in controller.orderedTones) ...[
                      _OpenerCard(
                        tone: tone,
                        message: openers.forTone(tone),
                        onCopy: () async {
                          HapticFeedback.lightImpact();
                          await controller.copyOpener(openers.forTone(tone));
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (controller.copiedConfirmation)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Copied — go make the move.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.neonPink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (controller.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        controller.errorMessage!,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.isBusy
                            ? null
                            : controller.tryAgain,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: AppColors.neonPink.withValues(alpha: 0.45),
                          ),
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          'Try again',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: controller.startOver,
                            child: SizedBox(
                              height: 48,
                              child: Center(
                                child: Text(
                                  'New profile',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenerCard extends StatelessWidget {
  const _OpenerCard({
    required this.tone,
    required this.message,
    required this.onCopy,
  });

  final ReplyTone tone;
  final String message;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 128),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(
                    const Color(0xFF2A2036),
                    tone.accentColor,
                    0.08,
                  )!
                  .withValues(alpha: 0.94),
              const Color(0xF0120E18),
            ],
          ),
          border: Border.all(
            color: tone.accentColor.withValues(alpha: 0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: tone.accentColor.withValues(alpha: 0.18),
              blurRadius: 20,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ToneIcon(tone: tone, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tone.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: tone.accentColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tone.subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF9A8FA8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tone.accentColor,
                      side: BorderSide(
                        color: tone.accentColor.withValues(alpha: 0.55),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
