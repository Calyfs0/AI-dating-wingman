import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../../history/controllers/history_controller.dart';
import '../../history/models/history_entry.dart';
import '../../people/models/person.dart';
import '../../usage/usage_controller.dart';
import '../models/generation_prefs.dart';
import '../models/reply_generation_result.dart';
import '../models/suggested_replies.dart';
import '../services/generate_replies_service.dart';

enum ReplyFlowPhase { upload, textEntry, generating, results }

enum ReplyInputSource { screenshot, text }

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
        _usage = usage;

  final GenerateRepliesService _service;
  final GenerationPrefs Function()? _prefsOf;
  final HistoryController? _history;
  final UsageController? _usage;
  final ImagePicker _picker = ImagePicker();

  ReplyFlowPhase phase = ReplyFlowPhase.upload;
  ReplyInputSource lastSource = ReplyInputSource.screenshot;
  XFile? selectedImage;
  String typedMessage = '';
  String typedContext = '';
  SuggestedReplies? replies;
  String? errorMessage;
  String? noReplyTitle;
  String? noReplyMessage;
  bool isBusy = false;
  String loadingMessage = 'Reading the conversation…';
  bool copiedConfirmation = false;
  Person? attachedPerson;

  /// Tone to show first on results (from You prefs at generate time).
  ReplyTone preferredVibe = ReplyTone.natural;

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

  bool get hasImage => selectedImage != null;
  bool get canGenerate => hasImage && !isBusy;
  bool get hasNoReplyNotice =>
      noReplyTitle != null && noReplyMessage != null;

  List<ReplyTone> get orderedTones {
    final preferred = preferredVibe;
    return [
      preferred,
      ...ReplyTone.values.where((t) => t != preferred),
    ];
  }

  /// Wipe session fields so the next chat cannot inherit the last one.
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
    if (clearReplies) replies = null;
    errorMessage = null;
    noReplyTitle = null;
    noReplyMessage = null;
    copiedConfirmation = false;
  }

  /// Returns and clears a pending "no reply needed" notice for the UI.
  ({String title, String message})? consumeNoReplyNotice() {
    final title = noReplyTitle;
    final message = noReplyMessage;
    if (title == null || message == null) return null;
    noReplyTitle = null;
    noReplyMessage = null;
    notifyListeners();
    return (title: title, message: message);
  }

  Future<void> chooseScreenshot() => _pickImage(ImageSource.gallery);

  /// Capture a chat on another phone (or any screen) with the camera.
  Future<void> capturePhoto() => _pickImage(ImageSource.camera);

  Future<void> _pickImage(ImageSource source) async {
    errorMessage = null;
    final fromCamera = source == ImageSource.camera;
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1800,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) return;
      // New photo chat — drop any prior typed session completely.
      _resetChatState(clearImage: false, clearTyped: true, clearReplies: true);
      selectedImage = file;
      lastSource = ReplyInputSource.screenshot;
      phase = ReplyFlowPhase.upload;
      notifyListeners();
    } on PlatformException catch (e) {
      debugPrint('image_picker: ${e.code}');
      errorMessage = fromCamera
          ? 'Couldn’t open the camera. Check permissions and try again.'
          : 'Couldn’t open Photos. Check permissions and try again.';
      notifyListeners();
    } catch (e) {
      debugPrint('image_picker: ${e.runtimeType}');
      errorMessage = fromCamera
          ? 'Couldn’t open the camera. Please try again.'
          : 'Couldn’t open Photos. Please try again.';
      notifyListeners();
    }
  }

  void clearScreenshot() {
    selectedImage = null;
    replies = null;
    errorMessage = null;
    phase = ReplyFlowPhase.upload;
    notifyListeners();
  }

  /// [fresh] clears typed fields — use for a brand-new text chat.
  void openTextEntry({bool fresh = true}) {
    // Text chat never carries a prior screenshot.
    _resetChatState(
      clearImage: true,
      clearTyped: fresh,
      clearReplies: true,
    );
    phase = ReplyFlowPhase.textEntry;
    notifyListeners();
  }

  void backFromTextEntry() {
    // Leaving compose without generating — discard the draft so it
    // cannot leak into a later photo/text chat.
    _resetChatState(clearImage: true, clearTyped: true, clearReplies: true);
    phase = ReplyFlowPhase.upload;
    notifyListeners();
  }

  /// Back to the hub — fully isolated from the previous chat.
  void startOver() {
    _generationToken++;
    isBusy = false;
    _resetChatState(clearImage: true, clearTyped: true, clearReplies: true);
    lastSource = ReplyInputSource.screenshot;
    phase = ReplyFlowPhase.upload;
    notifyListeners();
  }

  /// Leave results without wiping the screenshot / typed draft.
  void backFromResults() {
    _generationToken++;
    isBusy = false;
    replies = null;
    errorMessage = null;
    noReplyTitle = null;
    noReplyMessage = null;
    copiedConfirmation = false;
    if (lastSource == ReplyInputSource.text) {
      phase = ReplyFlowPhase.textEntry;
    } else {
      phase = ReplyFlowPhase.upload;
    }
    notifyListeners();
  }

  /// Abort an in-flight generate and return to the prior input screen.
  void cancelGeneration() {
    if (phase != ReplyFlowPhase.generating) return;
    _generationToken++;
    isBusy = false;
    errorMessage = null;
    phase = lastSource == ReplyInputSource.text
        ? ReplyFlowPhase.textEntry
        : ReplyFlowPhase.upload;
    notifyListeners();
  }

  Future<void> generateReplies() async {
    final image = selectedImage;
    if (image == null) {
      errorMessage = 'Choose a screenshot of your chat to continue.';
      notifyListeners();
      return;
    }
    // Photo chat must not send leftover typed context later via edit→regenerate.
    typedMessage = '';
    typedContext = '';
    final prefs = _prefs;
    preferredVibe = prefs.preferredVibe;
    await _runGeneration(
      source: ReplyInputSource.screenshot,
      work: () => _service.generateFromScreenshot(
        image.path,
        prefs: prefs,
      ),
    );
  }

  Future<void> generateFromTypedMessage({
    required String message,
    String context = '',
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      errorMessage = 'Enter the message you received to continue.';
      notifyListeners();
      return;
    }
    // Text chat must not keep a prior screenshot around.
    selectedImage = null;
    typedMessage = trimmed;
    typedContext = context.trim();
    final prefs = _prefs;
    preferredVibe = prefs.preferredVibe;
    await _runGeneration(
      source: ReplyInputSource.text,
      work: () => _service.generateFromMessage(
        message: typedMessage,
        context: typedContext.isEmpty ? null : typedContext,
        prefs: prefs,
      ),
    );
  }

  Future<void> _runGeneration({
    required ReplyInputSource source,
    required Future<ReplyGenerationResult> Function() work,
  }) async {
    if (isBusy) return;

    final usage = _usage;
    if (usage != null && !await usage.tryConsume()) {
      errorMessage = usage.limitMessage;
      notifyListeners();
      return;
    }

    final token = ++_generationToken;
    isBusy = true;
    errorMessage = null;
    noReplyTitle = null;
    noReplyMessage = null;
    lastSource = source;
    phase = ReplyFlowPhase.generating;
    loadingMessage = source == ReplyInputSource.text
        ? 'Reading your message…'
        : 'Reading the conversation…';
    notifyListeners();

    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (token != _generationToken || phase != ReplyFlowPhase.generating) {
        return;
      }
      loadingMessage = 'Finding the right words…';
      notifyListeners();
    });

    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (token != _generationToken || phase != ReplyFlowPhase.generating) {
        return;
      }
      loadingMessage = 'Turning tension into text…';
      notifyListeners();
    });

    try {
      final result = await work();
      if (token != _generationToken) return;
      switch (result) {
        case RepliesReady(:final replies):
          this.replies = replies;
          phase = ReplyFlowPhase.results;
          final person = attachedPerson;
          await _history?.addFromReplies(
            kind: HistoryKind.reply,
            replies: replies,
            personId: person?.id,
            personName: person?.name,
          );
        case NoReplyNeeded(:final title, :final message):
          replies = null;
          noReplyTitle = title;
          noReplyMessage = message;
          phase = source == ReplyInputSource.text
              ? ReplyFlowPhase.textEntry
              : ReplyFlowPhase.upload;
      }
    } on AppException catch (e) {
      if (token != _generationToken) return;
      errorMessage = e.message;
      phase = source == ReplyInputSource.text
          ? ReplyFlowPhase.textEntry
          : ReplyFlowPhase.upload;
    } catch (e) {
      if (token != _generationToken) return;
      errorMessage = AppExceptionMapper.map(e).message;
      phase = source == ReplyInputSource.text
          ? ReplyFlowPhase.textEntry
          : ReplyFlowPhase.upload;
    } finally {
      if (token == _generationToken) {
        isBusy = false;
        notifyListeners();
      }
    }
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

  /// Re-run from an edited "latest message" without leaving the results screen.
  /// Photo chats keep the screenshot; text chats resend only the edited line.
  Future<void> regenerateFromEditedMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      errorMessage = 'Enter the message you received to continue.';
      notifyListeners();
      return;
    }
    if (isBusy) return;

    final image = selectedImage;
    final keepScreenshot = image != null &&
        lastSource == ReplyInputSource.screenshot;

    typedMessage = trimmed;
    if (!keepScreenshot) {
      // Pure text session — don't drag optional context from an older chat.
      typedContext = '';
      selectedImage = null;
      lastSource = ReplyInputSource.text;
    }

    final token = ++_generationToken;
    final prefs = _prefs;
    preferredVibe = prefs.preferredVibe;
    final previousReplies = replies;

    isBusy = true;
    errorMessage = null;
    noReplyTitle = null;
    noReplyMessage = null;
    phase = ReplyFlowPhase.results;
    notifyListeners();

    try {
      final ReplyGenerationResult outcome;
      if (keepScreenshot) {
        outcome = await _service.generateFromScreenshot(
          image.path,
          latestMessageOverride: trimmed,
          prefs: prefs,
        );
      } else {
        outcome = await _service.generateFromMessage(
          message: typedMessage,
          prefs: prefs,
        );
      }
      if (token != _generationToken) return;
      switch (outcome) {
        case RepliesReady(:final replies):
          this.replies = SuggestedReplies(
            natural: replies.natural,
            playful: replies.playful,
            latestIncoming: trimmed,
          );
          phase = ReplyFlowPhase.results;
        case NoReplyNeeded(:final title, :final message):
          noReplyTitle = title;
          noReplyMessage = message;
          // Keep prior cards when possible so regenerate doesn't feel like a crash.
          if (previousReplies != null) {
            replies = previousReplies;
            phase = ReplyFlowPhase.results;
          } else {
            replies = null;
            phase = keepScreenshot
                ? ReplyFlowPhase.upload
                : ReplyFlowPhase.textEntry;
          }
      }
    } on AppException catch (e) {
      if (token != _generationToken) return;
      errorMessage = e.message;
    } catch (e) {
      if (token != _generationToken) return;
      errorMessage = AppExceptionMapper.map(e).message;
    } finally {
      if (token == _generationToken) {
        isBusy = false;
        notifyListeners();
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
      errorMessage = 'Couldn’t copy. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
