import 'package:supabase_flutter/supabase_flutter.dart';
import 'subscription_services.dart';

/// Usage checks against `usage_events`. Server Edge Function remains authoritative.
class SupabaseUsageService implements UsageService {
  SupabaseUsageService(this._client, this._entitlements);

  final SupabaseClient _client;
  final EntitlementService _entitlements;
  static const _analysisLimit = 3;

  @override
  Future<bool> canConsume(UsageAction action) async {
    final isPro = await _entitlements.isPro();
    if (isPro) return true;
    if (action != UsageAction.conversationAnalysis) return true;
    final used = await _analysisCount();
    return used < _analysisLimit;
  }

  @override
  Future<void> record(UsageAction action) async {
    // analyze-conversation inserts usage_events; avoid double-counting.
  }

  @override
  Future<UsageSnapshot> snapshot() async {
    return UsageSnapshot(
      analysesUsed: await _analysisCount(),
      analysesLimit: _analysisLimit,
      isPro: await _entitlements.isPro(),
    );
  }

  Future<int> _analysisCount() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return 0;
    final result = await _client
        .from('usage_events')
        .select('id')
        .eq('user_id', uid)
        .eq('action', UsageAction.conversationAnalysis.name);
    return (result as List).length;
  }
}
