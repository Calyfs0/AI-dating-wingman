import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/di/service_locator.dart';
import '../../core/errors/app_exception.dart';
import '../../core/network/connectivity_service.dart';
import '../../data/repositories/supabase_repositories.dart';
import '../../domain/entities/ai_generation.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/repositories.dart';
import '../../services/ai/ai_services.dart';
import '../../services/ai/supabase_ai_services.dart';
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
  final ConversationRepository _conversations = getIt<ConversationRepository>();
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
  List<String> lastAnalysisKeyFacts = const [];
  ProcessingStage? processingStage;
  bool isOnline = true;
  bool isBootstrapping = true;
  String? errorMessage;
  UsageSnapshot? usageSnapshot;
  StreamSubscription<bool>? _connectivitySub;

  Future<void> _init() async {
    profile = await _auth.ensureAnonymousSession();
    people = await _people.list();
    usageSnapshot = await _usage.snapshot();
    isOnline = await _connectivity.isOnline;
    _connectivitySub = _connectivity.onStatusChange.listen((online) {
      isOnline = online;
      notifyListeners();
    });
    isBootstrapping = false;
    notifyListeners();
  }

  Future<void> refreshUsage() async {
    usageSnapshot = await _usage.snapshot();
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

  Future<Conversation?> conversationForPerson(String personId) =>
      _conversations.latestForPerson(personId);

  Future<List<Conversation>> conversationsForPerson(String personId) =>
      _conversations.listForPerson(personId);

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

  void _clearActiveReply({bool notify = false}) {
    activeConversation = null;
    activeGeneration = null;
    lastAnalysisKeyFacts = const [];
    final analysis = _analysis;
    if (analysis is SupabaseConversationAnalysisService) {
      analysis.clearCache();
    }
    if (notify) {
      // Never notify during build — GoRouter listens to this controller.
      scheduleMicrotask(notifyListeners);
    }
  }

  Stream<ProcessingStage> processConversation({
    List<String> imagePaths = const [],
    String? pastedText,
  }) {
    _clearActiveReply(notify: true);
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
      final analysis = _analysis;
      if (analysis is SupabaseConversationAnalysisService) {
        lastAnalysisKeyFacts = analysis.lastKeyFacts;
      } else {
        lastAnalysisKeyFacts = activeConversation?.topics ?? const [];
      }
      final responses = _responses;
      if (responses is SupabaseResponseGenerationService &&
          activeConversation != null) {
        responses.activeConversation = activeConversation;
      }
      await _usage.record(UsageAction.conversationAnalysis);
      await _privacy.deleteTemporaryScreenshots();
      await _analytics.track(AnalyticsEvents.conversationAnalyzed);
      notifyListeners();
      return activeConversation;
    } catch (e) {
      errorMessage = e is AppException
          ? e.message
          : AppExceptionMapper.map(e).message;
      notifyListeners();
      return null;
    }
  }

  Future<AIGeneration?> generateResponse(ResponseTone tone) async {
    final conversation = activeConversation;
    if (conversation == null) return null;
    try {
      errorMessage = null;
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
    } catch (e) {
      errorMessage = e is AppException
          ? e.message
          : AppExceptionMapper.map(e).message;
      notifyListeners();
      return null;
    }
  }

  Future<AIGeneration?> humanizeActive() async {
    if (activeGeneration == null) return null;
    try {
      activeGeneration = await _responses.humanize(
        generation: activeGeneration!,
        style: profile?.learnedStyle,
      );
      notifyListeners();
      return activeGeneration;
    } catch (e) {
      errorMessage = e is AppException
          ? e.message
          : AppExceptionMapper.map(e).message;
      notifyListeners();
      return null;
    }
  }

  Future<AIGeneration?> regenerate(String direction) async {
    if (activeGeneration == null) return null;
    try {
      activeGeneration = await _responses.regenerate(
        generation: activeGeneration!,
        direction: direction,
        style: profile?.learnedStyle,
      );
      notifyListeners();
      return activeGeneration;
    } catch (e) {
      errorMessage = e is AppException
          ? e.message
          : AppExceptionMapper.map(e).message;
      notifyListeners();
      return null;
    }
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

  Future<Person> saveConversationToPerson({Person? person, String? name}) async {
    final conversation = activeConversation;
    final displayName = name?.trim().isNotEmpty == true
        ? name!.trim()
        : (conversation?.personName ?? 'Someone');
    final summary = conversation?.recommendedStrategy.read.isNotEmpty == true
        ? conversation!.recommendedStrategy.read
        : 'Conversation saved';
    final facts = lastAnalysisKeyFacts.isNotEmpty
        ? lastAnalysisKeyFacts
        : (conversation?.topics ?? const <String>[]);

    final Person target;
    if (person != null) {
      target = await _people.update(
        person.copyWith(
          latestContext: summary,
          lastActivityAt: DateTime.now(),
          status: PersonStatus.active,
          keyFacts: facts.isNotEmpty ? facts : person.keyFacts,
          timeline: [
            ...person.timeline,
            PersonTimelineEvent(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              label: 'Conversation analyzed',
              at: DateTime.now(),
            ),
          ],
        ),
      );
    } else {
      target = await _people.create(
        Person(
          id: '',
          name: displayName,
          platform: conversation?.platform ?? 'Hinge',
          status: PersonStatus.active,
          lastActivityAt: DateTime.now(),
          latestContext: summary,
          keyFacts: facts,
          timeline: [
            PersonTimelineEvent(
              id: '1',
              label: 'Conversation saved',
              at: DateTime.now(),
            ),
          ],
        ),
      );
    }

    final peopleRepo = _people;
    if (conversation != null && peopleRepo is SupabasePersonRepository) {
      await peopleRepo.linkConversation(
        conversationId: conversation.id,
        personId: target.id,
      );
      activeConversation = Conversation(
        id: conversation.id,
        personId: target.id,
        personName: target.name,
        platform: conversation.platform,
        participants: conversation.participants,
        messages: conversation.messages,
        topics: conversation.topics,
        conversationState: conversation.conversationState,
        interestSignals: conversation.interestSignals,
        recommendedStrategy: conversation.recommendedStrategy,
        confidence: conversation.confidence,
        rawImagePaths: conversation.rawImagePaths,
        pastedText: conversation.pastedText,
      );
    }

    await _analytics.track(AnalyticsEvents.conversationSaved);
    await refreshPeople();
    return target;
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
}
