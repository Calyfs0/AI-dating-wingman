import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../bloom.dart';
import '../design_controller.dart';
import '../design_data.dart';

class KehloWordmark extends StatelessWidget {
  const KehloWordmark({
    super.key,
    required this.size,
    required this.color,
    this.heartColor,
  });

  final double size;
  final Color color;
  final Color? heartColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kehlo', style: BloomType.script(size, color)),
        Padding(
          padding: EdgeInsets.only(top: size * 0.18, left: 1),
          child: Icon(
            Icons.favorite_rounded,
            size: size * 0.22,
            color: heartColor ?? color,
          ),
        ),
      ],
    );
  }
}

class ProPill extends StatelessWidget {
  const ProPill({super.key, this.onPhoto = false});

  final bool onPhoto;

  @override
  Widget build(BuildContext context) {
    final preview = context.watch<DesignController>().proPreview;
    return Material(
      color: onPhoto ? Colors.white.withValues(alpha: 0.92) : Bloom.pinkSoft,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showProSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            preview ? 'PRO' : 'PRO',
            style: BloomType.sans(
              size: 11,
              weight: FontWeight.w800,
              color: Bloom.pinkDeep,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class BloomButton extends StatelessWidget {
  const BloomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.showArrow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Bloom.pink.withValues(alpha: enabled ? 0.28 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: FilledButton(
          onPressed: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                }
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: Bloom.pink,
            disabledBackgroundColor: Bloom.pink.withValues(alpha: 0.55),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            elevation: 0,
          ),
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: BloomType.sans(
                        size: 16,
                        weight: FontWeight.w700,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    if (showArrow) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class BloomOutlineButton extends StatelessWidget {
  const BloomOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.refresh_rounded,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: busy ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Bloom.pinkDeep,
          side: const BorderSide(color: Bloom.pink, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          backgroundColor: Colors.white,
        ),
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Bloom.pink,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: Bloom.pinkDeep),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: BloomType.sans(
                      size: 15,
                      weight: FontWeight.w700,
                      color: Bloom.pinkDeep,
                      height: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.index, this.count = 3});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == index ? Bloom.pink : Bloom.dot,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class BloomHeader extends StatelessWidget {
  const BloomHeader({
    super.key,
    required this.title,
    this.back = false,
    this.onBack,
    this.trailing,
  });

  final String title;
  final bool back;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          if (back)
            IconButton(
              onPressed: () {
                if (onBack != null) {
                  onBack!();
                  return;
                }
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              color: Bloom.ink,
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: BloomType.sans(size: 17, weight: FontWeight.w700),
            ),
          ),
          trailing ?? const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class BloomSearchField extends StatefulWidget {
  const BloomSearchField({
    super.key,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<BloomSearchField> createState() => _BloomSearchFieldState();
}

class _BloomSearchFieldState extends State<BloomSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant BloomSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Bloom.shadow, blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: BloomType.sans(size: 14, weight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: BloomType.sans(
            size: 14,
            weight: FontWeight.w500,
            color: Bloom.mute,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: Bloom.mute),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class PhotoFrame extends StatelessWidget {
  const PhotoFrame({
    super.key,
    required this.asset,
    this.height,
    this.width,
    this.radius = 18,
    this.fit = BoxFit.cover,
  });

  final String asset;
  final double? height;
  final double? width;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        asset,
        height: height,
        width: width,
        fit: fit,
      ),
    );
  }
}

class SituationRow extends StatelessWidget {
  const SituationRow({super.key, required this.situation, required this.onTap});

  final Situation situation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Bloom.shadow,
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                PhotoFrame(
                  asset: situation.image,
                  width: 72,
                  height: 72,
                  radius: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        situation.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: BloomType.sans(size: 14.5, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        situation.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: BloomType.sans(
                          size: 12.5,
                          weight: FontWeight.w500,
                          color: Bloom.inkSoft,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ToneBadge extends StatelessWidget {
  const ToneBadge({super.key, required this.tone, this.label});

  final BloomTone tone;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final style = toneStyle(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 13, color: style.fg),
          const SizedBox(width: 4),
          Text(
            label ?? style.label,
            style: BloomType.sans(
              size: 12,
              weight: FontWeight.w700,
              color: style.fg,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Bloom.shadow, blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

void showBloomSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<void> showProSheet(BuildContext context) {
  final controller = context.read<DesignController>();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Bloom.dot,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 18),
            const CrownMark(size: 54),
            const SizedBox(height: 10),
            Text('Kehlo Pro', style: BloomType.display(28)),
            const SizedBox(height: 6),
            Text(
              controller.proPreview
                  ? 'Preview is on. Billing comes later.'
                  : 'Unlimited lines, every tone, and folders — on this device for now.',
              textAlign: TextAlign.center,
              style: BloomType.sans(size: 14, color: Bloom.inkSoft),
            ),
            const SizedBox(height: 16),
            const _Benefit(icon: Icons.all_inclusive_rounded, text: 'Lines for every situation'),
            const _Benefit(icon: Icons.favorite_outline_rounded, text: 'Sweet, playful, confident, thoughtful'),
            const _Benefit(icon: Icons.folder_open_rounded, text: 'Saved lines, sorted into folders'),
            const SizedBox(height: 18),
            BloomButton(
              label: controller.proPreview ? 'Keep previewing' : 'Turn on preview',
              showArrow: false,
              onPressed: () {
                controller.enablePreview();
                Navigator.of(context).pop();
                showBloomSnack(context, 'Pro preview is on. Nothing is billed.');
              },
            ),
          ],
        ),
      );
    },
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Bloom.pink, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: BloomType.sans(size: 14, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class CrownMark extends StatelessWidget {
  const CrownMark({super.key, this.size = 46});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF4D8),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.workspace_premium_rounded,
        color: const Color(0xFFE2B15A),
        size: size * 0.58,
      ),
    );
  }
}

class DesignShell extends StatelessWidget {
  const DesignShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Bloom.bg,
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Bloom.line)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                _NavItem(
                  label: 'Home',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  selected: shell.currentIndex == 0,
                  onTap: () => shell.goBranch(0, initialLocation: shell.currentIndex == 0),
                ),
                _NavItem(
                  label: 'Explore',
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore_rounded,
                  selected: shell.currentIndex == 1,
                  onTap: () => shell.goBranch(1, initialLocation: shell.currentIndex == 1),
                ),
                _NavItem(
                  label: 'Saved',
                  icon: Icons.bookmark_border_rounded,
                  activeIcon: Icons.bookmark_rounded,
                  selected: shell.currentIndex == 2,
                  onTap: () => shell.goBranch(2, initialLocation: shell.currentIndex == 2),
                ),
                _NavItem(
                  label: 'Profile',
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  selected: shell.currentIndex == 3,
                  onTap: () => shell.goBranch(3, initialLocation: shell.currentIndex == 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Bloom.pink : Bloom.mute;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: BloomType.sans(
                size: 11,
                weight: FontWeight.w700,
                color: color,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
