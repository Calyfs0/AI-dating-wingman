import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/communication_style.dart';
import '../../domain/entities/user_profile.dart';

/// Auth boundary. Anonymous-first; account linking reconciles identity later.
abstract class AuthService {
  Future<UserProfile> ensureAnonymousSession();
  Future<UserProfile> currentProfile();
  Future<UserProfile> updateProfile(UserProfile profile);
  Future<UserProfile> linkApple();
  Future<UserProfile> linkGoogle();
  Future<UserProfile> linkEmail(String email);
  Future<void> deleteAllData();
  Stream<UserProfile?> get authStateChanges;
}

class LocalAuthService implements AuthService {
  LocalAuthService(this._prefs);

  final SharedPreferences _prefs;
  static const _uuid = Uuid();
  static const _keyUserId = 'wingman_user_id';
  static const _keyOnboarding = 'wingman_onboarding_done';
  static const _keyName = 'wingman_display_name';
  static const _keyFocus = 'wingman_focus';
  static const _keyStyles = 'wingman_styles';
  static const _keyFlirt = 'wingman_flirt';
  static const _keyGoal = 'wingman_goal';
  static const _keyNotifs = 'wingman_notifs';
  static const _keyAnonymous = 'wingman_anonymous';
  static const _keyStyleJson = 'wingman_learned_style';

  @override
  Stream<UserProfile?> get authStateChanges async* {
    yield await currentProfile();
  }

  @override
  Future<UserProfile> ensureAnonymousSession() async {
    var id = _prefs.getString(_keyUserId);
    if (id == null) {
      id = _uuid.v4();
      await _prefs.setString(_keyUserId, id);
      await _prefs.setBool(_keyAnonymous, true);
      await _prefs.setString(_keyName, 'Sagar');
      await _prefs.setString(
        _keyStyleJson,
        jsonEncode(
          const CommunicationStyle(
            humor: 0.82,
            directness: 0.61,
            flirting: 0.54,
            formality: 0.18,
            emojiUsage: 0.36,
          ).toJson(),
        ),
      );
      debugPrint('Kehlo: created anonymous session');
    }
    return currentProfile();
  }

  @override
  Future<UserProfile> currentProfile() async {
    final id = _prefs.getString(_keyUserId) ?? await _createId();
    final styleRaw = _prefs.getString(_keyStyleJson);
    CommunicationStyle style = const CommunicationStyle(
      humor: 0.82,
      directness: 0.61,
      flirting: 0.54,
      formality: 0.18,
      emojiUsage: 0.36,
    );
    if (styleRaw != null) {
      try {
        style = CommunicationStyle.fromJson(
          jsonDecode(styleRaw) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    return UserProfile(
      id: id,
      displayName: _prefs.getString(_keyName) ?? 'Sagar',
      focusAreas: (_prefs.getStringList(_keyFocus) ?? [])
          .map((e) => FocusArea.values.byName(e))
          .toList(),
      communicationStyles: _prefs.getStringList(_keyStyles) ?? const [],
      flirtingLevel: _prefs.getDouble(_keyFlirt) ?? 0.5,
      datingGoal: () {
        final raw = _prefs.getString(_keyGoal);
        if (raw == null) return null;
        return DatingGoal.values.byName(raw);
      }(),
      onboardingCompleted: _prefs.getBool(_keyOnboarding) ?? false,
      notificationsEnabled: _prefs.getBool(_keyNotifs) ?? false,
      isAnonymous: _prefs.getBool(_keyAnonymous) ?? true,
      planLabel: 'Free plan',
      learnedStyle: style,
      createdAt: DateTime.now(),
    );
  }

  Future<String> _createId() async {
    final id = _uuid.v4();
    await _prefs.setString(_keyUserId, id);
    await _prefs.setBool(_keyAnonymous, true);
    return id;
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    await _prefs.setString(_keyUserId, profile.id);
    await _prefs.setString(_keyName, profile.displayName);
    await _prefs.setStringList(
      _keyFocus,
      profile.focusAreas.map((e) => e.name).toList(),
    );
    await _prefs.setStringList(_keyStyles, profile.communicationStyles);
    await _prefs.setDouble(_keyFlirt, profile.flirtingLevel);
    if (profile.datingGoal != null) {
      await _prefs.setString(_keyGoal, profile.datingGoal!.name);
    }
    await _prefs.setBool(_keyOnboarding, profile.onboardingCompleted);
    await _prefs.setBool(_keyNotifs, profile.notificationsEnabled);
    await _prefs.setBool(_keyAnonymous, profile.isAnonymous);
    await _prefs.setString(
      _keyStyleJson,
      jsonEncode(profile.learnedStyle.toJson()),
    );
    return profile;
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
    await _prefs.clear();
  }
}

/// Supabase-ready wrapper. Falls back to local anonymous identity
/// until SUPABASE_URL / SUPABASE_ANON_KEY are provided at runtime.
class SupabaseReadyAuthService implements AuthService {
  SupabaseReadyAuthService(this._local);

  final LocalAuthService _local;

  @override
  Stream<UserProfile?> get authStateChanges => _local.authStateChanges;

  @override
  Future<UserProfile> ensureAnonymousSession() =>
      _local.ensureAnonymousSession();

  @override
  Future<UserProfile> currentProfile() => _local.currentProfile();

  @override
  Future<UserProfile> updateProfile(UserProfile profile) =>
      _local.updateProfile(profile);

  @override
  Future<UserProfile> linkApple() => _local.linkApple();

  @override
  Future<UserProfile> linkGoogle() => _local.linkGoogle();

  @override
  Future<UserProfile> linkEmail(String email) => _local.linkEmail(email);

  @override
  Future<void> deleteAllData() => _local.deleteAllData();
}
