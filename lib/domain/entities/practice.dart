import 'package:equatable/equatable.dart';

enum PracticeTopic {
  firstMessage,
  keepingAlive,
  flirting,
  askingOut,
  rejection,
  firstDate,
  confidence,
}

extension PracticeTopicCopy on PracticeTopic {
  String get title => switch (this) {
        PracticeTopic.firstMessage => 'First message',
        PracticeTopic.keepingAlive => 'Keeping conversation alive',
        PracticeTopic.flirting => 'Flirting',
        PracticeTopic.askingOut => 'Asking someone out',
        PracticeTopic.rejection => 'Handling rejection',
        PracticeTopic.firstDate => 'First date',
        PracticeTopic.confidence => 'Confidence',
      };

  String get description => switch (this) {
        PracticeTopic.firstMessage => 'Open with something specific and easy to answer.',
        PracticeTopic.keepingAlive => 'Keep momentum without interview energy.',
        PracticeTopic.flirting => 'Playful tension that still feels like you.',
        PracticeTopic.askingOut => 'Move from chat to a real plan.',
        PracticeTopic.rejection => 'Stay grounded when interest cools.',
        PracticeTopic.firstDate => 'Show up calm, curious, and present.',
        PracticeTopic.confidence => 'Sound natural when nerves kick in.',
      };
}

class PracticeSession extends Equatable {
  const PracticeSession({
    required this.id,
    required this.topic,
    this.personaName = 'Alex',
    this.prompt = '',
    this.userResponse,
    this.feedback,
  });

  final String id;
  final PracticeTopic topic;
  final String personaName;
  final String prompt;
  final String? userResponse;
  final PracticeFeedback? feedback;

  PracticeSession copyWith({
    String? userResponse,
    PracticeFeedback? feedback,
  }) {
    return PracticeSession(
      id: id,
      topic: topic,
      personaName: personaName,
      prompt: prompt,
      userResponse: userResponse ?? this.userResponse,
      feedback: feedback ?? this.feedback,
    );
  }

  @override
  List<Object?> get props =>
      [id, topic, personaName, prompt, userResponse, feedback];
}

class PracticeFeedback extends Equatable {
  const PracticeFeedback({
    required this.summary,
    this.confidence = 0,
    this.naturalness = 0,
    this.conversation = 0,
  });

  final String summary;
  final double confidence;
  final double naturalness;
  final double conversation;

  @override
  List<Object?> get props => [summary, confidence, naturalness, conversation];
}
