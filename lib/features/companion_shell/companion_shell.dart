import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../openers/controllers/openers_flow_controller.dart';
import '../people/controllers/people_controller.dart';
import '../screenshot_reply/controllers/reply_flow_controller.dart';

/// Root shell: Reply · Openers · Practice · People · You
class CompanionShell extends StatelessWidget {
  const CompanionShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: navigationShell,
      bottomNavigationBar: CompanionNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class CompanionNavBar extends StatelessWidget {
  const CompanionNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// 0 Reply · 1 Openers · 2 Practice · 3 People · 4 You
  static const _items = [
    (Icons.auto_awesome_rounded, 'Reply'),
    (Icons.waving_hand_outlined, 'Openers'),
    (Icons.forum_outlined, 'Practice'),
    (Icons.favorite_border_rounded, 'People'),
    (Icons.person_outline_rounded, 'You'),
  ];

  @override
  Widget build(BuildContext context) {
    final replyBusy = context.watch<ReplyFlowController>().phase ==
        ReplyFlowPhase.generating;
    final openersBusy =
        context.watch<OpenersFlowController>().phase == OpenersPhase.generating;
    final yourMove = context.watch<PeopleController>().yourMoveCount;
    // Hide nav during core generate so the loading screen owns attention.
    if ((currentIndex == 0 && replyBusy) || (currentIndex == 1 && openersBusy)) {
      return const SizedBox.shrink();
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xE6100C18),
            border: Border(
              top: BorderSide(
                color: AppColors.neonPink.withValues(alpha: 0.18),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Row(
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Expanded(
                      child: _NavItem(
                        icon: _items[i].$1,
                        label: _items[i].$2,
                        selected: currentIndex == i,
                        badgeCount: i == 3 ? yourMove : 0,
                        onTap: () => onTap(i),
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.neonPink : const Color(0xFF8A8098);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 22, color: color),
                if (badgeCount > 0)
                  Positioned(
                    right: -10,
                    top: -6,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neonPink,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
