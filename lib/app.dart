import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/di/service_locator.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/companion_shell/companion_shell.dart';
import 'features/openers/controllers/openers_flow_controller.dart';
import 'features/people/controllers/people_controller.dart';
import 'features/screenshot_reply/controllers/reply_flow_controller.dart';
import 'features/screenshot_reply/services/generate_replies_service.dart';
import 'features/you/controllers/you_preferences_controller.dart';

class WingmanApp extends StatefulWidget {
  const WingmanApp({super.key});

  @override
  State<WingmanApp> createState() => _WingmanAppState();
}

class _WingmanAppState extends State<WingmanApp> {
  late final ReplyFlowController _reply;
  late final OpenersFlowController _openers;
  late final PeopleController _people;
  late final YouPreferencesController _you;

  @override
  void initState() {
    super.initState();
    final service = getIt<GenerateRepliesService>();
    _reply = ReplyFlowController(service);
    _openers = OpenersFlowController(service);
    _people = PeopleController()..load();
    _you = YouPreferencesController()..load();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompanionProviders(
      reply: _reply,
      openers: _openers,
      people: _people,
      you: _you,
      child: MaterialApp(
        title: 'Gotchu',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const CompanionShell(),
      ),
    );
  }
}
