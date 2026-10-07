import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/di/service_locator.dart';
import '../../core/network/connectivity_service.dart';
import '../../domain/entities/ai_generation.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/repositories.dart';
import '../../services/ai/ai_services.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/auth/auth_service.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/privacy/privacy_service.dart';
import '../../services/subscription/subscription_services.dart';

class AppController extends ChangeNotifier {
  AppController() {
    _init();
  }

  final AuthService _auth = getIt<AuthService>();
  final UserRepository _users = getIt<UserRepository>();
  final PersonRepository _people = getIt<PersonRepository>();
  final FeedbackRepository _feedback = getIt<FeedbackRepository>();
  final AnalyticsService _analytics = getIt<AnalyticsService>();
  final NotificationService _notifications = getIt<NotificationService>();
  final PrivacyService _privacy = getIt<PrivacyService>();
  final ConnectivityService _connectivity = getIt<ConnectivityService>();
  final ConversationAnalysisService _analysis =
      getIt<ConversationAnalysisService>();
  final ResponseGenerationService _responses =
      getIt<ResponseGenerationService>();
  final ProfileAnalysisService _profiles = getIt<ProfileAnalysisService>();
  final OpenerService _openers = getIt<OpenerService>();
  final PracticeService _practice = getIt<PracticeService>();
  final CoachingService _coaching = getIt<CoachingService>();
  final UsageService _usage = getIt<UsageService>();
  final EntitlementService _entitlements = getIt<EntitlementService>();
  final SubscriptionService _subscriptions = getIt<SubscriptionService>();

  UserProfile? profile;
  List<Person> people = [];
  Conversation? activeConversation;
  AIGeneration? activeGeneration;
  ProcessingStage? processingStage;
  bool isOnline = true;
  bool isBootstrapping = true;
  String? errorMessage;
  StreamSubscription<bool>? _connectivitySub;

