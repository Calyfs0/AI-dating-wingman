import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/person.dart';

class PeopleController extends ChangeNotifier {
  PeopleController();

  static const _storageKey = 'gotchu_people_v1';
  static const _legacyStorageKey = 'wingman_people_v1';

  final List<Person> _people = [];
  bool loaded = false;

  List<Person> get people {
    final sorted = [..._people]
      ..sort((a, b) {
        final byStatus = a.status.sortOrder.compareTo(b.status.sortOrder);
        if (byStatus != 0) return byStatus;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    return sorted;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey) ??
        prefs.getString(_legacyStorageKey);
    _people.clear();
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final item in list) {
          if (item is Map) {
            _people.add(Person.fromJson(Map<String, dynamic>.from(item)));
          }
        }
        if (prefs.containsKey(_legacyStorageKey)) {
          await prefs.setString(_storageKey, raw);
          await prefs.remove(_legacyStorageKey);
        }
      } catch (e) {
        debugPrint('people load: ${e.runtimeType}');
      }
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_people.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> addPerson({
    required String name,
    PersonStatus status = PersonStatus.yourMove,
    String note = '',
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _people.add(
      Person.create(name: trimmed, status: status, note: note),
    );
    notifyListeners();
    await _persist();
  }

  Future<void> updatePerson(Person person) async {
    final i = _people.indexWhere((p) => p.id == person.id);
    if (i < 0) return;
    _people[i] = person.copyWith(updatedAt: DateTime.now());
    notifyListeners();
    await _persist();
  }

  Future<void> removePerson(String id) async {
    _people.removeWhere((p) => p.id == id);
    notifyListeners();
    await _persist();
  }
}
