import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/category_screen.dart';
import 'screens/generate_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lines_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/situation_screen.dart';
import 'screens/welcome_screen.dart';
import 'widgets/bloom_widgets.dart';

final GlobalKey<NavigatorState> designRootKey = GlobalKey<NavigatorState>();

GoRouter createDesignRouter() {
  return GoRouter(
    navigatorKey: designRootKey,
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DesignShell(shell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'category/:id',
                    builder: (context, state) => CategoryScreen(
                      categoryId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ExploreScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/saved',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SavedScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'preferences',
                    parentNavigatorKey: designRootKey,
                    builder: (context, state) => const PreferencesPage(),
                  ),
                  GoRoute(
                    path: 'settings',
                    parentNavigatorKey: designRootKey,
                    builder: (context, state) => const SettingsPage(),
                  ),
                  GoRoute(
                    path: 'feedback',
                    parentNavigatorKey: designRootKey,
                    builder: (context, state) => const FeedbackPage(),
                  ),
                  GoRoute(
                    path: 'rate',
                    parentNavigatorKey: designRootKey,
                    builder: (context, state) => const RatePage(),
                  ),
                  GoRoute(
                    path: 'privacy',
                    parentNavigatorKey: designRootKey,
                    builder: (context, state) => const PrivacyPage(),
                  ),
                  GoRoute(
                    path: 'terms',
                    parentNavigatorKey: designRootKey,
                    builder: (context, state) => const TermsPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/situation/:id',
        parentNavigatorKey: designRootKey,
        builder: (context, state) => SituationScreen(
          id: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/generate',
        parentNavigatorKey: designRootKey,
        builder: (context, state) => const GenerateScreen(),
      ),
      GoRoute(
        path: '/lines',
        parentNavigatorKey: designRootKey,
        builder: (context, state) => const LinesScreen(),
      ),
    ],
  );
}
