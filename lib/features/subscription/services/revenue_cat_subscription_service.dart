import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/config/env_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../services/subscription/subscription_services.dart';
import 'entitlement_sync_service.dart';

/// Real RevenueCat SDK + server entitlement sync.
/// Fail-closed: missing key / web / store errors never grant Pro on device alone.
class RevenueCatSubscriptionService implements SubscriptionService {
  RevenueCatSubscriptionService(this._sync);

  final EntitlementSyncService _sync;

  final Map<String, Package> _packagesById = {};
  StoreProduct? _boostProduct;
  bool _configured = false;
  bool _listenerAttached = false;
  String? _appUserId;
  void Function()? _entitlementChangeHandler;

  @override
  void setEntitlementChangeHandler(void Function()? handler) {
    _entitlementChangeHandler = handler;
  }

  @override
  Future<void> configure({required String appUserId}) async {
    _appUserId = appUserId;
    if (!EnvConfig.hasRevenueCat) {
      debugPrint('RevenueCat: no API key — purchases disabled (fail closed)');
      return;
    }
    if (kIsWeb) {
      debugPrint('RevenueCat: web unsupported — fail closed');
      return;
    }

    try {
      if (!_configured) {
        final config = PurchasesConfiguration(EnvConfig.revenueCatApiKey)
          ..appUserID = appUserId;
        await Purchases.configure(config);
        _configured = true;
        _attachCustomerInfoListener();
      } else {
        await Purchases.logIn(appUserId);
      }
    } catch (e) {
      debugPrint('RevenueCat configure failed: $e');
      _configured = false;
    }
  }

  void _attachCustomerInfoListener() {
    if (_listenerAttached) return;
    _listenerAttached = true;
    Purchases.addCustomerInfoUpdateListener((_) {
      _entitlementChangeHandler?.call();
    });
  }

