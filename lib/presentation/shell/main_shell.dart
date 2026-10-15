import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'quick_actions_sheet.dart';
import 'wingman_nav_bar.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: WingmanNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        onCenterTap: () => showQuickActionsSheet(context),
      ),
    );
  }
}
