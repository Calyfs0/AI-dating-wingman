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
      setState(() => _images.addAll(files.take(8 - _images.length)));
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
            'Upload screenshots. Wingman writes the best next message.',
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
            subtitle: 'Optional fallback',
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
                            child: Icon(Icons.close, size: 14),
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
            label: 'Get my reply',
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
      setState(() => _stage = ProcessingStage.building);
      final generation =
          await controller.generateResponse(ResponseTone.natural);
      if (!mounted) return;
      if (generation == null) {
        setState(() => _failed = true);
        return;
      }
      context.go('/reply/result');
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
          title: 'Couldn\'t finish.',
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
            'Writing your reply…',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          ...List.generate(stages.length, (index) {
            final stage = stages[index];
            final done = index < stageIndex;
            final active = index == stageIndex;
            final label = index == stages.length - 1
                ? 'Crafting your message'
                : stage.label;
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
                    label,
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

/// Basic result: messages we read + one reply based only on those.
class ReplyResultScreen extends StatefulWidget {
  const ReplyResultScreen({super.key});

  @override
  State<ReplyResultScreen> createState() => _ReplyResultScreenState();
}

class _ReplyResultScreenState extends State<ReplyResultScreen> {
  bool _busy = false;

  Future<void> _withBusy(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final generation = controller.activeGeneration;
    final conversation = controller.activeConversation;
    final messages = conversation?.messages ?? const [];

    if (generation == null) {
      return WingmanScaffold(
        leading: WingmanIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onPressed: () => context.go('/home'),
        ),
        body: WingmanEmptyState(
          title: 'No reply yet.',
          body: 'Upload a chat screenshot to get a reply.',
          actionLabel: 'Help me reply',
          onAction: () => context.go('/reply'),
        ),
      );
    }

    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.go('/home'),
      ),
      body: ListView(
        children: [
          Text(
            'Send this',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Based only on the messages in your screenshot.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          WingmanGlassCard(
            child: SelectableText(
              generation.text,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: AppSpacing.md),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: AppSpacing.lg),
          WingmanButton(
            label: 'Copy reply',
            onPressed: _busy
                ? null
                : () async {
                    await Clipboard.setData(
                      ClipboardData(text: generation.text),
                    );
                    await controller.trackCopy();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied. Send it when you\'re ready.'),
                        ),
                      );
                    }
                  },
          ),
          const SizedBox(height: AppSpacing.sm),
          WingmanSecondaryButton(
            label: 'Try another',
            onPressed: _busy
                ? null
                : () => _withBusy(() async {
                      await controller.regenerate(
                        'different reply, still only from these messages',
                      );
                    }),
          ),
          if (messages.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Messages we read',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'If this looks wrong, go back and use a clearer screenshot.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            ...messages.map((message) {
              final isUser = message.speaker.name == 'user';
              final label = switch (message.speaker.name) {
                'user' => 'You',
                'other' => conversation?.personName ?? 'Them',
                _ => '?',
              };
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? AppColors.accentMuted
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppColors.textTertiary),
                          ),
                          const SizedBox(height: 4),
                          Text(message.text),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: AppSpacing.xl),
          WingmanSecondaryButton(
            label: 'Save to a person',
            onPressed: () => context.push('/reply/save'),
          ),
          const SizedBox(height: AppSpacing.sm),
          WingmanSecondaryButton(
            label: 'Done',
            onPressed: () => context.go('/home'),
          ),
          const SizedBox(height: AppSpacing.xl),
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
            'So you can reopen the chat and context later.',
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
                    child: Text(person.name),
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
                      final person = await controller.saveConversationToPerson(
                        person: matches.isEmpty ? null : matches.first,
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
            label: 'Skip',
            onPressed: () => context.go('/home'),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
