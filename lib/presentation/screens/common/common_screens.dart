import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/wingman_buttons.dart';
import '../../widgets/wingman_components.dart';

class GenericErrorScreen extends StatelessWidget {
  const GenericErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WingmanScaffold(
      body: WingmanErrorState(
        onPrimary: () => context.go('/home'),
        secondaryLabel: 'Go back',
        onSecondary: () => context.pop(),
      ),
    );
  }
}

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WingmanScaffold(
      body: Column(
        children: [
          const WingmanOfflineBanner(),
          const Expanded(
            child: WingmanEmptyState(
              title: 'You\'re offline.',
              body:
                  'Wingman will resume analysis and syncing when you reconnect. Your work isn\'t lost.',
              icon: Icons.wifi_off_rounded,
            ),
          ),
          WingmanButton(label: 'Back to Home', onPressed: () => context.go('/home')),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class EmptyStatesGalleryScreen extends StatelessWidget {
  const EmptyStatesGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WingmanScaffold(
      title: 'Empty states',
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      body: ListView(
        children: const [
          WingmanEmptyState(
            title: 'No people yet.',
            body:
                'Save a conversation and Wingman can remember useful context for you.',
            icon: Icons.people_outline,
          ),
          WingmanEmptyState(
            title: 'Ready when you are.',
            body: 'Choose something to practice.',
            icon: Icons.self_improvement_rounded,
          ),
          WingmanEmptyState(
            title: 'Your insights will appear as Wingman learns how you communicate.',
            body: '',
            icon: Icons.auto_awesome,
          ),
        ],
      ),
    );
  }
}
