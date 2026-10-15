import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/profile_audit.dart';
import '../../../domain/entities/user_profile.dart';
import '../../controllers/app_controller.dart';
import '../../widgets/wingman_buttons.dart';
import '../../widgets/wingman_cards.dart';
import '../../widgets/wingman_components.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppController>().profile;

    return WingmanScaffold(
      title: 'You',
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              WingmanAvatar(name: profile?.displayName ?? 'You', size: 56),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.displayName ?? 'You',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      profile?.planLabel ?? 'Free plan',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          WingmanButton(
            label: 'Go Pro',
            onPressed: () => context.push('/paywall'),
          ),
          const SizedBox(height: AppSpacing.xl),
          _tile(context, 'Recent replies', '/history'),
          _tile(context, 'Communication style', '/you/style'),
          _tile(context, 'Dating goals', '/you/goals'),
          _tile(context, 'Privacy & data', '/privacy'),
          _tile(context, 'Notifications', '/you/notifications'),
          _tile(context, 'Secure your account', '/you/account'),
          _tile(context, 'Subscription', '/you/subscription'),
          const SizedBox(height: AppSpacing.xl),
          Text('Danger zone', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          WingmanCard(
            onTap: () => context.push('/you/delete'),
            borderColor: AppColors.danger.withValues(alpha: 0.35),
            child: Text(
              'Delete my data',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.danger,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String label, String? route) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: WingmanCard(
        onTap: route == null ? null : () => context.push(route),
        child: Row(
          children: [
            Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class CommunicationStyleScreen extends StatelessWidget {
  const CommunicationStyleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final style = context.watch<AppController>().profile?.learnedStyle;

    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      title: 'Communication style',
      body: ListView(
        children: [
          Text(
            'These are AI estimates based on your interactions with Wingman.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          WingmanProgressBar(label: 'Humor', value: style?.humor ?? 0.5),
          const SizedBox(height: AppSpacing.md),
          WingmanProgressBar(label: 'Directness', value: style?.directness ?? 0.5),
          const SizedBox(height: AppSpacing.md),
          WingmanProgressBar(label: 'Flirting', value: style?.flirting ?? 0.5),
          const SizedBox(height: AppSpacing.md),
          WingmanProgressBar(label: 'Formality', value: style?.formality ?? 0.2),
          const SizedBox(height: AppSpacing.md),
          WingmanProgressBar(label: 'Emoji usage', value: style?.emojiUsage ?? 0.3),
          const SizedBox(height: AppSpacing.xl),
          WingmanSecondaryButton(
            label: 'Adjust manually',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Manual style adjustments saved locally.')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DatingGoalsSettingsScreen extends StatelessWidget {
  const DatingGoalsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goal = context.watch<AppController>().profile?.datingGoal;
    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      title: 'Dating goals',
      body: Text(
        goal?.label ?? 'Not set yet',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool? enabled;
  bool reminders = true;
  bool briefings = true;
  bool insights = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await context.read<AppController>().notifications.preferences();
    if (!mounted) return;
    setState(() {
      enabled = prefs.enabled;
      reminders = prefs.conversationReminders;
      briefings = prefs.dateBriefings;
      insights = prefs.insights;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      title: 'Notifications',
      body: ListView(
        children: [
          SwitchListTile(
            value: enabled ?? false,
            onChanged: (v) async {
              if (v) {
                final granted =
                    await context.read<AppController>().requestNotifications();
                setState(() => enabled = granted);
              } else {
                await context.read<AppController>().notifications.update(
                      (await context.read<AppController>().notifications.preferences())
                          .copyWith(enabled: false),
                    );
                setState(() => enabled = false);
              }
            },
            title: const Text('Enable notifications'),
            activeThumbColor: AppColors.accent,
          ),
          SwitchListTile(
            value: reminders,
            onChanged: (v) => setState(() => reminders = v),
            title: const Text('Conversation reminders'),
          ),
          SwitchListTile(
            value: briefings,
            onChanged: (v) => setState(() => briefings = v),
            title: const Text('Date briefings'),
          ),
          SwitchListTile(
            value: insights,
            onChanged: (v) => setState(() => insights = v),
            title: const Text('New insights'),
          ),
        ],
      ),
    );
  }
}

class AccountLinkingScreen extends StatelessWidget {
  const AccountLinkingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final anonymous =
        context.watch<AppController>().profile?.isAnonymous ?? true;

    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      title: 'Secure your account',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            anonymous
                ? 'You\'re using Wingman privately. Link an account to keep your progress across devices.'
                : 'Your account is linked.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          WingmanButton(
            label: 'Continue with Apple',
            onPressed: () async {
              final controller = context.read<AppController>();
              await controller.auth.linkApple();
              await controller.refreshProfile();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          WingmanSecondaryButton(
            label: 'Continue with Google',
            onPressed: () async {
              final controller = context.read<AppController>();
              await controller.auth.linkGoogle();
              await controller.refreshProfile();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          WingmanSecondaryButton(
            label: 'Continue with Email',
            onPressed: () async {
              final controller = context.read<AppController>();
              await controller.auth.linkEmail('user@example.com');
              await controller.refreshProfile();
            },
          ),
        ],
      ),
    );
  }
}

class PrivacyDataScreen extends StatelessWidget {
  const PrivacyDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      title: 'Privacy & data',
      body: ListView(
        children: [
          Text(
            'Screenshots are processed securely and deleted unless you explicitly save them. Wingman never automatically sends messages for you.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('• Conversation text is not logged to analytics'),
          const SizedBox(height: 8),
          const Text('• Raw screenshots stay out of analytics'),
          const SizedBox(height: 8),
          const Text('• You control what gets remembered'),
          const SizedBox(height: 8),
          const Text('• You can delete everything anytime'),
        ],
      ),
    );
  }
}

class DeleteDataScreen extends StatelessWidget {
  const DeleteDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      title: 'Delete my data',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This permanently removes your saved people, preferences, and local Wingman data from this device.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Spacer(),
          WingmanButton(
            label: 'Delete everything',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Delete my data?'),
                  content: const Text(
                    'This cannot be undone. Your conversation memory and preferences will be removed.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed != true || !context.mounted) return;
              final controller = context.read<AppController>();
              await controller.privacy.deleteAllUserData();
              await controller.auth.deleteAllData();
              if (context.mounted) context.go('/');
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          WingmanSecondaryButton(label: 'Cancel', onPressed: () => context.pop()),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class CoachInsightsScreen extends StatefulWidget {
  const CoachInsightsScreen({super.key});

  @override
  State<CoachInsightsScreen> createState() => _CoachInsightsScreenState();
}

class _CoachInsightsScreenState extends State<CoachInsightsScreen> {
  String _period = 'week';
  CoachingStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats =
        await context.read<AppController>().coachingService.stats(period: _period);
    if (!mounted) return;
    setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      title: 'Your dating patterns',
      body: stats == null
          ? const WingmanLoadingState()
          : ListView(
              children: [
                Row(
                  children: [
                    for (final period in ['week', 'month', 'all'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: WingmanChip(
                          label: period == 'week'
                              ? 'This week'
                              : period == 'month'
                                  ? 'This month'
                                  : 'All time',
                          selected: _period == period,
                          onSelected: (_) {
                            setState(() => _period = period);
                            _load();
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                WingmanProgressBar(label: 'You initiate', value: stats.youInitiate),
                const SizedBox(height: AppSpacing.md),
                WingmanProgressBar(
                  label: 'You ask questions',
                  value: stats.youAskQuestions,
                ),
                const SizedBox(height: AppSpacing.md),
                WingmanProgressBar(
                  label: 'They ask questions',
                  value: stats.theyAskQuestions,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Your strongest trait', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(stats.strongestTrait, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.lg),
                Text('Opportunity', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(stats.opportunity, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.xxl),
                WingmanButton(
                  label: 'Practice this',
                  onPressed: () => context.go('/practice'),
                ),
              ],
            ),
    );
  }
}

class SubscriptionManagementScreen extends StatelessWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      title: 'Subscription',
      body: FutureBuilder(
        future: context.read<AppController>().entitlementService.snapshot(),
        builder: (context, snapshot) {
          final isPro = snapshot.data?.isPro ?? false;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPro ? 'Wingman Pro' : 'Free plan',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'RevenueCat is the source of truth for paid access. Supabase stores account metadata only.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              if (!isPro)
                WingmanButton(
                  label: 'Start Pro',
                  onPressed: () => context.push('/paywall'),
                ),
              const SizedBox(height: AppSpacing.sm),
              WingmanSecondaryButton(
                label: 'Restore purchases',
                onPressed: () async {
                  final result = await context
                      .read<AppController>()
                      .subscriptionService
                      .restore();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message ?? 'Restored.'),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
