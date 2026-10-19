import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Client-side usage display + soft gate.
///
/// **Server is source of truth** (`usage_events` via Edge Functions).
/// Local prefs keep the You tab snappy; [refreshFromServer] / [applyServerUsage]
/// reconcile after every billable call.
class UsageController extends ChangeNotifier {
  UsageController({
    this.freeDailyLimit = 12,
    this.proDailyLimit = 200,
  });

  static const _dayKey = 'gotchu_usage_day';
  static const _countKey = 'gotchu_usage_count';
  static const _proKey = 'gotchu_is_pro';

  /// Must match Edge `FREE_DAILY_LIMIT` default / `PRO_DAILY_LIMIT`.
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
    // Prefer server counts when online (non-blocking for first paint).
    unawaited(refreshFromServer());
  }

  Future<void> _rollDayIfNeeded(SharedPreferences prefs) async {
    final today = utcDayStamp();
    if (_day != today) {
      _day = today;
      usedToday = 0;
      await prefs.setString(_dayKey, _day);
      await prefs.setInt(_countKey, 0);
    }
  }

  /// UTC calendar day — matches Edge `_shared/usage.ts`.
  static String utcDayStamp([DateTime? now]) {
    final n = (now ?? DateTime.now()).toUtc();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static DateTime utcDayStart([DateTime? now]) {
    final n = (now ?? DateTime.now()).toUtc();
    return DateTime.utc(n.year, n.month, n.day);
  }

  /// Soft client gate (UX). Server still enforces.
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

  /// Apply snapshot returned by Edge (`usage` field) or 402 payload.
  Future<void> applyServerUsage({
    required int used,
    required int limit,
    required bool isPro,
  }) async {
    this.isPro = isPro;
    usedToday = used.clamp(0, limit > 0 ? limit : used);
    _day = utcDayStamp();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_proKey, isPro);
    await prefs.setString(_dayKey, _day);
    await prefs.setInt(_countKey, usedToday);
    notifyListeners();
  }

  Future<void> applyUsageMap(Map<String, dynamic>? usage) async {
    if (usage == null) return;
    final used = _asInt(usage['used']);
    final limit = _asInt(usage['limit']);
    if (used == null) return;
    await applyServerUsage(
      used: used,
      limit: limit ?? dailyLimit,
      isPro: usage['isPro'] == true,
    );
  }

  /// Force local bar to "empty" after a 402 (even if prefs were out of sync).
  Future<void> markExhausted([String? serverMessage]) async {
    usedToday = dailyLimit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKey, usedToday);
    await prefs.setString(_dayKey, utcDayStamp());
    notifyListeners();
  }

  /// Pull today's `generation` count from Supabase (RLS-scoped).
  Future<void> refreshFromServer() async {
    try {
      late final SupabaseClient client;
      try {
        client = Supabase.instance.client;
      } catch (_) {
        // Not initialized (unit tests / early boot).
        return;
      }
      final uid = client.auth.currentUser?.id;
      if (uid == null) return;

      final profile = await client
          .from('profiles')
          .select('is_pro')
          .eq('id', uid)
          .maybeSingle();
      final serverPro = profile?['is_pro'] == true;

      final rows = await client
          .from('usage_events')
          .select('id')
          .eq('user_id', uid)
          .eq('action', 'generation')
          .gte('created_at', utcDayStart().toIso8601String());

      final used = (rows as List).length;
      await applyServerUsage(
        used: used,
        limit: serverPro ? proDailyLimit : freeDailyLimit,
        isPro: serverPro,
      );
    } catch (e) {
      debugPrint('UsageController.refreshFromServer: $e');
    }
  }

  Future<void> setPro(bool value) async {
    isPro = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_proKey, value);
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
