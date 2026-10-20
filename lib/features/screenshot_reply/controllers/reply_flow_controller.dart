import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../../history/controllers/history_controller.dart';
import '../../history/models/history_entry.dart';
import '../../people/models/person.dart';
import '../../usage/usage_controller.dart';
import '../models/generation_prefs.dart';
import '../models/reply_flow_state.dart';
import '../models/reply_generation_result.dart';
import '../models/suggested_replies.dart';
import '../services/generate_replies_service.dart';

export '../models/reply_flow_state.dart';

/// In-memory only — nothing is persisted or linked across chats
/// (aside from optional local history snapshots).
class ReplyFlowController extends ChangeNotifier {
  ReplyFlowController(
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

  ReplyFlowState _state = const ReplyUploadState();
  NoReplyNotice? _pendingNoReply;

  /// Session inputs that survive phase transitions (for try-again / regenerate).
  XFile? selectedImage;
  String typedMessage = '';
  String typedContext = '';
  ReplyInputSource lastSource = ReplyInputSource.screenshot;
  Person? attachedPerson;
  /// Session-only vibe (seeded from You prefs; tone switch updates this, not You).
  ReplyTone preferredVibe = ReplyTone.natural;
  bool copiedConfirmation = false;

  int _generationToken = 0;
  GenerationCancelToken? _cancelToken;
  /// Soft local credit reserved for the in-flight generate (refunded on cancel).
  bool _softConsumed = false;

  // ---- Compatibility getters (screens keep light updates) ----

  ReplyFlowState get state => _state;
  ReplyFlowPhase get phase => _state.phase;
  String? get errorMessage => _state.errorMessage;
  bool get isBusy => _state.isBusy;
  bool get isStreaming => _state.isStreaming;

  SuggestedReplies? get replies => switch (_state) {
        ReplyResultsState(:final replies) => replies,
        _ => null,
      };

  String get loadingMessage => switch (_state) {
        ReplyGeneratingState(:final loadingMessage) => loadingMessage,
        _ => 'Reading the conversation…',
      };

  /// Legacy dual fields — prefer [consumeNoReplyNotice].
  String? get noReplyTitle => _pendingNoReply?.title;
  String? get noReplyMessage => _pendingNoReply?.message;

  bool get hasImage => selectedImage != null;
  bool get canGenerate => hasImage && !isBusy;
  bool get hasNoReplyNotice => _pendingNoReply != null;

  GenerationPrefs get _prefs {
    final base = _prefsOf?.call() ?? const GenerationPrefs();
    // Session vibe wins for this flow; You prefs supply casual/language defaults.
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

  void _setState(ReplyFlowState next) {
    _state = next;
    notifyListeners();
  }

  void setAttachedPerson(Person? person) {
    attachedPerson = person;
    notifyListeners();
  }

  void _resetChatState({
    bool clearImage = true,
    bool clearTyped = true,
    bool clearReplies = true,
  }) {
    if (clearImage) selectedImage = null;
    if (clearTyped) {
      typedMessage = '';
      typedContext = '';
    }
    _pendingNoReply = null;
    copiedConfirmation = false;
    // clearReplies handled by transitioning state away from results
  }

  ({String title, String message})? consumeNoReplyNotice() {
    final notice = _pendingNoReply;
    if (notice == null) return null;
    _pendingNoReply = null;
    notifyListeners();
    return (title: notice.title, message: notice.message);
  }

  void _queueNoReply(NoReplyNotice notice) {
    _pendingNoReply = notice;
  }

  Future<void> chooseScreenshot() => _pickImage(ImageSource.gallery);

  Future<void> capturePhoto() =>
      _pickImage(kIsWeb ? ImageSource.gallery : ImageSource.camera);

  Future<void> _pickImage(ImageSource source) async {
    final fromCamera = source == ImageSource.camera;
    try {
      // Leaner images = faster upload + vision. Chat text stays readable at ~1280.
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 72,
        maxWidth: 1280,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) return;
      _resetChatState(clearImage: false, clearTyped: true, clearReplies: true);
      selectedImage = file;
      lastSource = ReplyInputSource.screenshot;
      _setState(ReplyUploadState(selectedImage: file));
    } on PlatformException catch (e) {
      debugPrint('image_picker: ${e.code}');
      _setState(
        ReplyUploadState(
          selectedImage: selectedImage,
          errorMessage: fromCamera
              ? 'Camera access is needed to photograph a chat. Allow Camera for Kehlo in Settings, then try again.'
              : 'Photo access is needed to pick a screenshot. Allow Photos for Kehlo in Settings, then try again.',
        ),
      );
    } catch (e) {
      debugPrint('image_picker: ${e.runtimeType}');
      _setState(
        ReplyUploadState(
          selectedImage: selectedImage,
          errorMessage: fromCamera
              ? 'Couldn’t open the camera. Please try again.'
              : 'Couldn’t open Photos. Please try again.',
        ),
      );
    }
  }

  void clearScreenshot() {
    selectedImage = null;
    _pendingNoReply = null;
    _setState(const ReplyUploadState());
  }

  void openTextEntry({bool fresh = true}) {
    _resetChatState(
      clearImage: true,
      clearTyped: fresh,
      clearReplies: true,
    );
    if (fresh) _seedSessionVibeFromYou();
    _setState(const ReplyTextEntryState());
  }

  void backFromTextEntry() {
    _resetChatState(clearImage: true, clearTyped: true, clearReplies: true);
    _setState(const ReplyUploadState());
  }

  void startOver() {
    _generationToken++;
    _cancelToken?.cancel();
    _cancelToken = null;
    _refundSoftConsumeIfNeeded();
    _resetChatState(clearImage: true, clearTyped: true, clearReplies: true);
    lastSource = ReplyInputSource.screenshot;
    attachedPerson = null;
    _seedSessionVibeFromYou();
    _setState(const ReplyUploadState());
  }

  void backFromResults() {
    _generationToken++;
    _cancelToken?.cancel();
    _cancelToken = null;
    _pendingNoReply = null;
    copiedConfirmation = false;
    if (lastSource == ReplyInputSource.text) {
      _setState(const ReplyTextEntryState());
    } else {
      _setState(ReplyUploadState(selectedImage: selectedImage));
    }
  }

  void cancelGeneration() {
    if (!_state.isBusy && !_state.isStreaming) return;
    _cancelToken?.cancel();
    _cancelToken = null;
    _generationToken++;
    _refundSoftConsumeIfNeeded();
    _returnToInput();
  }

  void _refundSoftConsumeIfNeeded() {
    if (!_softConsumed) return;
    _softConsumed = false;
    unawaited(_usage?.refundConsume());
  }

  void _clearSoftConsume() {
    _softConsumed = false;
  }

  void _returnToInput({String? error}) {
    if (lastSource == ReplyInputSource.text) {
      _setState(ReplyTextEntryState(errorMessage: error));
    } else {
      _setState(
        ReplyUploadState(selectedImage: selectedImage, errorMessage: error),
      );
    }
  }

  Future<void> generateReplies() async {
    final image = selectedImage;
    if (image == null) {
      _setState(
        const ReplyUploadState(
          errorMessage: 'Choose a screenshot of your chat to continue.',
        ),
      );
      return;
    }
    typedMessage = '';
    typedContext = '';
    final prefs = _prefs;
    await _runGeneration(
      source: ReplyInputSource.screenshot,
      work: ({required onPartial, required cancelToken}) =>
          _service.generateFromScreenshot(
        image,
        prefs: prefs,
        onPartial: onPartial,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<void> generateFromTypedMessage({
    required String message,
    String context = '',
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      _setState(
        const ReplyTextEntryState(
          errorMessage: 'Enter the message you received to continue.',
        ),
      );
      return;
    }
    selectedImage = null;
    typedMessage = trimmed;
    typedContext = context.trim();
    final prefs = _prefs;
    await _runGeneration(
      source: ReplyInputSource.text,
      work: ({required onPartial, required cancelToken}) =>
          _service.generateFromMessage(
        message: typedMessage,
        context: typedContext.isEmpty ? null : typedContext,
        prefs: prefs,
        onPartial: onPartial,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<void> _runGeneration({
    required ReplyInputSource source,
    required Future<ReplyGenerationResult> Function({
      required ReplyPartialCallback onPartial,
      required GenerationCancelToken cancelToken,
    }) work,
  }) async {
    if (isBusy) return;

    lastSource = source;

    final usage = _usage;
    if (usage != null && !await usage.tryConsume()) {
      _returnToInput(error: usage.limitMessage);
      return;
    }
    _softConsumed = usage != null;

    final token = ++_generationToken;
    _cancelToken?.cancel();
    final cancelToken = GenerationCancelToken();
    _cancelToken = cancelToken;

    _pendingNoReply = null;
    _setState(
      ReplyGeneratingState(
        source: source,
        loadingMessage: source == ReplyInputSource.text
            ? 'Reading your message…'
            : 'Reading the conversation…',
      ),
    );

    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (token != _generationToken) return;
      final s = _state;
      if (s is! ReplyGeneratingState) return;
      _setState(s.copyWith(loadingMessage: 'Understanding the vibe…'));
    });

    Future<void>.delayed(const Duration(milliseconds: 1900), () {
      if (token != _generationToken) return;
      final s = _state;
      if (s is! ReplyGeneratingState) return;
      _setState(s.copyWith(loadingMessage: 'Crafting your replies…'));
    });

    void onPartial(String natural, String playful, {String? latestIncoming}) {
      if (token != _generationToken) return;
      final existing = replies;
      final incoming = (latestIncoming?.trim().isNotEmpty == true)
          ? latestIncoming!.trim()
          : (existing?.latestIncoming?.trim().isNotEmpty == true
              ? existing!.latestIncoming
              : (typedMessage.trim().isNotEmpty ? typedMessage.trim() : null));
      final hasReplies =
          natural.trim().length >= 8 || playful.trim().length >= 8;
      if (!hasReplies) {
        // latest_incoming often streams before reply bodies — keep generating
        // unless we already showed cards, then just fill their message.
        if (incoming == null ||
            incoming.isEmpty ||
            existing == null ||
            existing.latestIncoming == incoming) {
          return;
        }
        _setState(
          ReplyResultsState(
            replies: existing.copyWith(latestIncoming: incoming),
            source: source,
            isStreaming: true,
          ),
        );
        return;
      }
      _setState(
        ReplyResultsState(
          replies: SuggestedReplies(
            natural: natural.isEmpty ? '…' : natural,
            playful: playful.isEmpty ? '…' : playful,
            latestIncoming: incoming,
          ),
          source: source,
          isStreaming: true,
        ),
      );
    }

    try {
      final result = await work(
        onPartial: onPartial,
        cancelToken: cancelToken,
      );
      if (token != _generationToken) return;
      await _applyGenerationOutcome(result, source: source);
    } catch (e) {
      if (token != _generationToken) return;
      await _applyGenerationFailure(e, source: source, keepPartials: true);
    } finally {
      if (token == _generationToken) {
        _cancelToken = null;
        final s = _state;
        if (s is ReplyResultsState && (s.isStreaming || s.isRegenerating)) {
          _setState(
            s.copyWith(isStreaming: false, isRegenerating: false),
          );
        } else if (s is ReplyGeneratingState) {
          // Failure path should already have moved off generating.
          _returnToInput();
        } else {
          notifyListeners();
        }
      }
    }
  }

  Future<void> _applyGenerationOutcome(
    ReplyGenerationResult result, {
    required ReplyInputSource source,
    String? latestIncomingOverride,
  }) async {
    _clearSoftConsume();
    await _usage?.refreshFromServer();
    switch (result) {
      case RepliesReady(:final replies):
        final incoming = (latestIncomingOverride?.trim().isNotEmpty == true)
            ? latestIncomingOverride!.trim()
            : (replies.latestIncoming?.trim().isNotEmpty == true
                ? replies.latestIncoming!.trim()
                : (typedMessage.trim().isNotEmpty ? typedMessage.trim() : null));
        final merged = SuggestedReplies(
          natural: replies.natural,
          playful: replies.playful,
          latestIncoming: incoming,
          hook: replies.hook,
          why: replies.why,
        );
        _setState(
          ReplyResultsState(replies: merged, source: source),
        );
        final person = attachedPerson;
        await _history?.addFromReplies(
          kind: HistoryKind.reply,
          replies: merged,
          personId: person?.id,
          personName: person?.name,
        );
      case NoReplyNeeded(:final title, :final message):
        _queueNoReply(NoReplyNotice(title: title, message: message));
        _returnToInput();
    }
  }

  Future<void> _applyGenerationFailure(
    Object e, {
    required ReplyInputSource source,
    required bool keepPartials,
    SuggestedReplies? restoreReplies,
  }) async {
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

    if (restoreReplies != null) {
      _setState(
        ReplyResultsState(
          replies: restoreReplies,
          source: source,
          errorMessage: mapped.message,
        ),
      );
      return;
    }

    final current = _state;
    if (keepPartials &&
        current is ReplyResultsState &&
        current.replies.natural.trim().isNotEmpty) {
      _setState(
        current.copyWith(
          isStreaming: false,
          isRegenerating: false,
          errorMessage: mapped.message,
        ),
      );
      return;
    }

    _returnToInput(error: mapped.message);
  }

  Future<void> tryAgain() async {
    if (lastSource == ReplyInputSource.text) {
      if (typedMessage.trim().isEmpty) {
        openTextEntry(fresh: true);
        return;
      }
      await generateFromTypedMessage(
        message: typedMessage,
        context: typedContext,
      );
      return;
    }
    if (selectedImage == null) {
      startOver();
      return;
    }
    await generateReplies();
  }

  Future<void> regenerateFromEditedMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      final s = _state;
      if (s is ReplyResultsState) {
        _setState(
          s.copyWith(
            errorMessage: 'Enter the message you received to continue.',
          ),
        );
      }
      return;
    }
    if (isBusy) return;

    final image = selectedImage;
    final keepScreenshot =
        image != null && lastSource == ReplyInputSource.screenshot;

    typedMessage = trimmed;
    if (!keepScreenshot) {
      typedContext = '';
      selectedImage = null;
      lastSource = ReplyInputSource.text;
    }

    final token = ++_generationToken;
    _cancelToken?.cancel();
    final cancelToken = GenerationCancelToken();
    _cancelToken = cancelToken;
    final prefs = _prefs;
    final previousReplies = replies;
    final source = lastSource;

    _pendingNoReply = null;
    if (previousReplies != null) {
      _setState(
        ReplyResultsState(
          replies: previousReplies,
          source: source,
          isStreaming: true,
          isRegenerating: true,
        ),
      );
    } else {
      _setState(
        ReplyGeneratingState(
          source: source,
          loadingMessage: 'Finding the right words…',
        ),
      );
    }

    void onPartial(String natural, String playful, {String? latestIncoming}) {
      if (token != _generationToken) return;
      if (natural.trim().length < 8 && playful.trim().length < 8) return;
      _setState(
        ReplyResultsState(
          replies: SuggestedReplies(
            natural: natural.isEmpty ? '…' : natural,
            playful: playful.isEmpty ? '…' : playful,
            latestIncoming: (latestIncoming?.trim().isNotEmpty == true)
                ? latestIncoming!.trim()
                : trimmed,
          ),
          source: source,
          isStreaming: true,
          isRegenerating: true,
        ),
      );
    }

    try {
      final ReplyGenerationResult outcome;
      if (keepScreenshot) {
        outcome = await _service.generateFromScreenshot(
          image,
          latestMessageOverride: trimmed,
          prefs: prefs,
          onPartial: onPartial,
          cancelToken: cancelToken,
        );
      } else {
        outcome = await _service.generateFromMessage(
          message: typedMessage,
          prefs: prefs,
          onPartial: onPartial,
          cancelToken: cancelToken,
        );
      }
      if (token != _generationToken) return;
      switch (outcome) {
        case RepliesReady(:final replies):
          await _usage?.refreshFromServer();
          _setState(
            ReplyResultsState(
              replies: SuggestedReplies(
                natural: replies.natural,
                playful: replies.playful,
                latestIncoming: trimmed,
              ),
              source: source,
            ),
          );
        case NoReplyNeeded(:final title, :final message):
          _queueNoReply(NoReplyNotice(title: title, message: message));
          if (previousReplies != null) {
            _setState(
              ReplyResultsState(replies: previousReplies, source: source),
            );
          } else {
            _returnToInput();
          }
      }
    } catch (e) {
      if (token != _generationToken) return;
      await _applyGenerationFailure(
        e,
        source: source,
        keepPartials: false,
        restoreReplies: previousReplies,
      );
    } finally {
      if (token == _generationToken) {
        _cancelToken = null;
        final s = _state;
        if (s is ReplyResultsState && (s.isStreaming || s.isRegenerating)) {
          _setState(s.copyWith(isStreaming: false, isRegenerating: false));
        } else {
          notifyListeners();
        }
      }
    }
  }

  Future<bool> copyReply(String text) async {
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
    } catch (e) {
      debugPrint('clipboard: ${e.runtimeType}');
      final s = _state;
      if (s is ReplyResultsState) {
        _setState(
          s.copyWith(errorMessage: 'Couldn’t copy. Please try again.'),
        );
      } else {
        notifyListeners();
      }
      return false;
    }
  }
}
