import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'presentation/controllers/app_controller.dart';

class WingmanApp extends StatefulWidget {
  const WingmanApp({super.key});

  @override
  State<WingmanApp> createState() => _WingmanAppState();
}

class _WingmanAppState extends State<WingmanApp> {
  late final AppController _controller;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _controller = AppController();
    _router = createAppRouter(_controller);
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
