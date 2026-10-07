import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/local_repositories.dart';
import '../../domain/repositories/repositories.dart';
import '../../services/ai/ai_services.dart';
import '../../services/ai/mock_ai_services.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/auth/auth_service.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/privacy/privacy_service.dart';
import '../../services/subscription/subscription_services.dart';
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

  final localAuth = LocalAuthService(prefs);
  final auth = SupabaseReadyAuthService(localAuth);
  getIt.registerSingleton<AuthService>(auth);
  getIt.registerSingleton<UserRepository>(LocalUserRepository(auth));
  getIt.registerSingleton<PersonRepository>(LocalPersonRepository());
  getIt.registerSingleton<FeedbackRepository>(LocalFeedbackRepository());

  final subscription = LocalSubscriptionService();
  final entitlements = LocalEntitlementService(subscription);
  getIt
    ..registerSingleton<SubscriptionService>(subscription)
    ..registerSingleton<EntitlementService>(entitlements)
    ..registerSingleton<UsageService>(LocalUsageService(entitlements));

  getIt
    ..registerSingleton<ConversationAnalysisService>(
      MockConversationAnalysisService(),
    )
    ..registerSingleton<ResponseGenerationService>(
      MockResponseGenerationService(),
    )
    ..registerSingleton<ProfileAnalysisService>(MockProfileAnalysisService())
    ..registerSingleton<OpenerService>(MockOpenerService())
    ..registerSingleton<PracticeService>(MockPracticeService())
    ..registerSingleton<CoachingService>(MockCoachingService());

  await auth.ensureAnonymousSession();
  final profile = await auth.currentProfile();
  await subscription.configure(appUserId: profile.id);
  await getIt<AnalyticsService>().identify(profile.id);
}
