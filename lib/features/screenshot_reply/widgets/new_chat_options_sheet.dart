import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/reply_flow_controller.dart';

/// Photos / camera / type — pick without bouncing through the empty hub first.
Future<void> showNewChatOptionsSheet(BuildContext context) {
  final controller = context.read<ReplyFlowController>();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF16101C),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'New chat',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'How do you want to continue?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF9A8FA8),
                ),
              ),
              const SizedBox(height: 14),
              _OptionTile(
                icon: Icons.photo_library_outlined,
                title: 'Choose from Photos',
                subtitle: 'Upload a saved screenshot',
                onTap: () {
                  Navigator.pop(sheetContext);
                  controller.chooseScreenshot();
                },
              ),
              const SizedBox(height: 8),
              _OptionTile(
                icon: Icons.photo_camera_outlined,
                title: 'Take a photo',
                subtitle: 'Snap the chat from another phone',
                onTap: () {
                  Navigator.pop(sheetContext);
                  controller.capturePhoto();
                },
              ),
              const SizedBox(height: 8),
              _OptionTile(
                icon: Icons.keyboard_alt_outlined,
                title: 'Type a message',
                subtitle: 'Paste or enter what they sent',
                onTap: () {
                  Navigator.pop(sheetContext);
                  controller.openTextEntry();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF221828),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.neonPink, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF9A8FA8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.neonPink.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
