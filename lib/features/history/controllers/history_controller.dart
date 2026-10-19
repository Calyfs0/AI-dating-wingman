import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../screenshot_reply/models/suggested_replies.dart';
import '../models/history_entry.dart';

class HistoryController extends ChangeNotifier {
  HistoryController({this.maxEntries = 20});

  static const _storageKey = 'gotchu_history_v1';

  final int maxEntries;
  final List<HistoryEntry> _entries = [];
  bool loaded = false;

  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  List<HistoryEntry> forPerson(String personId) =>
      _entries.where((e) => e.personId == personId).toList(growable: false);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    _entries.clear();
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final item in list) {
          if (item is Map) {
            _entries.add(HistoryEntry.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      } catch (e) {
        debugPrint('history load: ${e.runtimeType}');
      }
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> addFromReplies({
    required HistoryKind kind,
    required SuggestedReplies replies,
    String? personId,
    String? personName,
  }) async {
    _entries.insert(
      0,
      HistoryEntry.fromReplies(
        kind: kind,
        replies: replies,
        personId: personId,
        personName: personName,
      ),
    );
    while (_entries.length > maxEntries) {
      _entries.removeLast();
    }
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _entries.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
