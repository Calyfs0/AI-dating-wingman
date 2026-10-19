import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/reply_flow_controller.dart';
import '../widgets/desire_backdrop.dart';
import '../widgets/mockup_components.dart';
import '../widgets/new_chat_options_sheet.dart';
import '../widgets/no_reply_needed_dialog.dart';

/// Upload screen built to match `wingman_mockup_upload`.
class UploadScreenshotScreen extends StatefulWidget {
  const UploadScreenshotScreen({super.key});

  @override
  State<UploadScreenshotScreen> createState() => _UploadScreenshotScreenState();
}

class _UploadScreenshotScreenState extends State<UploadScreenshotScreen> {
  bool _showingNoReply = false;

  void _maybeShowNoReply(ReplyFlowController controller) {
    if (_showingNoReply || !controller.hasNoReplyNotice) return;
    _showingNoReply = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final notice = controller.consumeNoReplyNotice();
      if (notice == null) {
        _showingNoReply = false;
        return;
      }
      await showNoReplyNeededDialog(
        context,
        title: notice.title,
        message: notice.message,
      );
      if (mounted) _showingNoReply = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReplyFlowController>();
    _maybeShowNoReply(controller);
    final hasImage = controller.selectedImage != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesireBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: hasImage
                    ? _SelectedChatLayout(
                        path: controller.selectedImage!.path,
                        errorMessage: controller.errorMessage,
                        isBusy: controller.isBusy,
                        onClear: controller.clearScreenshot,
                        onChange: () => showNewChatOptionsSheet(context),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        children: [
                          const GotchuBrandHeader(),
                          const SizedBox(height: 16),
                          const MoodChipRow(),
                          const SizedBox(height: 22),
                          DashedUploadZone(
                            onTap: controller.isBusy
                                ? null
                                : controller.chooseScreenshot,
                            onCameraTap: controller.isBusy
                                ? null
                                : controller.capturePhoto,
                            onTypeMessageTap: controller.isBusy
                                ? null
                                : controller.openTextEntry,
                          ),
                          if (controller.errorMessage != null) ...[
                            const SizedBox(height: 14),
                            GlassCard(
                              borderColor:
                                  AppColors.danger.withValues(alpha: 0.45),
                              child: Text(
                                controller.errorMessage!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: NeonGenerateButton(
                  isLoading: controller.isBusy,
                  onPressed: controller.isBusy
                      ? null
                      : () {
                          if (controller.selectedImage == null) {
                            showNewChatOptionsSheet(context);
                          } else {
                            controller.generateReplies();
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact chrome + large scrollable preview once a chat is selected.
class _SelectedChatLayout extends StatelessWidget {
  const _SelectedChatLayout({
    required this.path,
    required this.onClear,
    required this.onChange,
    required this.isBusy,
    this.errorMessage,
  });

  final String path;
  final VoidCallback onClear;
  final VoidCallback onChange;
  final bool isBusy;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Selected chat',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              TextButton(
                onPressed: isBusy ? null : onChange,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.neonPink,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  visualDensity: VisualDensity.compact,
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Change'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _SelectedShot(
              path: path,
              onClear: isBusy ? null : onClear,
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 10),
            GlassCard(
              borderColor: AppColors.danger.withValues(alpha: 0.45),
              child: Text(
                errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SelectedShot extends StatelessWidget {
  const _SelectedShot({required this.path, required this.onClear});

  final String path;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1324),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Image.file(
                  File(path),
                  fit: BoxFit.fitWidth,
                  width: double.infinity,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 200,
                    child: Center(
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ),
            if (onClear != null)
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onClear,
                    child: const Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
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
