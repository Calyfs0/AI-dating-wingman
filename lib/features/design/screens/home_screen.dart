import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../bloom.dart';
import '../design_controller.dart';
import '../design_data.dart';
import '../widgets/bloom_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DesignController>();
    final query = controller.homeQuery.trim();
    final results = query.isEmpty
        ? const <Situation>[]
        : filterSituations(query: query);

    return Scaffold(
      backgroundColor: Bloom.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const _HomeHero(),
            const SizedBox(height: 16),
            BloomSearchField(
              hint: 'Search situations, e.g. first message',
              value: controller.homeQuery,
              onChanged: controller.setHomeQuery,
            ),
            const SizedBox(height: 22),
            if (query.isNotEmpty) ...[
              Text(
                results.isEmpty ? 'No matches' : 'Results',
                style: BloomType.sans(size: 16, weight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (results.isEmpty)
                Text(
                  'Try travel, coffee, pets, or a first message.',
                  style: BloomType.sans(size: 14, color: Bloom.inkSoft),
                )
              else
                for (final situation in results)
                  SituationRow(
                    situation: situation,
                    onTap: () => _openSituation(context, situation),
                  ),
            ] else ...[
              Row(
                children: [
                  Text(
                    'Popular situations',
                    style: BloomType.sans(size: 16, weight: FontWeight.w800),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/explore'),
                    child: Text(
                      'See all',
                      style: BloomType.sans(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: Bloom.pink,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 196,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: popularIds.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final situation = situationById(popularIds[index]);
                    return _PopularCard(
                      situation: situation,
                      onTap: () => _openSituation(context, situation),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.92,
                children: [
                  for (final category in homeCategories)
                    _CategoryTile(
                      category: category,
                      onTap: () => context.push('/home/category/${category.id}'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void _openSituation(BuildContext context, Situation situation) {
  context.read<DesignController>().selectSituation(situation.id);
  context.push('/situation/${situation.id}');
}

class _HomeHero extends StatelessWidget {
  const _HomeHero();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 214,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/design/street_hero.jpg', fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33000000), Color(0x00000000), Color(0x99000000)],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const KehloWordmark(size: 46, color: Colors.white),
                      const Spacer(),
                      const ProPill(onPhoto: true),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 210,
                    child: Text(
                      'Good conversations start here.',
                      style: BloomType.script(30, Colors.white),
                    ),
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

class _PopularCard extends StatelessWidget {
  const _PopularCard({required this.situation, required this.onTap});

  final Situation situation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
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
                BoxShadow(color: Bloom.shadow, blurRadius: 16, offset: Offset(0, 6)),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhotoFrame(
                  asset: situation.image,
                  height: 96,
                  width: double.infinity,
                  radius: 16,
                ),
                const SizedBox(height: 8),
                Text(
                  situation.title.replaceAll('Profile prompt ', ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BloomType.sans(size: 13.5, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  situation.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BloomType.sans(
                    size: 11.5,
                    color: Bloom.inkSoft,
                    height: 1.3,
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final BloomCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(color: Bloom.shadow, blurRadius: 16, offset: Offset(0, 6)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          child: Column(
            children: [
              Expanded(
                child: PhotoFrame(
                  asset: category.image,
                  radius: 16,
                  width: double.infinity,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.label,
                textAlign: TextAlign.center,
                style: BloomType.sans(size: 13.5, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
