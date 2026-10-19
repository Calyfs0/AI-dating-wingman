import 'package:image_picker/image_picker.dart';

import '../../screenshot_reply/models/suggested_replies.dart';

/// Coarse phase for shell routing (derived from [OpenersFlowState]).
enum OpenersPhase { upload, generating, results }

/// Strongly typed Openers UI state.
sealed class OpenersFlowState {
  const OpenersFlowState();

  OpenersPhase get phase;
  String? get errorMessage;
  bool get isBusy;
  bool get isStreaming;
}

final class OpenersUploadState extends OpenersFlowState {
  const OpenersUploadState({this.errorMessage, this.selectedImage});

  @override
  final String? errorMessage;
  final XFile? selectedImage;

  @override
  OpenersPhase get phase => OpenersPhase.upload;

  @override
  bool get isBusy => false;

  @override
  bool get isStreaming => false;

  OpenersUploadState copyWith({
    String? errorMessage,
    XFile? selectedImage,
    bool clearError = false,
    bool clearImage = false,
  }) {
    return OpenersUploadState(
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedImage: clearImage ? null : (selectedImage ?? this.selectedImage),
    );
  }
}

final class OpenersGeneratingState extends OpenersFlowState {
  const OpenersGeneratingState({required this.loadingMessage});

  final String loadingMessage;

  @override
  OpenersPhase get phase => OpenersPhase.generating;

  @override
  String? get errorMessage => null;

  @override
  bool get isBusy => true;

  @override
  bool get isStreaming => false;

  OpenersGeneratingState copyWith({String? loadingMessage}) {
    return OpenersGeneratingState(
      loadingMessage: loadingMessage ?? this.loadingMessage,
    );
  }
}

final class OpenersResultsState extends OpenersFlowState {
  const OpenersResultsState({
    required this.openers,
    this.isStreaming = false,
    this.errorMessage,
  });

  final SuggestedReplies openers;
  @override
  final bool isStreaming;
  @override
  final String? errorMessage;

  @override
  OpenersPhase get phase => OpenersPhase.results;

  @override
  bool get isBusy => isStreaming;

  OpenersResultsState copyWith({
    SuggestedReplies? openers,
    bool? isStreaming,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OpenersResultsState(
      openers: openers ?? this.openers,
      isStreaming: isStreaming ?? this.isStreaming,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
