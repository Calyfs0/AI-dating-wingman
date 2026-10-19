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

/// Results screen — copy-first hierarchy: hero reply → Copy → tone / regenerate.
class SuggestedRepliesScreen extends StatefulWidget {
  const SuggestedRepliesScreen({super.key});

  @override
  State<SuggestedRepliesScreen> createState() => _SuggestedRepliesScreenState();
}

class _SuggestedRepliesScreenState extends State<SuggestedRepliesScreen> {
  late final ReplyFlowController _flow;
  late final TextEditingController _messageController;
  late final FocusNode _messageFocus;
  String _baseline = '';
  bool _whyExpanded = false;

  @override
  void initState() {
    super.initState();
    _flow = context.read<ReplyFlowController>();
    _baseline = _resolvedIncoming(_flow);
    _messageController = TextEditingController(text: _baseline);
    _messageFocus = FocusNode()..addListener(() => setState(() {}));
    _messageController.addListener(() => setState(() {}));
    // Streaming often mounts this screen before latestIncoming arrives.
    _flow.addListener(_syncIncomingFromFlow);
  }

  @override
  void dispose() {
    _flow.removeListener(_syncIncomingFromFlow);
    _messageFocus.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _resolvedIncoming(ReplyFlowController flow) {
    final fromReplies = flow.replies?.latestIncoming?.trim() ?? '';
    if (fromReplies.isNotEmpty) return fromReplies;
    return flow.typedMessage.trim();
  }

  void _syncIncomingFromFlow() {
    if (!mounted) return;
    final next = _resolvedIncoming(_flow);
    if (next.isEmpty) return;
    final current = _messageController.text.trim();
    // Don't clobber edits the user already made.
    if (current.isNotEmpty && current != _baseline.trim()) return;
    if (current == next) {
      _baseline = next;
      return;
    }
    _baseline = next;
    _messageController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
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

  String? _whyText(SuggestedReplies replies) {
    final why = replies.why?.trim();
    final hook = replies.hook?.trim();
    if (why != null && why.isNotEmpty) return why;
    if (hook != null && hook.isNotEmpty) return hook;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReplyFlowController>();
    final replies = controller.replies;
    final text = Theme.of(context).textTheme;
    if (replies == null) return const SizedBox.shrink();

    final regenerating = controller.isBusy &&
        controller.phase == ReplyFlowPhase.results;
    final streaming = controller.isStreaming;
    final selectedTone = controller.preferredVibe;
    final message = replies.forTone(selectedTone);
    final why = _whyText(replies);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

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
                              streaming
                                  ? 'Writing replies…'
                                  : 'Suggested replies',
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
                        padding: EdgeInsets.fromLTRB(
                          20,
                          8,
                          20,
                          16 + (bottomInset > 0 ? 8 : 0),
                        ),
                        children: [
                          _EditableIncomingBubble(
                            controller: _messageController,
                            focusNode: _messageFocus,
                            canSend: _canSend && !regenerating,
                            isSending: regenerating,
                            onSend: () => _send(controller),
                          ),
                          const SizedBox(height: 16),
                          _ToneSwitcher(
                            selected: selectedTone,
                            enabled: !regenerating,
                            onChanged: (tone) {
                              HapticFeedback.selectionClick();
                              controller.setPreferredVibe(tone);
                            },
                          ),
                          const SizedBox(height: 14),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: regenerating ? 0.45 : 1,
                            child: IgnorePointer(
                              ignoring: regenerating,
                              child: _HeroReplyCard(
                                tone: selectedTone,
                                message: message,
                                copied: controller.copiedConfirmation,
                                onCopy: () => controller.copyReply(message),
                                why: why,
                                whyExpanded: _whyExpanded,
                                onToggleWhy: why == null
                                    ? null
                                    : () => setState(
                                          () => _whyExpanded = !_whyExpanded,
                                        ),
                              ),
                            ),
                          ),
                          if (regenerating) ...[
                            const SizedBox(height: 14),
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
                                  'Crafting new replies…',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: const Color(0xFFB9AEC8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (controller.errorMessage != null) ...[
                            const SizedBox(height: 10),
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
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _SecondaryAction(
                        icon: Icons.refresh_rounded,
                        label: 'Try again',
                        onPressed:
                            regenerating ? null : controller.tryAgain,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SecondaryAction(
                        icon: Icons.add_rounded,
                        label: 'New chat',
                        onPressed: regenerating
                            ? null
                            : () => showNewChatOptionsSheet(context),
                      ),
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

class _ToneSwitcher extends StatelessWidget {
  const _ToneSwitcher({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final ReplyTone selected;
  final bool enabled;
  final ValueChanged<ReplyTone> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (final tone in ReplyTone.values) ...[
              if (tone != ReplyTone.values.first) const SizedBox(width: 4),
              Expanded(
                child: _ToneChip(
                  tone: tone,
                  selected: selected == tone,
                  enabled: enabled,
                  onTap: () => onChanged(tone),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToneChip extends StatelessWidget {
  const _ToneChip({
    required this.tone,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final ReplyTone tone;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            color: selected
                ? tone.accentColor.withValues(alpha: 0.22)
                : Colors.transparent,
            border: Border.all(
              color: selected
                  ? tone.accentColor.withValues(alpha: 0.7)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ToneIcon(tone: tone, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  tone.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFFB9AEC8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroReplyCard extends StatelessWidget {
  const _HeroReplyCard({
    required this.tone,
    required this.message,
    required this.copied,
    required this.onCopy,
    required this.why,
    required this.whyExpanded,
    required this.onToggleWhy,
  });

  final ReplyTone tone;
  final String message;
  final bool copied;
  final VoidCallback onCopy;
  final String? why;
  final bool whyExpanded;
  final VoidCallback? onToggleWhy;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(
                  const Color(0xFF2A2036),
                  tone.accentColor,
                  0.1,
                )!
                .withValues(alpha: 0.96),
            const Color(0xF0120E18),
          ],
        ),
        border: Border.all(
          color: tone.accentColor.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: tone.accentColor.withValues(alpha: 0.16),
            blurRadius: 22,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tone.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: tone.accentColor,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.4,
                letterSpacing: -0.3,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            _CopyButton(
              accent: tone.accentColor,
              copied: copied,
              onPressed: onCopy,
            ),
            if (why != null && onToggleWhy != null) ...[
              const SizedBox(height: 10),
              _WhyThisWorks(
                text: why!,
                expanded: whyExpanded,
                onToggle: onToggleWhy!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({
    required this.accent,
    required this.copied,
    required this.onPressed,
  });

  final Color accent;
  final bool copied;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: copied ? null : AppColors.accentGradient,
          color: copied ? accent.withValues(alpha: 0.28) : null,
          border: copied
              ? Border.all(color: accent.withValues(alpha: 0.75), width: 1.4)
              : null,
          boxShadow: copied
              ? null
              : [
                  BoxShadow(
                    color: AppColors.neonPink.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    copied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        copied ? 'Copied — go send it' : 'Copy reply',
                        maxLines: 1,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WhyThisWorks extends StatelessWidget {
  const _WhyThisWorks({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Why this works',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9A8FA8),
                    ),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: const Color(0xFF9A8FA8),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(bottom: 2, top: 2),
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.4,
                color: const Color(0xFFB9AEC8),
              ),
            ),
          ),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
        ),
      ],
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
          minWidth: MediaQuery.sizeOf(context).width * 0.5,
          maxWidth: MediaQuery.sizeOf(context).width * 0.88,
          minHeight: 48,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xE2221A2C), Color(0xD0141018)],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft: Radius.circular(6),
            ),
            border: Border.all(
              color: focused
                  ? AppColors.neonPink.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.1),
            ),
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
                  maxLines: 4,
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFE8E0F0),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
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
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.only(bottom: 4, top: 2),
                  ),
                  onSubmitted: (_) {
                    if (canSend) onSend();
                  },
                ),
              ),
              const SizedBox(width: 4),
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
          width: 32,
          height: 32,
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
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  Icons.arrow_upward_rounded,
                  size: 16,
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.35),
                ),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFD8CFE4),
          backgroundColor: Colors.black.withValues(alpha: 0.22),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: const Color(0xFFB9AEC8)),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                    color: const Color(0xFFD8CFE4),
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
