import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/history_controller.dart';
import '../models/history_entry.dart';

Future<void> showHistorySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final history = ctx.watch<HistoryController>();
      final entries = history.entries;
      return DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollController) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xF016101C),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                  color: AppColors.neonPink.withValues(alpha: 0.28),
                ),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recent',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        'On this device only',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF9A8FA8),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: entries.isEmpty
                      ? Center(
                          child: Text(
                            'Nothing yet — generate a reply or opener.',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFB9AEC8),
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                          itemCount: entries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return _HistoryCard(entry: entry);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final label = entry.kind == HistoryKind.reply ? 'Reply' : 'Opener';
    final preview = entry.natural;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC1A1016),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neonPink.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neonPink,
                  ),
                ),
                if (entry.personName != null &&
                    entry.personName!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '· ${entry.personName}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF9A8FA8),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  tooltip: 'Copy natural',
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: preview));
                    HapticFeedback.lightImpact();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Copied',
                            style: GoogleFonts.plusJakartaSans(),
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
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
              preview,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.white,
                height: 1.35,
              ),
            ),
            if (entry.hook != null && entry.hook!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Hook: ${entry.hook}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF9A8FA8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
