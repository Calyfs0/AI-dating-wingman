import 'suggested_replies.dart';

/// Outcome of a generate-replies call.
sealed class ReplyGenerationResult {
  const ReplyGenerationResult();
}

class RepliesReady extends ReplyGenerationResult {
  const RepliesReady(this.replies);

  final SuggestedReplies replies;
}

/// Latest message was already from the user — nothing to send.
class NoReplyNeeded extends ReplyGenerationResult {
  const NoReplyNeeded({
    required this.title,
    required this.message,
    this.latestOutgoing,
  });

  final String title;
  final String message;
  final String? latestOutgoing;
}
