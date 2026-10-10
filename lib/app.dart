import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/screenshot_reply/controllers/reply_flow_controller.dart';
import 'features/screenshot_reply/screens/reply_flow_shell.dart';
import 'features/screenshot_reply/services/generate_replies_service.dart';

class WingmanApp extends StatefulWidget {
  const WingmanApp({super.key});

  @override
  State<WingmanApp> createState() => _WingmanAppState();
}

class _WingmanAppState extends State<WingmanApp> {
  late final ReplyFlowController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReplyFlowController(getIt<GenerateRepliesService>());
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: MaterialApp(
        title: 'Wingman',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const ReplyFlowShell(),
      ),
    );
  }
}
