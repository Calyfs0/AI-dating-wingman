import 'dart:async';

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
import '../models/openers_flow_state.dart';

export '../models/openers_flow_state.dart';

class OpenersFlowController extends ChangeNotifier {
  OpenersFlowController(
    this._service, {
    GenerationPrefs Function()? prefsOf,
    HistoryController? history,
    UsageController? usage,
  })  : _prefsOf = prefsOf,
        _history = history,
        _usage = usage {
    _seedSessionVibeFromYou();
  }

  final GenerateRepliesService _service;
  final GenerationPrefs Function()? _prefsOf;
  final HistoryController? _history;
  final UsageController? _usage;
  final ImagePicker _picker = ImagePicker();

  OpenersFlowState _state = const OpenersUploadState();

  XFile? selectedImage;
  Person? attachedPerson;
  /// Session-only vibe (seeded from You; tone switch updates this, not You).
  ReplyTone preferredVibe = ReplyTone.natural;
  bool copiedConfirmation = false;

  int _generationToken = 0;
  GenerationCancelToken? _cancelToken;
  bool _softConsumed = false;

  OpenersFlowState get state => _state;
  OpenersPhase get phase => _state.phase;
  String? get errorMessage => _state.errorMessage;
  bool get isBusy => _state.isBusy;
  bool get isStreaming => _state.isStreaming;

  SuggestedReplies? get openers => switch (_state) {
        OpenersResultsState(:final openers) => openers,
        _ => null,
      };

  String get loadingMessage => switch (_state) {
        OpenersGeneratingState(:final loadingMessage) => loadingMessage,
        _ => 'Reading their profile…',
      };

  GenerationPrefs get _prefs {
    final base = _prefsOf?.call() ?? const GenerationPrefs();
    final prefs = GenerationPrefs(
      preferredVibe: preferredVibe,
      keepCasual: base.keepCasual,
      matchLanguage: base.matchLanguage,
      personName: base.personName,
      personNote: base.personNote,
    );
    final person = attachedPerson;
    if (person == null) return prefs;
    return prefs.withPerson(name: person.name, note: person.note);
  }

  List<ReplyTone> get orderedTones {
    final preferred = preferredVibe;
    return [
      preferred,
      ...ReplyTone.values.where((t) => t != preferred),
    ];
  }

  void _seedSessionVibeFromYou() {
    preferredVibe =
        _prefsOf?.call().preferredVibe ?? ReplyTone.natural;
  }

  /// Results tone switch — session only; does not write You preferences.
  void setPreferredVibe(ReplyTone tone) {
    if (preferredVibe == tone) return;
    preferredVibe = tone;
    notifyListeners();
  }

  void _setState(OpenersFlowState next) {
    _state = next;
    notifyListeners();
  }

  void setAttachedPerson(Person? person) {
    attachedPerson = person;
    notifyListeners();
  }

