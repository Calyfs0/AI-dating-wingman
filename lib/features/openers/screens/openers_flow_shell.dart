import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/openers_flow_controller.dart';
import 'openers_generating_screen.dart';
import 'openers_results_screen.dart';
import 'openers_upload_screen.dart';

class OpenersFlowShell extends StatelessWidget {
  const OpenersFlowShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OpenersFlowController>().state;
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
        return FadeTransition(opacity: animation, child: child);
      },
      child: switch (state) {
        OpenersUploadState() =>
          const OpenersUploadScreen(key: ValueKey('o-up')),
        OpenersGeneratingState() =>
          const OpenersGeneratingScreen(key: ValueKey('o-gen')),
        OpenersResultsState() =>
          const OpenersResultsScreen(key: ValueKey('o-res')),
      },
    );
  }
}
