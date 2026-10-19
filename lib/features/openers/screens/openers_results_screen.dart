import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../screenshot_reply/models/suggested_replies.dart';
import '../../screenshot_reply/widgets/desire_backdrop.dart';
import '../../screenshot_reply/widgets/tone_icons.dart';
import '../controllers/openers_flow_controller.dart';

/// Copy-first Openers results — parity with Reply results hierarchy.
class OpenersResultsScreen extends StatefulWidget {
  const OpenersResultsScreen({super.key});

  @override
  State<OpenersResultsScreen> createState() => _OpenersResultsScreenState();
}

class _OpenersResultsScreenState extends State<OpenersResultsScreen> {
  bool _metaExpanded = false;

  String? _metaText(SuggestedReplies openers) {
    final why = openers.why?.trim();
    final hook = openers.hook?.trim();
    if (why != null && why.isNotEmpty && hook != null && hook.isNotEmpty) {
      return 'Hook: $hook\n$why';
    }
    if (why != null && why.isNotEmpty) return why;
    if (hook != null && hook.isNotEmpty) return 'Hook: $hook';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OpenersFlowController>();
    final openers = controller.openers;
    if (openers == null) return const SizedBox.shrink();

    final busy = controller.isBusy;
    final streaming = controller.isStreaming;
    final selectedTone = controller.preferredVibe;
    final message = openers.forTone(selectedTone);
    final meta = _metaText(openers);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                            onPressed:
                                busy ? null : controller.backFromResults,
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              streaming
                                  ? 'Writing openers…'
                                  : 'Suggested openers',
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
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        children: [
                          Text(
                            'First messages grounded in their profile',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFFB9AEC8),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _ToneSwitcher(
                            selected: selectedTone,
                            enabled: !busy,
                            onChanged: (tone) {
                              HapticFeedback.selectionClick();
                              controller.setPreferredVibe(tone);
                            },
                          ),
                          const SizedBox(height: 14),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: busy && !streaming ? 0.45 : 1,
                            child: IgnorePointer(
                              ignoring: busy && !streaming,
                              child: _HeroOpenerCard(
                                tone: selectedTone,
                                message: message,
                                copied: controller.copiedConfirmation,
                                onCopy: () => controller.copyOpener(message),
                                meta: meta,
                                metaExpanded: _metaExpanded,
                                onToggleMeta: meta == null
                                    ? null
                                    : () => setState(
                                          () =>
                                              _metaExpanded = !_metaExpanded,
                                        ),
                              ),
                            ),
                          ),
                          if (busy && streaming) ...[
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
                                  'Crafting openers…',
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
                              style: GoogleFonts.plusJakartaSans(
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
                        onPressed: busy ? null : controller.tryAgain,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SecondaryAction(
                        icon: Icons.add_rounded,
                        label: 'New profile',
                        onPressed: busy ? null : controller.startOver,
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

class _HeroOpenerCard extends StatelessWidget {
  const _HeroOpenerCard({
    required this.tone,
    required this.message,
    required this.copied,
    required this.onCopy,
    required this.meta,
    required this.metaExpanded,
    required this.onToggleMeta,
  });

  final ReplyTone tone;
  final String message;
  final bool copied;
  final VoidCallback onCopy;
  final String? meta;
  final bool metaExpanded;
  final VoidCallback? onToggleMeta;

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
            if (meta != null && onToggleMeta != null) ...[
              const SizedBox(height: 10),
              _WhyThisOpener(
                text: meta!,
                expanded: metaExpanded,
                onToggle: onToggleMeta!,
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
                        copied ? 'Copied — go make the move' : 'Copy opener',
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

class _WhyThisOpener extends StatelessWidget {
  const _WhyThisOpener({
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
