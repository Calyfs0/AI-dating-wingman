import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/screenshot_reply/controllers/reply_flow_controller.dart';
import 'features/screenshot_reply/services/generate_replies_service.dart';
import 'presentation/controllers/app_controller.dart';

class WingmanApp extends StatefulWidget {
  const WingmanApp({super.key});

  @override
  State<WingmanApp> createState() => _WingmanAppState();
}

class _WingmanAppState extends State<WingmanApp> {
  late final AppController _appController;
  late final ReplyFlowController _replyController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _appController = AppController();
    _replyController = ReplyFlowController(getIt<GenerateRepliesService>());
    _router = createAppRouter(_appController);
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
    _replyController.dispose();
    _appController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _appController),
        ChangeNotifierProvider.value(value: _replyController),
      ],
      child: MaterialApp.router(
        title: 'Wingman',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        routerConfig: _router,
      ),
    );
  }
}
