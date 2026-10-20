import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../usage/usage_controller.dart';
import 'paywall_sheet.dart';

/// Soft landing when free (or Pro daily) budget is exhausted — not a dead end.
class UsageLimitCallout extends StatelessWidget {
  const UsageLimitCallout({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    final usage = context.watch<UsageController>();
    final body = message?.trim().isNotEmpty == true
        ? message!
        : usage.limitMessage;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xCC1A1016),
        border: Border.all(
          color: AppColors.neonPink.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              usage.isPro
                  ? "You've hit today's Pro limit"
                  : "You've used today's free replies",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFFD4C8DE),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            if (!usage.isPro)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => showPaywallSheet(context),
                    child: SizedBox(
                      height: 44,
                      child: Center(
                        child: Text(
                          'Upgrade to Pro',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else ...[
              Text(
                'Pro resets tomorrow. Practice stays free — or check You for status.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF9A8FA8),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => context.go('/you'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Open You',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// True when [message] looks like a usage / 402 soft limit (not a hard crash).
bool isUsageLimitMessage(String? message) {
  if (message == null || message.isEmpty) return false;
  final m = message.toLowerCase();
  return m.contains('today') &&
      (m.contains('free') ||
          m.contains('limit') ||
          m.contains('pro') ||
          m.contains('replies'));
}
