import '../../domain/entities/ai_generation.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/practice.dart';
import '../../domain/entities/profile_audit.dart';
import '../../domain/entities/communication_style.dart';

/// Pipeline stages for conversation processing UI.
enum ProcessingStage {
  extracting,
  understanding,
  analyzing,
  building,
  done,
  failed,
}

extension ProcessingStageLabel on ProcessingStage {
  String get label => switch (this) {
        ProcessingStage.extracting => 'Extracting messages',
        ProcessingStage.understanding => 'Understanding context',
        ProcessingStage.analyzing => 'Analyzing dynamics',
        ProcessingStage.building => 'Building your response',
        ProcessingStage.done => 'Ready',
        ProcessingStage.failed => 'Couldn\'t finish',
      };
}

abstract class ConversationAnalysisService {
  Stream<ProcessingStage> analyzeProgress({
    List<String> imagePaths = const [],
    String? pastedText,
  });

  Future<Conversation> analyze({
    List<String> imagePaths = const [],
    String? pastedText,
    String? personName,
  });

  Future<MessageInterpretation> interpretMessage(String message);
  Future<ReviewBeforeSendResult> reviewBeforeSend(String draft);
}

abstract class ResponseGenerationService {
  Future<AIGeneration> generate({
    required Conversation conversation,
    required ResponseTone tone,
    CommunicationStyle? style,
  });

  Future<AIGeneration> humanize({
    required AIGeneration generation,
    CommunicationStyle? style,
  });

  Future<AIGeneration> regenerate({
    required AIGeneration generation,
    required String direction,
    CommunicationStyle? style,
  });
}

abstract class ProfileAnalysisService {
  Future<ProfileAudit> audit({
    List<String> photoPaths = const [],
    String bio = '',
    List<String> prompts = const [],
  });

  Future<String> rewriteBio({
    required String currentBio,
    required String direction,
    CommunicationStyle? style,
  });
}

abstract class OpenerService {
  Future<OpenerResult> generate({
    required String profileText,
    List<String> imagePaths = const [],
    CommunicationStyle? style,
  });
}

abstract class PracticeService {
  Future<PracticeSession> start(PracticeTopic topic);
  Future<PracticeFeedback> evaluate({
    required PracticeSession session,
    required String response,
  });
}

abstract class CoachingService {
  Future<List<AIInsight>> insights();
  Future<CoachingStats> stats({String period = 'week'});
}
