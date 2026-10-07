import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/greeting.dart';
import '../../../data/mock/demo_data.dart';
import '../../controllers/app_controller.dart';
import '../../widgets/wingman_buttons.dart';
import '../../widgets/wingman_components.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final profile = controller.profile;
    final people = controller.people.take(3).toList();
    final name = profile?.displayName ?? 'You';

    return WingmanScaffold(
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          if (!controller.isOnline) const WingmanOfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.sm,
                AppSpacing.screenHorizontal,
                AppSpacing.huge,
              ),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${timeOfDayGreeting()}, $name',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    WingmanIconButton(
                      icon: Icons.settings_outlined,
                      tooltip: 'Settings',
                      onPressed: () => context.go('/you'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'What are we working on?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                // Mockup: 2×2 quick-action tiles
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  children: [
                    _ActionTile(
                      title: 'Reply',
                      subtitle: 'Upload a conversation.\nI\'ll tell you what to say.',
                      icon: Icons.chat_bubble_outline_rounded,
                      emphasized: true,
                      onTap: () {
                        controller.analytics.track('reply_started');
                        context.push('/reply');
                      },
                    ),
                    _ActionTile(
                      title: 'Analyze',
                      subtitle: 'What\'s actually happening?',
                      icon: Icons.insights_outlined,
                      onTap: () => context.push('/reply'),
                    ),
                    _ActionTile(
                      title: 'Opener',
                      subtitle: 'Start the conversation right.',
                      icon: Icons.waving_hand_outlined,
                      onTap: () => context.push('/opener'),
                    ),
                    _ActionTile(
                      title: 'Profile',
                      subtitle: 'Improve your dating profile.',
                      icon: Icons.badge_outlined,
                      onTap: () => context.push('/profile-audit'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                WingmanSectionHeader(
                  title: 'Your people',
                  actionLabel: 'See all',
                  onAction: () => context.go('/people'),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (people.isEmpty)
                  const WingmanEmptyState(
                    title: 'No people yet.',
                    body:
                        'Save a conversation and Wingman can remember useful context for you.',
                    icon: Icons.people_outline,
                  )
                else
                  ...people.map(
                    (person) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: WingmanPersonCard(
                        person: person,
                        onTap: () => context.push('/people/${person.id}'),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sectionGap),
                WingmanInsightCard(
                  title: DemoData.homeInsight.title,
                  body: DemoData.homeInsight.body,
                  ctaLabel: DemoData.homeInsight.ctaLabel,
                  onCta: () => context.push('/insights'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.emphasized = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: emphasized
              ? AppColors.accent.withValues(alpha: 0.4)
              : AppColors.borderSubtle,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: emphasized
                      ? AppColors.accentMuted
                      : AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: emphasized ? AppColors.accent : AppColors.textSecondary,
                  size: 20,
                ),
              ),
              const Spacer(),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
