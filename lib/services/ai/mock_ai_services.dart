import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../domain/entities/ai_generation.dart';
import '../../domain/entities/communication_style.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/practice.dart';
import '../../domain/entities/profile_audit.dart';
import 'ai_services.dart';

const _uuid = Uuid();

/// Demo AI layer with realistic Kehlo copy. Swap for edge-function clients later.
class MockConversationAnalysisService implements ConversationAnalysisService {
  @override
  Stream<ProcessingStage> analyzeProgress({
    List<String> imagePaths = const [],
    String? pastedText,
  }) async* {
    yield ProcessingStage.extracting;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    yield ProcessingStage.understanding;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    yield ProcessingStage.analyzing;
    await Future<void>.delayed(const Duration(milliseconds: 550));
    yield ProcessingStage.building;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    yield ProcessingStage.done;
  }

  @override
  Future<Conversation> analyze({
    List<String> imagePaths = const [],
    String? pastedText,
    String? personName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final name = personName ?? 'Emma';
    return Conversation(
      id: _uuid.v4(),
      personName: name,
      platform: 'Hinge',
      participants: ['You', name],
      topics: const ['travel', 'live music', 'coffee'],
      conversationState: ConversationState.active,
      interestSignals: const ConversationSignals(
        interest: 0.82,
        energy: 0.76,
        momentum: 0.68,
        reciprocity: 0.91,
      ),
      recommendedStrategy: const ConversationStrategy(
        read:
            'They\'re engaged and playful, but you\'ve been doing slightly more of the work. This is a good moment to give them something easy to respond to.',
        dos: [
          'Make a playful observation.',
          'Give them something easy to respond to.',
        ],
        donts: [
          'Ask another interview-style question.',
          'Over-explain.',
        ],
      ),
      confidence: 0.74,
      messages: [
        ConversationMessage(
          id: '1',
          text: 'okay wait that trip looked unreal',
          speaker: MessageSpeaker.other,
        ),
        ConversationMessage(
          id: '2',
          text: 'haha yeah it was chaotic in the best way',
          speaker: MessageSpeaker.user,
        ),
        ConversationMessage(
          id: '3',
          text: 'haha yeah maybe',
          speaker: MessageSpeaker.other,
        ),
      ],
      rawImagePaths: imagePaths,
      pastedText: pastedText,
    );
  }

  @override
  Future<MessageInterpretation> interpretMessage(String message) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return MessageInterpretation(
      message: message,
      interpretation:
          'Probably neutral rather than strongly positive. They\'re not rejecting the idea, but they\'re also not investing much in it yet.',
      guidance:
          'Don\'t overreact. Best move: change topic or leave the conversation for now.',
    );
  }

  @override
  Future<ReviewBeforeSendResult> reviewBeforeSend(String draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return ReviewBeforeSendResult(
      original: draft,
      verdict: 'I\'d tweak it.',
      why:
          'It\'s positive, but generic and doesn\'t give them much to respond to.',
      better: 'Okay that outfit is unfair 😂\nwhere were you going?',
      sendWorthiness: 8.7,
    );
  }
}

