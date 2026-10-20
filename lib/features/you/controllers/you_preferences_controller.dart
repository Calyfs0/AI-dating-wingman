import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../screenshot_reply/models/generation_prefs.dart';
import '../../screenshot_reply/models/suggested_replies.dart';

class YouPreferencesController extends ChangeNotifier {
  YouPreferencesController();

  static const _vibeKey = 'kehlo_default_vibe';
  static const _casualKey = 'kehlo_keep_casual';
  static const _matchLangKey = 'kehlo_match_language';

  // Legacy keys — migrated once on load.
  static const _gotchuVibeKey = 'gotchu_default_vibe';
  static const _gotchuCasualKey = 'gotchu_keep_casual';
  static const _gotchuMatchLangKey = 'gotchu_match_language';
  static const _legacyVibeKey = 'wingman_default_vibe';
  static const _legacyCasualKey = 'wingman_keep_casual';
  static const _legacyMatchLangKey = 'wingman_match_language';

  ReplyTone defaultVibe = ReplyTone.natural;
  bool keepCasual = true;
  bool matchLanguage = true;
  bool loaded = false;

  GenerationPrefs get asGenerationPrefs => GenerationPrefs(
        preferredVibe: defaultVibe,
        keepCasual: keepCasual,
        matchLanguage: matchLanguage,
      );

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final vibeName = prefs.getString(_vibeKey) ??
        prefs.getString(_gotchuVibeKey) ??
        prefs.getString(_legacyVibeKey);
    defaultVibe = ReplyTone.values.firstWhere(
      (t) => t.name == vibeName,
      orElse: () => ReplyTone.natural,
    );
    keepCasual = prefs.getBool(_casualKey) ??
        prefs.getBool(_gotchuCasualKey) ??
        prefs.getBool(_legacyCasualKey) ??
        true;
    matchLanguage = prefs.getBool(_matchLangKey) ??
        prefs.getBool(_gotchuMatchLangKey) ??
        prefs.getBool(_legacyMatchLangKey) ??
        true;
    loaded = true;
    notifyListeners();

    // Migrate legacy keys when present.
    final migrating = prefs.containsKey(_gotchuVibeKey) ||
        prefs.containsKey(_gotchuCasualKey) ||
        prefs.containsKey(_gotchuMatchLangKey) ||
        prefs.containsKey(_legacyVibeKey) ||
        prefs.containsKey(_legacyCasualKey) ||
        prefs.containsKey(_legacyMatchLangKey);
    if (migrating) {
      await prefs.setString(_vibeKey, defaultVibe.name);
      await prefs.setBool(_casualKey, keepCasual);
      await prefs.setBool(_matchLangKey, matchLanguage);
      for (final k in [
        _gotchuVibeKey,
        _gotchuCasualKey,
        _gotchuMatchLangKey,
        _legacyVibeKey,
        _legacyCasualKey,
        _legacyMatchLangKey,
      ]) {
        await prefs.remove(k);
      }
    }
  }

  Future<void> setDefaultVibe(ReplyTone tone) async {
    defaultVibe = tone;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vibeKey, tone.name);
  }

  Future<void> setKeepCasual(bool value) async {
    keepCasual = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_casualKey, value);
  }

  Future<void> setMatchLanguage(bool value) async {
    matchLanguage = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_matchLangKey, value);
  }
}
