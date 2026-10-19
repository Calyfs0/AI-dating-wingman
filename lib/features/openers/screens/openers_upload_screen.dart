import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../screenshot_reply/widgets/desire_backdrop.dart';
import '../../screenshot_reply/widgets/mockup_components.dart';
import '../../screenshot_reply/widgets/picked_image_preview.dart';
import '../controllers/openers_flow_controller.dart';
import '../widgets/openers_source_sheet.dart';

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
                                  onPressed: c.isBusy
                                      ? null
                                      : () => showOpenersSourceSheet(context),
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
                                    child: PickedImagePreview(
                                      file: c.selectedImage!,
                                      errorHeight: 180,
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
                            'Upload their profile → get 2 first messages you can send.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: const Color(0xFFB9AEC8),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 18),
                          DashedUploadZone(
                            onTap: c.isBusy ? null : c.chooseFromPhotos,
                            onCameraTap: c.isBusy ? null : c.capturePhoto,
                            showTypeMessage: false,
                            showCamera: !kIsWeb,
                            title: kIsWeb
                                ? 'Choose a profile screenshot'
                                : 'Upload a profile screenshot',
                            subtitle:
                                'Natural + playful openers from their prompts.',
                            footer: 'Hinge · Bumble · Tinder · OkCupid',
                            cameraTitle: 'Take a photo',
                            cameraSubtitle:
                                'Snap their profile from another phone',
                          ),
                          const SizedBox(height: 12),
                          const UploadTrustLine(),
                          const SizedBox(height: 8),
                          const UploadHintLine(
                            text:
                                'Tip: include name + prompts/bio so the opener can reference something real.',
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Default vibe',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF7E738F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const MoodChipRow(),
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
                  label: hasImage
                      ? 'Generate openers'
                      : (kIsWeb
                          ? 'Choose screenshot'
                          : 'Upload screenshot'),
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