  @override
  Future<List<SubscriptionOffering>> offerings() async {
    if (!_canUseStore) return const [];

    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      final packages = <SubscriptionPackage>[];

      _packagesById.clear();
      _boostProduct = null;

      if (current != null) {
        for (final p in current.availablePackages) {
          final storeId = p.storeProduct.identifier;
          final isBoost = storeId == AppConstants.boostProductId;
          _packagesById[p.identifier] = p;
          if (isBoost) {
            _boostProduct = p.storeProduct;
            packages.add(
              SubscriptionPackage(
                id: p.identifier,
                title: p.storeProduct.title,
                priceString: p.storeProduct.priceString,
                period: '1 hour',
                isBoost: true,
              ),
            );
          } else {
            packages.add(
              SubscriptionPackage(
                id: p.identifier,
                title: p.storeProduct.title,
                priceString: p.storeProduct.priceString,
                period: _periodLabel(p.packageType),
              ),
            );
          }
        }
      }

      // Boost is a consumable — usually outside the subscription offering.
      await _loadBoostProduct();
      if (_boostProduct != null &&
          !packages.any((p) => p.isBoost)) {
        packages.insert(
          0,
          SubscriptionPackage(
            id: AppConstants.boostProductId,
            title: _boostProduct!.title,
            priceString: _boostProduct!.priceString,
            period: '1 hour',
            isBoost: true,
          ),
        );
      } else if (!packages.any((p) => p.isBoost)) {
        // Always surface Boost in the paywall; price fills in when Store answers.
        packages.insert(
          0,
          const SubscriptionPackage(
            id: AppConstants.boostProductId,
            title: 'Kehlo Boost',
            priceString: '1 hour',
            period: '1 hour',
            isBoost: true,
          ),
        );
      }

      if (packages.isEmpty) return const [];

      return [
        SubscriptionOffering(
          id: current?.identifier ?? 'default',
          packages: packages,
        ),
      ];
    } catch (e) {
      debugPrint('RevenueCat offerings failed: $e');
      // Still offer Boost + empty monthly rather than a blank sheet.
      return const [
        SubscriptionOffering(
          id: 'default',
          packages: [
            SubscriptionPackage(
              id: AppConstants.boostProductId,
              title: 'Kehlo Boost',
              priceString: '1 hour',
              period: '1 hour',
              isBoost: true,
            ),
          ],
        ),
      ];
    }
  }

  Future<void> _loadBoostProduct() async {
    if (_boostProduct != null) return;
    try {
      var products = await Purchases.getProducts(
        [AppConstants.boostProductId],
        productCategory: ProductCategory.nonSubscription,
      );
      if (products.isEmpty) {
        // Some RC/store combos only resolve without a category filter.
        products = await Purchases.getProducts([AppConstants.boostProductId]);
      }
      if (products.isNotEmpty) {
        _boostProduct = products.first;
      }
    } catch (e) {
      debugPrint('RevenueCat boost product: $e');
    }
  }

  @override
  Future<PurchaseResult> purchase(SubscriptionPackage package) async {
    if (!_canUseStore) {
      return const PurchaseResult(
        success: false,
        isPro: false,
        message: 'Pro purchases aren’t available on this build yet.',
      );
    }

    if (package.isBoost || package.id == AppConstants.boostProductId) {
      return purchaseBoost();
    }

    final storePackage = _packagesById[package.id];
    if (storePackage == null) {
      return const PurchaseResult(
        success: false,
        isPro: false,
        message: 'That plan isn’t available right now. Try again.',
      );
    }

    try {
      await Purchases.purchasePackage(storePackage);
      // Apple finished. Switch to Monthly immediately; server follows.
      return const PurchaseResult(
        success: true,
        isPro: true,
        kind: 'subscription',
        pendingServerConfirm: true,
      );
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      // Sandbox often says "already subscribed" when Monthly is already owned.
      if (code == PurchasesErrorCode.productAlreadyPurchasedError) {
        return const PurchaseResult(
          success: true,
          isPro: true,
          kind: 'subscription',
          pendingServerConfirm: true,
        );
      }
      return _mapPurchaseError(e);
    } on AppException catch (e) {
      return PurchaseResult(
        success: false,
        isPro: false,
        message: e.message,
      );
    } catch (_) {
      return const PurchaseResult(
        success: false,
        isPro: false,
        message: 'Purchase didn’t complete. Try again.',
      );
    }
  }

  @override
  Future<PurchaseResult> purchaseBoost() async {
    if (!_canUseStore) {
      return const PurchaseResult(
        success: false,
        isPro: false,
        message: 'Boost isn’t available on this build yet.',
      );
    }

    var product = _boostProduct;
    if (product == null) {
      try {
        final products = await Purchases.getProducts(
          [AppConstants.boostProductId],
          productCategory: ProductCategory.nonSubscription,
        );
        if (products.isNotEmpty) product = products.first;
      } catch (e) {
        debugPrint('RevenueCat getProducts boost: $e');
      }
    }

    if (product == null) {
      return const PurchaseResult(
        success: false,
        isPro: false,
        message: 'Boost isn’t available in the store yet.',
      );
    }

    return _purchaseBoostProduct(product);
  }

  Future<PurchaseResult> _purchaseBoostProduct(StoreProduct product) async {
    try {
      final info = await Purchases.purchaseStoreProduct(product);
      final tx = _latestBoostTransaction(info);
      // Apple already succeeded. One server call turns Boost on — no RC poll.
      var result = await _sync.activateBoost(
        storeTransactionId: tx?.transactionIdentifier,
        productId: tx?.productIdentifier ?? product.identifier,
      );
      if (!result.isPro) {
        result = await _sync.activateBoost(
          storeTransactionId: tx?.transactionIdentifier,
          productId: tx?.productIdentifier ?? product.identifier,
        );
      }
      return PurchaseResult(
        success: result.isPro,
        isPro: result.isPro,
        kind: result.kind,
        proExpiresAt: result.isSubscription ? null : result.proExpiresAt,
        message: result.isPro ? null : 'Boost didn’t turn on. Try again.',
      );
    } on PlatformException catch (e) {
      return _mapPurchaseError(e);
    } on AppException catch (e) {
      return PurchaseResult(
        success: false,
        isPro: false,
        message: e.message,
      );
    } catch (_) {
      return const PurchaseResult(
        success: false,
        isPro: false,
        message: 'Boost purchase didn’t complete. Try again.',
      );
    }
  }

  bool _sdkHasMonthlyPro(CustomerInfo info) {
    bool isMonthlyId(String id) {
      final n = id.toLowerCase();
      if (n.contains('boost')) return false;
      return n == AppConstants.monthlyProductId ||
          n.contains('monthly') ||
          n.contains('pro');
    }

    if (info.activeSubscriptions.any(isMonthlyId)) return true;
    final ent = info.entitlements.all[AppConstants.entitlementPro];
    if (ent != null &&
        ent.isActive &&
        isMonthlyId(ent.productIdentifier)) {
      return true;
    }
    for (final entry in info.allExpirationDates.entries) {
      if (!isMonthlyId(entry.key)) continue;
      final raw = entry.value;
      if (raw == null || raw.isEmpty) return true;
      final exp = DateTime.tryParse(raw);
      if (exp == null || exp.isAfter(DateTime.now())) return true;
    }
    return false;
  }

  StoreTransaction? _latestBoostTransaction(CustomerInfo info) {
    final matches = info.nonSubscriptionTransactions
        .where(
          (t) =>
              t.productIdentifier == AppConstants.boostProductId ||
              t.productIdentifier.toLowerCase().contains('boost'),
        )
        .toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
    return matches.first;
  }

  PurchaseResult _mapPurchaseError(PlatformException e) {
    final code = PurchasesErrorHelper.getErrorCode(e);
    if (code == PurchasesErrorCode.purchaseCancelledError) {
      return const PurchaseResult(
        success: false,
        isPro: false,
        message: null,
      );
    }
    return PurchaseResult(
      success: false,
      isPro: false,
      message: e.message?.isNotEmpty == true
          ? e.message
          : 'Purchase didn’t complete. Try again.',
    );
  }

  PurchaseResult _resultFromSync(
    EntitlementSyncResult synced, {
    required String notProMessage,
  }) {
    return PurchaseResult(
      success: synced.isPro,
      isPro: synced.isPro,
      kind: synced.kind,
      // Subscription → null expiry (clears Boost timer locally).
      proExpiresAt: synced.isSubscription ? null : synced.proExpiresAt,
      message: synced.isPro ? null : notProMessage,
    );
  }

  @override
  Future<PurchaseResult> syncEntitlement({bool expectSubscription = false}) async {
    try {
      String? rcAppUserId;
      if (_canUseStore) {
        try {
          final info = await Purchases.getCustomerInfo();
          rcAppUserId = info.originalAppUserId;
        } catch (e) {
          debugPrint('RevenueCat customer info for sync: $e');
        }
      }
      final synced = await _sync.syncFromRevenueCat(
        expectSubscription: expectSubscription,
        rcAppUserId: rcAppUserId,
      );
      return _resultFromSync(
        synced,
        notProMessage: 'No active Pro subscription found.',
      );
    } on AppException catch (e) {
      return PurchaseResult(
        success: false,
        isPro: false,
        message: e.message,
      );
    } catch (_) {
      return const PurchaseResult(
        success: false,
        isPro: false,
        message: 'Couldn’t sync Pro status.',
      );
    }
  }

  @override
  Future<PurchaseResult> restore() async {
    // Always try server sync (covers web / other-device Pro).
    if (_canUseStore) {
      try {
        await Purchases.restorePurchases();
      } catch (e) {
        debugPrint('RevenueCat restorePurchases: $e');
      }
    }

    try {
      var sdkMonthly = false;
      if (_canUseStore) {
        try {
          await Purchases.syncPurchases();
          final info = await Purchases.getCustomerInfo();
          sdkMonthly = _sdkHasMonthlyPro(info);
        } catch (e) {
          debugPrint('RevenueCat sync before restore: $e');
        }
      }
      var synced = await _sync.syncFromRevenueCat(
        expectSubscription: sdkMonthly,
      );
      if (sdkMonthly && !synced.isSubscription) {
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        synced = await _sync.syncFromRevenueCat(expectSubscription: true);
      }
      if (!synced.isSubscription && !synced.isPro && _canUseStore) {
        try {
          final info = await Purchases.getCustomerInfo();
          final tx = _latestBoostTransaction(info);
          if (tx != null) {
            final activated = await _sync.activateBoost(
              storeTransactionId: tx.transactionIdentifier,
              productId: tx.productIdentifier,
            );
            return PurchaseResult(
              success: activated.isPro,
              isPro: activated.isPro,
              kind: activated.kind,
              proExpiresAt:
                  activated.isSubscription ? null : activated.proExpiresAt,
              message:
                  activated.isPro ? null : 'No active Pro subscription found.',
            );
          }
        } catch (e) {
          debugPrint('RevenueCat restore boost: $e');
        }
      }
      if (sdkMonthly && !synced.isSubscription) {
        return PurchaseResult(
          success: false,
          isPro: synced.isPro,
          kind: synced.kind,
          proExpiresAt: synced.isSubscription ? null : synced.proExpiresAt,
          message:
              'Monthly isn’t active yet. Boost is still on — try Restore again.',
        );
      }
      return _resultFromSync(
        synced,
        notProMessage: 'No active Pro subscription found.',
      );
    } on AppException catch (e) {
      return PurchaseResult(
        success: false,
        isPro: false,
        message: e.message,
      );
    } catch (_) {
      return const PurchaseResult(
        success: false,
        isPro: false,
        message: 'Couldn’t restore purchases. Try again.',
      );
    }
  }

  @override
  Stream<EntitlementSnapshot> get entitlementChanges async* {
    yield EntitlementSnapshot(
      isPro: false,
      source: _configured ? 'revenuecat' : 'none',
    );
  }

  bool get _canUseStore =>
      EnvConfig.hasRevenueCat && !kIsWeb && _configured && _appUserId != null;

  static String _periodLabel(PackageType type) {
    return switch (type) {
      PackageType.annual => 'year',
      PackageType.sixMonth => '6 months',
      PackageType.threeMonth => '3 months',
      PackageType.twoMonth => '2 months',
      PackageType.monthly => 'month',
      PackageType.weekly => 'week',
      PackageType.lifetime => 'lifetime',
      _ => 'plan',
    };
  }
}

