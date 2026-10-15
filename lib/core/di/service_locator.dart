import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../features/screenshot_reply/services/generate_replies_service.dart';
import '../config/env_config.dart';
import '../errors/app_exception.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
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

  getIt
    ..registerSingleton<SupabaseClient>(client)
    ..registerSingleton<GenerateRepliesService>(
      SupabaseGenerateRepliesService(client),
    );

  debugPrint('Wingman: Supabase backend enabled (screenshot → reply)');
}

Future<void> _ensureAnonymousSession(SupabaseClient client) async {
  if (client.auth.currentSession != null) return;
  final response = await client.auth.signInAnonymously();
  if (response.user == null) {
    throw const AuthException('Could not start a private session.');
  }
  debugPrint('Wingman: anonymous session ready');
}
