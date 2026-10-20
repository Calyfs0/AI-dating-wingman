import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/companion_shell/companion_shell.dart';
import '../../features/onboarding/controllers/onboarding_controller.dart';
import '../../features/onboarding/screens/kehlo_onboarding_screen.dart';
import '../../features/openers/screens/openers_flow_shell.dart';
import '../../features/people/screens/people_screen.dart';
import '../../features/practice/screens/practice_screen.dart';
import '../../features/profile_audit/screens/profile_audit_screen.dart';
import '../../features/screenshot_reply/screens/reply_flow_shell.dart';
import '../../features/you/screens/you_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Path-based routes for mobile + web (GitHub Pages base-href compatible).
///
/// Primary tabs: Reply · Openers · Practice · People · You.
GoRouter createKehloRouter({
  required OnboardingController onboarding,
}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/reply',
    refreshListenable: onboarding,
    redirect: (context, state) {
      if (!onboarding.loaded) return null;
      final loc = state.matchedLocation;
      final onOnboarding = loc.startsWith('/onboarding');
      if (!onboarding.onboarded && !onOnboarding) return '/onboarding';
      if (onboarding.onboarded && onOnboarding) return '/reply';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const KehloOnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return CompanionShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reply',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ReplyFlowShell(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/openers',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: OpenersFlowShell(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/practice',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PracticeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/people',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PeopleScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/you',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: YouScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/profile-audit',
        builder: (context, state) => const ProfileAuditScreen(),
      ),
    ],
  );
}
