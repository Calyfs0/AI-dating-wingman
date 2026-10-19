import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../screenshot_reply/models/suggested_replies.dart';
import '../../you/controllers/you_preferences_controller.dart';

class OnboardingController extends ChangeNotifier {
  OnboardingController(this._you);

  static const onboardedKey = 'gotchu_onboarded';

  final YouPreferencesController _you;

  bool loaded = false;
  bool onboarded = false;
  int step = 0;
  ReplyTone vibe = ReplyTone.natural;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    onboarded = prefs.getBool(onboardedKey) ?? false;
    vibe = _you.defaultVibe;
    loaded = true;
    notifyListeners();
  }

  void setVibe(ReplyTone tone) {
    vibe = tone;
    notifyListeners();
  }

  void next() {
    if (step < 2) {
      step++;
      notifyListeners();
    }
  }

  void back() {
    if (step > 0) {
      step--;
      notifyListeners();
    }
  }

  Future<void> complete() async {
    await _you.setDefaultVibe(vibe);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardedKey, true);
    onboarded = true;
    notifyListeners();
  }
}
