import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/mock/demo_data.dart';
import '../../../domain/entities/conversation.dart';
import '../../../domain/entities/person.dart';
import '../../controllers/app_controller.dart';
import '../../widgets/wingman_buttons.dart';
import '../../widgets/wingman_cards.dart';
import '../../widgets/wingman_components.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  PersonFilter _filter = PersonFilter.all;

  @override
  Widget build(BuildContext context) {
    final people = context.watch<AppController>().people.where((p) {
      return switch (_filter) {
        PersonFilter.all => true,
        PersonFilter.active =>
          p.status == PersonStatus.active || p.status == PersonStatus.waiting,
        PersonFilter.dates => p.status == PersonStatus.dating,
      };
    }).toList();

    return WingmanScaffold(
      title: 'People',
      actions: [
        WingmanIconButton(
          icon: Icons.add,
          tooltip: 'Add person',
          onPressed: () => _showAddPerson(context),
        ),
      ],
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: PersonFilter.values.map((filter) {
              final selected = _filter == filter;
              final label = switch (filter) {
                PersonFilter.all => 'All',
                PersonFilter.active => 'Active',
                PersonFilter.dates => 'Dates',
              };
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: WingmanChip(
                  label: label,
                  selected: selected,
                  onSelected: (_) async {
                    setState(() => _filter = filter);
                    await context
                        .read<AppController>()
                        .refreshPeople(filter: filter);
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: people.isEmpty
                ? WingmanEmptyState(
                    title: 'No people yet.',
                    body:
                        'Save a conversation and Wingman can remember useful context for you.',
                    actionLabel: 'Add someone',
                    onAction: () => _showAddPerson(context),
                    icon: Icons.people_outline,
                  )
                : ListView.separated(
                    itemCount: people.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final person = people[index];
                      return WingmanPersonCard(
                        person: person,
                        onTap: () => context.push('/people/${person.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddPerson(BuildContext context) async {
    final nameController = TextEditingController();
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.screenHorizontal,
            right: AppSpacing.screenHorizontal,
            top: AppSpacing.xl,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add someone', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.md),
              WingmanTextField(controller: nameController, hint: 'Name'),
              const SizedBox(height: AppSpacing.lg),
              WingmanButton(
                label: 'Save',
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) return;
                  await context.read<AppController>().addPerson(
                        name: nameController.text.trim(),
                      );
                  if (context.mounted) Navigator.pop(context, true);
                },
              ),
            ],
          ),
        );
      },
    );
    nameController.dispose();
    if (created == true && mounted) setState(() {});
  }
}

class PersonProfileScreen extends StatefulWidget {
  const PersonProfileScreen({super.key, required this.personId});

  final String personId;

  @override
  State<PersonProfileScreen> createState() => _PersonProfileScreenState();
}

