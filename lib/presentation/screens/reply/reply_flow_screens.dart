import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/ai_generation.dart';
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
  final _focusNode = FocusNode();
  bool _showPaste = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _hasInput =>
      _images.isNotEmpty || _textController.text.trim().isNotEmpty;

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    if (source == ImageSource.gallery) {
      final files = await picker.pickMultiImage(
        imageQuality: 55,
        maxWidth: 1280,
      );
      if (files.isEmpty) return;
      setState(() {
        _images.addAll(files.take(8 - _images.length));
      });
    } else {
      final file = await picker.pickImage(
        source: source,
        imageQuality: 55,
        maxWidth: 1280,
      );
      if (file == null) return;
      setState(() {
        if (_images.length < 8) _images.add(file);
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard is empty.')),
      );
      return;
    }
    _textController
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
    setState(() => _showPaste = true);
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
            'Upload screenshots of the chat. Wingman reads them with AI.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          WingmanDashedDropZone(
            onTap: () => _pick(ImageSource.gallery),
            label: 'Add screenshots',
            subtitle: '1–8 images · clearer crops work best',
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
            title: 'Paste text instead',
            subtitle: 'Optional fallback if screenshots are blurry',
            icon: Icons.content_paste_rounded,
            onTap: () => setState(() => _showPaste = !_showPaste),
          ),
          if (_showPaste) ...[
            const SizedBox(height: AppSpacing.md),
            WingmanSecondaryButton(
              label: 'Paste from clipboard',
              onPressed: _pasteFromClipboard,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              onChanged: (_) => setState(() {}),
              maxLines: 8,
              minLines: 5,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              enableInteractiveSelection: true,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Paste the conversation here...',
              ),
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Image.file(
                          File(_images[index].path),
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(index)),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.surface,
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: AppColors.textPrimary,
                            ),
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
      final message = context.read<AppController>().errorMessage;
      return WingmanScaffold(
        body: WingmanErrorState(
          title: 'Couldn\'t finish this analysis.',
          body: message ??
              'Try a clearer screenshot, or paste the text as a fallback.',
          primaryLabel: 'Try again',
          onPrimary: () {
            setState(() {
              _failed = false;
              _stage = ProcessingStage.extracting;
            });
            _run();
          },
          secondaryLabel: 'Go back',
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

    return WingmanScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Reading the conversation…',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          ...List.generate(stages.length, (index) {
            final stage = stages[index];
            final done = index < stageIndex;
            final active = index == stageIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    done
                        ? Icons.check_circle
                        : active
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                    color: done || active
                        ? AppColors.accent
                        : AppColors.textTertiary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    stage.label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: done || active
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                        ),
                  ),
                ],
              ),
            );
          }),
          const Spacer(),
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// Re-export remaining reply flow screens from the previous file content below.
// Keep analysis / next-move / response / interpret / review / save screens.

