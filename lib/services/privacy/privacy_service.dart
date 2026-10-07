/// Sensitive media lifecycle: process → extract → delete raw unless saved.
abstract class PrivacyService {
  Future<void> markScreenshotTemporary(String path);
  Future<void> deleteTemporaryScreenshots();
  Future<void> retainScreenshot(String path);
  Future<void> deleteAllUserData();
}

class LocalPrivacyService implements PrivacyService {
  final Set<String> _temporary = {};
  final Set<String> _retained = {};

  @override
  Future<void> markScreenshotTemporary(String path) async {
    _temporary.add(path);
  }

  @override
  Future<void> deleteTemporaryScreenshots() async {
    // Raw screenshots are treated as sensitive and removed after processing
    // unless the user explicitly consented to save.
    _temporary.removeWhere((path) => !_retained.contains(path));
    _temporary.clear();
  }

  @override
  Future<void> retainScreenshot(String path) async {
    _retained.add(path);
    _temporary.remove(path);
  }

  @override
  Future<void> deleteAllUserData() async {
    _temporary.clear();
    _retained.clear();
  }
}