class MockResponseGenerationService implements ResponseGenerationService {
  @override
  Future<AIGeneration> generate({
    required Conversation conversation,
    required ResponseTone tone,
    CommunicationStyle? style,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final text = switch (tone) {
      ResponseTone.playful =>
        'Okay now I\'m curious 😂\nhow did you even end up there?',
      ResponseTone.natural =>
        'That sounds like a story. What was the best part of it?',
      ResponseTone.confident =>
        'Alright you\'ve got my attention — tell me the chaotic part.',
      ResponseTone.yourStyle =>
        'Wait that\'s actually funny. What happened after?',
    };
    return AIGeneration(
      id: _uuid.v4(),
      text: text,
      tone: tone,
      alternatives: [
        'Okay that\'s unfairly interesting. What started it?',
        'I need the short version of that story.',
      ],
      whyItWorks:
          'It references the conversation, stays light, and gives them an easy opening.',
      sendWorthiness: 8.4,
    );
  }

  @override
  Future<AIGeneration> humanize({
    required AIGeneration generation,
    CommunicationStyle? style,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return generation.copyWith(
      id: _uuid.v4(),
      text: 'Okay now I\'m actually curious — how did you even end up there?',
    );
  }

  @override
  Future<AIGeneration> regenerate({
    required AIGeneration generation,
    required String direction,
    CommunicationStyle? style,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final text = switch (direction) {
      'playful' => 'That trip sounds suspiciously fun 😂 what was the highlight?',
      'natural' => 'Sounds like a good one. What made it memorable?',
      _ => 'Alright I need details. What happened?',
    };
    return generation.copyWith(id: _uuid.v4(), text: text);
  }
}

class MockProfileAnalysisService implements ProfileAnalysisService {
  @override
  Future<ProfileAudit> audit({
    List<String> photoPaths = const [],
    String bio = '',
    List<String> prompts = const [],
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return ProfileAudit(
      id: _uuid.v4(),
      overallStrength: 7.8,
      clarity: 0.82,
      personality: 0.74,
      approachability: 0.8,
      conversationPotential: 0.71,
      currentBio: bio.isEmpty
          ? 'Love travel, coffee, and good conversations.'
          : bio,
      suggestedBio:
          'Usually planning my next trip before I\'ve finished the current one.\nCoffee, bad jokes and finding underrated places to eat.',
      photos: [
        const ProfilePhotoReview(
          id: '1',
          verdict: PhotoVerdict.keep,
          reason:
              'Strong first impression. Face is clear and the photo feels natural.',
          recommendedOrder: 1,
        ),
        const ProfilePhotoReview(
          id: '2',
          verdict: PhotoVerdict.replace,
          reason: 'The group makes it unclear who you are.',
          recommendedOrder: 4,
        ),
        const ProfilePhotoReview(
          id: '3',
          verdict: PhotoVerdict.reorder,
          reason: 'Good lifestyle signal — better as photo 2 or 3.',
          recommendedOrder: 2,
        ),
      ],
    );
  }

  @override
  Future<String> rewriteBio({
    required String currentBio,
    required String direction,
    CommunicationStyle? style,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return switch (direction) {
      'funnier' =>
        'Professional over-packer. Amateur coffee critic. Expert at finding the one restaurant that is somehow always closed.',
      'shorter' =>
        'Travel, coffee, bad jokes, and underrated places to eat.',
      _ =>
        'Usually planning my next trip before I\'ve finished the current one.\nCoffee, bad jokes and finding underrated places to eat.',
    };
  }
}

class MockOpenerService implements OpenerService {
  @override
  Future<OpenerResult> generate({
    required String profileText,
    List<String> imagePaths = const [],
    CommunicationStyle? style,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return OpenerResult(
      id: _uuid.v4(),
      hooks: const ['Dog', 'Japan', 'Guitar', 'Food'],
      opener:
          'Important question:\ndid you actually enjoy Japan\nor were you just there for the food? 😂',
      whyItWorks:
          'It references something specific and creates an easy response.',
    );
  }
}

class MockPracticeService implements PracticeService {
  @override
  Future<PracticeSession> start(PracticeTopic topic) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final prompt = switch (topic) {
      PracticeTopic.firstDate => 'So, what made you want to meet me?',
      PracticeTopic.firstMessage =>
        'You matched. Their profile mentions live music and late-night ramen.',
      PracticeTopic.askingOut =>
        'The chat has been good for a few days. They just said this weekend is open.',
      _ => 'Alright — your move. Keep it natural.',
    };
    return PracticeSession(
      id: _uuid.v4(),
      topic: topic,
      personaName: 'Alex',
      prompt: prompt,
    );
  }

  @override
  Future<PracticeFeedback> evaluate({
    required PracticeSession session,
    required String response,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return const PracticeFeedback(
      summary:
          'Good answer. You sounded confident, but you didn\'t give them much to continue with.',
      confidence: 8,
      naturalness: 9,
      conversation: 6,
    );
  }
}

class MockCoachingService implements CoachingService {
  @override
  Future<List<AIInsight>> insights() async {
    return const [
      AIInsight(
        id: '1',
        title: 'Kehlo noticed something',
        body:
            'You tend to ask multiple questions in a row.\nTry mixing questions with playful statements.',
      ),
    ];
  }

  @override
  Future<CoachingStats> stats({String period = 'week'}) async {
    return const CoachingStats(
      youInitiate: 0.62,
      youAskQuestions: 0.71,
      theyAskQuestions: 0.49,
      strongestTrait: 'You create playful conversations.',
      opportunity:
          'You tend to keep conversations going too long before suggesting a date.',
    );
  }
}
