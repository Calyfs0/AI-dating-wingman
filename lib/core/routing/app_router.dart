import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/practice.dart';
import '../../domain/entities/profile_audit.dart';
import '../../presentation/controllers/app_controller.dart';
import '../../presentation/screens/common/common_screens.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screens.dart';
import '../../presentation/screens/opener/opener_screen.dart';
import '../../presentation/screens/paywall/paywall_screen.dart';
import '../../presentation/screens/people/people_screens.dart';
import '../../presentation/screens/practice/practice_screens.dart';
import '../../presentation/screens/profile/profile_screens.dart';
import '../../presentation/screens/reply/reply_flow_screens.dart';
import '../../presentation/screens/you/you_screens.dart';
import '../../presentation/shell/main_shell.dart';

GoRouter createAppRouter(AppController controller) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: controller,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/onboarding/promise',
        builder: (_, __) => const PromiseScreen(),
      ),
      GoRoute(
        path: '/onboarding/focus',
        builder: (_, __) => const FocusScreen(),
      ),
      GoRoute(
        path: '/onboarding/style',
        builder: (_, __) => const StyleOnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/goal',
        builder: (_, __) => const GoalScreen(),
      ),
      GoRoute(
        path: '/onboarding/privacy',
        builder: (_, __) => const PrivacyOnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/notifications',
        builder: (_, __) => const NotificationsOnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/people',
                builder: (_, __) => const PeopleScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => PersonProfileScreen(
                      personId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'prepare',
                        builder: (_, state) => DatePreparationScreen(
                          personId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'debrief',
                        builder: (_, state) => DateDebriefScreen(
                          personId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/practice',
                builder: (_, __) => const PracticeHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/you',
                builder: (_, __) => const YouScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/reply',
        builder: (_, __) => const AddConversationScreen(),
        routes: [
          GoRoute(
            path: 'processing',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return ProcessingScreen(
                imagePaths: (extra['images'] as List?)?.cast<String>() ?? const [],
                pastedText: (extra['text'] as String?)?.isEmpty == true
                    ? null
                    : extra['text'] as String?,
              );
            },
          ),
          GoRoute(
            path: 'analysis',
            builder: (_, __) => const AnalysisOverviewScreen(),
          ),
          GoRoute(
            path: 'next-move',
            builder: (_, __) => const NextMoveScreen(),
          ),
          GoRoute(
            path: 'response',
            builder: (_, __) => const ResponseDetailScreen(),
          ),
          GoRoute(
            path: 'interpret',
            builder: (_, __) => const InterpretMessageScreen(),
          ),
          GoRoute(
            path: 'review',
            builder: (_, __) => const ReviewBeforeSendScreen(),
          ),
          GoRoute(
            path: 'save',
            builder: (_, __) => const SaveToPersonScreen(),
          ),
        ],
      ),
      GoRoute(path: '/opener', builder: (_, __) => const OpenerScreen()),
      GoRoute(
        path: '/profile-audit',
        builder: (_, __) => const ProfileAuditScreen(),
        routes: [
          GoRoute(
            path: 'photos',
            builder: (_, state) => PhotoAnalysisScreen(
              audit: state.extra as ProfileAudit? ?? _demoProfileAudit,
            ),
          ),
          GoRoute(
            path: 'bio',
            builder: (_, state) => BioRewriteScreen(
              audit: state.extra as ProfileAudit? ?? _demoProfileAudit,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/practice/session',
        builder: (_, state) => PracticeSessionScreen(
          topic: state.extra as PracticeTopic? ?? PracticeTopic.firstDate,
        ),
      ),
      GoRoute(
        path: '/practice/feedback',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PracticeFeedbackScreen(
            response: extra?['response'] as String? ??
                'I liked how easy it felt talking to you — coffee this weekend?',
            feedback: extra?['feedback'] as PracticeFeedback? ??
                const PracticeFeedback(
                  summary:
                      'Good answer. You sounded confident, but you didn\'t give them much to continue with.',
                  confidence: 8,
                  naturalness: 9,
                  conversation: 6,
                ),
            topic: extra?['topic'] as PracticeTopic? ?? PracticeTopic.firstDate,
          );
        },
      ),
      GoRoute(path: '/insights', builder: (_, __) => const CoachInsightsScreen()),
      GoRoute(path: '/paywall', builder: (_, __) => const PaywallScreen()),
      GoRoute(path: '/privacy', builder: (_, __) => const PrivacyDataScreen()),
      GoRoute(path: '/you/style', builder: (_, __) => const CommunicationStyleScreen()),
      GoRoute(path: '/you/goals', builder: (_, __) => const DatingGoalsSettingsScreen()),
      GoRoute(
        path: '/you/notifications',
        builder: (_, __) => const NotificationSettingsScreen(),
      ),
      GoRoute(path: '/you/account', builder: (_, __) => const AccountLinkingScreen()),
      GoRoute(
        path: '/you/subscription',
        builder: (_, __) => const SubscriptionManagementScreen(),
      ),
      GoRoute(path: '/you/delete', builder: (_, __) => const DeleteDataScreen()),
      GoRoute(path: '/error', builder: (_, __) => const GenericErrorScreen()),
      GoRoute(path: '/offline', builder: (_, __) => const OfflineScreen()),
      GoRoute(
        path: '/empty-states',
        builder: (_, __) => const EmptyStatesGalleryScreen(),
      ),
    ],
    errorBuilder: (_, __) => const GenericErrorScreen(),
  );
}

const _demoProfileAudit = ProfileAudit(
  id: 'demo-audit',
  overallStrength: 7.8,
  clarity: 0.82,
  personality: 0.74,
  approachability: 0.8,
  conversationPotential: 0.71,
  currentBio: 'Love travel, coffee, and good conversations.',
  suggestedBio:
      'Usually planning my next trip before I\'ve finished the current one.\nCoffee, bad jokes and finding underrated places to eat.',
  photos: [
    ProfilePhotoReview(
      id: '1',
      verdict: PhotoVerdict.keep,
      reason:
          'Strong first impression. Face is clear and the photo feels natural.',
      recommendedOrder: 1,
    ),
    ProfilePhotoReview(
      id: '2',
      verdict: PhotoVerdict.replace,
      reason: 'The group makes it unclear who you are.',
      recommendedOrder: 4,
    ),
    ProfilePhotoReview(
      id: '3',
      verdict: PhotoVerdict.reorder,
      reason: 'Good lifestyle signal — better as photo 2 or 3.',
      recommendedOrder: 2,
    ),
  ],
);

/// Convenience accessor when a BuildContext already has AppController.
GoRouter routerOf(BuildContext context) {
  return createAppRouter(context.read<AppController>());
}
