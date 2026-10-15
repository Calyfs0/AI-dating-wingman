import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../screenshot_reply/models/suggested_replies.dart';
import '../../screenshot_reply/widgets/desire_backdrop.dart';
import '../controllers/you_preferences_controller.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final you = context.watch<YouPreferencesController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesireBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Text(
                'You',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              _GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.accentGradient,
                        border: Border.all(
                          color: AppColors.neonPink.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'G',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gotchu',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Free plan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFFB9AEC8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Default reply vibe',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB9AEC8),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ReplyTone.values.map((tone) {
                  final selected = you.defaultVibe == tone;
                  return ChoiceChip(
                    label: Text(tone.title),
                    selected: selected,
                    onSelected: (_) => you.setDefaultVibe(tone),
                    selectedColor: AppColors.neonPink.withValues(alpha: 0.28),
                    backgroundColor: const Color(0xCC1A1016),
                    labelStyle: GoogleFonts.plusJakartaSans(
                      color: selected ? Colors.white : const Color(0xFFB9AEC8),
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: selected ? AppColors.neonPink : Colors.white12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              Text(
                'Tone & style',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB9AEC8),
                ),
              ),
              const SizedBox(height: 10),
              _GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ToggleRow(
                      title: 'Keep it casual',
                      subtitle: 'No therapy-speak or email energy',
                      value: you.keepCasual,
                      onChanged: you.setKeepCasual,
                    ),
                    Divider(
                      height: 1,
                      color: AppColors.neonPink.withValues(alpha: 0.12),
                    ),
                    _ToggleRow(
                      title: 'Match their language',
                      subtitle: 'Hindi, Tamil, Hinglish, English…',
                      value: you.matchLanguage,
                      onChanged: you.setMatchLanguage,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _GlassCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.neonPink.withValues(alpha: 0.9),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Privacy',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Screenshots stay on device — never stored on our servers.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFFB9AEC8),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _ProCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xCC1A1016),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.neonPink.withValues(alpha: 0.18),
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF9A8FA8),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.neonPink.withValues(alpha: 0.55),
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _ProCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.neonPink.withValues(alpha: 0.28),
            const Color(0xFF2A1830),
          ],
        ),
        border: Border.all(
          color: AppColors.neonPink.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFF2C94C),
                  size: 26,
                ),
                const SizedBox(width: 10),
                  Text(
                  'Gotchu Pro',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock unlimited replies, openers, and deeper coaching.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFFD4C8DE),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Pro coming soon — you’re on the free plan for now.',
                          style: GoogleFonts.plusJakartaSans(),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        'Unlock unlimited replies',
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
          ],
        ),
      ),
    );
  }
}
