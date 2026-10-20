import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/subscription/subscription_services.dart';
import '../../usage/usage_controller.dart';

/// Owns paywall offerings + purchase/restore → server-verified [UsageController.isPro].
class SubscriptionController extends ChangeNotifier {
  SubscriptionController({
    required SubscriptionService subscription,
    required UsageController usage,
    required SupabaseClient client,
  })  : _subscription = subscription,
        _usage = usage,
        _client = client {
    _subscription.setEntitlementChangeHandler(_onStoreEntitlementChanged);
  }

  final SubscriptionService _subscription;
  final UsageController _usage;
  final SupabaseClient _client;

  bool configured = false;
  bool busy = false;
  /// Shown on the full-screen purchase lock (empty when idle).
  String busyMessage = '';
  String? lastError;
  List<SubscriptionOffering> offerings = const [];

  DateTime? _lastQuietSyncAt;
  static const _quietSyncMinGap = Duration(seconds: 20);

  bool get hasStoreOfferings =>
      offerings.any((o) => o.packages.isNotEmpty);

  SubscriptionPackage? get boostPackage {
    for (final o in offerings) {
      for (final p in o.packages) {
        if (p.isBoost) return p;
      }
    }
    return null;
  }

  List<SubscriptionPackage> get subscriptionPackages => offerings
      .expand((o) => o.packages)
      .where((p) => !p.isBoost)
      .toList(growable: false);

  Future<void> configureIdentity() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _subscription.configure(appUserId: uid);
    configured = true;
    await refreshOfferings();
    // Drop cancelled Monthly / pick up other-device Pro on every cold start.
    await syncEntitlement(quiet: true);
  }

  Future<void> refreshOfferings() async {
    offerings = await _subscription.offerings();
    notifyListeners();
  }

  /// RC → server → local usage. [quiet] skips the full-screen lock.
  Future<bool> syncEntitlement({bool quiet = true}) async {
    if (busy) return _usage.isPro;
    if (quiet) {
      final last = _lastQuietSyncAt;
      if (last != null &&
          DateTime.now().difference(last) < _quietSyncMinGap) {
        return _usage.isPro;
      }
    }
    if (!quiet) {
      busy = true;
      busyMessage = 'Checking Pro…';
      lastError = null;
      notifyListeners();
    }
    try {
      final result = await _subscription.syncEntitlement();
      await _applyPurchaseResult(result);
      if (!quiet) lastError = result.isPro ? null : result.message;
      _lastQuietSyncAt = DateTime.now();
      notifyListeners();
      return result.isPro || _usage.isPro;
    } finally {
      if (!quiet) {
        busy = false;
        busyMessage = '';
        notifyListeners();
      }
    }
  }

  void _onStoreEntitlementChanged() {
    // Debounced quiet sync when RC pushes cancel/renew mid-session.
    unawaited(syncEntitlement(quiet: true));
  }

  Future<void> _applyPurchaseResult(PurchaseResult result) async {
    if (result.pendingServerConfirm) {
      _usage.keepMonthlyUntilServerAgrees();
    }
    await _usage.setPro(
      result.isPro,
      expiresAt: result.proExpiresAt,
      serverSubscription: result.isSubscription && !result.pendingServerConfirm,
    );
    await _usage.refreshFromServer();
    if (result.pendingServerConfirm) {
      unawaited(_catchUpMonthly());
    }
  }

  Future<void> _catchUpMonthly() async {
    for (var i = 0; i < 12; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      final result = await _subscription.syncEntitlement(
        expectSubscription: true,
      );
      if (!result.isSubscription) continue;
      await _usage.setPro(true, expiresAt: null, serverSubscription: true);
      await _usage.refreshFromServer();
      return;
    }
  }

  Future<bool> purchase(SubscriptionPackage package) async {
    if (busy) return false;
    // Monthly users shouldn't buy Boost (Apple would still charge).
    if (package.isBoost && _usage.isSubscriptionPro) {
      lastError = 'You’re already on Pro Monthly.';
      notifyListeners();
      return false;
    }
    busy = true;
    busyMessage = package.isBoost
        ? 'Turning on Boost…'
        : 'Unlocking Pro…';
    lastError = null;
    notifyListeners();
    try {
      final result = package.isBoost
          ? await _subscription.purchaseBoost()
          : await _subscription.purchase(package);
      await _applyPurchaseResult(result);
      lastError = result.success ? null : result.message;
      notifyListeners();
      return result.success;
    } finally {
      busy = false;
      busyMessage = '';
      notifyListeners();
    }
  }

  Future<bool> purchaseBoost() async {
    if (busy) return false;
    if (_usage.isSubscriptionPro) {
      lastError = 'You’re already on Pro Monthly.';
      notifyListeners();
      return false;
    }
    busy = true;
    busyMessage = 'Turning on Boost…';
    lastError = null;
    notifyListeners();
    try {
      final result = await _subscription.purchaseBoost();
      await _applyPurchaseResult(result);
      lastError = result.success ? null : result.message;
      notifyListeners();
      return result.success;
    } finally {
      busy = false;
      busyMessage = '';
      notifyListeners();
    }
  }

  Future<bool> restore() async {
    if (busy) return false;
    busy = true;
    busyMessage = 'Restoring purchases…';
    lastError = null;
    notifyListeners();
    try {
      final result = await _subscription.restore();
      await _applyPurchaseResult(result);
      lastError = result.isPro ? null : result.message;
      notifyListeners();
      return result.isPro || _usage.isPro;
    } finally {
      busy = false;
      busyMessage = '';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.setEntitlementChangeHandler(null);
    super.dispose();
  }
}
