import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

class WingmanCard extends StatelessWidget {
  const WingmanCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.gradient = false,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool gradient;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding,
      decoration: BoxDecoration(
        color: gradient ? null : AppColors.surface,
        gradient: gradient ? AppColors.cardGradient : null,
        borderRadius: AppRadius.card,
        border: Border.all(color: borderColor ?? AppColors.borderSubtle),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: content,
      ),
    );
  }
}

class WingmanGlassCard extends StatelessWidget {
  const WingmanGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return WingmanCard(
      onTap: onTap,
      padding: padding,
      gradient: true,
      borderColor: AppColors.border,
      child: child,
    );
  }
}

class WingmanFeatureCard extends StatelessWidget {
  const WingmanFeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.emphasized = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return WingmanCard(
      onTap: onTap,
      gradient: emphasized,
      borderColor: emphasized ? AppColors.accent.withValues(alpha: 0.35) : null,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: emphasized ? AppColors.accentMuted : AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              icon,
              color: emphasized ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class WingmanSelectableCard extends StatelessWidget {
  const WingmanSelectableCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WingmanCard(
      onTap: onTap,
      borderColor: selected ? AppColors.accent.withValues(alpha: 0.55) : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.accent : Colors.transparent,
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.border,
                width: 1.5,
              ),
            ),
            child: selected
                ? const Icon(Icons.check, size: 14, color: AppColors.textInverse)
                : null,
          ),
        ],
      ),
    );
  }
}
