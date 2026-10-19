import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../screenshot_reply/models/generation_prefs.dart';
import '../../screenshot_reply/models/suggested_replies.dart';

class YouPreferencesController extends ChangeNotifier {
  YouPreferencesController();

  static const _vibeKey = 'gotchu_default_vibe';
  static const _casualKey = 'gotchu_keep_casual';
  static const _matchLangKey = 'gotchu_match_language';

  // Legacy Wingman keys — migrated once on load.
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
    final vibeName =
        prefs.getString(_vibeKey) ?? prefs.getString(_legacyVibeKey);
    defaultVibe = ReplyTone.values.firstWhere(
      (t) => t.name == vibeName,
      orElse: () => ReplyTone.natural,
    );
    keepCasual = prefs.getBool(_casualKey) ??
        prefs.getBool(_legacyCasualKey) ??
        true;
    matchLanguage = prefs.getBool(_matchLangKey) ??
        prefs.getBool(_legacyMatchLangKey) ??
        true;
    loaded = true;
    notifyListeners();

    // Migrate legacy keys when present.
    if (prefs.containsKey(_legacyVibeKey) ||
        prefs.containsKey(_legacyCasualKey) ||
        prefs.containsKey(_legacyMatchLangKey)) {
      await prefs.setString(_vibeKey, defaultVibe.name);
      await prefs.setBool(_casualKey, keepCasual);
      await prefs.setBool(_matchLangKey, matchLanguage);
      await prefs.remove(_legacyVibeKey);
      await prefs.remove(_legacyCasualKey);
      await prefs.remove(_legacyMatchLangKey);
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
