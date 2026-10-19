import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/reply_flow_controller.dart';
import '../models/suggested_replies.dart';
import '../widgets/desire_backdrop.dart';
import '../widgets/new_chat_options_sheet.dart';
import '../widgets/tone_icons.dart';

/// Results screen — editable message preview, two reply cards, bottom actions.
class SuggestedRepliesScreen extends StatefulWidget {
  const SuggestedRepliesScreen({super.key});

  @override
  State<SuggestedRepliesScreen> createState() => _SuggestedRepliesScreenState();
}

class _SuggestedRepliesScreenState extends State<SuggestedRepliesScreen> {
  late final TextEditingController _messageController;
  late final FocusNode _messageFocus;
  String _baseline = '';

  @override
  void initState() {
    super.initState();
    final replies = context.read<ReplyFlowController>().replies;
    final typed = context.read<ReplyFlowController>().typedMessage;
    _baseline = (replies?.latestIncoming?.trim().isNotEmpty == true)
        ? replies!.latestIncoming!.trim()
        : typed.trim();
    _messageController = TextEditingController(text: _baseline);
    _messageFocus = FocusNode()..addListener(() => setState(() {}));
    _messageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _messageFocus.dispose();
    _messageController.dispose();
    super.dispose();
  }

  bool get _isDirty {
    return _messageController.text.trim() != _baseline.trim();
  }

  bool get _canSend {
    final text = _messageController.text.trim();
    return text.isNotEmpty && _isDirty;
  }

  Future<void> _send(ReplyFlowController controller) async {
    if (!_canSend || controller.isBusy) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    final sent = _messageController.text.trim();
    await controller.regenerateFromEditedMessage(sent);
    if (!mounted) return;
    if (controller.errorMessage == null) {
      _baseline = sent;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReplyFlowController>();
    final replies = controller.replies;
    final text = Theme.of(context).textTheme;
    if (replies == null) return const SizedBox.shrink();

    final regenerating = controller.isBusy &&
        controller.phase == ReplyFlowPhase.results;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: DesireBackdrop(
        readabilityScrim: true,
        child: Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Back',
                            onPressed: regenerating
                                ? null
                                : controller.backFromResults,
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Suggested replies',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                        children: [
                          _EditableIncomingBubble(
                            controller: _messageController,
                            focusNode: _messageFocus,
                            canSend: _canSend && !regenerating,
                            isSending: regenerating,
                            onSend: () => _send(controller),
                          ),
                          const SizedBox(height: 14),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: regenerating ? 0.45 : 1,
                            child: IgnorePointer(
                              ignoring: regenerating,
                              child: Column(
                                children: [
                                  for (final tone
                                      in controller.orderedTones) ...[
                                    _ReplyCard(
                                      tone: tone,
                                      message: replies.forTone(tone),
                                      onCopy: () => controller
                                          .copyReply(replies.forTone(tone)),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (regenerating) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.neonPink,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Writing new replies…',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: const Color(0xFFB9AEC8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (controller.errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              controller.errorMessage!,
                              style: text.bodyMedium?.copyWith(
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (controller.copiedConfirmation) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Copied — go send it',
                          style: text.labelLarge?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: _BottomGhost(
                            icon: Icons.refresh_rounded,
                            label: 'Try again',
                            onPressed: regenerating
                                ? null
                                : controller.tryAgain,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 6,
                          child: _BottomGhost(
                            icon: Icons.add_rounded,
                            label: 'New chat',
                            purple: true,
                            onPressed: regenerating
                                ? null
                                : () => showNewChatOptionsSheet(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableIncomingBubble extends StatelessWidget {
  const _EditableIncomingBubble({
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.sizeOf(context).width * 0.55,
          maxWidth: MediaQuery.sizeOf(context).width * 0.9,
          minHeight: 56,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xF2221A2C), Color(0xF0141018)],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(6),
            ),
            border: Border.all(
              color: focused
                  ? AppColors.neonPink.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              if (focused)
                BoxShadow(
                  color: AppColors.neonPink.withValues(alpha: 0.18),
                  blurRadius: 18,
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: !isSending,
                  minLines: 1,
                  maxLines: 6,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: AppColors.neonPink,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'Their message…',
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF7E738F),
                    ),
                    contentPadding: const EdgeInsets.only(bottom: 4, top: 2),
                  ),
                  onSubmitted: (_) {
                    if (canSend) onSend();
                  },
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: _SendArrow(
                  enabled: canSend,
                  busy: isSending,
                  onPressed: onSend,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendArrow extends StatelessWidget {
  const _SendArrow({
    required this.enabled,
    required this.busy,
    required this.onPressed,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !busy;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: active ? onPressed : null,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: active ? AppColors.accentGradient : null,
            color: active ? null : Colors.white.withValues(alpha: 0.06),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.neonPink.withValues(alpha: 0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: busy
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  Icons.arrow_upward_rounded,
                  size: 18,
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.35),
                ),
        ),
      ),
    );
  }
}

class _ReplyCard extends StatelessWidget {
  const _ReplyCard({
    required this.tone,
    required this.message,
    required this.onCopy,
  });

  final ReplyTone tone;
  final String message;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 128),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(
                    const Color(0xFF2A2036),
                    tone.accentColor,
                    0.08,
                  )!
                  .withValues(alpha: 0.94),
              const Color(0xF0120E18),
            ],
          ),
          border: Border.all(
            color: tone.accentColor.withValues(alpha: 0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: tone.accentColor.withValues(alpha: 0.18),
              blurRadius: 20,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ToneIcon(tone: tone, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tone.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                            color: tone.accentColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            tone.subtitle,
                            maxLines: 1,
                            softWrap: false,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF9A8FA8),
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  OutlinedButton.icon(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tone.accentColor,
                      side: BorderSide(
                        color: tone.accentColor.withValues(alpha: 0.55),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  letterSpacing: -0.1,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomGhost extends StatelessWidget {
  const _BottomGhost({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.purple = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool purple;

  static const _purple = Color(0xFF8E44AD);
  static const _purpleSoft = Color(0xFFB57EDC);

  @override
  Widget build(BuildContext context) {
    final bg = purple
        ? _purple.withValues(alpha: 0.42)
        : Colors.black.withValues(alpha: 0.28);
    final border = purple
        ? _purpleSoft.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.18);

    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: bg,
          side: BorderSide(color: border, width: purple ? 1.4 : 1),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: purple ? _purpleSoft : Colors.white,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
