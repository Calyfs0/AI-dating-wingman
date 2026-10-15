import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/service_locator.dart';
import '../../../features/screenshot_reply/controllers/reply_flow_controller.dart';
import '../../../features/screenshot_reply/screens/reply_flow_shell.dart';
import '../../../services/reply/reply_history_service.dart';

/// Full-screen host for the screenshot reply flow (core UI unchanged).
class ScreenshotReplyScreen extends StatefulWidget {
  const ScreenshotReplyScreen({super.key});

  @override
  State<ScreenshotReplyScreen> createState() => _ScreenshotReplyScreenState();
}

class _ScreenshotReplyScreenState extends State<ScreenshotReplyScreen> {
  ReplyFlowController? _controller;
  bool _recordedThisSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReplyFlowController>().startOver();
      _recordedThisSession = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<ReplyFlowController>();
    if (_controller == controller) return;
    _controller?.removeListener(_onFlowChanged);
    _controller = controller;
    _controller!.addListener(_onFlowChanged);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onFlowChanged);
    super.dispose();
  }

  void _onFlowChanged() {
    final controller = _controller;
    if (controller == null || _recordedThisSession) return;
    if (controller.phase != ReplyFlowPhase.results || controller.replies == null) {
      return;
    }
    _recordedThisSession = true;
    final preview = controller.replies!.natural;
    final source = controller.lastSource == ReplyInputSource.screenshot
        ? 'screenshot'
        : 'message';
    final snippet = controller.typedMessage.trim().isNotEmpty
        ? controller.typedMessage.trim()
        : null;
    getIt<ReplyHistoryService>().record(
      source: source,
      preview: preview,
      replies: controller.replies!,
      contextSnippet: snippet,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        context.read<ReplyFlowController>().startOver();
        _recordedThisSession = false;
      },
      child: const ReplyFlowShell(),
    );
  }
}
