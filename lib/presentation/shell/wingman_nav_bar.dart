import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

class WingmanNavigationBar extends StatelessWidget {
  const WingmanNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCenterTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCenterTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: SizedBox(
          height: AppSpacing.navBarHeight,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.soft,
                ),
                child: Row(
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      selected: currentIndex == 0,
                      onTap: () => onTap(0),
                    ),
                    _NavItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'People',
                      selected: currentIndex == 1,
                      onTap: () => onTap(1),
                    ),
                    const SizedBox(width: 64),
                    _NavItem(
                      icon: Icons.fitness_center_rounded,
                      label: 'Practice',
                      selected: currentIndex == 2,
                      onTap: () => onTap(2),
                    ),
                    _NavItem(
                      icon: Icons.person_outline_rounded,
                      label: 'You',
                      selected: currentIndex == 3,
                      onTap: () => onTap(3),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                child: WingmanFloatingActionButton(onPressed: onCenterTap),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WingmanFloatingActionButton extends StatelessWidget {
  const WingmanFloatingActionButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Quick actions',
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.fabGradient,
            boxShadow: AppShadows.fab,
          ),
          child: const Icon(Icons.add_rounded, color: AppColors.textInverse, size: 30),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.textTertiary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
