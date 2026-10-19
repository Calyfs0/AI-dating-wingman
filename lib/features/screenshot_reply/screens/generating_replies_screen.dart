import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/reply_flow_controller.dart';
import '../widgets/generating_status_view.dart';

class GeneratingRepliesScreen extends StatelessWidget {
  const GeneratingRepliesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReplyFlowController>();

    return GeneratingStatusView(
      statusMessage: controller.loadingMessage,
      subtitle: 'Working on replies you can send…',
      onCancel: controller.cancelGeneration,
      heroIcon: Icons.auto_awesome_rounded,
    );
  }
}
