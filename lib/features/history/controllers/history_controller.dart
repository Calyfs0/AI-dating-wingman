import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../screenshot_reply/models/suggested_replies.dart';
import '../models/history_entry.dart';

class HistoryController extends ChangeNotifier {
  HistoryController({this.maxEntries = 20});

  static const _storageKey = 'kehlo_history_v1';
  static const _gotchuStorageKey = 'gotchu_history_v1';

  final int maxEntries;
  final List<HistoryEntry> _entries = [];
  bool loaded = false;

  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  List<HistoryEntry> forPerson(String personId) =>
      _entries.where((e) => e.personId == personId).toList(growable: false);

  /// Soft retention pulse — lines saved this calendar week (local).
  int get unstucksThisWeek {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(start.year, start.month, start.day);
    return _entries.where((e) => !e.createdAt.isBefore(weekStart)).length;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey) ??
        prefs.getString(_gotchuStorageKey);
    _entries.clear();
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final item in list) {
          if (item is Map) {
            _entries.add(HistoryEntry.fromJson(Map<String, dynamic>.from(item)));
          }
        }
        if (prefs.containsKey(_gotchuStorageKey)) {
          await prefs.setString(_storageKey, raw);
          await prefs.remove(_gotchuStorageKey);
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
