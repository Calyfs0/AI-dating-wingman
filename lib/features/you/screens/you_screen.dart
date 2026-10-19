import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/gotchu_logo.dart';
import '../../history/controllers/history_controller.dart';
import '../../history/widgets/history_sheet.dart';
import '../../profile_audit/screens/profile_audit_screen.dart';
import '../../screenshot_reply/models/suggested_replies.dart';
import '../../screenshot_reply/widgets/desire_backdrop.dart';
import '../../usage/usage_controller.dart';
import '../controllers/you_preferences_controller.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final you = context.watch<YouPreferencesController>();
    final usage = context.watch<UsageController>();
    final history = context.watch<HistoryController>();

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
                          const GotchuLogo(fontSize: 36),
                          const SizedBox(height: 2),
                          Text(
                            usage.isPro
                                ? 'Pro · ${usage.remaining} left today'
                                : 'Free · ${usage.remaining}/${usage.dailyLimit} today',
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
              _GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _YouLinkRow(
                      icon: Icons.photo_library_outlined,
                      iconColor: AppColors.neonPink.withValues(alpha: 0.9),
                      title: 'Profile audit',
                      subtitle: 'Scores, photo notes, bio rewrites',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ProfileAuditScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(
                      height: 1,
                      color: AppColors.neonPink.withValues(alpha: 0.12),
                    ),
                    _YouLinkRow(
                      icon: Icons.history_rounded,
                      iconColor: const Color(0xFFB9AEC8),
                      title: 'Recent history',
                      subtitle: '${history.entries.length} on this device',
                      onTap: () => showHistorySheet(context),
                    ),
                    if (history.entries.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () async {
                            await history.clear();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Local history cleared',
                                    style: GoogleFonts.plusJakartaSans(),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: Text(
                            'Clear history',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                            'Screenshots are sent briefly for analysis, then discarded — we don’t save them to your account.',
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

class _YouLinkRow extends StatelessWidget {
  const _YouLinkRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
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
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB9AEC8),
              ),
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
              'Free plan includes a daily Reply / Openers / Profile audit budget. Practice is free rehearsal and doesn’t use those credits.',
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
                          'You’re on the Pro waitlist. Limits stay free until Pro is live.',
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
                        'Join the Pro waitlist',
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
