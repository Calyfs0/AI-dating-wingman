import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/profile_audit.dart';
import '../../controllers/app_controller.dart';
import '../../widgets/wingman_buttons.dart';
import '../../widgets/wingman_cards.dart';
import '../../widgets/wingman_components.dart';

class ProfileAuditScreen extends StatefulWidget {
  const ProfileAuditScreen({super.key});

  @override
  State<ProfileAuditScreen> createState() => _ProfileAuditScreenState();
}

class _ProfileAuditScreenState extends State<ProfileAuditScreen> {
  ProfileAudit? _audit;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final controller = context.read<AppController>();
    await controller.analytics.track('profile_audit_started');
    final audit = await controller.profileService.audit();
    if (!mounted) return;
    setState(() {
      _audit = audit;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _audit == null) {
      return const WingmanScaffold(body: WingmanLoadingState(message: 'Auditing profile...'));
    }
    final audit = _audit!;

    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      body: ListView(
        children: [
          Text('Profile audit', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Profile strength\n${audit.overallStrength.toStringAsFixed(1)} / 10',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            'A product heuristic for clarity and conversation potential — not attractiveness.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          WingmanProgressBar(label: 'Clarity', value: audit.clarity),
          const SizedBox(height: AppSpacing.md),
          WingmanProgressBar(label: 'Personality', value: audit.personality),
          const SizedBox(height: AppSpacing.md),
          WingmanProgressBar(label: 'Approachability', value: audit.approachability),
          const SizedBox(height: AppSpacing.md),
          WingmanProgressBar(
            label: 'Conversation potential',
            value: audit.conversationPotential,
          ),
          const SizedBox(height: AppSpacing.xl),
          WingmanButton(
            label: 'Review photos',
            onPressed: () => context.push('/profile-audit/photos', extra: audit),
          ),
          const SizedBox(height: AppSpacing.sm),
          WingmanSecondaryButton(
            label: 'Rewrite bio',
            onPressed: () => context.push('/profile-audit/bio', extra: audit),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class PhotoAnalysisScreen extends StatelessWidget {
  const PhotoAnalysisScreen({super.key, required this.audit});

  final ProfileAudit audit;

  @override
  Widget build(BuildContext context) {
    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      title: 'Photo analysis',
      body: ListView.separated(
        itemCount: audit.photos.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final photo = audit.photos[index];
          final label = switch (photo.verdict) {
            PhotoVerdict.keep => 'KEEP',
            PhotoVerdict.replace => 'REPLACE',
            PhotoVerdict.reorder => 'REORDER',
          };
          final color = switch (photo.verdict) {
            PhotoVerdict.keep => AppColors.success,
            PhotoVerdict.replace => AppColors.danger,
            PhotoVerdict.reorder => AppColors.warning,
          };
          return WingmanCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Photo ${index + 1}', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.image_outlined, color: AppColors.textTertiary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(photo.reason, style: Theme.of(context).textTheme.bodyMedium),
                if (photo.recommendedOrder != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Recommended order: ${photo.recommendedOrder}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class BioRewriteScreen extends StatefulWidget {
  const BioRewriteScreen({super.key, required this.audit});

  final ProfileAudit audit;

  @override
  State<BioRewriteScreen> createState() => _BioRewriteScreenState();
}

class _BioRewriteScreenState extends State<BioRewriteScreen> {
  late String _suggested;

  @override
  void initState() {
    super.initState();
    _suggested = widget.audit.suggestedBio;
  }

  Future<void> _rewrite(String direction) async {
    final result = await context.read<AppController>().profileService.rewriteBio(
          currentBio: widget.audit.currentBio,
          direction: direction,
          style: context.read<AppController>().profile?.learnedStyle,
        );
    if (!mounted) return;
    setState(() => _suggested = result);
  }

  @override
  Widget build(BuildContext context) {
    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      body: ListView(
        children: [
          Text('Your bio', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          WingmanCard(
            child: Text(
              widget.audit.currentBio,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Suggested bio', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          WingmanGlassCard(
            child: Text(_suggested, style: Theme.of(context).textTheme.bodyLarge),
          ),
          const SizedBox(height: AppSpacing.lg),
          WingmanSecondaryButton(
            label: 'Make it more like me',
            onPressed: () => _rewrite('like_me'),
          ),
          const SizedBox(height: AppSpacing.sm),
          WingmanSecondaryButton(
            label: 'Make it funnier',
            onPressed: () => _rewrite('funnier'),
          ),
          const SizedBox(height: AppSpacing.sm),
          WingmanSecondaryButton(
            label: 'Make it shorter',
            onPressed: () => _rewrite('shorter'),
          ),
          const SizedBox(height: AppSpacing.sm),
          WingmanButton(
            label: 'Copy',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _suggested));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