  Future<void> chooseFromPhotos() => _pick(ImageSource.gallery);
  Future<void> capturePhoto() =>
      _pick(kIsWeb ? ImageSource.gallery : ImageSource.camera);

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 72,
        maxWidth: 1280,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) return;
      selectedImage = file;
      _setState(OpenersUploadState(selectedImage: file));
    } on PlatformException catch (e) {
      debugPrint('openers picker: ${e.code}');
      _setState(
        OpenersUploadState(
          selectedImage: selectedImage,
          errorMessage:
              'Photo or camera access is needed for profile screenshots. Allow access for Kehlo in Settings, then try again.',
        ),
      );
    } catch (e) {
      debugPrint('openers picker: ${e.runtimeType}');
      _setState(
        OpenersUploadState(
          selectedImage: selectedImage,
          errorMessage: 'Couldn’t open that source. Please try again.',
        ),
      );
    }
  }

  void clearImage() {
    selectedImage = null;
    _setState(const OpenersUploadState());
  }

  void startOver() {
    _generationToken++;
    _cancelToken?.cancel();
    _cancelToken = null;
    _refundSoftConsumeIfNeeded();
    selectedImage = null;
    attachedPerson = null;
    copiedConfirmation = false;
    _seedSessionVibeFromYou();
    _setState(const OpenersUploadState());
  }

  void backFromResults() {
    _generationToken++;
    _cancelToken?.cancel();
    _cancelToken = null;
    copiedConfirmation = false;
    _setState(OpenersUploadState(selectedImage: selectedImage));
  }

  void cancelGeneration() {
    if (!_state.isBusy && !_state.isStreaming) return;
    _cancelToken?.cancel();
    _cancelToken = null;
    _generationToken++;
    _refundSoftConsumeIfNeeded();
    _setState(OpenersUploadState(selectedImage: selectedImage));
  }

  void _refundSoftConsumeIfNeeded() {
    if (!_softConsumed) return;
    _softConsumed = false;
    unawaited(_usage?.refundConsume());
  }

  void _clearSoftConsume() {
    _softConsumed = false;
  }

  Future<void> generate() async {
    final image = selectedImage;
    if (image == null) {
      _setState(
        const OpenersUploadState(
          errorMessage: 'Choose a profile screenshot to continue.',
        ),
      );
      return;
    }
    if (isBusy) return;

    final usage = _usage;
    if (usage != null && !await usage.tryConsume()) {
      _setState(
        OpenersUploadState(
          selectedImage: selectedImage,
          errorMessage: usage.limitMessage,
        ),
      );
      return;
    }
    _softConsumed = usage != null;

    final token = ++_generationToken;
    _cancelToken?.cancel();
    final cancelToken = GenerationCancelToken();
    _cancelToken = cancelToken;
    // Upload-screen MoodChip writes You prefs — pick that up for a fresh run.
    // Results tone switch keeps session vibe on Try again.
    if (_state is OpenersUploadState) {
      _seedSessionVibeFromYou();
    }
    final prefs = _prefs;

    _setState(
      const OpenersGeneratingState(loadingMessage: 'Reading their profile…'),
    );

    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (token != _generationToken) return;
      final s = _state;
      if (s is! OpenersGeneratingState) return;
      _setState(s.copyWith(loadingMessage: 'Finding the hooks…'));
    });

    Future<void>.delayed(const Duration(milliseconds: 1900), () {
      if (token != _generationToken) return;
      final s = _state;
      if (s is! OpenersGeneratingState) return;
      _setState(s.copyWith(loadingMessage: 'Crafting first messages…'));
    });

    void onPartial(String natural, String playful, {String? latestIncoming}) {
      if (token != _generationToken) return;
      if (natural.trim().length < 8 && playful.trim().length < 8) return;
      final existing = openers;
      _setState(
        OpenersResultsState(
          openers: SuggestedReplies(
            natural: natural.isEmpty ? '…' : natural,
            playful: playful.isEmpty ? '…' : playful,
            hook: existing?.hook,
            why: existing?.why,
            latestIncoming: (latestIncoming?.trim().isNotEmpty == true)
                ? latestIncoming!.trim()
                : existing?.latestIncoming,
          ),
          isStreaming: true,
        ),
      );
    }

    try {
      final result = await _service.generateOpeners(
        image,
        prefs: prefs,
        onPartial: onPartial,
        cancelToken: cancelToken,
      );
      if (token != _generationToken) return;
      await _applyOutcome(result);
    } catch (e) {
      if (token != _generationToken) return;
      await _applyFailure(e);
    } finally {
      if (token == _generationToken) {
        _cancelToken = null;
        final s = _state;
        if (s is OpenersResultsState && s.isStreaming) {
          _setState(s.copyWith(isStreaming: false));
        } else if (s is OpenersGeneratingState) {
          _setState(OpenersUploadState(selectedImage: selectedImage));
        } else {
          notifyListeners();
        }
      }
    }
  }

  Future<void> _applyOutcome(ReplyGenerationResult result) async {
    _clearSoftConsume();
    await _usage?.refreshFromServer();
    switch (result) {
      case RepliesReady(:final replies):
        _setState(OpenersResultsState(openers: replies));
        final person = attachedPerson;
        await _history?.addFromReplies(
          kind: HistoryKind.opener,
          replies: replies,
          personId: person?.id,
          personName: person?.name,
        );
      case NoReplyNeeded():
        _setState(
          OpenersUploadState(
            selectedImage: selectedImage,
            errorMessage:
                "Couldn't find enough profile detail. Try a clearer screenshot.",
          ),
        );
    }
  }

  Future<void> _applyFailure(Object e) async {
    if (e is AppException && e.message == 'Cancelled.') {
      _refundSoftConsumeIfNeeded();
      return;
    }

    _clearSoftConsume();
    AppException mapped;
    if (e is UsageLimitException) {
      await _usage?.markExhausted();
      await _usage?.refreshFromServer();
      mapped = e;
    } else if (e is AppException) {
      mapped = e;
    } else {
      mapped = AppExceptionMapper.map(e);
      if (mapped is UsageLimitException) {
        await _usage?.markExhausted();
        await _usage?.refreshFromServer();
      }
    }

    _setState(
      OpenersUploadState(
        selectedImage: selectedImage,
        errorMessage: mapped.message,
      ),
    );
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
      final s = _state;
      if (s is OpenersResultsState) {
        _setState(
          s.copyWith(errorMessage: 'Couldn’t copy. Please try again.'),
        );
      }
      return false;
    }
  }
}
