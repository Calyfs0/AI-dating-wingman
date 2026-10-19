import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../features/history/controllers/history_controller.dart';
import '../../features/onboarding/controllers/onboarding_controller.dart';
import '../../features/openers/controllers/openers_flow_controller.dart';
import '../../features/people/controllers/people_controller.dart';
import '../../features/people/services/people_coach_service.dart';
import '../../features/practice/controllers/practice_controller.dart';
import '../../features/practice/services/practice_service.dart';
import '../../features/profile_audit/controllers/profile_audit_controller.dart';
import '../../features/profile_audit/services/profile_audit_service.dart';
import '../../features/screenshot_reply/controllers/reply_flow_controller.dart';
import '../../features/screenshot_reply/services/generate_replies_service.dart';
import '../../features/usage/usage_controller.dart';
import '../../features/you/controllers/you_preferences_controller.dart';
import '../../features/you/services/account_service.dart';
import '../config/env_config.dart';
import '../errors/app_exception.dart';

final getIt = GetIt.instance;

/// Boots Supabase + registers services and session controllers.
/// Safe to call repeatedly: services register once; controllers re-bind if disposed.
Future<void> configureDependencies() async {
  if (!getIt.isRegistered<SupabaseClient>()) {
    if (!EnvConfig.hasSupabase) {
      throw const AuthException(
        'Supabase is not configured. Add your project URL and anon key.',
      );
    }

    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      publishableKey: EnvConfig.supabaseAnonKey,
    );

    final client = Supabase.instance.client;
    await _ensureAnonymousSession(client);
    _registerServices(client);
  }

  if (!getIt.isRegistered<YouPreferencesController>()) {
    _registerControllers();
    await _loadControllers();
  }

  debugPrint('Gotchu: DI ready (services + controllers)');
}

void _registerServices(SupabaseClient client) {
  getIt
    ..registerSingleton<SupabaseClient>(client)
    ..registerSingleton<GenerateRepliesService>(
      SupabaseGenerateRepliesService(client),
    )
    ..registerSingleton<PracticeService>(PracticeService(client))
    ..registerSingleton<ProfileAuditService>(ProfileAuditService(client))
    ..registerSingleton<PeopleCoachService>(PeopleCoachService(client))
    ..registerSingleton<AccountService>(AccountService(client));
}

void _registerControllers() {
  final you = YouPreferencesController();
  final history = HistoryController();
  final usage = UsageController();
  final people = PeopleController();
  final onboarding = OnboardingController(you);

  getIt
    ..registerSingleton<YouPreferencesController>(
      you,
      dispose: (c) => c.dispose(),
    )
    ..registerSingleton<HistoryController>(
      history,
      dispose: (c) => c.dispose(),
    )
    ..registerSingleton<UsageController>(
      usage,
      dispose: (c) => c.dispose(),
    )
    ..registerSingleton<PeopleController>(
      people,
      dispose: (c) => c.dispose(),
    )
    ..registerSingleton<OnboardingController>(
      onboarding,
      dispose: (c) => c.dispose(),
    )
    ..registerSingleton<ReplyFlowController>(
      ReplyFlowController(
        getIt<GenerateRepliesService>(),
        prefsOf: () => getIt<YouPreferencesController>().asGenerationPrefs,
        history: history,
        usage: usage,
      ),
      dispose: (c) => c.dispose(),
    )
    ..registerSingleton<OpenersFlowController>(
      OpenersFlowController(
        getIt<GenerateRepliesService>(),
        prefsOf: () => getIt<YouPreferencesController>().asGenerationPrefs,
        history: history,
        usage: usage,
      ),
      dispose: (c) => c.dispose(),
    )
    ..registerSingleton<PracticeController>(
      PracticeController(getIt<PracticeService>()),
      dispose: (c) => c.dispose(),
    )
    ..registerSingleton<ProfileAuditController>(
      ProfileAuditController(
        getIt<ProfileAuditService>(),
        usage: usage,
      ),
      dispose: (c) => c.dispose(),
    );
}

Future<void> _loadControllers() async {
  await Future.wait<void>([
    getIt<YouPreferencesController>().load(),
    getIt<HistoryController>().load(),
    getIt<UsageController>().load(),
    getIt<PeopleController>().load(),
    getIt<OnboardingController>().load(),
  ]);
}

/// Dispose session controllers only (keeps Supabase + services for process lifetime).
Future<void> disposeSessionControllers() async {
  Future<void> drop<T extends Object>() async {
    if (!getIt.isRegistered<T>()) return;
    await getIt.unregister<T>();
  }

  await drop<ReplyFlowController>();
  await drop<OpenersFlowController>();
  await drop<PracticeController>();
  await drop<ProfileAuditController>();
  await drop<OnboardingController>();
  await drop<PeopleController>();
  await drop<UsageController>();
  await drop<HistoryController>();
  await drop<YouPreferencesController>();
}

Future<void> _ensureAnonymousSession(SupabaseClient client) async {
  if (client.auth.currentSession != null) return;
  final response = await client.auth.signInAnonymously();
  if (response.user == null) {
    throw const AuthException('Could not start a private session.');
  }
  debugPrint('Gotchu: anonymous session ready');
}
