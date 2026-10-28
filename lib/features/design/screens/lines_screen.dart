import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../bloom.dart';
import '../design_controller.dart';
import '../design_data.dart';
import '../widgets/bloom_widgets.dart';

class LinesScreen extends StatelessWidget {
  const LinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DesignController>();
    final lines = controller.currentLines;

    return Scaffold(
      backgroundColor: Bloom.bg,
      body: SafeArea(
        child: Column(
          children: [
            const BloomHeader(title: 'Your Lines', back: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                children: [
                  Text(
                    'Here are a few ways to say hello.',
                    style: BloomType.sans(size: 14, color: Bloom.inkSoft),
                  ),
                  const SizedBox(height: 14),
                  for (final line in lines) ...[
                    _LineCard(line: line),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: BloomOutlineButton(
                label: 'Generate More',
                busy: controller.generating,
                onPressed: () => controller.runGenerate(more: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineCard extends StatefulWidget {
  const _LineCard({required this.line});

  final GeneratedLine line;

  @override
  State<_LineCard> createState() => _LineCardState();
}

class _LineCardState extends State<_LineCard> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.line.text));
    if (!mounted) return;
    setState(() => _copied = true);
    showBloomSnack(context, 'Copied');
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DesignController>();
    final saved = controller.isSaved(widget.line.text);

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ToneBadge(tone: widget.line.tone),
          const SizedBox(height: 10),
          Text(
            widget.line.text,
            style: BloomType.sans(size: 15, weight: FontWeight.w500, height: 1.45),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: _copy,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      Icon(
                        _copied ? Icons.check_rounded : Icons.copy_rounded,
                        size: 16,
                        color: Bloom.inkSoft,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _copied ? 'Copied' : 'Copy',
                        style: BloomType.sans(
                          size: 13,
                          weight: FontWeight.w600,
                          color: Bloom.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  controller.toggleSave(widget.line);
                  showBloomSnack(
                    context,
                    saved ? 'Removed from Saved' : 'Saved to your lines',
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      Icon(
                        saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 16,
                        color: saved ? Bloom.pink : Bloom.inkSoft,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        saved ? 'Saved' : 'Save',
                        style: BloomType.sans(
                          size: 13,
                          weight: FontWeight.w600,
                          color: saved ? Bloom.pink : Bloom.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
