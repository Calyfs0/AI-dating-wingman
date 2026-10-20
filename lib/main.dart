import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/errors/app_exception.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/screens/kehlo_splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const _KehloBootstrap());
}

/// Shows the branded splash immediately, boots Supabase in parallel,
/// then hands off as soon as both splash + boot are done.
class _KehloBootstrap extends StatefulWidget {
  const _KehloBootstrap();

  @override
  State<_KehloBootstrap> createState() => _KehloBootstrapState();
}

class _KehloBootstrapState extends State<_KehloBootstrap> {
  final Completer<void> _splashDone = Completer<void>();

  bool _ready = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  void _onSplashFinished() {
    if (!_splashDone.isCompleted) _splashDone.complete();
  }

  Future<void> _boot() async {
    Object? error;
    StackTrace? stack;

    try {
      await Future.wait<void>([
        configureDependencies(),
        _splashDone.future,
      ]);
    } catch (e, st) {
      error = e;
      stack = st;
      // Don't hang if boot failed before splash finished.
      if (!_splashDone.isCompleted) {
        await _splashDone.future;
      }
    }

    if (!mounted) return;

    if (error != null) {
      debugPrint('Kehlo bootstrap failed: $error\n$stack');
      setState(() {
        _errorMessage = error is AppException
            ? error.message
            : 'Kehlo couldn’t start. Check setup and try again.';
      });
      return;
    }

    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const KehloApp();

    if (_errorMessage != null) {
      return _BootstrapErrorApp(message: _errorMessage!);
    }

    return MaterialApp(
      title: 'Kehlo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: KehloSplashScreen(onFinished: _onSplashFinished),
    );
  }
}

class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