  Future<void> _init() async {
    profile = await _auth.ensureAnonymousSession();
    people = await _people.list();
    isOnline = await _connectivity.isOnline;
    _connectivitySub = _connectivity.onStatusChange.listen((online) {
      isOnline = online;
      notifyListeners();
    });
    isBootstrapping = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> refreshProfile() async {
    profile = await _users.getProfile();
    notifyListeners();
  }

  Future<void> saveOnboarding(UserProfile Function(UserProfile) transform) async {
    final current = profile ?? await _auth.currentProfile();
    profile = await _users.saveProfile(transform(current));
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await saveOnboarding((p) => p.copyWith(onboardingCompleted: true));
    await _analytics.track(AnalyticsEvents.onboardingCompleted);
  }

  Future<bool> requestNotifications() async {
    final granted = await _notifications.requestPermission();
    await saveOnboarding((p) => p.copyWith(notificationsEnabled: granted));
    return granted;
  }

  Future<void> refreshPeople({PersonFilter filter = PersonFilter.all}) async {
    people = await _people.list(filter: filter);
    notifyListeners();
  }

  Future<Person?> personById(String id) => _people.getById(id);

  Future<Person> addPerson({
    required String name,
    String platform = 'Hinge',
  }) async {
    final person = await _people.create(
      Person(
        id: '',
        name: name,
        platform: platform,
        status: PersonStatus.active,
        lastActivityAt: DateTime.now(),
        latestContext: 'Just added',
      ),
    );
    await _analytics.track(AnalyticsEvents.personCreated);
    await refreshPeople();
    return person;
  }

  Stream<ProcessingStage> processConversation({
    List<String> imagePaths = const [],
    String? pastedText,
  }) {
    for (final path in imagePaths) {
      _privacy.markScreenshotTemporary(path);
    }
    if (imagePaths.isNotEmpty) {
      _analytics.track(
        AnalyticsEvents.conversationUploaded,
        properties: {'count': imagePaths.length},
      );
    }
    return _analysis.analyzeProgress(
      imagePaths: imagePaths,
      pastedText: pastedText,
    );
  }

  Future<Conversation?> finishAnalysis({
    List<String> imagePaths = const [],
    String? pastedText,
    String? personName,
  }) async {
    errorMessage = null;
    final allowed = await _usage.canConsume(UsageAction.conversationAnalysis);
    if (!allowed) {
      errorMessage = const UsageLimitException().message;
      notifyListeners();
      return null;
    }
    try {
      activeConversation = await _analysis.analyze(
        imagePaths: imagePaths,
        pastedText: pastedText,
        personName: personName,
      );
      await _usage.record(UsageAction.conversationAnalysis);
      await _privacy.deleteTemporaryScreenshots();
      await _analytics.track(AnalyticsEvents.conversationAnalyzed);
      notifyListeners();
      return activeConversation;
    } catch (e) {
      errorMessage = 'Couldn\'t read this conversation. Try a clearer screenshot or paste the text instead.';
      notifyListeners();
      return null;
    }
  }

  Future<AIGeneration?> generateResponse(ResponseTone tone) async {
    final conversation = activeConversation;
    if (conversation == null) return null;
    activeGeneration = await _responses.generate(
      conversation: conversation,
      tone: tone,
      style: profile?.learnedStyle,
    );
    await _analytics.track(
      AnalyticsEvents.responseGenerated,
      properties: {'tone': tone.name},
    );
    notifyListeners();
    return activeGeneration;
  }

  Future<AIGeneration?> humanizeActive() async {
    if (activeGeneration == null) return null;
    activeGeneration = await _responses.humanize(
      generation: activeGeneration!,
      style: profile?.learnedStyle,
    );
    notifyListeners();
    return activeGeneration;
  }

  Future<AIGeneration?> regenerate(String direction) async {
    if (activeGeneration == null) return null;
    activeGeneration = await _responses.regenerate(
      generation: activeGeneration!,
      direction: direction,
      style: profile?.learnedStyle,
    );
    notifyListeners();
    return activeGeneration;
  }

  Future<void> submitFeedback({
    required bool isPositive,
    List<FeedbackIssue> issues = const [],
  }) async {
    if (activeGeneration == null) return;
    await _feedback.save(
      GenerationFeedback(
        generationId: activeGeneration!.id,
        isPositive: isPositive,
        issues: issues,
      ),
    );
    await _analytics.track(
      AnalyticsEvents.responseFeedback,
      properties: {
        'positive': isPositive,
        'issues': issues.map((e) => e.name).toList(),
      },
    );
  }

  Future<void> trackCopy() =>
      _analytics.track(AnalyticsEvents.responseCopied);

  Future<void> saveConversationToPerson(Person person) async {
    await _people.update(
      person.copyWith(
        latestContext: 'Conversation saved',
        lastActivityAt: DateTime.now(),
        status: PersonStatus.active,
      ),
    );
    await _analytics.track(AnalyticsEvents.conversationSaved);
    await refreshPeople();
  }

  ConversationAnalysisService get analysisService => _analysis;
  ResponseGenerationService get responseService => _responses;
  ProfileAnalysisService get profileService => _profiles;
  OpenerService get openerService => _openers;
  PracticeService get practiceService => _practice;
  CoachingService get coachingService => _coaching;
  UsageService get usageService => _usage;
  EntitlementService get entitlementService => _entitlements;
  SubscriptionService get subscriptionService => _subscriptions;
  AnalyticsService get analytics => _analytics;
  PrivacyService get privacy => _privacy;
  AuthService get auth => _auth;
  NotificationService get notifications => _notifications;

  /// Seeds demo conversation/generation state for screenshot / deep-link demos.
  void prepareDemoForRoute(String path) {
    final needsConversation = path.startsWith('/reply/') &&
        path != '/reply' &&
        !path.startsWith('/reply/processing');
    if (needsConversation && activeConversation == null) {
      activeConversation = Conversation(
        id: 'demo',
        personName: 'Emma',
        platform: 'Hinge',
        participants: const ['You', 'Emma'],
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
        messages: const [
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
      );
    }
    if ((path.contains('/response') || path.contains('/review')) &&
        activeGeneration == null) {
      activeGeneration = const AIGeneration(
        id: 'demo-gen',
        text: 'Okay now I\'m curious 😂\nhow did you even end up there?',
        tone: ResponseTone.playful,
        alternatives: [
          'Okay that\'s unfairly interesting. What started it?',
          'I need the short version of that story.',
        ],
        whyItWorks:
            'It references the conversation, stays light, and gives them an easy opening.',
        sendWorthiness: 8.4,
      );
    }
    notifyListeners();
  }
}

// Re-export for convenience in controller file consumers.
class UsageLimitException implements Exception {
  const UsageLimitException([
    this.message = 'You\'ve reached your free limit. Go Pro to continue.',
  ]);
  final String message;
}
