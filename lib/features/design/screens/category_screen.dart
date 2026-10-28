import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../bloom.dart';
import '../design_controller.dart';
import '../design_data.dart';
import '../widgets/bloom_widgets.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  static const _apps = ['All', 'Tinder', 'Bumble', 'Hinge', 'Others'];

  @override
  Widget build(BuildContext context) {
    final category = categoryById(categoryId);
    final controller = context.watch<DesignController>();
    final items = filterSituations(
      categoryId: categoryId,
      app: controller.appFilter,
      applyApp: category?.filtersApps ?? false,
    );

    return Scaffold(
      backgroundColor: Bloom.bg,
      body: SafeArea(
        child: Column(
          children: [
            BloomHeader(title: category?.label ?? 'Situations', back: true),
            if (category?.filtersApps ?? false)
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _apps.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final app = _apps[index];
                    final selected = controller.appFilter == app;
                    return ChoiceChip(
                      label: Text(app),
                      selected: selected,
                      showCheckmark: false,
                      onSelected: (_) => controller.setAppFilter(app),
                      labelStyle: BloomType.sans(
                        size: 13,
                        weight: FontWeight.w700,
                        color: selected ? Bloom.pinkDeep : Bloom.inkSoft,
                      ),
                      selectedColor: Bloom.pinkSoft,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: selected ? Bloom.pink.withValues(alpha: 0.5) : Bloom.line,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Text(
                        'Nothing in this filter yet. Try All.',
                        textAlign: TextAlign.center,
                        style: BloomType.sans(size: 14, color: Bloom.inkSoft),
                      ),
                    )
                  else
                    for (final situation in items)
                      SituationRow(
                        situation: situation,
                        onTap: () {
                          controller.selectSituation(situation.id);
                          context.push('/situation/${situation.id}');
                        },
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

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DesignController>();
    final items = filterSituations(query: controller.exploreQuery);

    return Scaffold(
      backgroundColor: Bloom.bg,
      body: SafeArea(
        child: Column(
          children: [
            const BloomHeader(title: 'Explore'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: BloomSearchField(
                hint: 'Search situations, e.g. first message',
                value: controller.exploreQuery,
                onChanged: controller.setExploreQuery,
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: homeCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = homeCategories[index];
                  return ActionChip(
                    label: Text(category.label),
                    onPressed: () => context.go('/home/category/${category.id}'),
                    labelStyle: BloomType.sans(
                      size: 13,
                      weight: FontWeight.w700,
                      color: Bloom.inkSoft,
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Bloom.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  if (items.isEmpty)
                    Text(
                      'No situations match that yet.',
                      style: BloomType.sans(size: 14, color: Bloom.inkSoft),
                    )
                  else
                    for (final situation in items)
                      SituationRow(
                        situation: situation,
                        onTap: () {
                          controller.selectSituation(situation.id);
                          context.push('/situation/${situation.id}');
                        },
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
