import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/local_repositories.dart';
import '../../data/repositories/supabase_repositories.dart';
import '../../domain/repositories/repositories.dart';
import '../../services/ai/ai_services.dart';
import '../../services/ai/mock_ai_services.dart';
import '../../services/ai/supabase_ai_services.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/supabase_auth_service.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/privacy/privacy_service.dart';
import '../../services/subscription/subscription_services.dart';
import '../../services/subscription/supabase_usage_service.dart';
import '../config/env_config.dart';
import '../network/connectivity_service.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();

  getIt
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerSingleton<ConnectivityService>(DeviceConnectivityService())
    ..registerSingleton<AnalyticsService>(DebugAnalyticsService())
    ..registerSingleton<PrivacyService>(LocalPrivacyService())
    ..registerSingleton<NotificationService>(LocalNotificationService(prefs));

  final subscription = LocalSubscriptionService();
  final entitlements = LocalEntitlementService(subscription);
  getIt
    ..registerSingleton<SubscriptionService>(subscription)
    ..registerSingleton<EntitlementService>(entitlements);

  if (EnvConfig.hasSupabase) {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      publishableKey: EnvConfig.supabaseAnonKey,
    );
    final client = Supabase.instance.client;
    final auth = SupabaseAuthService(client);

    getIt
      ..registerSingleton<SupabaseClient>(client)
      ..registerSingleton<AuthService>(auth)
      ..registerSingleton<UserRepository>(SupabaseUserRepository(auth))
      ..registerSingleton<PersonRepository>(SupabasePersonRepository(client))
      ..registerSingleton<ConversationRepository>(
        SupabaseConversationRepository(client),
      )
      ..registerSingleton<FeedbackRepository>(
        SupabaseFeedbackRepository(client),
      )
      ..registerSingleton<UsageService>(
        SupabaseUsageService(client, entitlements),
      )
      ..registerSingleton<ConversationAnalysisService>(
        SupabaseConversationAnalysisService(client),
      )
      ..registerSingleton<ResponseGenerationService>(
        SupabaseResponseGenerationService(client),
      );

    debugPrint('Wingman: Supabase backend enabled');
  } else {
    debugPrint(
      'Wingman: SUPABASE_URL / SUPABASE_ANON_KEY missing — local/mock mode. '
      'See docs/SETUP.md',
    );
    final localAuth = LocalAuthService(prefs);
    getIt
      ..registerSingleton<AuthService>(localAuth)
      ..registerSingleton<UserRepository>(LocalUserRepository(localAuth))
      ..registerSingleton<PersonRepository>(LocalPersonRepository())
      ..registerSingleton<ConversationRepository>(LocalConversationRepository())
      ..registerSingleton<FeedbackRepository>(LocalFeedbackRepository())
      ..registerSingleton<UsageService>(LocalUsageService(entitlements))
      ..registerSingleton<ConversationAnalysisService>(
        MockConversationAnalysisService(),
      )
      ..registerSingleton<ResponseGenerationService>(
        MockResponseGenerationService(),
      );
  }

  // Not in v1 slice — stay on mocks until wired.
  getIt
    ..registerSingleton<ProfileAnalysisService>(MockProfileAnalysisService())
    ..registerSingleton<OpenerService>(MockOpenerService())
    ..registerSingleton<PracticeService>(MockPracticeService())
    ..registerSingleton<CoachingService>(MockCoachingService());

  final auth = getIt<AuthService>();
  await auth.ensureAnonymousSession();
  final profile = await auth.currentProfile();
  await subscription.configure(appUserId: profile.id);
  await getIt<AnalyticsService>().identify(profile.id);
}
