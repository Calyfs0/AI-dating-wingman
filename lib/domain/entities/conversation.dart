import 'package:equatable/equatable.dart';

enum ConversationState { active, stalled, cooling, escalating }

enum MessageSpeaker { user, other, unknown }

class ConversationMessage extends Equatable {
  const ConversationMessage({
    required this.id,
    required this.text,
    required this.speaker,
    this.sentAt,
  });

  final String id;
  final String text;
  final MessageSpeaker speaker;
  final DateTime? sentAt;

  @override
  List<Object?> get props => [id, text, speaker, sentAt];
}

class ConversationSignals extends Equatable {
  const ConversationSignals({
    this.interest = 0,
    this.energy = 0,
    this.momentum = 0,
    this.reciprocity = 0,
  });

  final double interest;
  final double energy;
  final double momentum;
  final double reciprocity;

  @override
  List<Object?> get props => [interest, energy, momentum, reciprocity];
}

class ConversationStrategy extends Equatable {
  const ConversationStrategy({
    this.read = '',
    this.dos = const [],
    this.donts = const [],
  });

  final String read;
  final List<String> dos;
  final List<String> donts;

  @override
  List<Object?> get props => [read, dos, donts];
}

/// Structured internal conversation representation for the AI pipeline.
class Conversation extends Equatable {
  const Conversation({
    required this.id,
    this.personId,
    this.personName = 'Someone',
    this.platform = 'Hinge',
    this.participants = const [],
    this.messages = const [],
    this.topics = const [],
    this.conversationState = ConversationState.active,
    this.interestSignals = const ConversationSignals(),
    this.recommendedStrategy = const ConversationStrategy(),
    this.confidence = 0.0,
    this.rawImagePaths = const [],
    this.pastedText,
  });

  final String id;
  final String? personId;
  final String personName;
  final String platform;
  final List<String> participants;
  final List<ConversationMessage> messages;
  final List<String> topics;
  final ConversationState conversationState;
  final ConversationSignals interestSignals;
  final ConversationStrategy recommendedStrategy;
  final double confidence;
  final List<String> rawImagePaths;
  final String? pastedText;

  Map<String, dynamic> toStructuredJson() => {
        'conversation_id': id,
        'participants': participants,
        'messages': messages
            .map(
              (m) => {
                'id': m.id,
                'text': m.text,
                'speaker': m.speaker.name,
                'sent_at': m.sentAt?.toIso8601String(),
              },
            )
            .toList(),
        'topics': topics,
        'conversation_state': conversationState.name,
        'interest_signals': {
          'interest': interestSignals.interest,
          'energy': interestSignals.energy,
          'momentum': interestSignals.momentum,
          'reciprocity': interestSignals.reciprocity,
        },
        'recommended_strategy': {
          'read': recommendedStrategy.read,
          'dos': recommendedStrategy.dos,
          'donts': recommendedStrategy.donts,
        },
        'confidence': confidence,
      };

  @override
  List<Object?> get props => [
        id,
        personId,
        personName,
        platform,
        participants,
        messages,
        topics,
        conversationState,
        interestSignals,
        recommendedStrategy,
        confidence,
        rawImagePaths,
        pastedText,
      ];
}
