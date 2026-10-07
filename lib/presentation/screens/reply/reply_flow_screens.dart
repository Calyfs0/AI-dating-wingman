import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/ai_generation.dart';
import '../../../domain/entities/conversation.dart';
import '../../../services/ai/ai_services.dart';
import '../../controllers/app_controller.dart';
import '../../widgets/wingman_buttons.dart';
import '../../widgets/wingman_cards.dart';
import '../../widgets/wingman_components.dart';
import '../../widgets/wingman_logo.dart';

class AddConversationScreen extends StatefulWidget {
  const AddConversationScreen({super.key});

  @override
  State<AddConversationScreen> createState() => _AddConversationScreenState();
}

class _AddConversationScreenState extends State<AddConversationScreen> {
  final List<XFile> _images = [];
  final _textController = TextEditingController();
  bool _showPaste = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool get _hasInput => _images.isNotEmpty || _textController.text.trim().isNotEmpty;

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    if (source == ImageSource.gallery) {
      final files = await picker.pickMultiImage(imageQuality: 85);
      if (files.isEmpty) return;
      setState(() {
        _images.addAll(files.take(10 - _images.length));
      });
    } else {
      final file = await picker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;
      setState(() {
        if (_images.length < 10) _images.add(file);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      body: ListView(
        children: [
          Text(
            'Show me the conversation',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Upload a screenshot, paste text,\nor take a photo.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          WingmanDashedDropZone(
            onTap: () => _pick(ImageSource.gallery),
            label: 'Drop screenshots here',
            subtitle: '1–10 images · or choose below',
          ),
          const SizedBox(height: AppSpacing.lg),
          WingmanFeatureCard(
            title: 'From Photos',
            subtitle: 'Select one or more screenshots',
            icon: Icons.photo_library_outlined,
            onTap: () => _pick(ImageSource.gallery),
          ),
          const SizedBox(height: AppSpacing.sm),
          WingmanFeatureCard(
            title: 'Take a Photo',
            subtitle: 'Capture the conversation',
            icon: Icons.photo_camera_outlined,
            onTap: () => _pick(ImageSource.camera),
          ),
          const SizedBox(height: AppSpacing.sm),
          WingmanFeatureCard(
            title: 'Paste Text',
            subtitle: 'Drop the messages in directly',
            icon: Icons.content_paste_rounded,
            onTap: () => setState(() => _showPaste = !_showPaste),
          ),
          if (_showPaste) ...[
            const SizedBox(height: AppSpacing.md),
            WingmanTextField(
              controller: _textController,
              hint: 'Paste the conversation here...',
              maxLines: 8,
              minLines: 5,
              onChanged: (_) => setState(() {}),
            ),
          ],
          if (_images.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Selected', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.image_outlined, color: AppColors.textTertiary),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(index)),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.surface,
                            child: Icon(Icons.close, size: 14, color: AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          WingmanButton(
            label: 'Analyze conversation',
            onPressed: !_hasInput
                ? null
                : () {
                    context.push(
                      '/reply/processing',
                      extra: {
                        'images': _images.map((e) => e.path).toList(),
                        'text': _textController.text.trim(),
                      },
                    );
                  },
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({
    super.key,
    this.imagePaths = const [],
    this.pastedText,
  });

  final List<String> imagePaths;
  final String? pastedText;

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  ProcessingStage _stage = ProcessingStage.extracting;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final controller = context.read<AppController>();
    try {
      await for (final stage in controller.processConversation(
        imagePaths: widget.imagePaths,
        pastedText: widget.pastedText,
      )) {
        if (!mounted) return;
        setState(() => _stage = stage);
      }
      final conversation = await controller.finishAnalysis(
        imagePaths: widget.imagePaths,
        pastedText: widget.pastedText,
      );
      if (!mounted) return;
      if (conversation == null) {
        setState(() => _failed = true);
        return;
      }
      context.go('/reply/analysis');
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return WingmanScaffold(
        body: WingmanErrorState(
          title: 'Couldn\'t read this conversation.',
          body: 'Try a clearer screenshot or paste the text instead.',
          primaryLabel: 'Try again',
          onPrimary: () {
            setState(() {
              _failed = false;
              _stage = ProcessingStage.extracting;
            });
            _run();
          },
          secondaryLabel: 'Paste text',
          onSecondary: () => context.go('/reply'),
        ),
      );
    }

    final stages = [
      ProcessingStage.extracting,
      ProcessingStage.understanding,
      ProcessingStage.analyzing,
      ProcessingStage.building,
    ];

    final stageIndex = stages.indexOf(_stage).clamp(0, stages.length - 1);
    final progress = (stageIndex + 1) / stages.length;

    return WingmanScaffold(
      body: Column(
        children: [
          const Spacer(),
          WingmanCircularProgress(
            size: 128,
            progress: progress,
            child: Icon(
              Icons.auto_awesome,
              color: AppColors.accent,
              size: 36,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Reading the conversation...',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xxl),
          ...stages.map((stage) {
            final active = stages.indexOf(stage) <= stageIndex;
            final current = stage == _stage;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? AppColors.accent : AppColors.surfaceHighlight,
                    ),
                    child: current
                        ? const Padding(
                            padding: EdgeInsets.all(4),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textInverse,
                            ),
                          )
                        : active
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: AppColors.textInverse,
                              )
                            : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    stage.label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: active
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                        ),
                  ),
                ],
              ),
            );
          }),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class AnalysisOverviewScreen extends StatelessWidget {
  const AnalysisOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final conversation = context.watch<AppController>().activeConversation;
    if (conversation == null) {
      return WingmanScaffold(
        body: WingmanErrorState(
          title: 'No conversation loaded.',
          onPrimary: () => context.go('/reply'),
        ),
      );
    }
    final signals = conversation.interestSignals;
    final strategy = conversation.recommendedStrategy;

    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.go('/home'),
      ),
      body: ListView(
        children: [
          Text(conversation.personName, style: Theme.of(context).textTheme.headlineMedium),
          Text(
            '${conversation.platform} · Active',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Mockup: conversation snippet before metrics
          if (conversation.messages.isNotEmpty) ...[
            WingmanCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: conversation.messages.take(3).map((m) {
                  return WingmanMessageBubble(
                    text: m.text,
                    isUser: m.speaker == MessageSpeaker.user,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          WingmanProgressBar(label: 'Interest', value: signals.interest),
          const SizedBox(height: AppSpacing.md),
          WingmanProgressBar(label: 'Energy', value: signals.energy),
          const SizedBox(height: AppSpacing.md),
          WingmanProgressBar(label: 'Momentum', value: signals.momentum),
          const SizedBox(height: AppSpacing.md),
          WingmanProgressBar(label: 'Reciprocity', value: signals.reciprocity),
          const SizedBox(height: AppSpacing.md),
          Text(
            'AI estimates based on conversation signals, not certainty about someone\'s feelings.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('My read', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(strategy.read, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.xl),
          Text('Your next move', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text('Do', style: Theme.of(context).textTheme.titleMedium),
          ...strategy.dos.map(
            (item) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('✓ $item', style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Don\'t', style: Theme.of(context).textTheme.titleMedium),
          ...strategy.donts.map(
            (item) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('× $item', style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          WingmanSecondaryButton(
            label: 'What do they mean?',
            onPressed: () => context.push('/reply/interpret'),
          ),
          const SizedBox(height: AppSpacing.sm),
          WingmanButton(
            label: 'See recommended responses',
            onPressed: () => context.push('/reply/next-move'),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class NextMoveScreen extends StatelessWidget {
  const NextMoveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final conversation = context.watch<AppController>().activeConversation;
    final strategy = conversation?.recommendedStrategy;

    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      body: ListView(
        children: [
          Text('Your next move', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpacing.xl),
          Text('Do', style: Theme.of(context).textTheme.titleLarge),
          ...(strategy?.dos ?? const [
            'Make a playful observation.',
            'Give her something easy to respond to.',
          ]).map(
            (e) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('✓ $e', style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Don\'t', style: Theme.of(context).textTheme.titleLarge),
          ...(strategy?.donts ?? const [
            'Ask another interview-style question.',
            'Over-compliment.',
          ]).map(
            (e) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('× $e', style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ...ResponseTone.values.map(
            (tone) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: WingmanFeatureCard(
                title: tone.title,
                subtitle: tone.subtitle,
                icon: Icons.auto_awesome,
                emphasized: tone == ResponseTone.yourStyle,
                onTap: () async {
                  await context.read<AppController>().generateResponse(tone);
                  if (context.mounted) context.push('/reply/response');
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class ResponseDetailScreen extends StatefulWidget {
  const ResponseDetailScreen({super.key});

  @override
  State<ResponseDetailScreen> createState() => _ResponseDetailScreenState();
}

class _ResponseDetailScreenState extends State<ResponseDetailScreen> {
  int _altIndex = 0;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final generation = controller.activeGeneration;
    if (generation == null) {
      return WingmanScaffold(
        body: WingmanErrorState(
          onPrimary: () => context.go('/reply/next-move'),
        ),
      );
    }

    final alternatives = [generation.text, ...generation.alternatives];
    final text = alternatives[_altIndex.clamp(0, alternatives.length - 1)];

    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recommended response', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                setState(() {
                  if (details.primaryVelocity! < 0) {
                    _altIndex = (_altIndex + 1).clamp(0, alternatives.length - 1);
                  } else {
                    _altIndex = (_altIndex - 1).clamp(0, alternatives.length - 1);
                  }
                });
              },
              child: WingmanGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text, style: Theme.of(context).textTheme.headlineSmall),
                    const Spacer(),
                    Text(
                      'Swipe for alternatives · ${_altIndex + 1}/${alternatives.length}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: WingmanSecondaryButton(
                  label: 'Copy',
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    await controller.trackCopy();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied. Send it yourself when ready.')),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: WingmanSecondaryButton(
                  label: 'Edit',
                  onPressed: () => context.push('/reply/review'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          WingmanButton(
            label: 'Make it sound like me',
            isLoading: _loading,
            onPressed: () async {
              setState(() => _loading = true);
              await controller.humanizeActive();
              setState(() {
                _loading = false;
                _altIndex = 0;
              });
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('More playful'),
                onPressed: () async {
                  await controller.regenerate('playful');
                  setState(() => _altIndex = 0);
                },
              ),
              ActionChip(
                label: const Text('More natural'),
                onPressed: () async {
                  await controller.regenerate('natural');
                  setState(() => _altIndex = 0);
                },
              ),
              ActionChip(
                label: const Text('Try another'),
                onPressed: () async {
                  await controller.regenerate('another');
                  setState(() => _altIndex = 0);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              IconButton(
                tooltip: 'Helpful',
                onPressed: () => controller.submitFeedback(isPositive: true),
                icon: const Icon(Icons.thumb_up_alt_outlined),
              ),
              IconButton(
                tooltip: 'Not helpful',
                onPressed: () => _showFeedbackSheet(context, controller),
                icon: const Icon(Icons.thumb_down_alt_outlined),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/reply/save'),
                child: const Text('Save to person'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Future<void> _showFeedbackSheet(
    BuildContext context,
    AppController controller,
  ) async {
    final selected = <FeedbackIssue>{};
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What was wrong?', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: FeedbackIssue.values.map((issue) {
                      final isSelected = selected.contains(issue);
                      return WingmanChip(
                        label: issue.label,
                        selected: isSelected,
                        onSelected: (v) {
                          setModalState(() {
                            if (v) {
                              selected.add(issue);
                            } else {
                              selected.remove(issue);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  WingmanButton(
                    label: 'Submit',
                    onPressed: () async {
                      await controller.submitFeedback(
                        isPositive: false,
                        issues: selected.toList(),
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class InterpretMessageScreen extends StatefulWidget {
  const InterpretMessageScreen({super.key});

  @override
  State<InterpretMessageScreen> createState() => _InterpretMessageScreenState();
}

class _InterpretMessageScreenState extends State<InterpretMessageScreen> {
  String _selected = 'haha yeah maybe';
  String? _interpretation;
  String? _guidance;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() => _loading = true);
    final result = await context
        .read<AppController>()
        .analysisService
        .interpretMessage(_selected);
    if (!mounted) return;
    setState(() {
      _interpretation = result.interpretation;
      _guidance = result.guidance;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages =
        context.watch<AppController>().activeConversation?.messages ?? [];

    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      body: ListView(
        children: [
          Text('What does this mean?', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpacing.md),
          if (messages.isNotEmpty)
            ...messages.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: WingmanCard(
                  onTap: () {
                    setState(() => _selected = m.text);
                    _run();
                  },
                  borderColor: _selected == m.text
                      ? AppColors.accent.withValues(alpha: 0.5)
                      : null,
                  child: Text('"${m.text}"'),
                ),
              ),
            )
          else
            WingmanCard(child: Text('"$_selected"')),
          const SizedBox(height: AppSpacing.lg),
          if (_loading)
            const WingmanLoadingState(message: 'Reading the signal...')
          else ...[
            Text(
              _interpretation ?? '',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _guidance ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            WingmanButton(
              label: 'What should I send?',
              onPressed: () => context.push('/reply/next-move'),
            ),
          ],
        ],
      ),
    );
  }
}

class ReviewBeforeSendScreen extends StatefulWidget {
  const ReviewBeforeSendScreen({super.key});

  @override
  State<ReviewBeforeSendScreen> createState() => _ReviewBeforeSendScreenState();
}

class _ReviewBeforeSendScreenState extends State<ReviewBeforeSendScreen> {
  final _controller = TextEditingController(
    text: 'You look really beautiful in that dress.',
  );
  bool _loading = false;
  String? _verdict;
  String? _why;
  String? _better;
  double? _score;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _review() async {
    setState(() => _loading = true);
    final result = await context
        .read<AppController>()
        .analysisService
        .reviewBeforeSend(_controller.text.trim());
    if (!mounted) return;
    setState(() {
      _verdict = result.verdict;
      _why = result.why;
      _better = result.better;
      _score = result.sendWorthiness;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      body: ListView(
        children: [
          Text('Review before send', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpacing.md),
          WingmanTextField(
            controller: _controller,
            maxLines: 4,
            minLines: 3,
            hint: 'Paste or type your message',
          ),
          const SizedBox(height: AppSpacing.md),
          WingmanButton(
            label: 'Review',
            isLoading: _loading,
            onPressed: _controller.text.trim().isEmpty ? null : _review,
          ),
          if (_verdict != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(_verdict!, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text('Why', style: Theme.of(context).textTheme.titleMedium),
            Text(_why ?? '', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            Text('Better', style: Theme.of(context).textTheme.titleMedium),
            WingmanGlassCard(
              child: Text(_better ?? '', style: Theme.of(context).textTheme.bodyLarge),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Send-worthy\n${_score?.toStringAsFixed(1)} / 10',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'A product heuristic for clarity and response potential — not a prediction of dating success.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            WingmanButton(
              label: 'Use this',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _better ?? ''));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied. Send it yourself when ready.')),
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            WingmanSecondaryButton(
              label: 'Make it sound like me',
              onPressed: () => context.push('/reply/response'),
            ),
            const SizedBox(height: AppSpacing.sm),
            WingmanSecondaryButton(label: 'Try another', onPressed: _review),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class SaveToPersonScreen extends StatelessWidget {
  const SaveToPersonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final people = context.watch<AppController>().people;
    final person = people.isNotEmpty ? people.first : null;

    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Save this conversation to ${person?.name ?? 'someone'}?',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Save useful context so Wingman can remember the conversation over time.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          ...const [
            'Key topics and interests',
            'Important context',
            'Conversation summary',
            'Future recommendations',
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.check, color: AppColors.success, size: 18),
                  const SizedBox(width: 10),
                  Text(item),
                ],
              ),
            ),
          ),
          const Spacer(),
          WingmanButton(
            label: 'Save',
            onPressed: person == null
                ? null
                : () async {
                    await context.read<AppController>().saveConversationToPerson(person);
                    if (context.mounted) context.go('/people/${person.id}');
                  },
          ),
          const SizedBox(height: AppSpacing.sm),
          WingmanSecondaryButton(
            label: 'Don\'t save',
            onPressed: () => context.go('/home'),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
