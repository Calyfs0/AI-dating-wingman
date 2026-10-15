import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../screenshot_reply/widgets/desire_backdrop.dart';
import '../../screenshot_reply/widgets/mockup_components.dart';
import '../controllers/openers_flow_controller.dart';

class OpenersUploadScreen extends StatelessWidget {
  const OpenersUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<OpenersFlowController>();
    final hasImage = c.selectedImage != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesireBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: hasImage
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Selected profile',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: c.isBusy ? null : c.clearImage,
                                  child: Text(
                                    'Change',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.neonPink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: ColoredBox(
                                  color: const Color(0xFF1A1324),
                                  child: SingleChildScrollView(
                                    child: Image.file(
                                      File(c.selectedImage!.path),
                                      fit: BoxFit.fitWidth,
                                      width: double.infinity,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (c.errorMessage != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                c.errorMessage!,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        children: [
                          Text(
                            'Openers',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Upload their profile — get a first message that fits.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: const Color(0xFFB9AEC8),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 22),
                          DashedUploadZone(
                            onTap: c.isBusy ? null : c.chooseFromPhotos,
                            onCameraTap: c.isBusy ? null : c.capturePhoto,
                            showTypeMessage: false,
                            title: 'Upload a profile screenshot',
                            subtitle: "I'll craft a first message from their prompts.",
                            footer: 'Hinge · Bumble · Tinder · OkCupid',
                            cameraTitle: 'Take a photo',
                            cameraSubtitle: 'Snap their profile from another phone',
                          ),
                          if (c.errorMessage != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              c.errorMessage!,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: NeonGenerateButton(
                  label: 'Generate openers',
                  isLoading: c.isBusy,
                  onPressed: c.isBusy
                      ? null
                      : () {
                          if (c.selectedImage == null) {
                            c.chooseFromPhotos();
                          } else {
                            c.generate();
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
