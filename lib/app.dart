import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'core/routing/gotchu_router.dart';
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
import 'features/usage/usage_controller.dart';
import 'features/you/controllers/you_preferences_controller.dart';

class GotchuApp extends StatefulWidget {
  const GotchuApp({super.key});

  @override
  State<GotchuApp> createState() => _GotchuAppState();
}

class _GotchuAppState extends State<GotchuApp> {
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

  @override
  void initState() {
    super.initState();
    _router = createGotchuRouter(onboarding: _onboarding);
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
  void dispose() {
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
      ],
      child: Consumer<OnboardingController>(
        builder: (context, onboarding, _) {
          if (!onboarding.loaded) {
            return MaterialApp(
              title: 'Gotchu',
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
            title: 'Gotchu',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(),
            themeMode: ThemeMode.dark,
            routerConfig: _router,
            builder: (context, child) {
              final content = child ?? const SizedBox.shrink();
              // Wide web: keep phone-scale chrome, avoid stretched full-bleed.
              if (!kIsWeb) return content;
              return ColoredBox(
                color: AppColors.background,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: content,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
