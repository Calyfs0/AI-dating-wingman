import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../screenshot_reply/controllers/reply_flow_controller.dart';
import '../controllers/people_controller.dart';

/// Soft retention cue on Reply home when someone is Your move.
class YourMoveBanner extends StatelessWidget {
  const YourMoveBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final people = context.watch<PeopleController>();
    final count = people.yourMoveCount;
    if (!people.loaded || count <= 0) return const SizedBox.shrink();

    final first = people.yourMovePeople.first;
    final label = count == 1
        ? '${first.name} is waiting on your move'
        : '$count people need a reply';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            context.read<ReplyFlowController>().setAttachedPerson(first);
            context.go('/reply');
          },
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.neonPink.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.neonPink.withValues(alpha: 0.35),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    size: 18,
                    color: AppColors.neonPink.withValues(alpha: 0.95),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    'Reply',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neonPink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
