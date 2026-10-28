import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../bloom.dart';
import '../widgets/bloom_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6D7C8),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/design/welcome_hero.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x22FFFFFF),
                    Color(0x00FFFFFF),
                    Color(0x33000000),
                  ],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 18, 28, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 3),
                    const KehloWordmark(size: 78, color: Bloom.ink),
                    const SizedBox(height: 8),
                    Text(
                      'Say it better.',
                      style: BloomType.sans(
                        size: 18,
                        weight: FontWeight.w600,
                        color: Bloom.ink,
                      ),
                    ),
                    Text(
                      'Create real connections.',
                      style: BloomType.sans(
                        size: 16,
                        weight: FontWeight.w500,
                        color: Bloom.inkSoft,
                      ),
                    ),
                    const Spacer(flex: 5),
                    BloomButton(
                      label: 'Get Started',
                      onPressed: () => context.go('/onboarding'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
