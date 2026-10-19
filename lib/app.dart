import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/di/service_locator.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/companion_shell/companion_shell.dart';
import 'features/history/controllers/history_controller.dart';
import 'features/onboarding/controllers/onboarding_controller.dart';
import 'features/onboarding/screens/gotchu_onboarding_screen.dart';
import 'features/openers/controllers/openers_flow_controller.dart';
import 'features/people/controllers/people_controller.dart';
import 'features/practice/controllers/practice_controller.dart';
import 'features/practice/services/practice_service.dart';
import 'features/profile_audit/controllers/profile_audit_controller.dart';
import 'features/profile_audit/services/profile_audit_service.dart';
import 'features/screenshot_reply/controllers/reply_flow_controller.dart';
import 'features/screenshot_reply/services/generate_replies_service.dart';
import 'features/usage/usage_controller.dart';
import 'features/you/controllers/you_preferences_controller.dart';

class GotchuApp extends StatefulWidget {
  const GotchuApp({super.key});

  @override
  State<GotchuApp> createState() => _GotchuAppState();
}

class _GotchuAppState extends State<GotchuApp> {
  late final ReplyFlowController _reply;
  late final OpenersFlowController _openers;
  late final PeopleController _people;
  late final YouPreferencesController _you;
  late final HistoryController _history;
  late final UsageController _usage;
  late final OnboardingController _onboarding;
  late final PracticeController _practice;
  late final ProfileAuditController _profileAudit;

  @override
  void initState() {
    super.initState();
    final client = getIt<SupabaseClient>();
    final service = getIt<GenerateRepliesService>();
    _you = YouPreferencesController()..load();
    _people = PeopleController()..load();
    _history = HistoryController()..load();
    _usage = UsageController()..load();
    _onboarding = OnboardingController(_you)..load();
    _reply = ReplyFlowController(
      service,
      prefsOf: () => _you.asGenerationPrefs,
      history: _history,
      usage: _usage,
    );
    _openers = OpenersFlowController(
      service,
      prefsOf: () => _you.asGenerationPrefs,
      history: _history,
      usage: _usage,
    );
    _practice = PracticeController(PracticeService(client));
    _profileAudit = ProfileAuditController(
      ProfileAuditService(client),
      usage: _usage,
    );
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
    _reply.dispose();
    _openers.dispose();
    _people.dispose();
    _you.dispose();
    _history.dispose();
    _usage.dispose();
    _onboarding.dispose();
    _practice.dispose();
    _profileAudit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
      child: MaterialApp(
        title: 'Gotchu',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        home: Consumer<OnboardingController>(
          builder: (context, onboarding, _) {
            if (!onboarding.loaded) {
              return const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.neonPink),
                ),
              );
            }
            if (!onboarding.onboarded) {
              return const GotchuOnboardingScreen();
            }
            return const CompanionShell();
          },
        ),
      ),
    );
  }
}
