import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../widgets/wingman_cards.dart';

Future<void> showQuickActionsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
    builder: (context) => const QuickActionsSheet(),
  );
}

class QuickActionsSheet extends StatelessWidget {
  const QuickActionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.md,
          AppSpacing.screenHorizontal,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'What do you need?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            WingmanFeatureCard(
              title: 'Reply',
              subtitle: 'Analyze a conversation',
              icon: Icons.chat_bubble_outline_rounded,
              emphasized: true,
              onTap: () {
                Navigator.pop(context);
                context.push('/reply');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            WingmanFeatureCard(
              title: 'Opener',
              subtitle: 'Start a conversation',
              icon: Icons.waving_hand_outlined,
              onTap: () {
                Navigator.pop(context);
                context.push('/opener');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            WingmanFeatureCard(
              title: 'Profile',
              subtitle: 'Improve your profile',
              icon: Icons.badge_outlined,
              onTap: () {
                Navigator.pop(context);
                context.push('/profile-audit');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            WingmanFeatureCard(
              title: 'Practice',
              subtitle: 'Get better at dating',
              icon: Icons.fitness_center_rounded,
              onTap: () {
                Navigator.pop(context);
                context.go('/practice');
              },
            ),
          ],
        ),
      ),
    );
  }
}