/// Fail-closed stub when RC isn’t configured. Never grants Pro from the client.
class FailClosedSubscriptionService implements SubscriptionService {
  FailClosedSubscriptionService(this._sync);

  final EntitlementSyncService _sync;

  @override
  Future<void> configure({required String appUserId}) async {
    debugPrint(
      'Subscription: RC unset — fail closed (user=$appUserId)',
    );
  }

  @override
  Future<List<SubscriptionOffering>> offerings() async => const [];

  @override
  Future<PurchaseResult> purchase(SubscriptionPackage package) async {
    return const PurchaseResult(
      success: false,
      isPro: false,
      message: 'Pro purchases aren’t configured in this build.',
    );
  }

  @override
  Future<PurchaseResult> purchaseBoost() async {
    return const PurchaseResult(
      success: false,
      isPro: false,
      message: 'Boost isn’t configured in this build.',
    );
  }

  @override
  Future<PurchaseResult> restore() => syncEntitlement();

  @override
  Future<PurchaseResult> syncEntitlement({bool expectSubscription = false}) async {
    try {
      final synced = await _sync.syncFromRevenueCat(
        expectSubscription: expectSubscription,
      );
      return PurchaseResult(
        success: synced.isPro,
        isPro: synced.isPro,
        kind: synced.kind,
        proExpiresAt: synced.isSubscription ? null : synced.proExpiresAt,
        message: synced.isPro ? null : 'No active Pro subscription found.',
      );
    } on AppException catch (e) {
      return PurchaseResult(
        success: false,
        isPro: false,
        message: e.message,
      );
    } catch (_) {
      return const PurchaseResult(
        success: false,
        isPro: false,
        message: 'Couldn’t check Pro status. Try again.',
      );
    }
  }

  @override
  void setEntitlementChangeHandler(void Function()? handler) {}

  @override
  Stream<EntitlementSnapshot> get entitlementChanges async* {
    yield const EntitlementSnapshot(isPro: false, source: 'none');
  }
}

/// Prefer real RC when key present; otherwise fail closed. Entitlement id: [AppConstants.entitlementPro].
SubscriptionService createSubscriptionService(EntitlementSyncService sync) {
  assert(AppConstants.entitlementPro == 'pro');
  if (EnvConfig.hasRevenueCat && !kIsWeb) {
    return RevenueCatSubscriptionService(sync);
  }
  return FailClosedSubscriptionService(sync);
}
