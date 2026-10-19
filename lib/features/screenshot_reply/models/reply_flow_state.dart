import 'package:image_picker/image_picker.dart';

import 'suggested_replies.dart';

/// Coarse phase for shell routing (derived from [ReplyFlowState]).
enum ReplyFlowPhase { upload, textEntry, generating, results }

enum ReplyInputSource { screenshot, text }

/// Pending dialog after generate returns "already replied".
class NoReplyNotice {
  const NoReplyNotice({required this.title, required this.message});

  final String title;
  final String message;
}

/// Strongly typed Reply UI state. Controllers own one instance; screens read
/// via [ReplyFlowController] getters for light coupling.
sealed class ReplyFlowState {
  const ReplyFlowState();

  ReplyFlowPhase get phase;
  String? get errorMessage;
  bool get isBusy;
  bool get isStreaming;
}

final class ReplyUploadState extends ReplyFlowState {
  const ReplyUploadState({this.errorMessage, this.selectedImage});

  @override
  final String? errorMessage;
  final XFile? selectedImage;

  @override
  ReplyFlowPhase get phase => ReplyFlowPhase.upload;

  @override
  bool get isBusy => false;

  @override
  bool get isStreaming => false;

  ReplyUploadState copyWith({
    String? errorMessage,
    XFile? selectedImage,
    bool clearError = false,
    bool clearImage = false,
  }) {
    return ReplyUploadState(
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedImage: clearImage ? null : (selectedImage ?? this.selectedImage),
    );
  }
}

final class ReplyTextEntryState extends ReplyFlowState {
  const ReplyTextEntryState({this.errorMessage});

  @override
  final String? errorMessage;

  @override
  ReplyFlowPhase get phase => ReplyFlowPhase.textEntry;

  @override
  bool get isBusy => false;

  @override
  bool get isStreaming => false;

  ReplyTextEntryState copyWith({
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReplyTextEntryState(
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final class ReplyGeneratingState extends ReplyFlowState {
  const ReplyGeneratingState({
    required this.source,
    required this.loadingMessage,
  });

  final ReplyInputSource source;
  final String loadingMessage;

  @override
  ReplyFlowPhase get phase => ReplyFlowPhase.generating;

  @override
  String? get errorMessage => null;

  @override
  bool get isBusy => true;

  @override
  bool get isStreaming => false;

  ReplyGeneratingState copyWith({String? loadingMessage}) {
    return ReplyGeneratingState(
      source: source,
      loadingMessage: loadingMessage ?? this.loadingMessage,
    );
  }
}

final class ReplyResultsState extends ReplyFlowState {
  const ReplyResultsState({
    required this.replies,
    required this.source,
    this.isStreaming = false,
    this.isRegenerating = false,
    this.errorMessage,
  });

  final SuggestedReplies replies;
  final ReplyInputSource source;
  @override
  final bool isStreaming;
  final bool isRegenerating;
  @override
  final String? errorMessage;

  @override
  ReplyFlowPhase get phase => ReplyFlowPhase.results;

  @override
  bool get isBusy => isRegenerating || isStreaming;

  ReplyResultsState copyWith({
    SuggestedReplies? replies,
    bool? isStreaming,
    bool? isRegenerating,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReplyResultsState(
      replies: replies ?? this.replies,
      source: source,
      isStreaming: isStreaming ?? this.isStreaming,
      isRegenerating: isRegenerating ?? this.isRegenerating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
