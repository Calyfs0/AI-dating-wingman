import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'core/routing/kehlo_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/history/controllers/history_controller.dart';
import 'features/onboarding/controllers/onboarding_controller.dart';
import 'features/openers/controllers/openers_flow_controller.dart';
import 'features/people/controllers/people_controller.dart';
import 'features/people/services/people_coach_service.dart';
import 'features/practice/controllers/practice_controller.dart';
import 'features/profile_audit/controllers/profile_audit_controller.dart';
import 'features/screenshot_reply/controllers/reply_flow_controller.dart';
import 'features/subscription/controllers/subscription_controller.dart';
import 'features/usage/usage_controller.dart';
import 'features/you/controllers/you_preferences_controller.dart';

class KehloApp extends StatefulWidget {
  const KehloApp({super.key});

  @override
  State<KehloApp> createState() => _KehloAppState();
}

class _KehloAppState extends State<KehloApp> with WidgetsBindingObserver {
  late final GoRouter _router;

  // Resolved once from GetIt — constructed in configureDependencies().
  late final ReplyFlowController _reply = getIt();
  late final OpenersFlowController _openers = getIt();
  late final PeopleController _people = getIt();
  late final YouPreferencesController _you = getIt();
  late final HistoryController _history = getIt();
  late final UsageController _usage = getIt();
  late final OnboardingController _onboarding = getIt();
  late final PracticeController _practice = getIt();
  late final ProfileAuditController _profileAudit = getIt();
  late final SubscriptionController _subscription = getIt();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = createKehloRouter(onboarding: _onboarding);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Pick up subscription cancel / renew after returning from Settings.
      unawaited(_subscription.syncEntitlement(quiet: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    // Controllers are GetIt singletons with dispose hooks.
    disposeSessionControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: getIt<PeopleCoachService>()),
        ChangeNotifierProvider.value(value: _reply),
        ChangeNotifierProvider.value(value: _openers),
        ChangeNotifierProvider.value(value: _people),
        ChangeNotifierProvider.value(value: _you),
        ChangeNotifierProvider.value(value: _history),
        ChangeNotifierProvider.value(value: _usage),
        ChangeNotifierProvider.value(value: _onboarding),
        ChangeNotifierProvider.value(value: _practice),
        ChangeNotifierProvider.value(value: _profileAudit),
        ChangeNotifierProvider.value(value: _subscription),
      ],
      child: Consumer<OnboardingController>(
        builder: (context, onboarding, _) {
          if (!onboarding.loaded) {
            return MaterialApp(
              title: 'Kehlo',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark(),
              themeMode: ThemeMode.dark,
              home: const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.neonPink),
                ),
              ),
            );
          }
          return MaterialApp.router(
            title: 'Kehlo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(),
            themeMode: ThemeMode.dark,
            routerConfig: _router,
            builder: (context, child) {
              Widget content = child ?? const SizedBox.shrink();
              // Wide web: keep phone-scale chrome, avoid stretched full-bleed.
              if (kIsWeb) {
                content = ColoredBox(
                  color: AppColors.background,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: content,
                    ),
                  ),
                );
              }
              // Full-screen lock while Store / Boost activation finishes —
              // avoids taps cancelling or racing the purchase.
              return Consumer<SubscriptionController>(
                builder: (context, sub, _) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      content,
                      if (sub.busy)
                        const ModalBarrier(
                          dismissible: false,
                          color: Color(0x99000000),
                        ),
                      if (sub.busy)
                        Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1524),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.neonPink.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 22,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.neonPink,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    sub.busyMessage.isEmpty
                                        ? 'Working…'
                                        : sub.busyMessage,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Please wait — don’t leave this screen.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFB9AEC8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
