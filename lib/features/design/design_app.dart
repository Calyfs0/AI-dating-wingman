import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'bloom.dart';
import 'design_controller.dart';
import 'design_router.dart';

/// Product UI from the blossom mockups. Lines are local sample copy.
class DesignApp extends StatefulWidget {
  const DesignApp({super.key});

  @override
  State<DesignApp> createState() => _DesignAppState();
}

class _DesignAppState extends State<DesignApp> {
  final DesignController _controller = DesignController();
  late final GoRouter _router = createDesignRouter();

  @override
  void dispose() {
    _router.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: MaterialApp.router(
        title: 'Kehlo',
        debugShowCheckedModeBanner: false,
        theme: bloomTheme(),
        routerConfig: _router,
        builder: (context, child) {
          final content = child ?? const SizedBox.shrink();
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
            child: ColoredBox(
              color: kIsWeb ? Bloom.canvas : Bloom.bg,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: Bloom.bg),
                    child: content,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
