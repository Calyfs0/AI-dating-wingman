import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/screenshot_reply/models/suggested_replies.dart';

class ReplyHistoryEntry {
  const ReplyHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.source,
    required this.preview,
    required this.replies,
    this.contextSnippet,
  });

  final String id;
  final DateTime createdAt;
  final String source;
  final String preview;
  final SuggestedReplies replies;
  final String? contextSnippet;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'source': source,
        'preview': preview,
        'contextSnippet': contextSnippet,
        'replies': _repliesToJson(replies),
      };

  factory ReplyHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ReplyHistoryEntry(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      source: json['source'] as String? ?? 'screenshot',
      preview: json['preview'] as String? ?? '',
      contextSnippet: json['contextSnippet'] as String?,
      replies: _repliesFromJson(
        Map<String, dynamic>.from(json['replies'] as Map),
      ),
    );
  }
}

Map<String, dynamic> _repliesToJson(SuggestedReplies replies) => {
      'natural': replies.natural,
      'playful': replies.playful,
      'confident': replies.confident,
      'latestIncoming': replies.latestIncoming,
    };

SuggestedReplies _repliesFromJson(Map<String, dynamic> json) => SuggestedReplies(
      natural: json['natural'] as String? ?? '',
      playful: json['playful'] as String? ?? '',
      confident: json['confident'] as String? ?? '',
      latestIncoming: json['latestIncoming'] as String?,
    );

/// Lightweight local history of recent reply generations (device only).
class ReplyHistoryService {
  ReplyHistoryService(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'wingman_reply_history_v1';
  static const _maxEntries = 30;

  Future<List<ReplyHistoryEntry>> list() async {
    final raw = _prefs.getStringList(_key) ?? const [];
    final entries = <ReplyHistoryEntry>[];
    for (final item in raw) {
      try {
        entries.add(
          ReplyHistoryEntry.fromJson(
            jsonDecode(item) as Map<String, dynamic>,
          ),
        );
      } catch (_) {}
    }
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> record({
    required String source,
    required String preview,
    required SuggestedReplies replies,
    String? contextSnippet,
  }) async {
    final entry = ReplyHistoryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      source: source,
      preview: preview,
      replies: replies,
      contextSnippet: contextSnippet,
    );
    final current = await list();
    final next = [entry, ...current].take(_maxEntries).toList();
    await _prefs.setStringList(
      _key,
      next.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> clear() => _prefs.remove(_key);
}
