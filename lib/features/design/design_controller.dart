import 'package:flutter/foundation.dart';

import 'design_data.dart';

class DesignController extends ChangeNotifier {
  BloomTone tone = BloomTone.sweet;
  BloomTone defaultTone = BloomTone.sweet;
  Boldness boldness = Boldness.balanced;
  Boldness defaultBoldness = Boldness.balanced;
  String? activeSituationId;
  String contextText = situations.first.sampleContext;
  int variant = 0;
  bool generating = false;
  bool proPreview = false;
  bool notifications = true;
  bool haptics = true;
  String homeQuery = '';
  String exploreQuery = '';
  String appFilter = 'All';
  String? openFolderId;
  final List<SavedLine> saved = [...seededLines];
  final Set<String> likedSituations = {};

  Situation get active => situationById(activeSituationId ?? situations.first.id);

  List<GeneratedLine> get currentLines {
    final situation = active;
    final order = <BloomTone>[
      tone,
      ...BloomTone.values.where((item) => item != tone),
    ].take(3);
    return [
      for (final item in order)
        GeneratedLine(tone: item, text: lineFor(situation, item)),
    ];
  }

  String lineFor(Situation situation, BloomTone item) {
    final bank = situation.lines[item];
    final options = bank?[boldness] ??
        bank?[Boldness.balanced] ??
        const <String>[];
    if (options.isEmpty) {
      return 'Say it lightly, and leave them room to answer.';
    }
    return options[variant % options.length];
  }

  void selectSituation(String id) {
    final situation = situationById(id);
    final changed = activeSituationId != id;
    activeSituationId = id;
    if (changed) {
      contextText = situation.sampleContext;
      tone = defaultTone;
      boldness = defaultBoldness;
      variant = 0;
    }
    notifyListeners();
  }

  void setTone(BloomTone value) {
    tone = value;
    notifyListeners();
  }

  void setDefaultTone(BloomTone value) {
    defaultTone = value;
    tone = value;
    notifyListeners();
  }

  void setBoldness(Boldness value) {
    boldness = value;
    variant = 0;
    notifyListeners();
  }

  void setDefaultBoldness(Boldness value) {
    defaultBoldness = value;
    boldness = value;
    notifyListeners();
  }

  void setContext(String value) {
    contextText = value.length > 200 ? value.substring(0, 200) : value;
    notifyListeners();
  }

  void setHomeQuery(String value) {
    homeQuery = value;
    notifyListeners();
  }

  void setExploreQuery(String value) {
    exploreQuery = value;
    notifyListeners();
  }

  void setAppFilter(String value) {
    appFilter = value;
    notifyListeners();
  }

  void openFolder(String? id) {
    openFolderId = id;
    notifyListeners();
  }

  void toggleLike(String id) {
    if (!likedSituations.add(id)) likedSituations.remove(id);
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    notifications = value;
    notifyListeners();
  }

  void toggleHaptics(bool value) {
    haptics = value;
    notifyListeners();
  }

  void enablePreview() {
    proPreview = true;
    notifyListeners();
  }

  bool isSaved(String text) => saved.any((line) => line.text == text);

  void toggleSave(GeneratedLine line) {
    final index = saved.indexWhere((item) => item.text == line.text);
    if (index >= 0) {
      saved.removeAt(index);
    } else {
      final situation = active;
      saved.insert(
        0,
        SavedLine(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          text: line.text,
          tone: line.tone,
          mood: toneStyle(line.tone).label,
          tag: situation.tag,
          image: situation.image,
          folderId: situation.folderId,
        ),
      );
    }
    notifyListeners();
  }

  void removeSaved(String id) {
    saved.removeWhere((line) => line.id == id);
    notifyListeners();
  }

  Future<void> runGenerate({bool more = false}) async {
    if (generating) return;
    generating = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    variant = more ? variant + 1 : 0;
    generating = false;
    notifyListeners();
  }
}

List<Situation> filterSituations({
  String? categoryId,
  String query = '',
  String app = 'All',
  bool applyApp = false,
}) {
  final needle = query.trim().toLowerCase();
  return situations.where((item) {
    if (categoryId != null && !item.categories.contains(categoryId)) {
      return false;
    }
    if (applyApp && app != 'All' && !item.apps.contains(app)) return false;
    if (needle.isEmpty) return true;
    final haystack = '${item.title} ${item.subtitle} ${item.headline} ${item.lineFor}'
        .toLowerCase();
    return haystack.contains(needle);
  }).toList(growable: false);
}
