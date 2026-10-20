import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/subscription/subscription_services.dart';
import '../../usage/usage_controller.dart';
import '../controllers/subscription_controller.dart';

Future<void> showPaywallSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PaywallSheet(),
  );
}

class _PaywallSheet extends StatefulWidget {
  const _PaywallSheet();

  @override
  State<_PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<_PaywallSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionController>().refreshOfferings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionController>();
    final usage = context.watch<UsageController>();
    final bottom = MediaQuery.paddingOf(context).bottom;
    final boost = sub.boostPackage;
    final subs = sub.subscriptionPackages;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xEE160E18),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(
              color: AppColors.neonPink.withValues(alpha: 0.28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFF2C94C),
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Kehlo Pro',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    usage.isBoostPro
                        ? 'Boost is running. Go Monthly if you want Pro without the clock.'
                        : usage.isPro
                            ? 'You’re on Pro. Enjoy the higher daily budget.'
                            : 'Need more replies now? Grab a 1-hour Boost, or go Pro monthly.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFFD4C8DE),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (usage.isBoostPro) ...[
                    Text(
                      usage.proStatusLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF2C94C),
                      ),
                    ),
                    if (subs.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      for (var i = 0; i < subs.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _PackageButton(
                          package: subs[i],
                          primary: i == 0,
                          enabled: !sub.busy,
                          onTap: () => _buy(sub, subs[i]),
                        ),
                      ],
                    ],
                  ] else if (usage.isPro)
                    Text(
                      'Pro is active on this account.',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    )
                  else ...[
                    // Boost is always offered (consumable); monthly if Store returned it.
                    _PackageButton(
                      package: boost ??
                          const SubscriptionPackage(
                            id: 'kehlo_boost_1h',
                            title: 'Kehlo Boost',
                            priceString: '1 hour',
                            period: '1 hour',
                            isBoost: true,
                          ),
                      primary: true,
                      enabled: !sub.busy,
                      labelOverride: boost == null ||
                              boost.priceString == '1 hour'
                          ? 'Boost · 1 hour of Pro'
                          : 'Boost 1 hour · ${boost.priceString}',
                      onTap: () async {
                        final pkg = boost ??
                            const SubscriptionPackage(
                              id: 'kehlo_boost_1h',
                              title: 'Kehlo Boost',
                              priceString: '1 hour',
                              period: '1 hour',
                              isBoost: true,
                            );
                        await _buy(sub, pkg, boostSnack: true);
                      },
                    ),
                    if (subs.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      for (var i = 0; i < subs.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _PackageButton(
                          package: subs[i],
                          primary: false,
                          enabled: !sub.busy,
                          onTap: () => _buy(sub, subs[i]),
                        ),
                      ],
                    ] else ...[
                      const SizedBox(height: 10),
                      Text(
                        'Monthly Pro loads from the App Store when available.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFFB9AEC8),
                        ),
                      ),
                    ],
                  ],
                  if (sub.lastError != null && sub.lastError!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      sub.lastError!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: sub.busy
                        ? null
                        : () async {
                            final ok = await sub.restore();
                            if (!context.mounted) return;
                            if (ok) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Pro restored.',
                                    style: GoogleFonts.plusJakartaSans(),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Restore purchases',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
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

  Future<void> _buy(
    SubscriptionController sub,
    SubscriptionPackage package, {
    bool boostSnack = false,
  }) async {
    final ok = await sub.purchase(package);
    if (!mounted) return;
    if (ok) {
      final usage = context.read<UsageController>();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            boostSnack
                ? (usage.isBoostPro
                    ? 'Boost on — Pro for the next hour.'
                    : 'Pro is active.')
                : (usage.isSubscriptionPro
                    ? 'Welcome to Pro Monthly.'
                    : 'Welcome to Pro.'),
            style: GoogleFonts.plusJakartaSans(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (sub.lastError != null && sub.lastError!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sub.lastError!,
            style: GoogleFonts.plusJakartaSans(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _PackageButton extends StatelessWidget {
  const _PackageButton({
    required this.package,
    required this.primary,
    required this.enabled,
    required this.onTap,
    this.labelOverride,
  });

  final SubscriptionPackage package;
  final bool primary;
  final bool enabled;
  final VoidCallback onTap;
  final String? labelOverride;

  @override
  Widget build(BuildContext context) {
    final label = labelOverride ??
        (package.isBoost
            ? '${package.priceString} · 1 hour'
            : package.period == 'lifetime'
                ? '${package.priceString} · lifetime'
                : '${package.priceString}/${package.period}');

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
              height: 52,
              child: Center(
                child: Text(
                  package.isBoost ? label : 'Upgrade · $label',
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
        package.isBoost ? label : 'Pro monthly · $label',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
    );
  }
}
