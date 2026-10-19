import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wingman/core/theme/app_theme.dart';
import 'package:wingman/features/history/controllers/history_controller.dart';
import 'package:wingman/features/people/controllers/people_controller.dart';
import 'package:wingman/features/screenshot_reply/controllers/reply_flow_controller.dart';
import 'package:wingman/features/screenshot_reply/models/generation_prefs.dart';
import 'package:wingman/features/screenshot_reply/models/reply_generation_result.dart';
import 'package:wingman/features/screenshot_reply/models/suggested_replies.dart';
import 'package:wingman/features/screenshot_reply/screens/upload_screenshot_screen.dart';
import 'package:wingman/features/screenshot_reply/services/generate_replies_service.dart';
import 'package:wingman/features/you/controllers/you_preferences_controller.dart';

class _FakeService implements GenerateRepliesService {
  @override
  Future<ReplyGenerationResult> generateFromScreenshot(
    String imagePath, {
    String? latestMessageOverride,
    GenerationPrefs prefs = const GenerationPrefs(),
  }) async {
    return const RepliesReady(
      SuggestedReplies(
        natural: 'Sounds good — when works for you?',
        playful: "I'm in. Don't make me wait too long though.",
      ),
    );
  }

  @override
  Future<ReplyGenerationResult> generateFromMessage({
    required String message,
    String? context,
    GenerationPrefs prefs = const GenerationPrefs(),
  }) async {
    return const RepliesReady(
      SuggestedReplies(
        natural: 'Got it — tell me more.',
        playful: "Okay, I'm listening…",
      ),
    );
  }

  @override
  Future<ReplyGenerationResult> generateOpeners(
    String imagePath, {
    GenerationPrefs prefs = const GenerationPrefs(),
  }) async {
    return const RepliesReady(
      SuggestedReplies(
        natural: 'Your Japan photo looks unreal — when were you there?',
        playful: 'Okay but that guitar prompt? Instant respect.',
      ),
    );
  }
}

void main() {
  testWidgets('upload screen matches mockup chrome', (tester) async {
    SharedPreferencesFake.install();
    final you = YouPreferencesController();
    final people = PeopleController();
    final history = HistoryController();
    final controller = ReplyFlowController(
      _FakeService(),
      prefsOf: () => you.asGenerationPrefs,
      history: history,
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: controller),
          ChangeNotifierProvider.value(value: you),
          ChangeNotifierProvider.value(value: people),
          ChangeNotifierProvider.value(value: history),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const UploadScreenshotScreen(),
        ),
      ),
    );

    expect(find.textContaining('Gotchu'), findsWidgets);
    expect(find.text('Generate replies'), findsOneWidget);
    expect(find.text('Upload a screenshot of your chat'), findsOneWidget);
    expect(find.text('Natural'), findsOneWidget);
    expect(find.text('Playful'), findsOneWidget);
  });
}

/// Minimal SharedPreferences stub so People/History load paths don't hang.
class SharedPreferencesFake {
  static void install() {
    // Controllers only hit prefs on load()/set — tests don't call load.
  }
}
