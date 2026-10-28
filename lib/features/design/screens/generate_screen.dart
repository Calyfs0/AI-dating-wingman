import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../bloom.dart';
import '../design_controller.dart';
import '../design_data.dart';
import '../widgets/bloom_widgets.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  late final TextEditingController _context;

  @override
  void initState() {
    super.initState();
    _context = TextEditingController(
      text: context.read<DesignController>().contextText,
    );
  }

  @override
  void dispose() {
    _context.dispose();
    super.dispose();
  }

  Future<void> _pickSituation() async {
    final controller = context.read<DesignController>();
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'What do you need a line for?',
                  style: BloomType.sans(size: 16, weight: FontWeight.w800),
                ),
              ),
              for (final situation in situations)
                ListTile(
                  title: Text(
                    situation.lineFor,
                    style: BloomType.sans(size: 15, weight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    situation.subtitle,
                    style: BloomType.sans(size: 12.5, color: Bloom.inkSoft),
                  ),
                  trailing: situation.id == controller.active.id
                      ? const Icon(Icons.check_rounded, color: Bloom.pink)
                      : null,
                  onTap: () => Navigator.pop(context, situation.id),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    controller.selectSituation(picked);
    _context.text = controller.contextText;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DesignController>();
    final situation = controller.active;

    return Scaffold(
      backgroundColor: Bloom.bg,
      body: SafeArea(
        child: Column(
          children: [
            const BloomHeader(title: 'Generate a Line', back: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  Text(
                    'What do you need a line for?',
                    style: BloomType.sans(size: 15, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _pickSituation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Bloom.line),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                situation.lineFor,
                                style: BloomType.sans(size: 15, weight: FontWeight.w600),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Bloom.inkSoft),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Add more context (optional)',
                    style: BloomType.sans(size: 15, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _context,
                    maxLines: 4,
                    maxLength: 200,
                    onChanged: controller.setContext,
                    style: BloomType.sans(size: 14.5, weight: FontWeight.w500, height: 1.45),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      counterText: '',
                      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Bloom.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Bloom.pink, width: 1.4),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, right: 4),
                      child: Text(
                        '${controller.contextText.length}/200',
                        style: BloomType.sans(size: 12, color: Bloom.mute),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a tone',
                    style: BloomType.sans(size: 15, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final style in toneStyles) ...[
                        Expanded(
                          child: _ToneChoice(
                            style: style,
                            selected: controller.tone == style.tone,
                            onTap: () => controller.setTone(style.tone),
                          ),
                        ),
                        if (style != toneStyles.last) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'How bold do you want to be?',
                    style: BloomType.sans(size: 15, weight: FontWeight.w800),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Bloom.pink,
                      inactiveTrackColor: Bloom.pinkSoft,
                      thumbColor: Colors.white,
                      overlayColor: Bloom.pink.withValues(alpha: 0.12),
                      trackHeight: 4,
                      thumbShape: const _RingThumb(),
                    ),
                    child: Slider(
                      value: controller.boldness.index.toDouble(),
                      min: 0,
                      max: 2,
                      divisions: 2,
                      onChanged: (value) =>
                          controller.setBoldness(Boldness.values[value.round()]),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final level in Boldness.values)
                        Text(
                          switch (level) {
                            Boldness.subtle => 'Subtle',
                            Boldness.balanced => 'Balanced',
                            Boldness.bold => 'Bold',
                          },
                          style: BloomType.sans(
                            size: 12.5,
                            weight: controller.boldness == level
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: controller.boldness == level ? Bloom.ink : Bloom.mute,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: BloomButton(
                label: 'Generate Lines',
                busy: controller.generating,
                onPressed: () async {
                  await controller.runGenerate();
                  if (!context.mounted) return;
                  context.push('/lines');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToneChoice extends StatelessWidget {
  const _ToneChoice({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final ToneStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? style.bg : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? style.fg : Bloom.line),
          ),
          child: Column(
            children: [
              Icon(style.icon, size: 16, color: selected ? style.fg : Bloom.inkSoft),
              const SizedBox(height: 4),
              Text(
                style.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BloomType.sans(
                  size: 11,
                  weight: FontWeight.w700,
                  color: selected ? style.fg : Bloom.inkSoft,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingThumb extends SliderComponentShape {
  const _RingThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(22, 22);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(center, 10, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      10,
      Paint()
        ..color = Bloom.pink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(center, 3.5, Paint()..color = Bloom.pink);
  }
}
