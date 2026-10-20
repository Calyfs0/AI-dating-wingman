import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/kehlo_logo.dart';
import '../../screenshot_reply/models/suggested_replies.dart';
import '../../screenshot_reply/widgets/desire_backdrop.dart';
import '../../screenshot_reply/widgets/mockup_components.dart';
import '../controllers/onboarding_controller.dart';

class KehloOnboardingScreen extends StatelessWidget {
  const KehloOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesireBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (onboarding.step > 0)
                      IconButton(
                        onPressed: onboarding.back,
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      )
                    else
                      const SizedBox(width: 48, height: 48),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        await onboarding.skip();
                      },
                      child: Text(
                        'Skip',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFB9AEC8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: switch (onboarding.step) {
                      0 => const _PromiseStep(key: ValueKey(0)),
                      1 => _VibeStep(
                          key: const ValueKey(1),
                          vibe: onboarding.vibe,
                          onChanged: onboarding.setVibe,
                        ),
                      _ => const _PrivacyStep(key: ValueKey(2)),
                    },
                  ),
                ),
                NeonGenerateButton(
                  label: onboarding.step < 2 ? 'Continue' : 'Let’s go',
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    if (onboarding.step < 2) {
                      onboarding.next();
                    } else {
                      await onboarding.complete();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PromiseStep extends StatelessWidget {
  const _PromiseStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KehloLogo(fontSize: 56),
        const SizedBox(height: 20),
        Text(
          'Stuck on a reply?\nKehlo.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.15,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Upload a chat screenshot → get 2 replies you can copy and send. Sounds like you — not a chatbot.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            color: const Color(0xFFB9AEC8),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Core loop',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neonPink,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Upload the chat\n2. Pick a reply\n3. Copy → send',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: Colors.white,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Later: Openers for first messages from a profile. That’s optional.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF9A8FA8),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VibeStep extends StatelessWidget {
  const _VibeStep({
    super.key,
    required this.vibe,
    required this.onChanged,
  });

  final ReplyTone vibe;
  final ValueChanged<ReplyTone> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Default vibe',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We’ll lead with this tone. You can change it anytime in You.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            color: const Color(0xFFB9AEC8),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 24),
        for (final tone in ReplyTone.values) ...[
          _VibeOption(
            tone: tone,
            selected: vibe == tone,
            onTap: () => onChanged(tone),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _VibeOption extends StatelessWidget {
  const _VibeOption({
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  final ReplyTone tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: selected
                ? AppColors.neonPink.withValues(alpha: 0.22)
                : const Color(0xCC1A1016),
            border: Border.all(
              color: selected ? AppColors.neonPink : Colors.white12,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tone.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tone.subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFFB9AEC8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: selected ? AppColors.neonPink : const Color(0xFF7E738F),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyStep extends StatelessWidget {
  const _PrivacyStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy, straight up',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Screenshots are analyzed in memory and are not stored on your Kehlo account. History you keep stays on this device — clear it anytime in You.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            color: const Color(0xFFB9AEC8),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        GlassCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: AppColors.neonPink.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You’re in control. Delete account or clear local history from You whenever you want.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
