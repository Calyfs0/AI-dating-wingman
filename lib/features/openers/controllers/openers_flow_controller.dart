import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../../history/controllers/history_controller.dart';
import '../../history/models/history_entry.dart';
import '../../people/models/person.dart';
import '../../screenshot_reply/models/generation_prefs.dart';
import '../../screenshot_reply/models/reply_generation_result.dart';
import '../../screenshot_reply/models/suggested_replies.dart';
import '../../screenshot_reply/services/generate_replies_service.dart';
import '../../usage/usage_controller.dart';

enum OpenersPhase { upload, generating, results }

class OpenersFlowController extends ChangeNotifier {
  OpenersFlowController(
    this._service, {
    GenerationPrefs Function()? prefsOf,
    HistoryController? history,
    UsageController? usage,
  })  : _prefsOf = prefsOf,
        _history = history,
        _usage = usage;

  final GenerateRepliesService _service;
  final GenerationPrefs Function()? _prefsOf;
  final HistoryController? _history;
  final UsageController? _usage;
  final ImagePicker _picker = ImagePicker();

  OpenersPhase phase = OpenersPhase.upload;
  XFile? selectedImage;
  SuggestedReplies? openers;
  String? errorMessage;
  bool isBusy = false;
  String loadingMessage = 'Reading their profile…';
  bool copiedConfirmation = false;
  ReplyTone preferredVibe = ReplyTone.natural;
  Person? attachedPerson;

  int _generationToken = 0;

  GenerationPrefs get _prefs {
    final base = _prefsOf?.call() ?? const GenerationPrefs();
    final person = attachedPerson;
    if (person == null) return base;
    return base.withPerson(name: person.name, note: person.note);
  }

  void setAttachedPerson(Person? person) {
    attachedPerson = person;
    notifyListeners();
  }

  List<ReplyTone> get orderedTones {
    final preferred = preferredVibe;
    return [
      preferred,
      ...ReplyTone.values.where((t) => t != preferred),
    ];
  }

  Future<void> chooseFromPhotos() => _pick(ImageSource.gallery);
  Future<void> capturePhoto() => _pick(ImageSource.camera);

  Future<void> _pick(ImageSource source) async {
    errorMessage = null;
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1800,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) return;
      selectedImage = file;
      openers = null;
      phase = OpenersPhase.upload;
      notifyListeners();
    } on PlatformException catch (e) {
      debugPrint('openers picker: ${e.code}');
      errorMessage = 'Couldn’t open that source. Check permissions and try again.';
      notifyListeners();
    } catch (e) {
      debugPrint('openers picker: ${e.runtimeType}');
      errorMessage = 'Couldn’t open that source. Please try again.';
      notifyListeners();
    }
  }

  void clearImage() {
    selectedImage = null;
    openers = null;
    errorMessage = null;
    phase = OpenersPhase.upload;
    notifyListeners();
  }

  void startOver() {
    _generationToken++;
    isBusy = false;
    selectedImage = null;
    openers = null;
    errorMessage = null;
    copiedConfirmation = false;
    phase = OpenersPhase.upload;
    notifyListeners();
  }

  /// Leave results but keep the selected profile screenshot.
  void backFromResults() {
    _generationToken++;
    isBusy = false;
    openers = null;
    errorMessage = null;
    copiedConfirmation = false;
    phase = OpenersPhase.upload;
    notifyListeners();
  }

  void cancelGeneration() {
    if (phase != OpenersPhase.generating) return;
    _generationToken++;
    isBusy = false;
    errorMessage = null;
    phase = OpenersPhase.upload;
    notifyListeners();
  }

  Future<void> generate() async {
    final image = selectedImage;
    if (image == null) {
      errorMessage = 'Choose a profile screenshot to continue.';
      notifyListeners();
      return;
    }
    if (isBusy) return;

    final usage = _usage;
    if (usage != null && !await usage.tryConsume()) {
      errorMessage = usage.limitMessage;
      notifyListeners();
      return;
    }

    final token = ++_generationToken;
    final prefs = _prefs;
    preferredVibe = prefs.preferredVibe;

    isBusy = true;
    errorMessage = null;
    phase = OpenersPhase.generating;
    loadingMessage = 'Reading their profile…';
    notifyListeners();

    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (token != _generationToken || phase != OpenersPhase.generating) {
        return;
      }
      loadingMessage = 'Finding a first line…';
      notifyListeners();
    });

    try {
      final result = await _service.generateOpeners(
        image.path,
        prefs: prefs,
      );
      if (token != _generationToken) return;
      switch (result) {
        case RepliesReady(:final replies):
          openers = replies;
          phase = OpenersPhase.results;
          final person = attachedPerson;
          await _history?.addFromReplies(
            kind: HistoryKind.opener,
            replies: replies,
            personId: person?.id,
            personName: person?.name,
          );
        case NoReplyNeeded():
          errorMessage =
              "Couldn't find enough profile detail. Try a clearer screenshot.";
          phase = OpenersPhase.upload;
      }
    } on AppException catch (e) {
      if (token != _generationToken) return;
      errorMessage = e.message;
      phase = OpenersPhase.upload;
    } catch (e) {
      if (token != _generationToken) return;
      errorMessage = AppExceptionMapper.map(e).message;
      phase = OpenersPhase.upload;
    } finally {
      if (token == _generationToken) {
        isBusy = false;
        notifyListeners();
      }
    }
  }

  Future<void> tryAgain() async {
    if (selectedImage == null) {
      startOver();
      return;
    }
    await generate();
  }

  Future<bool> copyOpener(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      HapticFeedback.lightImpact();
      copiedConfirmation = true;
      notifyListeners();
      Future<void>.delayed(const Duration(seconds: 2), () {
        copiedConfirmation = false;
        notifyListeners();
      });
      return true;
    } catch (_) {
      errorMessage = 'Couldn’t copy. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
