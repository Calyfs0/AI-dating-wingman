import '../models/reply_generation_result.dart';
import '../models/suggested_replies.dart';

/// Validates and maps the `generate-replies` Edge Function JSON payload.
class ReplyResponseParser {
  const ReplyResponseParser();

  /// Throws [FormatException] with a user-safe message when invalid.
  ReplyGenerationResult parse(Map<String, dynamic> data) {
    if (data['error'] != null &&
        data['replies'] == null &&
        data['needsReply'] != false) {
      final message = data['error']?.toString().trim();
      throw FormatException(
        message?.isNotEmpty == true
            ? message!
            : "Couldn't read this conversation. Try a clearer screenshot.",
      );
    }

    if (data['readable'] == false) {
      final message = data['error']?.toString().trim();
      throw FormatException(
        message?.isNotEmpty == true
            ? message!
            : "Couldn't read this conversation. Try a clearer screenshot.",
      );
    }

    if (data['needsReply'] == false) {
      final title = data['title']?.toString().trim();
      final message = data['message']?.toString().trim();
      final outgoing = data['latestOutgoing']?.toString().trim();
      return NoReplyNeeded(
        title: (title != null && title.isNotEmpty)
            ? title
            : "You're all set",
        message: (message != null && message.isNotEmpty)
            ? message
            : "You already sent the last message — nothing to reply to right now. Let them come back to you.",
        latestOutgoing:
            outgoing == null || outgoing.isEmpty ? null : outgoing,
      );
    }

    final repliesRaw = data['replies'];
    if (repliesRaw is! Map) {
      throw const FormatException(
        "Couldn't generate replies. Please try again.",
      );
    }

    final replies = Map<String, dynamic>.from(repliesRaw);
    final natural = _requireReply(replies, 'natural');
    final playful = _requireReply(replies, 'playful');
    final confident = _requireReply(replies, 'confident');

    if (_tooSimilar(natural, playful) ||
        _tooSimilar(natural, confident) ||
        _tooSimilar(playful, confident)) {
      throw const FormatException(
        "Couldn't generate distinct replies. Please try again.",
      );
    }

    final latest = data['latestIncoming']?.toString().trim();
    return RepliesReady(
      SuggestedReplies(
        natural: natural,
        playful: playful,
        confident: confident,
        latestIncoming: latest?.isEmpty == true ? null : latest,
      ),
    );
  }

  String _requireReply(Map<String, dynamic> replies, String key) {
    var value = replies[key]?.toString().trim() ?? '';
    // Strip wrapping quotes the model sometimes adds.
    if (value.length >= 2) {
      final start = value[0];
      final end = value[value.length - 1];
      if ((start == '"' && end == '"') ||
          (start == "'" && end == "'") ||
          (start == '“' && end == '”')) {
        value = value.substring(1, value.length - 1).trim();
      }
    }
    if (value.isEmpty || value.length < 2) {
      throw const FormatException(
        "Couldn't generate replies. Please try again.",
      );
    }
    return value;
  }

  bool _tooSimilar(String a, String b) {
    final na = _normalize(a);
    final nb = _normalize(b);
    final fa = na.isNotEmpty ? na : a.trim().toLowerCase();
    final fb = nb.isNotEmpty ? nb : b.trim().toLowerCase();
    if (fa.isEmpty || fb.isEmpty) return true;
    if (fa == fb) return true;
    final shorter = fa.length <= fb.length ? fa : fb;
    final longer = fa.length <= fb.length ? fb : fa;
    if (shorter.length >= 24 && longer.contains(shorter)) {
      final ratio = shorter.length / longer.length;
      if (ratio >= 0.85) return true;
    }
    return false;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
