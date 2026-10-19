import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../../usage/usage_controller.dart';
import '../models/profile_audit_result.dart';
import '../services/profile_audit_service.dart';

enum ProfileAuditPhase { upload, generating, results }

class ProfileAuditController extends ChangeNotifier {
  ProfileAuditController(this._service, {UsageController? usage})
      : _usage = usage;

  final ProfileAuditService _service;
  final UsageController? _usage;
  final ImagePicker _picker = ImagePicker();

  ProfileAuditPhase phase = ProfileAuditPhase.upload;
  XFile? selectedImage;
  String bioDraft = '';
  ProfileAuditResult? result;
  String? errorMessage;
  bool isBusy = false;

  Future<void> choosePhoto() async {
    errorMessage = null;
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1800,
      );
      if (file == null) return;
      selectedImage = file;
      result = null;
      phase = ProfileAuditPhase.upload;
      notifyListeners();
    } on PlatformException {
      errorMessage =
          'Photo access is needed to pick a profile screenshot. Allow Photos for Gotchu in Settings, then try again.';
      notifyListeners();
    }
  }

  void clear() {
    selectedImage = null;
    result = null;
    errorMessage = null;
    bioDraft = '';
    phase = ProfileAuditPhase.upload;
    notifyListeners();
  }

  Future<void> runAudit() async {
    final image = selectedImage;
    if (image == null) {
      errorMessage = 'Upload a profile screenshot to continue.';
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

    isBusy = true;
    errorMessage = null;
    phase = ProfileAuditPhase.generating;
    notifyListeners();

    try {
      result = await _service.audit(
        imagePath: image.path,
        bio: bioDraft,
      );
      await _usage?.refreshFromServer();
      phase = ProfileAuditPhase.results;
    } on UsageLimitException catch (e) {
      await _usage?.markExhausted();
      await _usage?.refreshFromServer();
      errorMessage = e.message;
      phase = ProfileAuditPhase.upload;
    } on AppException catch (e) {
      errorMessage = e.message;
      phase = ProfileAuditPhase.upload;
    } catch (e) {
      final mapped = AppExceptionMapper.map(e);
      if (mapped is UsageLimitException) {
        await _usage?.markExhausted();
        await _usage?.refreshFromServer();
      }
      errorMessage = mapped.message;
      phase = ProfileAuditPhase.upload;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }
}
