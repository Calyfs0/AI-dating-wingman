import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/kehlo_logo.dart';
import '../../history/controllers/history_controller.dart';
import '../../history/widgets/history_sheet.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../../screenshot_reply/models/suggested_replies.dart';
import '../../screenshot_reply/widgets/desire_backdrop.dart';
import '../../subscription/controllers/subscription_controller.dart';
import '../../../services/subscription/subscription_services.dart';
import '../../usage/usage_controller.dart';
import '../controllers/you_preferences_controller.dart';
import '../services/account_service.dart';

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
                          const KehloLogo(fontSize: 36),
                          const SizedBox(height: 2),
                          Text(
                            usage.proStatusLabel,
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
                      onTap: () => context.push('/profile-audit'),
                    ),
                    Divider(
                      height: 1,
                      color: AppColors.neonPink.withValues(alpha: 0.12),
                    ),
                    _YouLinkRow(
                      icon: Icons.fitness_center_rounded,
                      iconColor: const Color(0xFFB9AEC8),
                      title: 'Practice',
                      subtitle: 'Low-stakes rehearsal — doesn’t use free credits',
                      onTap: () => context.push('/practice'),
                    ),
                    Divider(
                      height: 1,
                      color: AppColors.neonPink.withValues(alpha: 0.12),
                    ),
                    _YouLinkRow(
                      icon: Icons.history_rounded,
                      iconColor: const Color(0xFFB9AEC8),
                      title: 'Recent history',
                      subtitle: history.entries.isEmpty
                          ? 'Saved on this device only'
                          : '${history.entries.length} saved on this device',
                      onTap: () => showHistorySheet(context),
                    ),
                    if (history.entries.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1A1324),
                                title: Text(
                                  'Clear history?',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                  ),
                                ),
                                content: Text(
                                  'This removes saved replies from this device. It can’t be undone.',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFFB9AEC8),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(
                                      'Clear',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (ok != true || !context.mounted) return;
                            await history.clear();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Cleared from this device',
                                    style: GoogleFonts.plusJakartaSans(),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: Text(
                            'Clear on-device history',
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
              if (history.unstucksThisWeek > 0) ...[
                _WeeklyPulse(count: history.unstucksThisWeek),
                const SizedBox(height: 18),
              ],
              const _PrivacyCard(),
              const SizedBox(height: 18),
              _ProCard(),
              const SizedBox(height: 18),
              const _DeleteAccountButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyPulse extends StatelessWidget {
  const _WeeklyPulse({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.neonPink.withValues(alpha: 0.95),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              count == 1
                  ? 'You unstuck 1 chat this week.'
                  : 'You unstuck $count chats this week.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
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
                  'Privacy & data',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Chat and profile screenshots stay in memory for analysis only — Kehlo does not save them to your account or photo library. Suggested replies you keep in History stay on this device until you clear them.',
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
    );
  }
}

class _DeleteAccountButton extends StatefulWidget {
  const _DeleteAccountButton();

  @override
  State<_DeleteAccountButton> createState() => _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends State<_DeleteAccountButton> {
  bool _busy = false;

  Future<void> _confirmAndDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1324),
        title: Text(
          'Delete account?',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This removes your Kehlo cloud data (profile, usage, people on the server) and clears prefs on this device. Screenshots were never stored on your account. This can’t be undone.',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFFB9AEC8),
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFFB9AEC8)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final history = context.read<HistoryController>();
    final you = context.read<YouPreferencesController>();
    final usage = context.read<UsageController>();
    final onboarding = context.read<OnboardingController>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _busy = true);
    try {
      await getIt<AccountService>().deleteAccount();
      await history.clear();
      await you.load();
      await usage.load();
      await onboarding.load();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Account deleted. Starting fresh.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is AppException
          ? e.message
          : 'Couldn’t delete the account. Try again.';
      messenger.showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.plusJakartaSans()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _busy ? null : _confirmAndDelete,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.danger,
        side: BorderSide(color: AppColors.danger.withValues(alpha: 0.45)),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.danger,
              ),
            )
          : Text(
              'Delete account',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
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

class _ProCard extends StatefulWidget {
  @override
  State<_ProCard> createState() => _ProCardState();
}

class _ProCardState extends State<_ProCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionController>().refreshOfferings();
    });
  }

  Future<void> _buy(
    SubscriptionController sub,
    SubscriptionPackage package, {
    bool boost = false,
  }) async {
    final ok = await sub.purchase(package);
    if (!mounted) return;
    final usage = context.read<UsageController>();
    final successCopy = boost
        ? (usage.isBoostPro
            ? 'Boost on — Pro for the next hour.'
            : (sub.lastError ?? 'Boost status updated.'))
        : (usage.isSubscriptionPro
            ? 'Welcome to Pro Monthly.'
            : (sub.lastError ?? 'Pro status updated.'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? successCopy : (sub.lastError ?? 'Purchase didn’t complete.'),
          style: GoogleFonts.plusJakartaSans(),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _restore(SubscriptionController sub) async {
    final ok = await sub.restore();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Pro restored.' : (sub.lastError ?? 'Nothing to restore.'),
          style: GoogleFonts.plusJakartaSans(),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usage = context.watch<UsageController>();
    final sub = context.watch<SubscriptionController>();
    final boost = sub.boostPackage ??
        const SubscriptionPackage(
          id: 'kehlo_boost_1h',
          title: 'Kehlo Boost',
          priceString: '1 hour',
          period: '1 hour',
          isBoost: true,
        );
    final monthly = sub.subscriptionPackages.isNotEmpty
        ? sub.subscriptionPackages.first
        : null;
    final boostLabel = boost.priceString == '1 hour'
        ? 'Boost 1 hour'
        : 'Boost 1 hour · ${boost.priceString}';
    final monthlyLabel = monthly == null
        ? 'Pro monthly'
        : 'Pro monthly · ${monthly.priceString}';

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
                  'Kehlo Pro',
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
              _statusCopy(usage),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFFD4C8DE),
                height: 1.35,
              ),
            ),
            // —— Free: one-tap Boost + Monthly ——
            if (!usage.isPro) ...[
              const SizedBox(height: 14),
              _BuyButton(
                label: boostLabel,
                primary: true,
                enabled: !sub.busy,
                onTap: () => _buy(sub, boost, boost: true),
              ),
              const SizedBox(height: 10),
              if (monthly != null)
                _BuyButton(
                  label: monthlyLabel,
                  primary: false,
                  enabled: !sub.busy,
                  onTap: () => _buy(sub, monthly),
                )
              else
                Text(
                  'Monthly loads from the App Store when ready.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF9A8FA8),
                  ),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: sub.busy ? null : () => _restore(sub),
                child: Text(
                  'Restore purchases',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFD4C8DE),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            // —— Timed Boost: show clock; offer Monthly only (no second Boost) ——
            if (usage.isBoostPro) ...[
              const SizedBox(height: 10),
              Text(
                usage.proStatusLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF2C94C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${usage.remaining} of ${usage.dailyLimit} replies left today.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF9A8FA8),
                  height: 1.35,
                ),
              ),
              if (monthly != null) ...[
                const SizedBox(height: 14),
                _BuyButton(
                  label: monthlyLabel,
                  primary: true,
                  enabled: !sub.busy,
                  onTap: () => _buy(sub, monthly),
                ),
              ],
            ],
            // —— Monthly Pro: status only, no buy CTAs ——
            if (usage.isSubscriptionPro) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF6FCF97),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pro Monthly · ${usage.remaining} replies left today',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: sub.busy ? null : () => _restore(sub),
                child: Text(
                  'Restore on another device',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFD4C8DE),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (sub.lastError != null &&
                sub.lastError!.isNotEmpty &&
                !sub.busy) ...[
              const SizedBox(height: 10),
              Text(
                sub.lastError!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.danger,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _statusCopy(UsageController usage) {
    if (usage.isBoostPro) {
      return 'Boost is on. Keep Monthly handy if you want Pro without watching the clock.';
    }
    if (usage.isSubscriptionPro) {
      return 'You’re on Pro Monthly. Higher daily budget. Practice stays free.';
    }
    if (usage.isPro) {
      return 'Pro is active. Higher daily budget. Practice stays free.';
    }
    return 'Need more replies? One tap buys Boost or Monthly — no extra screens.';
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton({
    required this.label,
    required this.primary,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool primary;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onTap : null,
            child: SizedBox(
              height: 48,
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: AppColors.neonPink.withValues(alpha: 0.45)),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
    );
  }
}
