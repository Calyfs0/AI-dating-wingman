import '../../features/screenshot_reply/models/reply_generation_result.dart';
import '../../features/screenshot_reply/models/suggested_replies.dart';
import '../../features/screenshot_reply/services/generate_replies_service.dart';

/// Offline / local dev stand-in for the generate-replies edge function.
class MockGenerateRepliesService implements GenerateRepliesService {
  @override
  Future<ReplyGenerationResult> generateFromScreenshot(
    String imagePath, {
    String? latestMessageOverride,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const RepliesReady(
      SuggestedReplies(
        natural: 'Sounds good — when works for you?',
        playful: 'I’m in. Don’t make me wait too long though.',
        confident: 'Let’s set a time. Free Thursday?',
      ),
    );
  }

  @override
  Future<ReplyGenerationResult> generateFromMessage({
    required String message,
    String? context,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return RepliesReady(
      SuggestedReplies(
        natural: 'Got it — $message makes sense. What do you think we should do?',
        playful: 'Okay, noted. Now impress me with your next move.',
        confident: 'Clear. Let’s lock in a plan.',
      ),
    );
  }
}
