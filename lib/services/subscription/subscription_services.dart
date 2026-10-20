import 'package:flutter/foundation.dart';

/// RevenueCat is the source of truth for paid entitlement.
/// Never trust a client-side `isPro = true` bypass.
abstract class SubscriptionService {
  Future<void> configure({required String appUserId});
  Future<List<SubscriptionOffering>> offerings();
  Future<PurchaseResult> purchase(SubscriptionPackage package);

  /// Consumable Boost (`kehlo_boost_1h`) → server grants 1h Pro.
  Future<PurchaseResult> purchaseBoost();

  /// Consumable practice hour (`kehlo_practice_1h`). Does not grant Pro.
  Future<DateTime?> purchasePracticeHour();

  /// Store price label, e.g. ₹49. Null if the store has not loaded it.
  Future<String?> practiceHourPrice();

  Future<PurchaseResult> restore();

  /// Pull RC → server profiles (cancels, renewals, other-device Pro).
  Future<PurchaseResult> syncEntitlement({
    bool expectSubscription = false,
    bool storeOwnsMonthly = false,
  });

  /// Read the App Store receipt already on this device and save Pro/Boost.
  /// Runs on launch so a reinstall does not need Restore.
  Future<PurchaseResult> adoptStorePurchases();

  /// Fired when the store reports entitlement changes (optional).
  void setEntitlementChangeHandler(void Function()? handler);

  Stream<EntitlementSnapshot> get entitlementChanges;
}

abstract class EntitlementService {
  Future<bool> isPro();
  Future<EntitlementSnapshot> snapshot();
  Future<void> refresh();
}

abstract class UsageService {
  Future<bool> canConsume(UsageAction action);
  Future<void> record(UsageAction action);
  Future<UsageSnapshot> snapshot();
}

enum UsageAction {
  conversationAnalysis,
  responseGeneration,
  profileAudit,
  opener,
  practice,
  datePrep,
}

class SubscriptionOffering {
  const SubscriptionOffering({
    required this.id,
    required this.packages,
  });

  final String id;
  final List<SubscriptionPackage> packages;
}

class SubscriptionPackage {
  const SubscriptionPackage({
    required this.id,
    required this.title,
    required this.priceString,
    this.period = 'month',
    this.isBoost = false,
  });

  final String id;
  final String title;
  final String priceString;
  final String period;
  final bool isBoost;
}

class PurchaseResult {
  const PurchaseResult({
    required this.success,
    this.message,
    this.isPro = false,
    this.proExpiresAt,
    this.kind,
    this.pendingServerConfirm = false,
  });

  final bool success;
  final String? message;
  final bool isPro;
  final DateTime? proExpiresAt;

  /// `subscription` | `boost` | `none` when known.
  final String? kind;

  /// Store succeeded; profile may still show Boost until a follow-up sync.
  final bool pendingServerConfirm;

  bool get isSubscription => kind == 'subscription' && isPro;
  bool get isBoost => kind == 'boost' && isPro;
}

class EntitlementSnapshot {
  const EntitlementSnapshot({
    required this.isPro,
    this.activeEntitlements = const [],
    this.source = 'revenuecat',
  });

  final bool isPro;
  final List<String> activeEntitlements;
  final String source;
}

class UsageSnapshot {
  const UsageSnapshot({
    this.analysesUsed = 0,
    this.analysesLimit = 3,
    this.isPro = false,
  });

  final int analysesUsed;
  final int analysesLimit;
  final bool isPro;

  bool get hasRemaining => isPro || analysesUsed < analysesLimit;
}

/// Local RevenueCat-ready stub. Entitlement never flips from UI alone.
class LocalSubscriptionService implements SubscriptionService {
  final EntitlementSnapshot _entitlement =
      const EntitlementSnapshot(isPro: false);

  @override
  Future<void> configure({required String appUserId}) async {
    debugPrint('RevenueCat-ready: configure identity $appUserId');
  }

  @override
  Future<List<SubscriptionOffering>> offerings() async {
    // Fail closed: no fake store prices. Real offerings come from RevenueCat.
    return const [];
  }

  @override
  Future<PurchaseResult> purchase(SubscriptionPackage package) async {
    // Real purchases go through RevenueCat SDK / store.
    // This stub does not grant entitlement from the client.
    return const PurchaseResult(
      success: false,
      message: 'Connect RevenueCat to enable purchases.',
      isPro: false,
    );
  }

  @override
  Future<PurchaseResult> purchaseBoost() async {
    return const PurchaseResult(
      success: false,
      message: 'Connect RevenueCat to enable Boost.',
      isPro: false,
    );
  }

  @override
  Future<DateTime?> purchasePracticeHour() async => null;

  @override
  Future<String?> practiceHourPrice() async => null;

  @override
  Future<PurchaseResult> restore() async {
    return PurchaseResult(
      success: _entitlement.isPro,
      isPro: _entitlement.isPro,
      message: _entitlement.isPro ? null : 'No active subscription found.',
    );
  }

  @override
  Future<PurchaseResult> adoptStorePurchases() => syncEntitlement();

  @override
  Future<PurchaseResult> syncEntitlement({
    bool expectSubscription = false,
    bool storeOwnsMonthly = false,
  }) async {
    return PurchaseResult(
      success: _entitlement.isPro,
      isPro: _entitlement.isPro,
      message: _entitlement.isPro ? null : 'No active subscription found.',
    );
  }

  @override
  void setEntitlementChangeHandler(void Function()? handler) {}

  @override
  Stream<EntitlementSnapshot> get entitlementChanges async* {
    yield _entitlement;
  }
}

class LocalEntitlementService implements EntitlementService {
  LocalEntitlementService(this._subscription);

  final LocalSubscriptionService _subscription;
  EntitlementSnapshot _snapshot = const EntitlementSnapshot(isPro: false);

  @override
  Future<bool> isPro() async => _snapshot.isPro;

  @override
  Future<EntitlementSnapshot> snapshot() async => _snapshot;

  @override
  Future<void> refresh() async {
    await for (final value in _subscription.entitlementChanges) {
      _snapshot = value;
      break;
    }
  }
}

class LocalUsageService implements UsageService {
  LocalUsageService(this._entitlements);

  final EntitlementService _entitlements;
  int _analysesUsed = 0;

  @override
  Future<bool> canConsume(UsageAction action) async {
    // Server-side checks are authoritative in production.
    final isPro = await _entitlements.isPro();
    if (isPro) return true;
    if (action == UsageAction.conversationAnalysis) {
      return _analysesUsed < 3;
    }
    return true;
  }

  @override
  Future<void> record(UsageAction action) async {
    if (action == UsageAction.conversationAnalysis) {
      _analysesUsed += 1;
    }
  }

  @override
  Future<UsageSnapshot> snapshot() async {
    return UsageSnapshot(
      analysesUsed: _analysesUsed,
      isPro: await _entitlements.isPro(),
    );
  }
}
