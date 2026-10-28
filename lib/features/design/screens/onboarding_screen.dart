import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../bloom.dart';
import '../design_data.dart';
import '../widgets/bloom_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < 2) {
      _page.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Bloom.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    'Skip',
                    style: BloomType.sans(
                      size: 15,
                      weight: FontWeight.w600,
                      color: Bloom.mute,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _page,
                  onPageChanged: (value) => setState(() => _index = value),
                  children: const [
                    _MomentsPage(),
                    _OnboardScroll(child: _SituationsPage()),
                    _OnboardScroll(child: _StylePage()),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PageDots(index: _index),
              const SizedBox(height: 16),
              BloomButton(
                label: _index < 2 ? 'Next' : 'Get Started',
                onPressed: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MomentsPage extends StatelessWidget {
  const _MomentsPage();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Headline(
          lead: 'Turn small moments\ninto ',
          accent: 'great conversations.',
        ),
        const SizedBox(height: 12),
        Text(
          'Get AI-powered pickup lines, openers and replies for dating and beyond.',
          style: BloomType.sans(size: 15, color: Bloom.inkSoft, height: 1.45),
        ),
        const SizedBox(height: 22),
        const Expanded(
          child: PhotoFrame(
            asset: 'assets/design/moments_window.jpg',
            radius: 28,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ],
    );
  }
}

class _SituationsPage extends StatelessWidget {
  const _SituationsPage();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Headline(
          lead: 'Lines for\n',
          accent: 'every situation.',
        ),
        const SizedBox(height: 12),
        Text(
          'From first messages to in-person conversations, Kehlo has your back.',
          style: BloomType.sans(size: 15, color: Bloom.inkSoft, height: 1.45),
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.92,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final card in introCards) _IntroTile(card: card),
          ],
        ),
      ],
    );
  }
}

class _IntroTile extends StatelessWidget {
  const _IntroTile({required this.card});

  final IntroCard card;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Column(
        children: [
          Expanded(
            child: PhotoFrame(
              asset: card.image,
              radius: 16,
              width: double.infinity,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            card.label,
            textAlign: TextAlign.center,
            style: BloomType.sans(size: 13.5, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StylePage extends StatelessWidget {
  const _StylePage();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Headline(lead: 'Make it\n', accent: 'your style.'),
        const SizedBox(height: 12),
        Text(
          'Choose a tone that matches your personality.',
          style: BloomType.sans(size: 15, color: Bloom.inkSoft, height: 1.45),
        ),
        const SizedBox(height: 18),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: toneStyles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final style = toneStyles[index];
              return SoftCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    PhotoFrame(asset: style.asset, width: 54, height: 54, radius: 27),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            style.label,
                            style: BloomType.sans(size: 16, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            style.blurb,
                            style: BloomType.sans(size: 13, color: Bloom.inkSoft),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
        ),
      ],
    );
  }
}

class _OnboardScroll extends StatelessWidget {
  const _OnboardScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: child,
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.lead, required this.accent});

  final String lead;
  final String accent;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: BloomType.display(34, weight: FontWeight.w600),
        children: [
          TextSpan(text: lead),
          TextSpan(text: accent, style: BloomType.display(34, color: Bloom.pink)),
        ],
      ),
    );
  }
}
