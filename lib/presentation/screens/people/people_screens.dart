import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/mock/demo_data.dart';
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

class PersonProfileScreen extends StatelessWidget {
  const PersonProfileScreen({super.key, required this.personId});

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
                    onTap: () => context.push('/reply'),
                  ),
                  _ActionChip(
                    label: 'Insights',
                    onTap: () => context.push('/insights'),
                  ),
                  _ActionChip(label: 'Notes', onTap: () {}),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Key information', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              ...person.keyFacts.map(
                (fact) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Expanded(child: Text(fact)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
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
              const SizedBox(height: AppSpacing.xl),
              WingmanButton(
                label: 'Prepare me',
                onPressed: () => context.push('/people/${person.id}/prepare'),
              ),
              const SizedBox(height: AppSpacing.sm),
              WingmanSecondaryButton(
                label: 'Debrief',
                onPressed: () => context.push('/people/${person.id}/debrief'),
              ),
              const SizedBox(height: AppSpacing.sm),
              WingmanSecondaryButton(
                label: 'Analyze conversation',
                onPressed: () => context.push('/reply'),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor: AppColors.surfaceElevated,
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
