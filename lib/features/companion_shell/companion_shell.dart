import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../openers/controllers/openers_flow_controller.dart';
import '../openers/screens/openers_flow_shell.dart';
import '../people/controllers/people_controller.dart';
import '../people/screens/people_screen.dart';
import '../screenshot_reply/controllers/reply_flow_controller.dart';
import '../screenshot_reply/screens/reply_flow_shell.dart';
import '../you/controllers/you_preferences_controller.dart';
import '../you/screens/you_screen.dart';

/// Root shell: Reply · Openers · People · You
class CompanionShell extends StatefulWidget {
  const CompanionShell({super.key});

  @override
  State<CompanionShell> createState() => _CompanionShellState();
}

class _CompanionShellState extends State<CompanionShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IndexedStack(
        index: _index,
        children: const [
          ReplyFlowShell(),
          OpenersFlowShell(),
          PeopleScreen(),
          YouScreen(),
        ],
      ),
      bottomNavigationBar: CompanionNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
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

  static const _items = [
    (Icons.auto_awesome_rounded, 'Reply'),
    (Icons.waving_hand_outlined, 'Openers'),
    (Icons.favorite_border_rounded, 'People'),
    (Icons.person_outline_rounded, 'You'),
  ];

  @override
  Widget build(BuildContext context) {
    // Hide nav while Reply/Openers are mid-generation for a cleaner loading beat.
    final replyBusy = context.watch<ReplyFlowController>().phase ==
        ReplyFlowPhase.generating;
    final openersBusy =
        context.watch<OpenersFlowController>().phase == OpenersPhase.generating;
    if ((currentIndex == 0 && replyBusy) ||
        (currentIndex == 1 && openersBusy)) {
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
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Expanded(
                      child: _NavTap(
                        icon: _items[i].$1,
                        label: _items[i].$2,
                        selected: currentIndex == i,
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

class _NavTap extends StatelessWidget {
  const _NavTap({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.neonPink : const Color(0xFF7E738F);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Registers companion-scoped controllers for the shell tree.
class CompanionProviders extends StatelessWidget {
  const CompanionProviders({
    super.key,
    required this.reply,
    required this.openers,
    required this.people,
    required this.you,
    required this.child,
  });

  final ReplyFlowController reply;
  final OpenersFlowController openers;
  final PeopleController people;
  final YouPreferencesController you;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: reply),
        ChangeNotifierProvider.value(value: openers),
        ChangeNotifierProvider.value(value: people),
        ChangeNotifierProvider.value(value: you),
      ],
      child: child,
    );
  }
}
