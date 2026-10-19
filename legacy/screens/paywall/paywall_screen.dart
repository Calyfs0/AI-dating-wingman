import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../services/subscription/subscription_services.dart';
import '../../controllers/app_controller.dart';
import '../../widgets/wingman_buttons.dart';
import '../../widgets/wingman_cards.dart';
import '../../widgets/wingman_components.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  List<SubscriptionPackage> _packages = [];
  SubscriptionPackage? _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final controller = context.read<AppController>();
    await controller.analytics.track('paywall_viewed');
    final offerings = await controller.subscriptionService.offerings();
    final packages =
        offerings.isEmpty ? <SubscriptionPackage>[] : offerings.first.packages;
    if (!mounted) return;
    setState(() {
      _packages = packages;
      _selected = packages.isNotEmpty ? packages.first : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const benefits = [
      'Unlimited conversation analysis',
      'Personal communication style',
      'Relationship memory',
      'Advanced coaching',
      'Profile intelligence',
      'Practice sessions',
      'Date preparation',
    ];

    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.close_rounded,
        onPressed: () => context.pop(),
      ),
      body: _loading
          ? const WingmanLoadingState()
          : ListView(
              children: [
                Text(
                  'Your wingman can go further.',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.xl),
                ...benefits.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppColors.accent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(b)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ..._packages.map(
                  (package) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: WingmanSelectableCard(
                      title: package.title,
                      subtitle: '${package.priceString} / ${package.period}',
                      selected: _selected?.id == package.id,
                      onTap: () => setState(() => _selected = package),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                WingmanButton(
                  label: 'Start Pro',
                  onPressed: _selected == null
                      ? null
                      : () async {
                          final result = await context
                              .read<AppController>()
                              .subscriptionService
                              .purchase(_selected!);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result.message ??
                                    'Connect RevenueCat to enable purchases.',
                              ),
                            ),
                          );
                        },
                ),
                const SizedBox(height: AppSpacing.sm),
                WingmanSecondaryButton(
                  label: 'Maybe later',
                  onPressed: () => context.pop(),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
    );
  }
}

/// Reusable paywall surface for embedding if needed.
class WingmanPaywall extends StatelessWidget {
  const WingmanPaywall({super.key});

  @override
  Widget build(BuildContext context) => const PaywallScreen();
}
