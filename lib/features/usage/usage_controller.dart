import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local daily usage limits for free plan. Pro waitlist unlocks higher caps
/// when [isPro] is flipped (RevenueCat later).
class UsageController extends ChangeNotifier {
  UsageController({
    this.freeDailyLimit = 12,
    this.proDailyLimit = 200,
  });

  static const _dayKey = 'gotchu_usage_day';
  static const _countKey = 'gotchu_usage_count';
  static const _proKey = 'gotchu_is_pro';

  final int freeDailyLimit;
  final int proDailyLimit;

  bool loaded = false;
  bool isPro = false;
  int usedToday = 0;
  String _day = '';

  int get dailyLimit => isPro ? proDailyLimit : freeDailyLimit;
  int get remaining => (dailyLimit - usedToday).clamp(0, dailyLimit);
  bool get canGenerate => remaining > 0;

  String get limitMessage => isPro
      ? "You've hit today's Pro limit. Try again tomorrow."
      : "You've used today's free replies. Pro unlocks more — join the waitlist in You.";

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    isPro = prefs.getBool(_proKey) ?? false;
    _day = prefs.getString(_dayKey) ?? '';
    usedToday = prefs.getInt(_countKey) ?? 0;
    await _rollDayIfNeeded(prefs);
    loaded = true;
    notifyListeners();
  }

  Future<void> _rollDayIfNeeded(SharedPreferences prefs) async {
    final today = _todayStamp();
    if (_day != today) {
      _day = today;
      usedToday = 0;
      await prefs.setString(_dayKey, _day);
      await prefs.setInt(_countKey, 0);
    }
  }

  String _todayStamp() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  /// Returns false if over limit (does not increment).
  Future<bool> tryConsume() async {
    final prefs = await SharedPreferences.getInstance();
    await _rollDayIfNeeded(prefs);
    if (usedToday >= dailyLimit) {
      notifyListeners();
      return false;
    }
    usedToday++;
    await prefs.setInt(_countKey, usedToday);
    notifyListeners();
    return true;
  }

  Future<void> setPro(bool value) async {
    isPro = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_proKey, value);
  }
}
