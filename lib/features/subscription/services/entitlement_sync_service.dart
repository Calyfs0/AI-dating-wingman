import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/edge_function_errors.dart';

/// Result of [EntitlementSyncService.syncFromRevenueCat].
class EntitlementSyncResult {
  const EntitlementSyncResult({
    required this.isPro,
    required this.kind,
    this.proExpiresAt,
  });

  final bool isPro;

  /// `subscription` | `boost` | `none`
  final String kind;
  final DateTime? proExpiresAt;

  bool get isSubscription => kind == 'subscription' && isPro;
  bool get isBoost => kind == 'boost' && isPro;
}

/// Server-verified Pro sync: Edge checks RevenueCat with the secret key,
/// then upserts [profiles.is_pro]. Client never self-grants.
class EntitlementSyncService {
  EntitlementSyncService(this._client);

  final SupabaseClient _client;

  /// Syncs RC → profiles. Fail-closed on config errors.
  /// [expectSubscription] asks the server to wait for a Monthly row to replace Boost.
  Future<EntitlementSyncResult> syncFromRevenueCat({
    bool expectSubscription = false,
    String? rcAppUserId,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'sync-entitlement',
        body: {
          if (expectSubscription) 'expectSubscription': true,
          if (rcAppUserId != null && rcAppUserId.isNotEmpty)
            'rcAppUserId': rcAppUserId,
        },
      );
      final data = response.data;
      if (data is! Map) {
        throw const GenerationException('Could not sync Pro status.');
      }
      final map = Map<String, dynamic>.from(data);
      if (response.status >= 400) {
        throw mapEdgeHttpError(response.status, map);
      }
      final expiresRaw = map['proExpiresAt'] as String?;
      final kind = (map['kind'] as String?)?.trim() ??
          ((map['isPro'] == true)
              ? (expiresRaw != null && expiresRaw.isNotEmpty
                  ? 'boost'
                  : 'subscription')
              : 'none');
      return EntitlementSyncResult(
        isPro: map['isPro'] == true,
        kind: kind,
        proExpiresAt: expiresRaw != null && expiresRaw.isNotEmpty
            ? DateTime.tryParse(expiresRaw)?.toUtc()
            : null,
      );
    } on FunctionException catch (e) {
      throw mapFunctionException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppExceptionMapper.map(e);
    }
  }

  /// Redeems a Boost consumable purchase → 1h Pro on the server.
  Future<EntitlementSyncResult> activateBoost({
    String? storeTransactionId,
    String? productId,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'activate-boost',
        body: {
          if (storeTransactionId != null && storeTransactionId.isNotEmpty)
            'storeTransactionId': storeTransactionId,
          if (productId != null && productId.isNotEmpty) 'productId': productId,
        },
      );
      final data = response.data;
      if (data is! Map) {
        throw const GenerationException('Could not activate Boost.');
      }
      final map = Map<String, dynamic>.from(data);
      if (response.status >= 400) {
        throw mapEdgeHttpError(response.status, map);
      }
      final expiresRaw = map['proExpiresAt'] as String?;
      final kind = (map['kind'] as String?)?.trim() ??
          ((map['isPro'] == true)
              ? (expiresRaw != null && expiresRaw.isNotEmpty
                  ? 'boost'
                  : 'subscription')
              : 'none');
      return EntitlementSyncResult(
        isPro: map['isPro'] == true,
        kind: kind,
        proExpiresAt: expiresRaw != null && expiresRaw.isNotEmpty
            ? DateTime.tryParse(expiresRaw)?.toUtc()
            : null,
      );
    } on FunctionException catch (e) {
      throw mapFunctionException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppExceptionMapper.map(e);
    }
  }
}
