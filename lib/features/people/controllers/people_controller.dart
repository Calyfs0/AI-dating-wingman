import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/person.dart';

class PeopleController extends ChangeNotifier {
  PeopleController();

  static const _storageKey = 'kehlo_people_v1';
  static const _gotchuStorageKey = 'gotchu_people_v1';
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

  int get yourMoveCount =>
      _people.where((p) => p.status == PersonStatus.yourMove).length;

  List<Person> get yourMovePeople => people
      .where((p) => p.status == PersonStatus.yourMove)
      .toList(growable: false);

  Future<void> markWaiting(String id) async {
    final i = _people.indexWhere((p) => p.id == id);
    if (i < 0) return;
    _people[i] = _people[i].copyWith(
      status: PersonStatus.waiting,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
  }

  Future<void> markYourMove(String id) async {
    final i = _people.indexWhere((p) => p.id == id);
    if (i < 0) return;
    _people[i] = _people[i].copyWith(
      status: PersonStatus.yourMove,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey) ??
        prefs.getString(_gotchuStorageKey) ??
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
        if (prefs.containsKey(_gotchuStorageKey) ||
            prefs.containsKey(_legacyStorageKey)) {
          await prefs.setString(_storageKey, raw);
          await prefs.remove(_gotchuStorageKey);
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

  /// Returns the new [Person], or null if [name] was empty.
  Future<Person?> addPerson({
    required String name,
    PersonStatus status = PersonStatus.yourMove,
    String note = '',
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final person = Person.create(name: trimmed, status: status, note: note);
    _people.add(person);
    notifyListeners();
    await _persist();
    return person;
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
