import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../bloom.dart';
import '../design_controller.dart';
import '../design_data.dart';
import '../widgets/bloom_widgets.dart';

class SituationScreen extends StatelessWidget {
  const SituationScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final situation = situationById(id);
    final liked = context.watch<DesignController>().likedSituations.contains(id);

    return Scaffold(
      backgroundColor: Bloom.bg,
      body: SafeArea(
        child: Column(
          children: [
            BloomHeader(title: situation.badge, back: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 5,
                    child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PhotoFrame(
                        asset: situation.hero,
                        height: double.infinity,
                        width: double.infinity,
                        radius: 28,
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: () =>
                                context.read<DesignController>().toggleLike(id),
                            icon: Icon(
                              liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: liked ? Bloom.pink : Bloom.ink,
                            ),
                          ),
                        ),
                      ),
                    ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Bloom.pinkSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        situation.badge,
                        style: BloomType.sans(
                          size: 12,
                          weight: FontWeight.w700,
                          color: Bloom.pinkDeep,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(situation.headline, style: BloomType.display(30)),
                  const SizedBox(height: 8),
                  Text(
                    situation.blurb,
                    style: BloomType.sans(size: 15, color: Bloom.inkSoft, height: 1.45),
                  ),
                  const SizedBox(height: 18),
                  SoftCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF3E4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: Color(0xFFE0A15A),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tips',
                                style: BloomType.sans(size: 14, weight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                situation.tip,
                                style: BloomType.sans(
                                  size: 13.5,
                                  color: Bloom.inkSoft,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: BloomButton(
                label: 'Get Lines',
                onPressed: () {
                  context.read<DesignController>().selectSituation(situation.id);
                  context.push('/generate');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
