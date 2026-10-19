import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wingman/core/errors/app_exception.dart';
import 'package:wingman/features/screenshot_reply/controllers/reply_flow_controller.dart';
import 'package:wingman/features/screenshot_reply/models/generation_prefs.dart';
import 'package:wingman/features/screenshot_reply/models/reply_flow_state.dart';
import 'package:wingman/features/screenshot_reply/models/reply_generation_result.dart';
import 'package:wingman/features/screenshot_reply/models/suggested_replies.dart';
import 'package:wingman/features/screenshot_reply/services/generate_replies_service.dart';
import 'package:wingman/features/usage/usage_controller.dart';

class _FakeService implements GenerateRepliesService {
  ReplyGenerationResult? next;
  Object? errorToThrow;
  int calls = 0;

  @override
  Future<ReplyGenerationResult> generateFromScreenshot(
    XFile image, {
    String? latestMessageOverride,
    GenerationPrefs prefs = const GenerationPrefs(),
    ReplyPartialCallback? onPartial,
    GenerationCancelToken? cancelToken,
  }) =>
      _run(onPartial);

  @override
  Future<ReplyGenerationResult> generateFromMessage({
    required String message,
    String? context,
    GenerationPrefs prefs = const GenerationPrefs(),
    ReplyPartialCallback? onPartial,
    GenerationCancelToken? cancelToken,
  }) =>
      _run(onPartial);

  @override
  Future<ReplyGenerationResult> generateOpeners(
    XFile image, {
    GenerationPrefs prefs = const GenerationPrefs(),
    ReplyPartialCallback? onPartial,
    GenerationCancelToken? cancelToken,
  }) =>
      _run(onPartial);

  Future<ReplyGenerationResult> _run(ReplyPartialCallback? onPartial) async {
    calls++;
    if (errorToThrow != null) throw errorToThrow!;
    final result = next ??
        const RepliesReady(
          SuggestedReplies(
            natural: 'Yeah that works for me.',
            playful: 'Say less — I’m in.',
          ),
        );
    if (result is RepliesReady) {
      onPartial?.call(result.replies.natural, result.replies.playful);
    }
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeService service;
  late UsageController usage;
  late ReplyFlowController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = _FakeService();
    usage = UsageController(freeDailyLimit: 12, proDailyLimit: 200);
    await usage.load();
    controller = ReplyFlowController(
      service,
      usage: usage,
    );
  });

  tearDown(() {
    controller.dispose();
    usage.dispose();
  });

  test('generate success moves to results with replies', () async {
    service.next = const RepliesReady(
      SuggestedReplies(
        natural: 'Sounds good — Saturday?',
        playful: 'Coffee is a gateway drug. I’m game.',
      ),
    );

    await controller.generateFromTypedMessage(message: 'Want to grab coffee?');

    expect(controller.phase, ReplyFlowPhase.results);
    expect(controller.state, isA<ReplyResultsState>());
    expect(controller.replies?.natural, contains('Saturday'));
    expect(controller.replies?.playful, contains('Coffee'));
    expect(controller.errorMessage, isNull);
    expect(controller.isBusy, isFalse);
    expect(service.calls, 1);
  });

  test('generate error returns to text entry with message', () async {
    service.errorToThrow = const GenerationException('Model hiccup.');

    await controller.generateFromTypedMessage(message: 'hey');

    expect(controller.phase, ReplyFlowPhase.textEntry);
    expect(controller.errorMessage, 'Model hiccup.');
    expect(controller.replies, isNull);
    expect(controller.isBusy, isFalse);
  });

  test('over-limit soft gate skips the service call', () async {
    usage = UsageController(freeDailyLimit: 1, proDailyLimit: 200);
    await usage.load();
    expect(await usage.tryConsume(), isTrue);
    controller.dispose();
    controller = ReplyFlowController(service, usage: usage);

    await controller.generateFromTypedMessage(message: 'hey again');

    expect(service.calls, 0);
    expect(controller.phase, ReplyFlowPhase.textEntry);
    expect(controller.errorMessage, contains('free replies'));
  });

  test('usage limit exception from server surfaces and exhausts local usage',
      () async {
    service.errorToThrow = const UsageLimitException(
      "You've used today's free replies. Pro unlocks more — join the waitlist in You.",
    );

    await controller.generateFromTypedMessage(message: 'hey');

    expect(controller.phase, ReplyFlowPhase.textEntry);
    expect(controller.errorMessage, contains('free replies'));
    expect(usage.remaining, 0);
  });

  test('no-reply outcome queues notice and returns to text entry', () async {
    service.next = const NoReplyNeeded(
      title: "You're all set",
      message: 'You already said goodnight.',
    );

    await controller.generateFromTypedMessage(message: 'goodnight');

    expect(controller.phase, ReplyFlowPhase.textEntry);
    expect(controller.hasNoReplyNotice, isTrue);
    final notice = controller.consumeNoReplyNotice();
    expect(notice?.title, "You're all set");
    expect(notice?.message, contains('goodnight'));
    expect(controller.hasNoReplyNotice, isFalse);
  });
}
