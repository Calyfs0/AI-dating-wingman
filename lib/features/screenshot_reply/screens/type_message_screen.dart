import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../subscription/widgets/usage_limit_callout.dart';
import '../controllers/reply_flow_controller.dart';
import '../widgets/desire_backdrop.dart';
import '../widgets/mockup_components.dart';

/// Text-entry path: paste/type the message, optional context, generate.
class TypeMessageScreen extends StatefulWidget {
  const TypeMessageScreen({super.key});

  @override
  State<TypeMessageScreen> createState() => _TypeMessageScreenState();
}

class _TypeMessageScreenState extends State<TypeMessageScreen> {
  late final TextEditingController _messageController;
  late final TextEditingController _contextController;
  final _messageFocus = FocusNode();
  final _contextFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final c = context.read<ReplyFlowController>();
    _messageController = TextEditingController(text: c.typedMessage);
    _contextController = TextEditingController(text: c.typedContext);
    _messageFocus.addListener(() => setState(() {}));
    _contextFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _messageFocus.dispose();
    _contextFocus.dispose();
    _messageController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _pasteMessage() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Clipboard is empty.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _messageController
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
    _messageFocus.requestFocus();
    setState(() {});
  }

  InputDecoration _fieldDecoration({
    required String hint,
    double hintSize = 15,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF7E738F),
        fontWeight: FontWeight.w400,
        fontSize: hintSize,
        height: 1.4,
      ),
      filled: true,
      fillColor: Colors.transparent,
      isDense: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      contentPadding: const EdgeInsets.fromLTRB(2, 4, 2, 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReplyFlowController>();
    final canGenerate =
        _messageController.text.trim().isNotEmpty && !controller.isBusy;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: DesireBackdrop(
        readabilityScrim: true,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: controller.isBusy
                          ? null
                          : controller.backFromTextEntry,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Type a message',
                        textAlign: TextAlign.center,
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
                    10,
                    20,
                    16 + bottomInset * 0.12,
                  ),
                  children: [
                    Text(
                      'No screenshot needed — paste what they sent and get 2 replies.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFB9AEC8),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Text stays in this session — not saved as a screenshot.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF7E738F),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _SectionLabel(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Message you received',
                      required: true,
                    ),
                    const SizedBox(height: 12),
                    _InputCard(
                      focused: _messageFocus.hasFocus,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _messageController,
                            focusNode: _messageFocus,
                            minLines: 4,
                            maxLines: 8,
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                            cursorColor: AppColors.neonPink,
                            decoration: _fieldDecoration(
                              hint: 'Paste or type their message…',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  '${_messageController.text.trim().isEmpty ? 0 : _messageController.text.characters.length} chars',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: const Color(0xFF7E738F),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              _PasteChip(
                                onPressed:
                                    controller.isBusy ? null : _pasteMessage,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel(
                      icon: Icons.notes_rounded,
                      label: 'Optional context',
                    ),
                    const SizedBox(height: 12),
                    _InputCard(
                      focused: _contextFocus.hasFocus,
                      child: TextField(
                        controller: _contextController,
                        focusNode: _contextFocus,
                        minLines: 3,
                        maxLines: 5,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: Colors.white,
                          height: 1.45,
                        ),
                        cursorColor: AppColors.neonPink,
                        decoration: _fieldDecoration(
                          hint: 'How you know them, the vibe, what you want…',
                          hintSize: 14,
                        ),
                      ),
                    ),
                    if (controller.errorMessage != null) ...[
                      const SizedBox(height: 18),
                      if (isUsageLimitMessage(controller.errorMessage))
                        UsageLimitCallout(message: controller.errorMessage)
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            controller.errorMessage!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: NeonGenerateButton(
                  isLoading: controller.isBusy,
                  onPressed: canGenerate
                      ? () {
                          FocusScope.of(context).unfocus();
                          controller.generateFromTypedMessage(
                            message: _messageController.text,
                            context: _contextController.text,
                          );
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.label,
    this.required = false,
  });

  final IconData icon;
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.neonPink.withValues(alpha: 0.85)),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            color: Colors.white,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.neonPink.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Required',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.neonPink.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({required this.child, this.focused = false});

  final Widget child;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xF2141018),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: focused
              ? AppColors.neonPink.withValues(alpha: 0.65)
              : Colors.white.withValues(alpha: 0.12),
          width: focused ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: focused ? 0.4 : 0.28),
            blurRadius: focused ? 22 : 14,
            offset: const Offset(0, 8),
          ),
          if (focused)
            BoxShadow(
              color: AppColors.neonPink.withValues(alpha: 0.14),
              blurRadius: 18,
            ),
        ],
      ),
      child: child,
    );
  }
}

class _PasteChip extends StatelessWidget {
  const _PasteChip({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.neonPink.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.neonPink.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.content_paste_rounded,
                size: 15,
                color: onPressed == null
                    ? const Color(0xFF7E738F)
                    : AppColors.neonPink,
              ),
              const SizedBox(width: 6),
              Text(
                'Paste',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: onPressed == null
                      ? const Color(0xFF7E738F)
                      : AppColors.neonPink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
