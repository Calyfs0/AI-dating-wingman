import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/practice.dart';
import '../../controllers/app_controller.dart';
import '../../widgets/wingman_buttons.dart';
import '../../widgets/wingman_cards.dart';
import '../../widgets/wingman_components.dart';

class PracticeHomeScreen extends StatelessWidget {
  const PracticeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WingmanScaffold(
      title: 'What do you want to practice?',
      body: ListView.separated(
        padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.huge),
        itemCount: PracticeTopic.values.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final topic = PracticeTopic.values[index];
          return WingmanFeatureCard(
            title: topic.title,
            subtitle: topic.description,
            icon: Icons.self_improvement_rounded,
            onTap: () => context.push('/practice/session', extra: topic),
          );
        },
      ),
    );
  }
}

class PracticeSessionScreen extends StatefulWidget {
  const PracticeSessionScreen({super.key, required this.topic});

  final PracticeTopic topic;

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
  PracticeSession? _session;
  final _controller = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final controller = context.read<AppController>();
    final session = await controller.practiceService.start(widget.topic);
    await controller.analytics.track('practice_started');
    if (!mounted) return;
    setState(() {
      _session = session;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _session == null) {
      return const WingmanScaffold(body: WingmanLoadingState());
    }

    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('End'),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.topic == PracticeTopic.firstDate
                ? 'First date simulation'
                : widget.topic.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              WingmanAvatar(name: _session!.personaName, size: 40),
              const SizedBox(width: AppSpacing.sm),
              Text(_session!.personaName, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          WingmanMessageBubble(text: _session!.prompt, isUser: false),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: WingmanTextField(
                  controller: _controller,
                  hint: 'Type your response...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              WingmanIconButton(
                icon: Icons.mic_none_rounded,
                tooltip: 'Microphone',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Microphone is ready for device wiring.'),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          WingmanButton(
            label: 'Send',
            onPressed: _controller.text.trim().isEmpty
                ? null
                : () async {
                    final controller = context.read<AppController>();
                    final response = _controller.text.trim();
                    final feedback = await controller.practiceService.evaluate(
                      session: _session!,
                      response: response,
                    );
                    await controller.analytics.track('practice_completed');
                    if (!context.mounted) return;
                    context.push(
                      '/practice/feedback',
                      extra: {
                        'response': response,
                        'feedback': feedback,
                        'topic': widget.topic,
                      },
                    );
                  },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class PracticeFeedbackScreen extends StatelessWidget {
  const PracticeFeedbackScreen({
    super.key,
    required this.response,
    required this.feedback,
    required this.topic,
  });

  final String response;
  final PracticeFeedback feedback;
  final PracticeTopic topic;

  @override
  Widget build(BuildContext context) {
    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.go('/practice'),
      ),
      body: ListView(
        children: [
          Text('Your response', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          WingmanCard(
            child: Text(response, style: Theme.of(context).textTheme.bodyLarge),
          ),
          const SizedBox(height: AppSpacing.xl),
          _score(context, 'Confidence', feedback.confidence),
          _score(context, 'Naturalness', feedback.naturalness),
          _score(context, 'Conversation', feedback.conversation),
          const SizedBox(height: AppSpacing.lg),
          Text(feedback.summary, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.xxl),
          WingmanButton(
            label: 'Try again',
            onPressed: () => context.push('/practice/session', extra: topic),
          ),
        ],
      ),
    );
  }

  Widget _score(BuildContext context, String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(
            '${value.toStringAsFixed(0)}/10',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
