import 'package:flutter_test/flutter_test.dart';

/// In-memory simulation of the live rules:
/// - Monthly (non-boost subscription still in the future) wins and clears Boost.
/// - Boost is one hour, idempotent per store transaction, stacks on an active Boost.
/// - The screen only becomes Monthly after the server saved `pro_expires_at = null`.
/// - Restart reads the server profile, not a local guess.
/// - A new account starts free. Restore applies Monthly before any old Boost.

void main() {
  group('entitlement decisions', () {
    test('free user', () {
      final world = World();
      expect(world.sync().kind, 'none');
      expect(world.profile.isPro, isFalse);
    });

    test('boost purchase turns on one hour', () {
      final world = World();
      final result = world.buyBoost('tx-1');
      expect(result.kind, 'boost');
      expect(world.profile.isPro, isTrue);
      expect(world.profile.expiresAt, isNotNull);
      expect(
        world.profile.expiresAt!.difference(world.now).inMinutes,
        inInclusiveRange(59, 60),
      );
    });

    test('same boost transaction does not add another hour', () {
      final world = World();
      world.buyBoost('tx-1');
      final first = world.profile.expiresAt!;
      world.now = world.now.add(const Duration(minutes: 10));
      final again = world.buyBoost('tx-1');
      expect(again.kind, 'boost');
      expect(world.profile.expiresAt, first);
      expect(world.redemptions, hasLength(1));
    });

    test('second boost stacks from the current expiry', () {
      final world = World();
      world.buyBoost('tx-1');
      world.now = world.now.add(const Duration(minutes: 20));
      world.buyBoost('tx-2');
      expect(
        world.profile.expiresAt!.difference(world.now).inMinutes,
        inInclusiveRange(99, 100),
      );
    });

    test('expired boost becomes free on sync', () {
      final world = World();
      world.buyBoost('tx-1');
      world.now = world.now.add(const Duration(hours: 2));
      final snap = world.sync();
      expect(snap.kind, 'none');
      expect(world.profile.isPro, isFalse);
      expect(world.profile.expiresAt, isNull);
    });

    test('monthly while boost is on clears the timer', () {
      final world = World();
      world.buyBoost('tx-1');
      expect(world.clientLabel(), 'boost');
      world.rcMonthly = true;
      final bought = world.buyMonthly();
      expect(bought.success, isTrue);
      expect(bought.kind, 'subscription');
      expect(world.profile.expiresAt, isNull);
      expect(world.clientLabel(), 'monthly');
    });

    test('reopen after monthly does not bring boost back', () {
      final world = World();
      world.buyBoost('tx-1');
      world.rcMonthly = true;
      expect(world.buyMonthly().success, isTrue);
      world.restartApp();
      expect(world.clientLabel(), 'monthly');
      expect(world.profile.expiresAt, isNull);
    });

    test('killing the app before monthly saves keeps boost', () {
      final world = World();
      world.buyBoost('tx-1');
      world.rcMonthly = true;
      world.monthlyVisibleToServer = false;
      final bought = world.buyMonthly();
      expect(bought.success, isFalse);
      world.restartApp();
      expect(world.clientLabel(), 'boost');
    });

    test('monthly appears on a later poll and then sticks', () {
      final world = World();
      world.buyBoost('tx-1');
      world.rcMonthly = true;
      world.monthlyVisibleAfterPoll = 2;
      expect(world.buyMonthly().success, isTrue);
      world.restartApp();
      expect(world.clientLabel(), 'monthly');
    });

    test('cancelled monthly stays pro until the paid period ends', () {
      final world = World();
      world.rcMonthly = true;
      world.monthlyUnsubscribed = true;
      world.monthlyExpiresAt = world.now.add(const Duration(days: 10));
      expect(world.sync().kind, 'subscription');
      world.now = world.now.add(const Duration(days: 11));
      expect(world.sync().kind, 'none');
    });

    test('boost entitlement product does not count as monthly', () {
      final world = World();
      world.entitlementProduct = 'kehlo_boost_1h';
      world.entitlementExpiresAt = world.now.add(const Duration(minutes: 30));
      expect(world.sync().kind, 'none');
    });

    test('buying boost while monthly is active does not start a timer', () {
      final world = World();
      world.rcMonthly = true;
      world.sync();
      final result = world.buyBoost('tx-9');
      expect(result.kind, 'subscription');
      expect(world.profile.expiresAt, isNull);
      expect(world.redemptions, isEmpty);
    });

    test('delete account starts free even if the old profile was pro', () {
      final world = World();
      world.rcMonthly = true;
      world.sync();
      world.deleteAccount();
      expect(world.clientLabel(), 'free');
      expect(world.profile.isPro, isFalse);
    });

    test('restore after delete brings monthly back, not the old boost', () {
      final world = World();
      world.buyBoost('tx-old');
      world.rcMonthly = true;
      world.buyMonthly();
      world.deleteAccount();
      world.storeStillHasMonthly = true;
      world.storeStillHasBoostTx = 'tx-old';
      final restored = world.restore();
      expect(restored.kind, 'subscription');
      expect(world.profile.expiresAt, isNull);
      world.restartApp();
      expect(world.clientLabel(), 'monthly');
    });

    test('restore with only a boost receipt turns boost on', () {
      final world = World();
      world.deleteAccount();
      world.storeStillHasBoostTx = 'tx-new';
      final restored = world.restore();
      expect(restored.kind, 'boost');
      expect(world.profile.expiresAt, isNotNull);
    });

    test('restore does not redeem a boost that was already used', () {
      final world = World();
      world.buyBoost('tx-1');
      final expiry = world.profile.expiresAt;
      world.now = world.now.add(const Duration(hours: 3));
      world.sync();
      world.storeStillHasBoostTx = 'tx-1';
      final restored = world.restore();
      expect(restored.success, isFalse);
      expect(world.profile.expiresAt == expiry || world.profile.expiresAt == null,
          isTrue);
      expect(world.profile.isPro, isFalse);
    });

    test('daily boost cap blocks a 21st new transaction', () {
      final world = World();
      for (var i = 0; i < 20; i++) {
        expect(world.buyBoost('tx-$i').kind, 'boost');
      }
      final blocked = world.buyBoost('tx-20');
      expect(blocked.success, isFalse);
      expect(blocked.message, contains('limit'));
    });
  });
}

