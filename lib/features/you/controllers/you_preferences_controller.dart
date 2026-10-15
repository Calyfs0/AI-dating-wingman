import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../screenshot_reply/models/suggested_replies.dart';

class YouPreferencesController extends ChangeNotifier {
  YouPreferencesController();

  static const _vibeKey = 'wingman_default_vibe';
  static const _casualKey = 'wingman_keep_casual';
  static const _matchLangKey = 'wingman_match_language';

  ReplyTone defaultVibe = ReplyTone.natural;
  bool keepCasual = true;
  bool matchLanguage = true;
  bool loaded = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final vibeName = prefs.getString(_vibeKey);
    defaultVibe = ReplyTone.values.firstWhere(
      (t) => t.name == vibeName,
      orElse: () => ReplyTone.natural,
    );
    keepCasual = prefs.getBool(_casualKey) ?? true;
    matchLanguage = prefs.getBool(_matchLangKey) ?? true;
    loaded = true;
    notifyListeners();
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
