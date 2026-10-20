import 'dart:async';

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

  static const _dayKey = 'kehlo_usage_day';
  static const _countKey = 'kehlo_usage_count';
  static const _proKey = 'kehlo_is_pro';
  static const _expiresKey = 'kehlo_pro_expires_at';
  static const _gotchuDayKey = 'gotchu_usage_day';
  static const _gotchuCountKey = 'gotchu_usage_count';
  static const _gotchuProKey = 'gotchu_is_pro';

  /// Must match Edge `FREE_DAILY_LIMIT` default / `PRO_DAILY_LIMIT`.
  final int freeDailyLimit;
  final int proDailyLimit;

  bool loaded = false;
  bool isPro = false;
  int usedToday = 0;
  String _day = '';

  /// When set, Pro is a timed Boost. Null = subscription / non-expiring.
  DateTime? proExpiresAt;

  Timer? _boostTicker;

  /// Store already charged Monthly. Don't let a stale Boost expiry overwrite it.
  bool _keepMonthly = false;

  int get dailyLimit => isPro ? proDailyLimit : freeDailyLimit;
  int get remaining => (dailyLimit - usedToday).clamp(0, dailyLimit);
  bool get canGenerate => remaining > 0;

  bool get isBoostPro =>
      isPro &&
      proExpiresAt != null &&
      proExpiresAt!.isAfter(DateTime.now().toUtc());

  bool get isSubscriptionPro => isPro && proExpiresAt == null;

  Duration? get boostRemaining {
    if (!isBoostPro || proExpiresAt == null) return null;
    final left = proExpiresAt!.difference(DateTime.now().toUtc());
    return left.isNegative ? Duration.zero : left;
  }

  String get proStatusLabel {
    if (!isPro) return 'Free · $remaining/$dailyLimit replies today';
    if (isBoostPro) {
      final left = boostRemaining ?? Duration.zero;
      // Time only — remaining is reply budget, not "boosts left".
      return 'Boost · ${_formatBoostLeft(left)} left';
    }
    return 'Pro · $remaining replies left today';
  }

  String get limitMessage => isPro
      ? "You've hit today's Pro limit. Try again tomorrow."
      : "You've used today's free replies. Pro unlocks more — upgrade anytime.";

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    isPro = prefs.getBool(_proKey) ?? prefs.getBool(_gotchuProKey) ?? false;
    _day = prefs.getString(_dayKey) ?? prefs.getString(_gotchuDayKey) ?? '';
    usedToday =
        prefs.getInt(_countKey) ?? prefs.getInt(_gotchuCountKey) ?? 0;
    final expRaw = prefs.getString(_expiresKey);
    proExpiresAt = expRaw != null && expRaw.isNotEmpty
        ? DateTime.tryParse(expRaw)?.toUtc()
        : null;
    _applyExpiryLocal();
    if (prefs.containsKey(_gotchuDayKey) ||
        prefs.containsKey(_gotchuCountKey) ||
        prefs.containsKey(_gotchuProKey)) {
      await prefs.setBool(_proKey, isPro);
      await prefs.setString(_dayKey, _day);
      await prefs.setInt(_countKey, usedToday);
      await prefs.remove(_gotchuDayKey);
      await prefs.remove(_gotchuCountKey);
      await prefs.remove(_gotchuProKey);
    }
    await _rollDayIfNeeded(prefs);
    loaded = true;
    _ensureBoostTicker();
    notifyListeners();
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

  static String _formatBoostLeft(Duration d) {
    final totalMin = d.inMinutes.clamp(0, 24 * 60);
    if (totalMin >= 60) {
      final h = totalMin ~/ 60;
      final m = totalMin % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    if (totalMin <= 0) {
      final s = d.inSeconds.clamp(0, 59);
      return '${s}s';
    }
    return '${totalMin}m';
  }

  void _applyExpiryLocal() {
    if (proExpiresAt == null) return;
    if (!proExpiresAt!.isAfter(DateTime.now().toUtc())) {
      isPro = false;
      proExpiresAt = null;
    }
  }

  void _ensureBoostTicker() {
    _boostTicker?.cancel();
    _boostTicker = null;
    if (!isBoostPro) return;
    _boostTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      final wasPro = isPro;
      _applyExpiryLocal();
      if (!isPro && wasPro) {
        unawaited(_persistProFlags());
        _boostTicker?.cancel();
        _boostTicker = null;
      }
      notifyListeners();
    });
  }

  Future<void> _persistProFlags() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_proKey, isPro);
    if (proExpiresAt == null) {
      await prefs.remove(_expiresKey);
    } else {
      await prefs.setString(_expiresKey, proExpiresAt!.toIso8601String());
    }
  }

  /// Soft client gate (UX). Server still enforces.
  Future<bool> tryConsume() async {
    final prefs = await SharedPreferences.getInstance();
    await _rollDayIfNeeded(prefs);
    _applyExpiryLocal();
    if (usedToday >= dailyLimit) {
      notifyListeners();
      return false;
    }
    usedToday++;
    await prefs.setInt(_countKey, usedToday);
    notifyListeners();
    return true;
  }

  /// Undo a soft [tryConsume] when the user cancels before the server bills.
  Future<void> refundConsume() async {
    if (usedToday <= 0) return;
    usedToday--;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKey, usedToday);
    notifyListeners();
  }

  /// Apply snapshot returned by Edge (`usage` field) or 402 payload.
  Future<void> applyServerUsage({
    required int used,
    required int limit,
    required bool isPro,
    DateTime? proExpiresAt,
    bool clearExpiry = false,
  }) async {
    this.isPro = isPro;
    if (clearExpiry) {
      this.proExpiresAt = null;
    } else if (proExpiresAt != null) {
      this.proExpiresAt = proExpiresAt.toUtc();
    }
    // Only a profile with Pro and no expiry means Monthly has landed.
    // A generation payload can also have a null expiry — don't drop the hold then.
    if (_keepMonthly && isPro && clearExpiry) {
      _keepMonthly = false;
    } else if (_keepMonthly) {
      this.isPro = true;
      this.proExpiresAt = null;
    }
    if (this.isPro) _applyExpiryLocal();
    usedToday = used.clamp(0, limit > 0 ? limit : used);
    _day = utcDayStamp();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_proKey, this.isPro);
    await prefs.setString(_dayKey, _day);
    await prefs.setInt(_countKey, usedToday);
    if (this.proExpiresAt == null) {
      await prefs.remove(_expiresKey);
    } else {
      await prefs.setString(
        _expiresKey,
        this.proExpiresAt!.toIso8601String(),
      );
    }
    _ensureBoostTicker();
    notifyListeners();
  }

  Future<void> applyUsageMap(Map<String, dynamic>? usage) async {
    if (usage == null) return;
    final used = _asInt(usage['used']);
    final limit = _asInt(usage['limit']);
    if (used == null) return;
    final serverPro = usage['isPro'] == true;
    // Generation payloads don't include expiry — clear Boost timer when not Pro.
    await applyServerUsage(
      used: used,
      limit: limit ?? dailyLimit,
      isPro: serverPro,
      clearExpiry: !serverPro,
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
        return;
      }
      final uid = client.auth.currentUser?.id;
      if (uid == null) return;

      final profile = await client
          .from('profiles')
          .select('is_pro, pro_expires_at')
          .eq('id', uid)
          .maybeSingle();
      var serverPro = profile?['is_pro'] == true;
      DateTime? expires;
      final expiresRaw = profile?['pro_expires_at'] as String?;
      if (expiresRaw != null && expiresRaw.isNotEmpty) {
        expires = DateTime.tryParse(expiresRaw)?.toUtc();
      }
      if (serverPro && expires != null && !expires.isAfter(DateTime.now().toUtc())) {
        serverPro = false;
        expires = null;
      }

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
        proExpiresAt: expires,
        clearExpiry: !serverPro || expires == null,
      );
    } catch (e) {
      debugPrint('UsageController.refreshFromServer: $e');
    }
  }

  void keepMonthlyUntilServerAgrees() {
    _keepMonthly = true;
  }

  /// [expiresAt] null while [value] is true = Monthly / non-expiring Pro
  /// (clears any leftover Boost timer).
  Future<void> setPro(
    bool value, {
    DateTime? expiresAt,
    bool serverSubscription = false,
  }) async {
    if (serverSubscription && value && expiresAt == null) {
      _keepMonthly = false;
    }
    if (_keepMonthly && !serverSubscription) {
      value = true;
      expiresAt = null;
    }
    isPro = value;
    if (!value) {
      proExpiresAt = null;
    } else {
      proExpiresAt = expiresAt?.toUtc();
    }
    if (isPro) _applyExpiryLocal();
    await _persistProFlags();
    _ensureBoostTicker();
    notifyListeners();
  }

  @override
  void dispose() {
    _boostTicker?.cancel();
    super.dispose();
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
