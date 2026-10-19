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
    final state = context.watch<ReplyFlowController>().state;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: switch (state) {
        ReplyUploadState() => const UploadScreenshotScreen(
            key: ValueKey('upload'),
          ),
        ReplyTextEntryState() => const TypeMessageScreen(
            key: ValueKey('textEntry'),
          ),
        ReplyGeneratingState() => const GeneratingRepliesScreen(
            key: ValueKey('generating'),
          ),
        ReplyResultsState() => const SuggestedRepliesScreen(
            key: ValueKey('results'),
          ),
      },
    );
  }
}
