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
    final phase = context.watch<OpenersFlowController>().phase;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: switch (phase) {
        OpenersPhase.upload => const OpenersUploadScreen(key: ValueKey('o-up')),
        OpenersPhase.generating =>
          const OpenersGeneratingScreen(key: ValueKey('o-gen')),
        OpenersPhase.results =>
          const OpenersResultsScreen(key: ValueKey('o-res')),
      },
    );
  }
}
