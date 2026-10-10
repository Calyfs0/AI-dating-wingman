import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wingman/core/theme/app_theme.dart';
import 'package:wingman/features/screenshot_reply/controllers/reply_flow_controller.dart';
import 'package:wingman/features/screenshot_reply/models/suggested_replies.dart';
import 'package:wingman/features/screenshot_reply/screens/upload_screenshot_screen.dart';
import 'package:wingman/features/screenshot_reply/services/generate_replies_service.dart';

class _FakeService implements GenerateRepliesService {
  @override
  Future<SuggestedReplies> generateFromScreenshot(String imagePath) async {
    return const SuggestedReplies(
      natural: 'Sounds good — when works for you?',
      playful: 'I’m in. Don’t make me wait too long though.',
      confident: 'Let’s set a time. Free Thursday?',
    );
  }

  @override
  Future<SuggestedReplies> generateFromMessage({
    required String message,
    String? context,
  }) async {
    return const SuggestedReplies(
      natural: 'Got it — tell me more.',
      playful: 'Okay, I’m listening…',
      confident: 'Say when you’re free.',
    );
  }
}

void main() {
  testWidgets('upload screen matches mockup chrome', (tester) async {
    final controller = ReplyFlowController(_FakeService());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const UploadScreenshotScreen(),
        ),
      ),
    );

    expect(find.text('Wingman'), findsOneWidget);
    expect(find.text('Generate replies'), findsOneWidget);
    expect(find.text('Upload a screenshot of your chat'), findsOneWidget);
    expect(find.text('Flirt better'), findsOneWidget);
    expect(find.text('Keep the vibe'), findsOneWidget);
    expect(find.text('Get the date'), findsOneWidget);
  });
}
