import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/user_profile.dart';
import '../../controllers/app_controller.dart';
import '../../widgets/wingman_buttons.dart';
import '../../widgets/wingman_cards.dart';
import '../../widgets/wingman_components.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppAnimations.splash);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.standard),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _goNext();
    });
    _controller.forward();
  }

  void _goNext() {
    if (!mounted || _navigated) return;
    _navigated = true;
    final profile = context.read<AppController>().profile;
    if (profile?.onboardingCompleted == true) {
      context.go('/home');
    } else {
      context.go('/onboarding/promise');
    }
  }

  @override
  void dispose() {
    _navigated = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.accentGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.28),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'W',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.textInverse,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Wingman', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Your private AI dating coach.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PromiseScreen extends StatelessWidget {
  const PromiseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WingmanScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardLarge,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accent.withValues(alpha: 0.18),
                  AppColors.surfaceElevated,
                ],
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 24,
                  top: 28,
                  child: _softBubble('Know what to say'),
                ),
                Positioned(
                  left: 24,
                  bottom: 36,
                  child: _softBubble('Become better at dating'),
                ),
                Positioned(
                  left: 40,
                  top: 88,
                  child: Icon(
                    Icons.forum_outlined,
                    size: 48,
                    color: AppColors.accent.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Dating shouldn\'t feel like guessing.',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Understand conversations.\nFind the right words.\nBecome better at dating.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
          ),
          const Spacer(),
          WingmanButton(
            label: 'Let\'s go',
            onPressed: () => context.go('/onboarding/focus'),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _softBubble(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
    );
  }
}

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final Set<FocusArea> _selected = {};

  @override
  Widget build(BuildContext context) {
    return WingmanScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            'What do you want help with?',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Select all that apply.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: ListView.separated(
              itemCount: FocusArea.values.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final area = FocusArea.values[index];
                final selected = _selected.contains(area);
                return WingmanSelectableCard(
                  title: area.title,
                  subtitle: area.subtitle,
                  selected: selected,
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selected.remove(area);
                      } else {
                        _selected.add(area);
                      }
                    });
                  },
                );
              },
            ),
          ),
          WingmanButton(
            label: 'Continue',
            onPressed: _selected.isEmpty
                ? null
                : () async {
                    await context.read<AppController>().saveOnboarding(
                          (p) => p.copyWith(focusAreas: _selected.toList()),
                        );
                    if (context.mounted) context.go('/onboarding/style');
                  },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class StyleOnboardingScreen extends StatefulWidget {
  const StyleOnboardingScreen({super.key});

  @override
  State<StyleOnboardingScreen> createState() => _StyleOnboardingScreenState();
}

class _StyleOnboardingScreenState extends State<StyleOnboardingScreen> {
  static const styles = [
    'Chill',
    'Funny',
    'Flirty',
    'Sarcastic',
    'Direct',
    'Romantic',
  ];
  final Set<String> _selected = {};
  double _flirting = 0.5;

  @override
  Widget build(BuildContext context) {
    return WingmanScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            'How do you normally communicate?',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: styles
                .map(
                  (s) => WingmanChip(
                    label: s,
                    selected: _selected.contains(s),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selected.add(s);
                        } else {
                          _selected.remove(s);
                        }
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'How much flirting feels natural to you?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('Low', style: Theme.of(context).textTheme.labelSmall),
              Expanded(
                child: Slider(
                  value: _flirting,
                  onChanged: (v) => setState(() => _flirting = v),
                ),
              ),
              Text('High', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          const Spacer(),
          Text(
            'This is only a starting point. Wingman learns your real style from feedback.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          WingmanButton(
            label: 'Continue',
            onPressed: _selected.isEmpty
                ? null
                : () async {
                    await context.read<AppController>().saveOnboarding(
                          (p) => p.copyWith(
                            communicationStyles: _selected.toList(),
                            flirtingLevel: _flirting,
                            learnedStyle: p.learnedStyle.copyWith(flirting: _flirting),
                          ),
                        );
                    if (context.mounted) context.go('/onboarding/goal');
                  },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  DatingGoal? _selected;

  @override
  Widget build(BuildContext context) {
    return WingmanScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            'What are you looking for?',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: ListView.separated(
              itemCount: DatingGoal.values.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final goal = DatingGoal.values[index];
                return WingmanSelectableCard(
                  title: goal.label,
                  selected: _selected == goal,
                  onTap: () => setState(() => _selected = goal),
                );
              },
            ),
          ),
          WingmanButton(
            label: 'Continue',
            onPressed: _selected == null
                ? null
                : () async {
                    await context.read<AppController>().saveOnboarding(
                          (p) => p.copyWith(datingGoal: _selected),
                        );
                    if (context.mounted) context.go('/onboarding/privacy');
                  },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class PrivacyOnboardingScreen extends StatelessWidget {
  const PrivacyOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const points = [
      'Screenshots are processed securely.',
      'We don\'t sell your conversation data.',
      'You control what\'s saved.',
      'You can delete your data anytime.',
      'AI suggestions are never automatically sent.',
    ];

    return WingmanScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accentMuted,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
              ),
              child: const Icon(Icons.shield_outlined, color: AppColors.accent, size: 34),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Your conversations are yours.',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: AppSpacing.xl),
          ...points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(p, style: Theme.of(context).textTheme.bodyLarge),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          WingmanButton(
            label: 'Keep it private',
            onPressed: () => context.go('/onboarding/notifications'),
          ),
          WingmanTextButton(
            label: 'Learn more',
            onPressed: () => context.push('/privacy'),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class NotificationsOnboardingScreen extends StatelessWidget {
  const NotificationsOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AppController>();
    return WingmanScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(
            'Want your wingman nearby?',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Get reminders for conversations you\'ve chosen to keep track of.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const Spacer(),
          WingmanButton(
            label: 'Allow notifications',
            onPressed: () async {
              await controller.requestNotifications();
              await controller.completeOnboarding();
              if (context.mounted) context.go('/home');
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          WingmanSecondaryButton(
            label: 'Not now',
            onPressed: () async {
              await controller.completeOnboarding();
              if (context.mounted) context.go('/home');
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
