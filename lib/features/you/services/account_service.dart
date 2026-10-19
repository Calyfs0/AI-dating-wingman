import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/edge_function_errors.dart';

/// Deletes cloud account data via `delete-account`, then resets local prefs.
class AccountService {
  AccountService(this._client);

  final SupabaseClient _client;

  /// Wipes server rows + auth user (when service role is configured), then
  /// clears this device's SharedPreferences and starts a fresh anonymous session.
  Future<void> deleteAccount() async {
    try {
      final response = await _client.functions.invoke('delete-account');
      final data = response.data;
      if (response.status >= 400) {
        final map = data is Map
            ? Map<String, dynamic>.from(data)
            : <String, dynamic>{};
        throw mapEdgeHttpError(response.status, map);
      }
    } on AppException {
      rethrow;
    } on FunctionException catch (e) {
      // Fallback: wipe tables even if Edge isn't reachable.
      debugPrint('delete-account FunctionException: ${e.status}');
      try {
        await _client.rpc('delete_user_data');
      } catch (rpcError) {
        throw mapFunctionException(e);
      }
    } catch (e) {
      debugPrint('delete-account failed: $e');
      try {
        await _client.rpc('delete_user_data');
      } catch (_) {
        throw AppExceptionMapper.map(e);
      }
    }

    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('signOut after delete: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    final response = await _client.auth.signInAnonymously();
    if (response.user == null) {
      throw const AuthException(
        'Account deleted, but we couldn’t start a fresh session. Relaunch the app.',
      );
    }
  }
}
