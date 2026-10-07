import 'package:uuid/uuid.dart';
import '../../domain/entities/ai_generation.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/person.dart';

const _uuid = Uuid();

abstract final class ConversationMapper {
  static Conversation fromDbRow(Map<String, dynamic> row) {
    final structured = row['structured'];
    final map = structured is Map
        ? Map<String, dynamic>.from(structured)
        : <String, dynamic>{};
    return fromAnalyzeResponse({
      ...map,
      'id': row['id'],
      'person_id': row['person_id'],
      'personId': row['person_id'],
    });
  }

  static Conversation fromAnalyzeResponse(Map<String, dynamic> json) {
    final signals = json['interestSignals'] as Map<String, dynamic>? ??
        json['interest_signals'] as Map<String, dynamic>? ??
        const {};
    final strategy = json['recommendedStrategy'] as Map<String, dynamic>? ??
        json['recommended_strategy'] as Map<String, dynamic>? ??
        const {};
    final messagesRaw = json['messages'] as List? ?? const [];

    return Conversation(
      id: (json['id'] as String?) ?? _uuid.v4(),
      personId: json['personId'] as String? ?? json['person_id'] as String?,
      personName: (json['personName'] as String?) ??
          (json['person_name'] as String?) ??
          'Someone',
      platform: (json['platform'] as String?) ?? 'Unknown',
      participants:
          (json['participants'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      messages: messagesRaw.map((raw) {
        final m = Map<String, dynamic>.from(raw as Map);
        final speakerName = (m['speaker'] as String?) ?? 'unknown';
        return ConversationMessage(
          id: (m['id'] as String?) ?? _uuid.v4(),
          text: (m['text'] as String?) ?? '',
          speaker: MessageSpeaker.values.firstWhere(
            (s) => s.name == speakerName,
            orElse: () => MessageSpeaker.unknown,
          ),
          sentAt: m['sent_at'] != null || m['sentAt'] != null
              ? DateTime.tryParse(
                  (m['sent_at'] ?? m['sentAt']).toString(),
                )
              : null,
        );
      }).toList(),
      topics: (json['topics'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      conversationState: ConversationState.values.firstWhere(
        (s) =>
            s.name ==
            ((json['conversationState'] as String?) ??
                (json['conversation_state'] as String?) ??
                'active'),
        orElse: () => ConversationState.active,
      ),
      interestSignals: ConversationSignals(
        interest: _d(signals['interest']),
        energy: _d(signals['energy']),
        momentum: _d(signals['momentum']),
        reciprocity: _d(signals['reciprocity']),
      ),
      recommendedStrategy: ConversationStrategy(
        read: (strategy['read'] as String?) ?? '',
        dos: (strategy['dos'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        donts:
            (strategy['donts'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
      ),
      confidence: _d(json['confidence'], fallback: 0.5),
      pastedText: json['pastedText'] as String? ?? json['pasted_text'] as String?,
    );
  }

  static List<String> keyFactsFrom(Map<String, dynamic> json) {
    return (json['keyFacts'] as List? ?? json['key_facts'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
  }

  static AIGeneration fromGenerationResponse(Map<String, dynamic> json) {
    final toneName = (json['tone'] as String?) ?? ResponseTone.natural.name;
    return AIGeneration(
      id: (json['id'] as String?) ?? _uuid.v4(),
      text: (json['text'] as String?) ?? '',
      tone: ResponseTone.values.firstWhere(
        (t) => t.name == toneName,
        orElse: () => ResponseTone.natural,
      ),
      alternatives: (json['alternatives'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      whyItWorks: json['whyItWorks'] as String? ?? json['why_it_works'] as String?,
      sendWorthiness: json['sendWorthiness'] != null ||
              json['send_worthiness'] != null
          ? _d(json['sendWorthiness'] ?? json['send_worthiness'])
          : null,
    );
  }

  static Person fromRow(Map<String, dynamic> row) {
    final timelineRaw = row['timeline'] as List? ?? const [];
    final statusName = (row['status'] as String?) ?? 'active';
    return Person(
      id: row['id'] as String,
      name: row['name'] as String? ?? 'Someone',
      platform: row['platform'] as String? ?? 'Hinge',
      status: PersonStatus.values.firstWhere(
        (s) => s.name == statusName,
        orElse: () => PersonStatus.active,
      ),
      latestContext: row['latest_context'] as String?,
      keyFacts:
          (row['key_facts'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      timeline: timelineRaw.map((raw) {
        final m = Map<String, dynamic>.from(raw as Map);
        return PersonTimelineEvent(
          id: (m['id'] as String?) ?? _uuid.v4(),
          label: (m['label'] as String?) ?? '',
          at: m['at'] != null ? DateTime.tryParse(m['at'].toString()) : null,
        );
      }).toList(),
      lastActivityAt: row['last_activity_at'] != null
          ? DateTime.tryParse(row['last_activity_at'].toString())
          : null,
    );
  }

  static Map<String, dynamic> personToRow(Person person, String userId) {
    return {
      if (person.id.isNotEmpty) 'id': person.id,
      'user_id': userId,
      'name': person.name,
      'platform': person.platform,
      'status': person.status.name,
      'latest_context': person.latestContext,
      'key_facts': person.keyFacts,
      'timeline': person.timeline
          .map(
            (e) => {
              'id': e.id,
              'label': e.label,
              'at': e.at?.toIso8601String(),
            },
          )
          .toList(),
      'last_activity_at':
          (person.lastActivityAt ?? DateTime.now()).toIso8601String(),
    };
  }

  static double _d(Object? value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return fallback;
  }
}
