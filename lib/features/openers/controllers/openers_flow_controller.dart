import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../../screenshot_reply/models/reply_generation_result.dart';
import '../../screenshot_reply/models/suggested_replies.dart';
import '../../screenshot_reply/services/generate_replies_service.dart';

enum OpenersPhase { upload, generating, results }

class OpenersFlowController extends ChangeNotifier {
  OpenersFlowController(this._service);

  final GenerateRepliesService _service;
  final ImagePicker _picker = ImagePicker();

  OpenersPhase phase = OpenersPhase.upload;
  XFile? selectedImage;
  SuggestedReplies? openers;
  String? errorMessage;
  bool isBusy = false;
  String loadingMessage = 'Reading their profile…';
  bool copiedConfirmation = false;

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
    selectedImage = null;
    openers = null;
    errorMessage = null;
    copiedConfirmation = false;
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

    isBusy = true;
    errorMessage = null;
    phase = OpenersPhase.generating;
    loadingMessage = 'Reading their profile…';
    notifyListeners();

    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!isBusy || phase != OpenersPhase.generating) return;
      loadingMessage = 'Finding a first line…';
      notifyListeners();
    });

    try {
      final result = await _service.generateOpeners(image.path);
      switch (result) {
        case RepliesReady(:final replies):
          openers = replies;
          phase = OpenersPhase.results;
        case NoReplyNeeded():
          errorMessage =
              "Couldn't find enough profile detail. Try a clearer screenshot.";
          phase = OpenersPhase.upload;
      }
    } on AppException catch (e) {
      errorMessage = e.message;
      phase = OpenersPhase.upload;
    } catch (e) {
      errorMessage = AppExceptionMapper.map(e).message;
      phase = OpenersPhase.upload;
    } finally {
      isBusy = false;
      notifyListeners();
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