class AnalysisOverviewScreen extends StatelessWidget {
  const AnalysisOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final conversation = context.watch<AppController>().activeConversation;
    if (conversation == null) {
      return const WingmanScaffold(body: WingmanLoadingState());
    }
    final signals = conversation.interestSignals;
    final strategy = conversation.recommendedStrategy;
    final snippet = conversation.messages.take(3).map((m) => m.text).join('\n');

    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.go('/reply'),
      ),
      body: ListView(
        children: [
          Text('Here\'s what\'s going on',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpacing.md),
          if (snippet.isNotEmpty)
            WingmanGlassCard(
              child: Text(snippet, style: Theme.of(context).textTheme.bodyMedium),
            ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SignalChip(label: 'Interest', value: signals.interest),
              _SignalChip(label: 'Energy', value: signals.energy),
              _SignalChip(label: 'Momentum', value: signals.momentum),
              _SignalChip(label: 'Reciprocity', value: signals.reciprocity),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Strategy', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(strategy.read, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.md),
          Text('Do', style: Theme.of(context).textTheme.titleMedium),
          ...strategy.dos.map((e) => _Bullet(e)),
          const SizedBox(height: AppSpacing.sm),
          Text("Don't", style: Theme.of(context).textTheme.titleMedium),
          ...strategy.donts.map((e) => _Bullet(e)),
          const SizedBox(height: AppSpacing.xxl),
          WingmanButton(
            label: 'Choose next move',
            onPressed: () => context.push('/reply/next-move'),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _SignalChip extends StatelessWidget {
  const _SignalChip({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(
            '${(value * 100).round()}%',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class NextMoveScreen extends StatelessWidget {
  const NextMoveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final strategy = controller.activeConversation?.recommendedStrategy;

    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      body: ListView(
        children: [
          Text('Pick a tone', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpacing.sm),
          if (strategy != null)
            Text(strategy.read, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          ...ResponseTone.values.map((tone) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: WingmanFeatureCard(
                title: tone.title,
                subtitle: tone.subtitle,
                icon: Icons.chat_bubble_outline,
                onTap: () async {
                  final generation = await controller.generateResponse(tone);
                  if (!context.mounted) return;
                  if (generation == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          controller.errorMessage ??
                              'Couldn\'t generate a reply.',
                        ),
                      ),
                    );
                    return;
                  }
                  context.push('/reply/response');
                },
              ),
            );
          }),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class ResponseDetailScreen extends StatelessWidget {
  const ResponseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final generation = controller.activeGeneration;
    if (generation == null) {
      return const WingmanScaffold(body: WingmanLoadingState());
    }

    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      body: ListView(
        children: [
          Text('Your reply', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpacing.lg),
          WingmanGlassCard(
            child: SelectableText(
              generation.text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          if (generation.whyItWorks != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Why it works',
                style: Theme.of(context).textTheme.titleMedium),
            Text(generation.whyItWorks!,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (generation.alternatives.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Alternatives',
                style: Theme.of(context).textTheme.titleMedium),
            ...generation.alternatives.map(
              (alt) => Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: WingmanGlassCard(
                  child: SelectableText(alt),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          WingmanButton(
            label: 'Copy',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: generation.text));
              await controller.trackCopy();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied. Send it yourself when ready.'),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          WingmanSecondaryButton(
            label: 'Make it sound like me',
            onPressed: () => controller.humanizeActive(),
          ),
          const SizedBox(height: AppSpacing.sm),
          WingmanSecondaryButton(
            label: 'Regenerate',
            onPressed: () => controller.regenerate('fresher take'),
          ),
          const SizedBox(height: AppSpacing.sm),
          WingmanSecondaryButton(
            label: 'Save to a person',
            onPressed: () => context.push('/reply/save'),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class InterpretMessageScreen extends StatefulWidget {
  const InterpretMessageScreen({super.key});

  @override
  State<InterpretMessageScreen> createState() => _InterpretMessageScreenState();
}

class _InterpretMessageScreenState extends State<InterpretMessageScreen> {
  final _controller = TextEditingController();
  String? _interpretation;
  String? _guidance;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() => _loading = true);
    final result = await context
        .read<AppController>()
        .analysisService
        .interpretMessage(_controller.text.trim());
    if (!mounted) return;
    setState(() {
      _interpretation = result.interpretation;
      _guidance = result.guidance;
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
          Text('Interpret a message',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpacing.lg),
          WingmanTextField(
            controller: _controller,
            hint: 'Paste their message',
            maxLines: 5,
            minLines: 3,
          ),
          const SizedBox(height: AppSpacing.md),
          WingmanButton(
            label: _loading ? 'Reading…' : 'Interpret',
            onPressed: _loading || _controller.text.trim().isEmpty ? null : _run,
          ),
          if (_interpretation != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(_interpretation!,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(_guidance ?? '',
                style: Theme.of(context).textTheme.bodyMedium),
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
  final _controller = TextEditingController();
  String? _verdict;
  String? _why;
  String? _better;
  double? _score;
  bool _loading = false;

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
          Text('Review before send',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpacing.lg),
          WingmanTextField(
            controller: _controller,
            hint: 'Your draft…',
            maxLines: 6,
            minLines: 4,
          ),
          const SizedBox(height: AppSpacing.md),
          WingmanButton(
            label: _loading ? 'Reviewing…' : 'Review',
            onPressed: _loading || _controller.text.trim().isEmpty ? null : _review,
          ),
          if (_verdict != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(_verdict!, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(_why ?? '', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            WingmanGlassCard(
              child: Text(_better ?? '',
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
            if (_score != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  'Send-worthy ${_score!.toStringAsFixed(1)} / 10',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class SaveToPersonScreen extends StatefulWidget {
  const SaveToPersonScreen({super.key});

  @override
  State<SaveToPersonScreen> createState() => _SaveToPersonScreenState();
}

class _SaveToPersonScreenState extends State<SaveToPersonScreen> {
  late final TextEditingController _nameController;
  String? _selectedPersonId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final controller = context.read<AppController>();
    _nameController = TextEditingController(
      text: controller.activeConversation?.personName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final people = controller.people;
    final nameHint = controller.activeConversation?.personName ?? 'Someone';

    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Save this conversation?',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Wingman only remembers people you explicitly save.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (people.isNotEmpty) ...[
            Text('Existing people',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ...people.map((person) {
              final selected = _selectedPersonId == person.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: InkWell(
                  onTap: () => setState(() => _selectedPersonId = person.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.surfaceElevated
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.accent : AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(person.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          person.latestContext ?? person.platform,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),
            Text('Or save as new',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
          ],
          WingmanTextField(
            controller: _nameController,
            hint: 'Name (e.g. $nameHint)',
            onChanged: (_) {
              if (_selectedPersonId != null) {
                setState(() => _selectedPersonId = null);
              }
            },
          ),
          const Spacer(),
          WingmanButton(
            label: _saving ? 'Saving…' : 'Save',
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    try {
                      final selectedId = _selectedPersonId;
                      final matches = selectedId == null
                          ? const <Never>[]
                          : people.where((p) => p.id == selectedId).toList();
                      final selected =
                          matches.isEmpty ? null : matches.first;
                      final person = await controller.saveConversationToPerson(
                        person: selected,
                        name: _nameController.text.trim().isEmpty
                            ? nameHint
                            : _nameController.text.trim(),
                      );
                      if (context.mounted) {
                        context.go('/people/${person.id}');
                      }
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
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
