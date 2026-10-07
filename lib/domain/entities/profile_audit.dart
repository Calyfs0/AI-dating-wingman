import 'package:equatable/equatable.dart';

enum PhotoVerdict { keep, replace, reorder }

class ProfilePhotoReview extends Equatable {
  const ProfilePhotoReview({
    required this.id,
    required this.verdict,
    required this.reason,
    this.imagePath,
    this.recommendedOrder,
  });

  final String id;
  final PhotoVerdict verdict;
  final String reason;
  final String? imagePath;
  final int? recommendedOrder;

  @override
  List<Object?> get props => [id, verdict, reason, imagePath, recommendedOrder];
}

class ProfileAudit extends Equatable {
  const ProfileAudit({
    required this.id,
    this.overallStrength = 0,
    this.clarity = 0,
    this.personality = 0,
    this.approachability = 0,
    this.conversationPotential = 0,
    this.photos = const [],
    this.currentBio = '',
    this.suggestedBio = '',
  });

  final String id;
  final double overallStrength;
  final double clarity;
  final double personality;
  final double approachability;
  final double conversationPotential;
  final List<ProfilePhotoReview> photos;
  final String currentBio;
  final String suggestedBio;

  @override
  List<Object?> get props => [
        id,
        overallStrength,
        clarity,
        personality,
        approachability,
        conversationPotential,
        photos,
        currentBio,
        suggestedBio,
      ];
}

class OpenerResult extends Equatable {
  const OpenerResult({
    required this.id,
    required this.opener,
    this.hooks = const [],
    this.whyItWorks = '',
  });

  final String id;
  final String opener;
  final List<String> hooks;
  final String whyItWorks;

  @override
  List<Object?> get props => [id, opener, hooks, whyItWorks];
}

class MessageInterpretation extends Equatable {
  const MessageInterpretation({
    required this.message,
    required this.interpretation,
    required this.guidance,
  });

  final String message;
  final String interpretation;
  final String guidance;

  @override
  List<Object?> get props => [message, interpretation, guidance];
}

class ReviewBeforeSendResult extends Equatable {
  const ReviewBeforeSendResult({
    required this.original,
    required this.verdict,
    required this.why,
    required this.better,
    this.sendWorthiness = 0,
  });

  final String original;
  final String verdict;
  final String why;
  final String better;
  final double sendWorthiness;

  @override
  List<Object?> get props =>
      [original, verdict, why, better, sendWorthiness];
}

class DateBriefing extends Equatable {
  const DateBriefing({
    required this.personName,
    this.whatYouKnow = const [],
    this.goodTopics = const [],
    this.avoid = const [],
    this.tendency = '',
    this.challenge = '',
  });

  final String personName;
  final List<String> whatYouKnow;
  final List<String> goodTopics;
  final List<String> avoid;
  final String tendency;
  final String challenge;

  @override
  List<Object?> get props =>
      [personName, whatYouKnow, goodTopics, avoid, tendency, challenge];
}

class DateDebrief extends Equatable {
  const DateDebrief({
    required this.summary,
    this.chemistry = '',
    this.conversation = '',
    this.mutualInterest = '',
    this.nextStep = '',
    this.followUpMessage = '',
  });

  final String summary;
  final String chemistry;
  final String conversation;
  final String mutualInterest;
  final String nextStep;
  final String followUpMessage;

  @override
  List<Object?> get props => [
        summary,
        chemistry,
        conversation,
        mutualInterest,
        nextStep,
        followUpMessage,
      ];
}

class CoachingStats extends Equatable {
  const CoachingStats({
    this.youInitiate = 0,
    this.youAskQuestions = 0,
    this.theyAskQuestions = 0,
    this.strongestTrait = '',
    this.opportunity = '',
  });

  final double youInitiate;
  final double youAskQuestions;
  final double theyAskQuestions;
  final String strongestTrait;
  final String opportunity;

  @override
  List<Object?> get props => [
        youInitiate,
        youAskQuestions,
        theyAskQuestions,
        strongestTrait,
        opportunity,
      ];
}
