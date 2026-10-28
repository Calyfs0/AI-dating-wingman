import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../bloom.dart';
import '../design_controller.dart';
import '../design_data.dart';
import '../widgets/bloom_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final preview = context.watch<DesignController>().proPreview;

    return Scaffold(
      backgroundColor: Bloom.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            BloomHeader(
              title: 'Profile',
              trailing: IconButton(
                onPressed: () => context.push('/profile/settings'),
                icon: const Icon(Icons.settings_outlined, color: Bloom.ink),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: SizedBox(
                height: 168,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/design/man_portrait.jpg',
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.2),
                    ),
                    const Positioned(top: 12, right: 12, child: ProPill(onPhoto: true)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => showProSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(color: Bloom.shadow, blurRadius: 16, offset: Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CrownMark(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kehlo Pro',
                              style: BloomType.sans(size: 16, weight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              preview
                                  ? 'Preview is on. Unlimited lines in this build.'
                                  : 'Unlock unlimited lines, advanced AI and more.',
                              style: BloomType.sans(size: 12.5, color: Bloom.inkSoft, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Bloom.mute),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  _MenuRow(
                    icon: Icons.tune_rounded,
                    label: 'My Preferences',
                    onTap: () => context.push('/profile/preferences'),
                  ),
                  const Divider(height: 1, color: Bloom.line),
                  _MenuRow(
                    icon: Icons.settings_outlined,
                    label: 'App Settings',
                    onTap: () => context.push('/profile/settings'),
                  ),
                  const Divider(height: 1, color: Bloom.line),
                  _MenuRow(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Feedback',
                    onTap: () => context.push('/profile/feedback'),
                  ),
                  const Divider(height: 1, color: Bloom.line),
                  _MenuRow(
                    icon: Icons.star_outline_rounded,
                    label: 'Rate Kehlo',
                    onTap: () => context.push('/profile/rate'),
                  ),
                  const Divider(height: 1, color: Bloom.line),
                  _MenuRow(
                    icon: Icons.shield_outlined,
                    label: 'Privacy Policy',
                    onTap: () => context.push('/profile/privacy'),
                  ),
                  const Divider(height: 1, color: Bloom.line),
                  _MenuRow(
                    icon: Icons.description_outlined,
                    label: 'Terms of Service',
                    onTap: () => context.push('/profile/terms'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Bloom.inkSoft),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: BloomType.sans(size: 15, weight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Bloom.mute, size: 20),
          ],
        ),
      ),
    );
  }
}

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DesignController>();
    return _Subpage(
      title: 'My Preferences',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'Default tone',
            style: BloomType.sans(size: 15, weight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (final style in toneStyles)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: controller.defaultTone == style.tone ? style.bg : Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => controller.setDefaultTone(style.tone),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: controller.defaultTone == style.tone ? style.fg : Bloom.line,
                      ),
                    ),
                    child: Row(
                      children: [
                        PhotoFrame(asset: style.asset, width: 48, height: 48, radius: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                style.label,
                                style: BloomType.sans(size: 15, weight: FontWeight.w700),
                              ),
                              Text(
                                style.blurb,
                                style: BloomType.sans(size: 12.5, color: Bloom.inkSoft),
                              ),
                            ],
                          ),
                        ),
                        if (controller.defaultTone == style.tone)
                          Icon(Icons.check_circle_rounded, color: style.fg),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Default boldness',
            style: BloomType.sans(size: 15, weight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final level in Boldness.values) ...[
                Expanded(
                  child: ChoiceChip(
                    label: Text(
                      switch (level) {
                        Boldness.subtle => 'Subtle',
                        Boldness.balanced => 'Balanced',
                        Boldness.bold => 'Bold',
                      },
                    ),
                    selected: controller.defaultBoldness == level,
                    showCheckmark: false,
                    onSelected: (_) => controller.setDefaultBoldness(level),
                    labelStyle: BloomType.sans(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: controller.defaultBoldness == level
                          ? Bloom.pinkDeep
                          : Bloom.inkSoft,
                    ),
                    selectedColor: Bloom.pinkSoft,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: controller.defaultBoldness == level ? Bloom.pink : Bloom.line,
                    ),
                  ),
                ),
                if (level != Boldness.bold) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DesignController>();
    return _Subpage(
      title: 'App Settings',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  value: controller.notifications,
                  activeThumbColor: Colors.white,
                  activeTrackColor: Bloom.pink,
                  title: Text(
                    'Reminders',
                    style: BloomType.sans(size: 15, weight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'A gentle nudge when a line is waiting.',
                    style: BloomType.sans(size: 12.5, color: Bloom.inkSoft),
                  ),
                  onChanged: controller.toggleNotifications,
                ),
                const Divider(height: 1, color: Bloom.line),
                SwitchListTile(
                  value: controller.haptics,
                  activeThumbColor: Colors.white,
                  activeTrackColor: Bloom.pink,
                  title: Text(
                    'Haptics',
                    style: BloomType.sans(size: 15, weight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'A small tap when you copy or save.',
                    style: BloomType.sans(size: 12.5, color: Bloom.inkSoft),
                  ),
                  onChanged: controller.toggleHaptics,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Lines in this preview stay on this device. Nothing is sent to a server.',
            style: BloomType.sans(size: 13, color: Bloom.inkSoft, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Subpage(
      title: 'Feedback',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What should Kehlo feel like next?',
              style: BloomType.display(26),
            ),
            const SizedBox(height: 8),
            Text(
              'This stays on the device. There’s no inbox behind it yet.',
              style: BloomType.sans(size: 14, color: Bloom.inkSoft),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _text,
              maxLines: 6,
              maxLength: 400,
              onChanged: (_) => setState(() {}),
              style: BloomType.sans(size: 15),
              decoration: InputDecoration(
                hintText: 'A tone, a screen, a line that missed…',
                hintStyle: BloomType.sans(size: 14, color: Bloom.mute),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Bloom.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Bloom.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Bloom.pink),
                ),
              ),
            ),
            const Spacer(),
            BloomButton(
              label: 'Send note',
              showArrow: false,
              onPressed: _text.text.trim().isEmpty
                  ? null
                  : () {
                      _text.clear();
                      setState(() {});
                      showBloomSnack(context, 'Thanks — noted on this device.');
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class RatePage extends StatefulWidget {
  const RatePage({super.key});

  @override
  State<RatePage> createState() => _RatePageState();
}

class _RatePageState extends State<RatePage> {
  int _stars = 0;

  @override
  Widget build(BuildContext context) {
    return _Subpage(
      title: 'Rate Kehlo',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          children: [
            Text('How does Kehlo feel?', style: BloomType.display(28), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'A local rating for this preview. No store review is sent.',
              textAlign: TextAlign.center,
              style: BloomType.sans(size: 14, color: Bloom.inkSoft),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    onPressed: () => setState(() => _stars = i),
                    icon: Icon(
                      i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFE2B15A),
                      size: 36,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            BloomButton(
              label: 'Save rating',
              showArrow: false,
              onPressed: _stars == 0
                  ? null
                  : () => showBloomSnack(context, 'Saved $_stars stars on this device.'),
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CopyPage(
      title: 'Privacy Policy',
      heading: 'Your words stay here.',
      paragraphs: [
        'This preview keeps lines, saves, and preferences in memory on the device. Closing the tab clears them.',
        'Sample photos are illustrations for the design. They are not profiles of real people, and nothing you type is uploaded.',
        'When an account arrives, Kehlo will say plainly what is stored and how to delete it. Until then, there is no inbox and no purchase.',
      ],
    );
  }
}

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CopyPage(
      title: 'Terms of Service',
      heading: 'A preview, not a promise.',
      paragraphs: [
        'Kehlo in this build is a design preview. The lines are sample copy chosen on the device. They are not generated by a model and they are not advice.',
        'Use them kindly. A good line still leaves the other person room to say no.',
        'Pro is a local preview switch. It does not bill a card and it does not unlock a server.',
      ],
    );
  }
}

class _CopyPage extends StatelessWidget {
  const _CopyPage({
    required this.title,
    required this.heading,
    required this.paragraphs,
  });

  final String title;
  final String heading;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    return _Subpage(
      title: title,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(heading, style: BloomType.display(30)),
          const SizedBox(height: 14),
          for (final paragraph in paragraphs) ...[
            Text(
              paragraph,
              style: BloomType.sans(size: 15, color: Bloom.inkSoft, height: 1.5),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _Subpage extends StatelessWidget {
  const _Subpage({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Bloom.bg,
      body: SafeArea(
        child: Column(
          children: [
            BloomHeader(title: title, back: true),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
