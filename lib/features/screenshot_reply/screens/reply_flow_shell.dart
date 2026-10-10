import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/reply_flow_controller.dart';
import 'generating_replies_screen.dart';
import 'suggested_replies_screen.dart';
import 'type_message_screen.dart';
import 'upload_screenshot_screen.dart';

/// Hosts upload ↔ text entry ↔ results (with generating in between).
class ReplyFlowShell extends StatelessWidget {
  const ReplyFlowShell({super.key});

  @override
  Widget build(BuildContext context) {
    final phase = context.watch<ReplyFlowController>().phase;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: switch (phase) {
        ReplyFlowPhase.upload => const UploadScreenshotScreen(
            key: ValueKey('upload'),
          ),
        ReplyFlowPhase.textEntry => const TypeMessageScreen(
            key: ValueKey('textEntry'),
          ),
        ReplyFlowPhase.generating => const GeneratingRepliesScreen(
            key: ValueKey('generating'),
          ),
        ReplyFlowPhase.results => const SuggestedRepliesScreen(
            key: ValueKey('results'),
          ),
      },
    );
  }
}