class _PersonProfileScreenState extends State<PersonProfileScreen> {
  int _tab = 0; // 0 conversation, 1 insights, 2 notes
  Person? _person;
  Conversation? _conversation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final controller = context.read<AppController>();
    final person = await controller.personById(widget.personId);
    final conversation = person == null
        ? null
        : await controller.conversationForPerson(person.id);
    if (!mounted) return;
    setState(() {
      _person = person;
      _conversation = conversation;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const WingmanScaffold(body: WingmanLoadingState());
    }
    final person = _person;
    if (person == null) {
      return WingmanScaffold(
        leading: WingmanIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onPressed: () => context.pop(),
        ),
        body: const WingmanEmptyState(
          title: 'Person not found',
          body: 'This person may have been deleted.',
        ),
      );
    }

    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      title: person.name,
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              WingmanAvatar(name: person.name, size: 64),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${person.platform} · ${person.status.label}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (person.latestContext != null)
                      Text(
                        person.latestContext!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _ActionChip(
                label: 'Conversation',
                selected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              _ActionChip(
                label: 'Insights',
                selected: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
              _ActionChip(
                label: 'Notes',
                selected: _tab == 2,
                onTap: () => setState(() => _tab = 2),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_tab == 0) ..._conversationTab(context, person),
          if (_tab == 1) ..._insightsTab(context, person),
          if (_tab == 2) ..._notesTab(context),
          const SizedBox(height: AppSpacing.xl),
          WingmanButton(
            label: 'Analyze new chat',
            onPressed: () => context.push('/reply'),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  List<Widget> _conversationTab(BuildContext context, Person person) {
    final conversation = _conversation;
    final messages = conversation?.messages ?? const <ConversationMessage>[];

    if (messages.isEmpty) {
      return [
        const WingmanEmptyState(
          title: 'No saved messages yet.',
          body:
              'Analyze a chat and tap Save — the transcript will show up here.',
          icon: Icons.forum_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        WingmanButton(
          label: 'Analyze conversation',
          onPressed: () => context.push('/reply'),
        ),
      ];
    }

    return [
      Text('Saved conversation',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.sm),
      if (conversation!.pastedText != null &&
          conversation.pastedText!.trim().isNotEmpty) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: SelectableText(
            conversation.pastedText!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Parsed messages',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
      ],
      ...messages.map((message) {
        final isUser = message.speaker == MessageSpeaker.user;
        final label = switch (message.speaker) {
          MessageSpeaker.user => 'You',
          MessageSpeaker.other => person.name,
          MessageSpeaker.unknown => 'Unknown',
        };
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.text,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
      const SizedBox(height: AppSpacing.lg),
      Text('Timeline', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.sm),
      ...person.timeline.map(
        (event) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 5),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  event.label,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _insightsTab(BuildContext context, Person person) {
    return [
      Text('Key information', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.sm),
      if (person.keyFacts.isEmpty)
        Text(
          'No insights saved yet.',
          style: Theme.of(context).textTheme.bodyMedium,
        )
      else
        ...person.keyFacts.map(
          (fact) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(Icons.circle, size: 6, color: AppColors.accent),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(fact)),
              ],
            ),
          ),
        ),
    ];
  }

  List<Widget> _notesTab(BuildContext context) {
    return [
      Text(
        'Notes coming soon.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ];
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor:
            selected ? AppColors.accentMuted : AppColors.surfaceElevated,
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }
}

class DatePreparationScreen extends StatelessWidget {
  const DatePreparationScreen({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<AppController>().personById(personId),
      builder: (context, snapshot) {
        final person = snapshot.data;
        if (person == null) {
          return const WingmanScaffold(body: WingmanLoadingState());
        }
        final brief = DemoData.briefingFor(person);
        return WingmanScaffold(
          leading: WingmanIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: () => context.pop(),
          ),
          body: ListView(
            children: [
              Text(
                'Your 2-minute briefing',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: AppSpacing.xl),
              _BriefSection(title: 'What you know', items: brief.whatYouKnow),
              _BriefSection(title: 'Good topics', items: brief.goodTopics),
              _BriefSection(title: 'Avoid', items: brief.avoid),
              WingmanCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your tendency', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(brief.tendency, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.md),
                    Text('Your challenge', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(brief.challenge, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              WingmanButton(label: 'I\'m ready', onPressed: () => context.pop()),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }
}

class _BriefSection extends StatelessWidget {
  const _BriefSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: WingmanCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $item', style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DateDebriefScreen extends StatefulWidget {
  const DateDebriefScreen({super.key, required this.personId});

  final String personId;

  @override
  State<DateDebriefScreen> createState() => _DateDebriefScreenState();
}

class _DateDebriefScreenState extends State<DateDebriefScreen> {
  final _controller = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          Text('How did it go?', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpacing.md),
          WingmanTextField(
            controller: _controller,
            hint: 'Type a quick debrief...',
            maxLines: 5,
            minLines: 4,
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: WingmanIconButton(
              icon: Icons.mic_none_rounded,
              tooltip: 'Voice input',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Voice input is ready for device wiring.'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!_submitted)
            WingmanButton(
              label: 'Get debrief',
              onPressed: () => setState(() => _submitted = true),
            )
          else ...[
            WingmanCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date debrief', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  _metric(context, 'Chemistry', 'Strong'),
                  _metric(context, 'Conversation', 'Good'),
                  _metric(context, 'Mutual interest', 'Promising'),
                  const SizedBox(height: AppSpacing.md),
                  Text('Recommended next step', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Send a short follow-up that references one specific moment from the date.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Still thinking about that coffee place you mentioned — next round\'s on me?',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            WingmanSecondaryButton(label: 'Copy', onPressed: () {}),
            const SizedBox(height: AppSpacing.sm),
            WingmanSecondaryButton(label: 'Make it sound like me', onPressed: () {}),
            const SizedBox(height: AppSpacing.sm),
            WingmanButton(label: 'Save notes', onPressed: () => context.pop()),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