class Snap {
  Snap({
    required this.success,
    required this.kind,
    this.message,
  });

  final bool success;
  final String kind;
  final String? message;
}

class Profile {
  bool isPro = false;
  DateTime? expiresAt;
}

class World {
  DateTime now = DateTime.utc(2026, 10, 21, 12);
  Profile profile = Profile();
  final Map<String, DateTime> redemptions = {};

  bool rcMonthly = false;
  bool monthlyUnsubscribed = false;
  DateTime? monthlyExpiresAt;
  bool monthlyVisibleToServer = true;
  int monthlyVisibleAfterPoll = 0;
  int _polls = 0;

  String? entitlementProduct;
  DateTime? entitlementExpiresAt;

  bool storeStillHasMonthly = false;
  String? storeStillHasBoostTx;

  /// What the app shows after reading the server profile (cold start).
  String clientLabel() {
    if (!profile.isPro) return 'free';
    if (profile.expiresAt == null) return 'monthly';
    if (profile.expiresAt!.isAfter(now)) return 'boost';
    return 'free';
  }

  void restartApp() {
    // Local guess is discarded. Server profile is the only memory.
    if (profile.isPro &&
        profile.expiresAt != null &&
        !profile.expiresAt!.isAfter(now)) {
      profile.isPro = false;
      profile.expiresAt = null;
    }
  }

  void deleteAccount() {
    profile = Profile();
    // Redemptions stay global (store transaction ids are unique).
    rcMonthly = false;
    storeStillHasMonthly = false;
  }

  bool _serverSeesMonthly() {
    _polls++;
    if (!rcMonthly && !storeStillHasMonthly) return false;
    if (!monthlyVisibleToServer) return false;
    if (_polls < monthlyVisibleAfterPoll) return false;
    final exp = monthlyExpiresAt ?? now.add(const Duration(days: 30));
    if (!exp.isAfter(now)) return false;
    return true;
  }

  Snap sync({bool expectSubscription = false}) {
    final attempts = expectSubscription ? 10 : 1;
    var subscription = false;
    for (var i = 0; i < attempts; i++) {
      if (_serverSeesMonthly()) {
        subscription = true;
        break;
      }
      final ent = entitlementProduct;
      if (ent != null &&
          !ent.toLowerCase().contains('boost') &&
          (entitlementExpiresAt == null || entitlementExpiresAt!.isAfter(now))) {
        subscription = true;
        break;
      }
    }

    if (subscription) {
      profile.isPro = true;
      profile.expiresAt = null;
      return Snap(success: true, kind: 'subscription');
    }

    final exp = profile.expiresAt;
    if (profile.isPro && exp != null && exp.isAfter(now)) {
      return Snap(success: true, kind: 'boost');
    }
    if (exp != null && !exp.isAfter(now)) {
      profile.isPro = false;
      profile.expiresAt = null;
    }
    if (!profile.isPro) {
      return Snap(success: false, kind: 'none');
    }
    // isPro with null expiry but RC no longer monthly: treat as free.
    if (profile.expiresAt == null && !subscription) {
      profile.isPro = false;
      return Snap(success: false, kind: 'none');
    }
    return Snap(success: profile.isPro, kind: profile.isPro ? 'boost' : 'none');
  }

  Snap buyBoost(String tx) {
    if (_serverSeesMonthly()) {
      profile.isPro = true;
      profile.expiresAt = null;
      return Snap(success: true, kind: 'subscription');
    }
    if (redemptions.length >= 20 && !redemptions.containsKey(tx)) {
      return Snap(
        success: false,
        kind: 'none',
        message: 'You’ve hit today’s Boost limit.',
      );
    }
    final existing = redemptions[tx];
    if (existing != null) {
      if (existing.isAfter(now)) {
        profile.isPro = true;
        profile.expiresAt = existing;
        return Snap(success: true, kind: 'boost');
      }
      return Snap(
        success: false,
        kind: 'none',
        message: 'already used',
      );
    }
    final base = (profile.expiresAt != null && profile.expiresAt!.isAfter(now))
        ? profile.expiresAt!
        : now;
    final until = base.add(const Duration(hours: 1));
    redemptions[tx] = until;
    profile.isPro = true;
    profile.expiresAt = until;
    return Snap(success: true, kind: 'boost');
  }

  Snap buyMonthly() {
    rcMonthly = true;
    // Client only succeeds when a sync poll actually saved Monthly.
    for (var i = 0; i < 3; i++) {
      final snap = sync(expectSubscription: true);
      if (snap.kind == 'subscription') return snap;
    }
    return Snap(
      success: false,
      kind: clientLabel() == 'boost' ? 'boost' : 'none',
      message: 'not saved',
    );
  }

  Snap restore() {
    if (storeStillHasMonthly) {
      rcMonthly = true;
      monthlyVisibleToServer = true;
      return buyMonthly();
    }
    final tx = storeStillHasBoostTx;
    if (tx != null) return buyBoost(tx);
    return sync(expectSubscription: true);
  }
}
