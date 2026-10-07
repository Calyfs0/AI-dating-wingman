import 'package:flutter/foundation.dart';

/// Privacy-safe analytics abstraction.
/// Never track raw conversation text or screenshots.
abstract class AnalyticsService {
  Future<void> track(String event, {Map<String, Object?> properties = const {}});
  Future<void> identify(String userId, {Map<String, Object?> traits = const {}});
  Future<void> reset();
}

class DebugAnalyticsService implements AnalyticsService {
  @override
  Future<void> track(
    String event, {
    Map<String, Object?> properties = const {},
  }) async {
    assert(!_containsSensitiveKeys(properties));
    debugPrint('analytics:$event $properties');
  }

  @override
  Future<void> identify(
    String userId, {
    Map<String, Object?> traits = const {},
  }) async {
    debugPrint('analytics:identify $userId');
  }

  @override
  Future<void> reset() async {
    debugPrint('analytics:reset');
  }

  bool _containsSensitiveKeys(Map<String, Object?> properties) {
    const blocked = {
      'message',
      'messages',
      'screenshot',
      'image',
      'conversation_text',
      'bio',
      'raw',
    };
    return properties.keys.any((k) => blocked.contains(k.toLowerCase()));
  }
}

abstract final class AnalyticsEvents {
  static const onboardingCompleted = 'onboarding_completed';
  static const replyStarted = 'reply_started';
  static const conversationUploaded = 'conversation_uploaded';
  static const conversationAnalyzed = 'conversation_analyzed';
  static const responseGenerated = 'response_generated';
  static const responseCopied = 'response_copied';
  static const responseFeedback = 'response_feedback';
  static const personCreated = 'person_created';
  static const conversationSaved = 'conversation_saved';
  static const profileAuditStarted = 'profile_audit_started';
  static const practiceStarted = 'practice_started';
  static const practiceCompleted = 'practice_completed';
  static const paywallViewed = 'paywall_viewed';
  static const trialStarted = 'trial_started';
  static const subscriptionStarted = 'subscription_started';
  static const subscriptionCancelled = 'subscription_cancelled';
}
