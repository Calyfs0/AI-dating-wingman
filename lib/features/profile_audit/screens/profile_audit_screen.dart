import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../screenshot_reply/widgets/desire_backdrop.dart';
import '../../screenshot_reply/widgets/mockup_components.dart';
import '../../subscription/widgets/usage_limit_callout.dart';
import '../controllers/profile_audit_controller.dart';

class ProfileAuditScreen extends StatelessWidget {
  const ProfileAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ProfileAuditController>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesireBackdrop(
        child: SafeArea(
          child: switch (c.phase) {
            ProfileAuditPhase.upload => const _UploadView(),
            ProfileAuditPhase.generating => const _GeneratingView(),
            ProfileAuditPhase.results => const _ResultsView(),
          },
        ),
      ),
    );
  }
}

class _UploadView extends StatelessWidget {
  const _UploadView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ProfileAuditController>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              Expanded(
                child: Text(
                  'Profile',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            children: [
              Text(
                'Audit your profile',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Scores, photo notes, and three bio rewrites — same Kehlo vibe.',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFB9AEC8),
                ),
              ),
              const SizedBox(height: 18),
              if (c.selectedImage == null)
                DashedUploadZone(
                  onTap: c.choosePhoto,
                  showTypeMessage: false,
                  title: 'Upload a profile screenshot',
                  subtitle: 'Hinge, Bumble, Tinder — whatever you’re on.',
                  footer: '',
                  onCameraTap: null,
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(
                    File(c.selectedImage!.path),
                    fit: BoxFit.fitWidth,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 160,
                      child: Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: Color(0xFF7E738F)),
                      ),
                    ),
                  ),
                ),
              if (c.selectedImage != null) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: c.clear,
                    child: Text(
                      'Change',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.neonPink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => c.bioDraft = v,
                maxLines: 3,
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Paste your bio (optional)',
                  hintStyle:
                      GoogleFonts.plusJakartaSans(color: const Color(0xFF7E738F)),
                  filled: true,
                  fillColor: const Color(0xFF22182A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.neonPink.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
              if (c.errorMessage != null) ...[
                const SizedBox(height: 12),
                if (isUsageLimitMessage(c.errorMessage))
                  UsageLimitCallout(message: c.errorMessage)
                else
                  Text(
                    c.errorMessage!,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.danger),
                  ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: NeonGenerateButton(
            label: 'Audit profile',
            isLoading: c.isBusy,
            onPressed: c.isBusy
                ? null
                : () {
                    if (c.selectedImage == null) {
                      c.choosePhoto();
                    } else {
                      c.runAudit();
                    }
                  },
          ),
        ),
      ],
    );
  }
}

class _GeneratingView extends StatelessWidget {
  const _GeneratingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Reading your profile…',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ProfileAuditController>();
    final r = c.result!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: c.clear,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            Text(
              'Profile audit',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Overall ${((r.overall.clamp(0, 1)) * 100).round()}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.neonPink,
          ),
        ),
        const SizedBox(height: 16),
        _Bar('Clarity', r.clarity),
        _Bar('Personality', r.personality),
        _Bar('Approachability', r.approachability),
        _Bar('Conversation', r.conversationPotential),
        if (r.photoNotes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Photos',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          for (final note in r.photoNotes)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '· $note',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFB9AEC8),
                ),
              ),
            ),
        ],
        const SizedBox(height: 18),
        Text(
          'Bio rewrites',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        _BioCard(title: 'Like you', text: r.bioLikeMe),
        _BioCard(title: 'Funnier', text: r.bioFunnier),
        _BioCard(title: 'Shorter', text: r.bioShorter),
        if (r.hook != null && r.hook!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Opener hook: ${r.hook}',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.neonPink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 20),
        NeonGenerateButton(
          label: 'Audit another',
          onPressed: c.clear,
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar(this.label, this.value);
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFFB9AEC8),
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFF2A1C28),
              color: AppColors.neonPink,
            ),
          ),
        ],
      ),
    );
  }
}

class _BioCard extends StatelessWidget {
  const _BioCard({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xCC1A1016),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.neonPink.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: AppColors.neonPink,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: text));
                      HapticFeedback.lightImpact();
                    },
                    icon: const Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: Color(0xFFB9AEC8),
                    ),
                  ),
                ],
              ),
              Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
