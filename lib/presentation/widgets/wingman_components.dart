import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/person.dart';
import '../../core/utils/greeting.dart';

class WingmanScaffold extends StatelessWidget {
  const WingmanScaffold({
    super.key,
    required this.body,
    this.title,
    this.leading,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.padding,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry? padding;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null || leading != null || actions != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.sm,
                    AppSpacing.screenHorizontal,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      if (title != null)
                        Expanded(
                          child: Text(
                            title!,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        )
                      else
                        const Spacer(),
                      if (actions != null) ...actions!,
                    ],
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: padding ??
                      const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                      ),
                  child: body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WingmanChip extends StatelessWidget {
  const WingmanChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: AppColors.accentMuted,
      backgroundColor: AppColors.surfaceElevated,
      side: BorderSide(
        color: selected ? AppColors.accent.withValues(alpha: 0.5) : AppColors.border,
      ),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }
}

class WingmanProgressBar extends StatelessWidget {
  const WingmanProgressBar({
    super.key,
    required this.label,
    required this.value,
    this.showPercent = true,
  });

  final String label;
  final double value;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Semantics(
      label: '$label ${(clamped * 100).round()} percent',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: Theme.of(context).textTheme.labelMedium),
              ),
              if (showPercent)
                Text(
                  '${(clamped * 100).round()}%',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 6,
              backgroundColor: AppColors.surfaceHighlight,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class WingmanMetric extends StatelessWidget {
  const WingmanMetric({
    super.key,
    required this.label,
    required this.value,
    this.suffix = '',
  });

  final String label;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(
          '$value$suffix',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }
}

class WingmanAvatar extends StatelessWidget {
  const WingmanAvatar({
    super.key,
    required this.name,
    this.size = 48,
    this.imageUrl,
  });

  final String name;
  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return Semantics(
      label: '$name avatar',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.accentGradient,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textInverse,
                fontSize: size * 0.38,
              ),
        ),
      ),
    );
  }
}

class WingmanSectionHeader extends StatelessWidget {
  const WingmanSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              minimumSize: const Size(44, 44),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class WingmanPersonCard extends StatelessWidget {
  const WingmanPersonCard({
    super.key,
    required this.person,
    this.onTap,
  });

  final Person person;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              WingmanAvatar(name: person.name),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(person.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${person.status.momentumLabel} · ${relativeActivityLabel(person.lastActivityAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (person.latestContext != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        person.latestContext!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class WingmanInsightCard extends StatelessWidget {
  const WingmanInsightCard({
    super.key,
    required this.title,
    required this.body,
    this.ctaLabel = 'See insight',
    this.onCta,
  });

  final String title;
  final String body;
  final String ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: onCta,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
            ),
            child: Text(ctaLabel),
          ),
        ],
      ),
    );
  }
}

class WingmanMessageBubble extends StatelessWidget {
  const WingmanMessageBubble({
    super.key,
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accentDeep : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
      ),
    );
  }
}

class WingmanTextField extends StatelessWidget {
  const WingmanTextField({
    super.key,
    this.controller,
    this.hint,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.suffix,
  });

  final TextEditingController? controller;
  final String? hint;
  final int maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      minLines: minLines,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffix,
      ),
    );
  }
}

class WingmanLoadingState extends StatelessWidget {
  const WingmanLoadingState({
    super.key,
    this.message = 'Working on it...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class WingmanEmptyState extends StatelessWidget {
  const WingmanEmptyState({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.nightlight_round,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, color: AppColors.accent),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class WingmanErrorState extends StatelessWidget {
  const WingmanErrorState({
    super.key,
    this.title = 'Something went wrong.',
    this.body = 'Your conversation wasn\'t lost.\nTry again.',
    this.primaryLabel = 'Try again',
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh_rounded, color: AppColors.warning, size: 36),
            const SizedBox(height: AppSpacing.md),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            if (onPrimary != null)
              FilledButton(
                onPressed: onPrimary,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.textInverse,
                  minimumSize: const Size(160, 48),
                  shape: const StadiumBorder(),
                ),
                child: Text(primaryLabel),
              ),
            if (secondaryLabel != null && onSecondary != null)
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
          ],
        ),
      ),
    );
  }
}

class WingmanOfflineBanner extends StatelessWidget {
  const WingmanOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.warningMuted,
      child: Text(
        'You\'re offline. Some features will resume when you reconnect.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.warning,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
