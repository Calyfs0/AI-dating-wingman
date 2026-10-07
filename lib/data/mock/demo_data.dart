import '../../domain/entities/ai_generation.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/profile_audit.dart';

abstract final class DemoData {
  static final now = DateTime.now();

  static List<Person> people = [
    Person(
      id: 'emma',
      name: 'Emma',
      platform: 'Hinge',
      status: PersonStatus.active,
      latestContext: 'Talked about live music and Goa',
      lastActivityAt: now.subtract(const Duration(hours: 2)),
      keyFacts: const [
        'Works in marketing',
        'Loves live music',
        'Recently visited Goa',
        'Prefers sarcastic humor',
      ],
      timeline: [
        PersonTimelineEvent(
          id: '1',
          label: 'Matched on Hinge',
          at: now.subtract(const Duration(days: 8)),
        ),
        PersonTimelineEvent(
          id: '2',
          label: 'Talked about travel',
          at: now.subtract(const Duration(days: 5)),
        ),
        PersonTimelineEvent(
          id: '3',
          label: 'Talked about live music',
          at: now.subtract(const Duration(days: 3)),
        ),
        PersonTimelineEvent(
          id: '4',
          label: 'Discussed coffee',
          at: now.subtract(const Duration(days: 1)),
        ),
        PersonTimelineEvent(
          id: '5',
          label: 'Date planned',
          at: now.add(const Duration(days: 1)),
        ),
      ],
    ),
    Person(
      id: 'maya',
      name: 'Maya',
      platform: 'Bumble',
      status: PersonStatus.waiting,
      latestContext: 'Waiting on your reply about Saturday',
      lastActivityAt: now.subtract(const Duration(days: 1)),
      keyFacts: const [
        'Product designer',
        'Into climbing',
        'Prefers direct plans',
      ],
      timeline: [
        PersonTimelineEvent(
          id: '1',
          label: 'Matched on Bumble',
          at: now.subtract(const Duration(days: 4)),
        ),
        PersonTimelineEvent(
          id: '2',
          label: 'Talked about climbing',
          at: now.subtract(const Duration(days: 2)),
        ),
      ],
    ),
    Person(
      id: 'sophie',
      name: 'Sophie',
      platform: 'Hinge',
      status: PersonStatus.quiet,
      latestContext: 'No recent activity',
      lastActivityAt: now.subtract(const Duration(days: 3)),
      keyFacts: const [
        'Photographer',
        'Loves film cameras',
      ],
      timeline: [
        PersonTimelineEvent(
          id: '1',
          label: 'Matched on Hinge',
          at: now.subtract(const Duration(days: 12)),
        ),
      ],
    ),
  ];

  static const homeInsight = AIInsight(
    id: 'home-insight',
    title: 'Your wingman noticed something',
    body:
        'You tend to ask multiple questions\nin a row.\nTry mixing questions with playful\nstatements.',
  );

  static DateBriefing briefingFor(Person person) {
    return DateBriefing(
      personName: person.name,
      whatYouKnow: person.keyFacts,
      goodTopics: const ['Live music', 'Travel stories', 'Underrated food spots'],
      avoid: const ['Over-interviewing', 'Rehashing the whole chat history'],
      tendency: 'You ask too many questions when nervous.',
      challenge: 'Make a statement before asking a question.',
    );
  }
}
