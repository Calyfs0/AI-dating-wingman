import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/profile_audit.dart';
import '../../controllers/app_controller.dart';
import '../../widgets/wingman_buttons.dart';
import '../../widgets/wingman_cards.dart';
import '../../widgets/wingman_components.dart';

class OpenerScreen extends StatefulWidget {
  const OpenerScreen({super.key});

  @override
  State<OpenerScreen> createState() => _OpenerScreenState();
}

class _OpenerScreenState extends State<OpenerScreen> {
  OpenerResult? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() => _loading = true);
    final result = await context.read<AppController>().openerService.generate(
          profileText: 'Dog, Japan, Guitar, Food',
          style: context.read<AppController>().profile?.learnedStyle,
        );
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WingmanScaffold(
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      body: _loading || _result == null
          ? const WingmanLoadingState(message: 'Finding the best opener...')
          : ListView(
              children: [
                Text(
                  'Best openers for her',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Detected hooks', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _result!.hooks
                      .map(
                        (hook) => WingmanChip(
                          label: hook,
                          selected: true,
                          onSelected: (_) {},
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Best opener', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                WingmanGlassCard(
                  child: Text(
                    _result!.opener,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Why it works', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  _result!.whyItWorks,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                WingmanButton(
                  label: 'Copy',
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final controller = context.read<AppController>();
                    await Clipboard.setData(ClipboardData(text: _result!.opener));
                    await controller.trackCopy();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Copied. Send it yourself when ready.'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                WingmanSecondaryButton(label: 'Try another', onPressed: _generate),
                const SizedBox(height: AppSpacing.sm),
                WingmanSecondaryButton(
                  label: 'Make it more like me',
                  onPressed: _generate,
                ),
              ],
            ),
    );
  }
}
