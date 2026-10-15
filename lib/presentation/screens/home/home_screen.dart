import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/greeting.dart';
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
                  'Know what to say next.',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Screenshot a chat. Wingman writes a reply you can actually send.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      controller.analytics.track('reply_started');
                      context.push('/reply');
                    },
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: Ink(
                      height: 168,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        gradient: AppColors.accentGradient,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppColors.textInverse,
                              size: 28,
                            ),
                            const Spacer(),
                            Text(
                              'Help me reply',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(color: AppColors.textInverse),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload a screenshot',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textInverse
                                        .withValues(alpha: 0.85),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                WingmanSectionHeader(
                  title: 'Your people',
                  actionLabel: people.isEmpty ? null : 'See all',
                  onAction:
                      people.isEmpty ? null : () => context.go('/people'),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (people.isEmpty)
                  const WingmanEmptyState(
                    title: 'No people yet.',
                    body:
                        'After a reply, save the chat and Wingman will remember them here.',
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
