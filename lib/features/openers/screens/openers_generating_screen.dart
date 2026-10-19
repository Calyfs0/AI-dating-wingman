import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../screenshot_reply/widgets/generating_status_view.dart';
import '../controllers/openers_flow_controller.dart';

class OpenersGeneratingScreen extends StatelessWidget {
  const OpenersGeneratingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OpenersFlowController>();

    return GeneratingStatusView(
      statusMessage: controller.loadingMessage,
      subtitle: 'Making the first move count…',
      onCancel: controller.cancelGeneration,
      heroIcon: Icons.waving_hand_rounded,
    );
  }
}
