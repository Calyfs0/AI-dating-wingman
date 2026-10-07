import '../../domain/entities/person.dart';
import '../../domain/entities/profile_audit.dart';

/// Helpers for flows not yet on live AI (e.g. date prep). No seeded people.
abstract final class DemoData {
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
