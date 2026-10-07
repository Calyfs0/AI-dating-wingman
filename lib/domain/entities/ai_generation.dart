import 'package:equatable/equatable.dart';

enum ResponseTone { playful, natural, confident, yourStyle }

extension ResponseToneLabel on ResponseTone {
  String get title => switch (this) {
        ResponseTone.playful => 'Playful',
        ResponseTone.natural => 'Natural',
        ResponseTone.confident => 'Confident',
        ResponseTone.yourStyle => 'Your style',
      };

  String get subtitle => switch (this) {
        ResponseTone.playful => 'Light and playful',
        ResponseTone.natural => 'Conversational and safe',
        ResponseTone.confident => 'Bold and direct',
        ResponseTone.yourStyle => 'Based on how you usually talk',
      };
}

enum FeedbackIssue {
  tooCheesy,
  tooFormal,
  notMe,
  tooFlirty,
  tooLong,
  other,
}

extension FeedbackIssueLabel on FeedbackIssue {
  String get label => switch (this) {
        FeedbackIssue.tooCheesy => 'Too cheesy',
        FeedbackIssue.tooFormal => 'Too formal',
        FeedbackIssue.notMe => 'Not me',
        FeedbackIssue.tooFlirty => 'Too flirty',
        FeedbackIssue.tooLong => 'Too long',
        FeedbackIssue.other => 'Other',
      };
}

class AIGeneration extends Equatable {
  const AIGeneration({
    required this.id,
    required this.text,
    required this.tone,
    this.alternatives = const [],
    this.whyItWorks,
    this.sendWorthiness,
  });

  final String id;
  final String text;
  final ResponseTone tone;
  final List<String> alternatives;
  final String? whyItWorks;
  final double? sendWorthiness;

  AIGeneration copyWith({
    String? id,
    String? text,
    ResponseTone? tone,
    List<String>? alternatives,
    String? whyItWorks,
    double? sendWorthiness,
  }) {
    return AIGeneration(
      id: id ?? this.id,
      text: text ?? this.text,
      tone: tone ?? this.tone,
      alternatives: alternatives ?? this.alternatives,
      whyItWorks: whyItWorks ?? this.whyItWorks,
      sendWorthiness: sendWorthiness ?? this.sendWorthiness,
    );
  }

  @override
  List<Object?> get props =>
      [id, text, tone, alternatives, whyItWorks, sendWorthiness];
}

class GenerationFeedback extends Equatable {
  const GenerationFeedback({
    required this.generationId,
    required this.isPositive,
    this.issues = const [],
    this.note,
  });

  final String generationId;
  final bool isPositive;
  final List<FeedbackIssue> issues;
  final String? note;

  @override
  List<Object?> get props => [generationId, isPositive, issues, note];
}

class AIInsight extends Equatable {
  const AIInsight({
    required this.id,
    required this.title,
    required this.body,
    this.ctaLabel = 'See insight',
    this.category = 'pattern',
  });

  final String id;
  final String title;
  final String body;
  final String ctaLabel;
  final String category;

  @override
  List<Object?> get props => [id, title, body, ctaLabel, category];
}
