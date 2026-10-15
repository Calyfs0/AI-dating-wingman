import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/user_profile.dart';
import '../../controllers/app_controller.dart';
import '../../widgets/wingman_buttons.dart';
import '../../widgets/wingman_cards.dart';
import '../../widgets/wingman_components.dart';
import '../../widgets/wingman_logo.dart';

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
  late final Animation<double> _progress;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.standard),
    );
    _progress = Tween<double>(begin: 0.08, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _goNext();
    });
    _controller.forward();
  }

  void _goNext() {
    if (!mounted || _navigated) return;
    final app = context.read<AppController>();
    if (app.isBootstrapping) {
      void listener() {
        if (!app.isBootstrapping) {
          app.removeListener(listener);
          _goNext();
        }
      }
      app.addListener(listener);
      return;
    }
    _navigated = true;
    final profile = app.profile;
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
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _scale,
                child: Column(
                  children: [
                    const WingmanLogoMark(size: 96),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Wingman',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Your private AI dating coach.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(48, 0, 48, 36),
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) =>
                      WingmanThinProgressBar(value: _progress.value),
                ),
              ),
            ],
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed atmospheric hero plane (mockup: dating/conversation visual)
          DecoratedBox(
            decoration: const BoxDecoration(gradient: AppColors.heroAtmosphere),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _PromiseAtmospherePainter()),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 5),
                  Text(
                    'Dating shouldn\'t\nfeel like guessing.',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          height: 1.15,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Understand conversations.\nFind the right words.\nBecome better at dating.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.55,
                        ),
                  ),
                  const Spacer(flex: 2),
                  WingmanButton(
                    label: 'Let\'s go',
                    onPressed: () => context.go('/onboarding/focus'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromiseAtmospherePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final soft = Paint()..color = AppColors.accent.withValues(alpha: 0.12);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.22), 90, soft);
    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.34), 60, soft);

    final figure = Paint()..color = Colors.white.withValues(alpha: 0.06);
    final left = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(size.width * 0.38, size.height * 0.28),
        width: 54,
        height: 54,
      ))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * 0.38, size.height * 0.40),
            width: 78,
            height: 100,
          ),
          const Radius.circular(40),
        ),
      );
    final right = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(size.width * 0.58, size.height * 0.26),
        width: 50,
        height: 50,
      ))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * 0.58, size.height * 0.38),
            width: 72,
            height: 96,
          ),
          const Radius.circular(40),
        ),
      );
    canvas.drawPath(left, figure);
    canvas.drawPath(right, figure);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final Set<FocusArea> _selected = {};

  IconData _iconFor(FocusArea area) => switch (area) {
        FocusArea.conversations => Icons.forum_outlined,
        FocusArea.confidence => Icons.psychology_outlined,
        FocusArea.dating => Icons.favorite_border_rounded,
        FocusArea.meetPeople => Icons.diversity_3_outlined,
      };

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
          Text(
            'Select all that apply.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.92,
              children: FocusArea.values.map((area) {
                final selected = _selected.contains(area);
                return WingmanCard(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selected.remove(area);
                      } else {
                        _selected.add(area);
                      }
                    });
                  },
                  borderColor: selected
                      ? AppColors.accent.withValues(alpha: 0.55)
                      : null,
                  gradient: selected,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accentMuted
                              : AppColors.surfaceHighlight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _iconFor(area),
                          color: selected
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(area.title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        area.subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                      ),
                    ],
                  ),
                );
              }).toList(),
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
            spacing: 10,
            runSpacing: 10,
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
                            learnedStyle:
                                p.learnedStyle.copyWith(flirting: _flirting),
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
                final selected = _selected == goal;
                return WingmanCard(
                  onTap: () => setState(() => _selected = goal),
                  borderColor: selected
                      ? AppColors.accent.withValues(alpha: 0.55)
                      : null,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          goal.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      AnimatedContainer(
                        duration: AppAnimations.fast,
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
                            ? const Icon(
                                Icons.circle,
                                size: 10,
                                color: AppColors.textInverse,
                              )
                            : null,
                      ),
                    ],
                  ),
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
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.accentMuted,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: AppColors.accent,
                size: 38,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Your conversations are yours.',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          ...points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  ),
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
          const SizedBox(height: AppSpacing.xxl),
          const WingmanMockNotificationCard(),
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
