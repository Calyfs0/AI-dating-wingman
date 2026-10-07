import 'package:equatable/equatable.dart';

/// Learned personal communication style. Values are 0.0–1.0 estimates.
class CommunicationStyle extends Equatable {
  const CommunicationStyle({
    this.humor = 0.5,
    this.directness = 0.5,
    this.flirting = 0.5,
    this.formality = 0.2,
    this.emojiUsage = 0.3,
    this.averageMessageLength = 0.45,
    this.preferredVocabulary = const [],
    this.commonPhrases = const [],
    this.avoidPhrases = const [],
  });

  final double humor;
  final double directness;
  final double flirting;
  final double formality;
  final double emojiUsage;
  final double averageMessageLength;
  final List<String> preferredVocabulary;
  final List<String> commonPhrases;
  final List<String> avoidPhrases;

  CommunicationStyle copyWith({
    double? humor,
    double? directness,
    double? flirting,
    double? formality,
    double? emojiUsage,
    double? averageMessageLength,
    List<String>? preferredVocabulary,
    List<String>? commonPhrases,
    List<String>? avoidPhrases,
  }) {
    return CommunicationStyle(
      humor: humor ?? this.humor,
      directness: directness ?? this.directness,
      flirting: flirting ?? this.flirting,
      formality: formality ?? this.formality,
      emojiUsage: emojiUsage ?? this.emojiUsage,
      averageMessageLength: averageMessageLength ?? this.averageMessageLength,
      preferredVocabulary: preferredVocabulary ?? this.preferredVocabulary,
      commonPhrases: commonPhrases ?? this.commonPhrases,
      avoidPhrases: avoidPhrases ?? this.avoidPhrases,
    );
  }

  Map<String, dynamic> toJson() => {
        'humor': humor,
        'directness': directness,
        'flirting': flirting,
        'formality': formality,
        'emoji_usage': emojiUsage,
        'average_message_length': averageMessageLength,
        'preferred_vocabulary': preferredVocabulary,
        'common_phrases': commonPhrases,
        'avoid_phrases': avoidPhrases,
      };

  factory CommunicationStyle.fromJson(Map<String, dynamic> json) {
    return CommunicationStyle(
      humor: (json['humor'] as num?)?.toDouble() ?? 0.5,
      directness: (json['directness'] as num?)?.toDouble() ?? 0.5,
      flirting: (json['flirting'] as num?)?.toDouble() ?? 0.5,
      formality: (json['formality'] as num?)?.toDouble() ?? 0.2,
      emojiUsage: (json['emoji_usage'] as num?)?.toDouble() ?? 0.3,
      averageMessageLength:
          (json['average_message_length'] as num?)?.toDouble() ?? 0.45,
      preferredVocabulary:
          (json['preferred_vocabulary'] as List?)?.cast<String>() ?? const [],
      commonPhrases:
          (json['common_phrases'] as List?)?.cast<String>() ?? const [],
      avoidPhrases:
          (json['avoid_phrases'] as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  List<Object?> get props => [
        humor,
        directness,
        flirting,
        formality,
        emojiUsage,
        averageMessageLength,
        preferredVocabulary,
        commonPhrases,
        avoidPhrases,
      ];
}
