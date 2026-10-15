import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../services/reply/reply_history_service.dart';
import '../../widgets/wingman_buttons.dart';
import '../../widgets/wingman_components.dart';

class ReplyHistoryScreen extends StatefulWidget {
  const ReplyHistoryScreen({super.key});

  @override
  State<ReplyHistoryScreen> createState() => _ReplyHistoryScreenState();
}

class _ReplyHistoryScreenState extends State<ReplyHistoryScreen> {
  List<ReplyHistoryEntry> _entries = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await getIt<ReplyHistoryService>().list();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _clear() async {
    await getIt<ReplyHistoryService>().clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return WingmanScaffold(
      title: 'Recent replies',
      leading: WingmanIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
      ),
      actions: [
        if (_entries.isNotEmpty)
          WingmanIconButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Clear history',
            onPressed: _clear,
          ),
      ],
      body: _loading
          ? const WingmanLoadingState()
          : _entries.isEmpty
              ? WingmanEmptyState(
                  title: 'No replies yet.',
                  body:
                      'Generate replies from a chat screenshot and they’ll show up here on this device.',
                  icon: Icons.history_rounded,
                  actionLabel: 'Help me reply',
                  onAction: () => context.push('/reply'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.md,
                    bottom: AppSpacing.huge,
                  ),
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return _HistoryCard(entry: entry);
                  },
                ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final ReplyHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat.MMMd().add_jm().format(entry.createdAt);
    final sourceLabel =
        entry.source == 'screenshot' ? 'Screenshot' : 'Typed message';

    return WingmanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                sourceLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.accent,
                    ),
              ),
              const Spacer(),
              Text(
                when,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            entry.preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (entry.contextSnippet != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'They said: “${entry.contextSnippet!}”',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _ToneRow(label: 'Natural', text: entry.replies.natural),
          const SizedBox(height: 8),
          _ToneRow(label: 'Playful', text: entry.replies.playful),
          const SizedBox(height: 8),
          _ToneRow(label: 'Confident', text: entry.replies.confident),
        ],
      ),
    );
  }
}

class _ToneRow extends StatelessWidget {
  const _ToneRow({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.copy_rounded, size: 18),
          color: AppColors.textTertiary,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: text));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied')),
            );
          },
        ),
      ],
    );
  }
}
