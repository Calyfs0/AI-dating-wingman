import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart' as app_errors;
import '../../domain/entities/communication_style.dart';
import '../../domain/entities/user_profile.dart';
import 'auth_service.dart';

/// Real Supabase anonymous auth + `profiles` sync.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);

  final SupabaseClient _client;

  @override
  Stream<UserProfile?> get authStateChanges async* {
    yield* _client.auth.onAuthStateChange.asyncMap((event) async {
      if (event.session == null) return null;
      return currentProfile();
    });
  }

  @override
  Future<UserProfile> ensureAnonymousSession() async {
    final existing = _client.auth.currentSession;
    if (existing == null) {
      final response = await _client.auth.signInAnonymously();
      if (response.user == null) {
        throw const app_errors.AuthException(
          'Could not create anonymous session.',
        );
      }
      debugPrint('Wingman: created Supabase anonymous session');
    }
    await _ensureProfileRow();
    return currentProfile();
  }

  Future<void> _ensureProfileRow() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final existing = await _client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
    if (existing != null) return;
    await _client.from('profiles').upsert({
      'id': user.id,
      'display_name': 'You',
      'is_anonymous': true,
      'learned_style': const CommunicationStyle(
        humor: 0.5,
        directness: 0.5,
        flirting: 0.5,
        formality: 0.2,
        emojiUsage: 0.3,
      ).toJson(),
    });
  }

  @override
  Future<UserProfile> currentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return ensureAnonymousSession();
    }

    final row = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) {
      await _ensureProfileRow();
      return currentProfile();
    }

    final focusRaw = (row['focus_areas'] as List?)?.cast<String>() ?? const [];
    final goalRaw = row['dating_goal'] as String?;
    final styleRaw = row['learned_style'];
    CommunicationStyle style = const CommunicationStyle();
    if (styleRaw is Map) {
      style = CommunicationStyle.fromJson(Map<String, dynamic>.from(styleRaw));
    }

    return UserProfile(
      id: user.id,
      displayName: (row['display_name'] as String?) ?? 'You',
      focusAreas: focusRaw
          .map((e) {
            try {
              return FocusArea.values.byName(e);
            } catch (_) {
              return null;
            }
          })
          .whereType<FocusArea>()
          .toList(),
      communicationStyles:
          (row['communication_styles'] as List?)?.cast<String>() ?? const [],
      flirtingLevel: (row['flirting_level'] as num?)?.toDouble() ?? 0.5,
      datingGoal: goalRaw == null
          ? null
          : () {
              try {
                return DatingGoal.values.byName(goalRaw);
              } catch (_) {
                return null;
              }
            }(),
      onboardingCompleted: row['onboarding_completed'] as bool? ?? false,
      notificationsEnabled: row['notifications_enabled'] as bool? ?? false,
      isAnonymous: row['is_anonymous'] as bool? ?? true,
      planLabel: 'Free plan',
      learnedStyle: style,
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'].toString())
          : null,
    );
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const app_errors.AuthException();
    }

    await _client.from('profiles').upsert({
      'id': user.id,
      'display_name': profile.displayName,
      'is_anonymous': profile.isAnonymous,
      'onboarding_completed': profile.onboardingCompleted,
      'dating_goal': profile.datingGoal?.name,
      'flirting_level': profile.flirtingLevel,
      'focus_areas': profile.focusAreas.map((e) => e.name).toList(),
      'communication_styles': profile.communicationStyles,
      'learned_style': profile.learnedStyle.toJson(),
      'notifications_enabled': profile.notificationsEnabled,
      'updated_at': DateTime.now().toIso8601String(),
    });

    await _client.from('notification_preferences').upsert({
      'user_id': user.id,
      'enabled': profile.notificationsEnabled,
    });

    return profile.copyWith(id: user.id);
  }

  @override
  Future<UserProfile> linkApple() async {
    final current = await currentProfile();
    return updateProfile(current.copyWith(isAnonymous: false));
  }

  @override
  Future<UserProfile> linkGoogle() async {
    final current = await currentProfile();
    return updateProfile(current.copyWith(isAnonymous: false));
  }

  @override
  Future<UserProfile> linkEmail(String email) async {
    final current = await currentProfile();
    return updateProfile(current.copyWith(isAnonymous: false));
  }

  @override
  Future<void> deleteAllData() async {
    try {
      await _client.functions.invoke('delete-account');
    } catch (_) {
      await _client.rpc('delete_user_data');
    }
    await _client.auth.signOut();
  }
}
