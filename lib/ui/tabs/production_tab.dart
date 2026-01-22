import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/game_controller.dart';
import '../../game/game_ui_state.dart';
import '../../game/game_state.dart';
import '../../game/run_modifiers.dart';
import '../effects/particle_layer.dart';
import '../widgets/building_card.dart';
import '../widgets/law_progress_card.dart';
import '../widgets/layout_panel.dart';
import '../widgets/rate_summary_card.dart';
import '../widgets/ratio_panel.dart';
import '../widgets/resource_bar.dart';

class ProductionTab extends ConsumerWidget {
  const ProductionTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameUiProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final gameState = ref.watch(gameControllerProvider);
    final particleController = ref.read(particleControllerProvider);
    final anchorRegistry = ref.read(resourceAnchorRegistryProvider);
    final blueprints = gameState.resource(ResourceType.blueprint);
    final laws = gameState.resource(ResourceType.law);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (isWide) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 2,
                  child: Column(
                    children: [
                      Text(
                        '管理设施与配比，提升整体产能与定律进度',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF8FA3BF),
                            ),
                      ),
                      const SizedBox(height: 12),
                      RateSummaryCard(summary: state.rateSummary),
                      const SizedBox(height: 12),
                      _RunModifierCard(
                        modifiers: gameState.runModifiers,
                      ),
                      const SizedBox(height: 12),
                      LawProgressCard(
                        blueprints: blueprints,
                        laws: laws,
                      ),
                      const SizedBox(height: 16),
                      const RatioPanel(),
                      const SizedBox(height: 16),
                      const LayoutPanel(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: ListView.separated(
                    itemCount: state.buildings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final building = state.buildings[index];
                      return BuildingCard(
                        data: building,
                        onBuyOne: () => controller.buy(building.id, 1),
                        onBuyTen: () => controller.buy(building.id, 10),
                        onBuyMax: () => controller.buy(building.id, -1),
                        particleController: particleController,
                        anchorRegistry: anchorRegistry,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            Text(
              '管理设施与配比，提升整体产能与定律进度',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8FA3BF),
                  ),
            ),
            const SizedBox(height: 12),
            RateSummaryCard(summary: state.rateSummary),
            const SizedBox(height: 12),
            _RunModifierCard(
              modifiers: gameState.runModifiers,
            ),
            const SizedBox(height: 12),
            LawProgressCard(
              blueprints: blueprints,
              laws: laws,
            ),
            const SizedBox(height: 16),
            for (final building in state.buildings) ...[
              BuildingCard(
                data: building,
                onBuyOne: () => controller.buy(building.id, 1),
                onBuyTen: () => controller.buy(building.id, 10),
                onBuyMax: () => controller.buy(building.id, -1),
                particleController: particleController,
                anchorRegistry: anchorRegistry,
              ),
              const SizedBox(height: 12),
            ],
            const RatioPanel(),
            const SizedBox(height: 16),
            const LayoutPanel(),
          ],
        );
      },
    );
  }
}

class _RunModifierCard extends StatelessWidget {
  const _RunModifierCard({
    required this.modifiers,
  });

  final List<String> modifiers;

  @override
  Widget build(BuildContext context) {
    if (modifiers.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '本轮变体',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            for (final id in modifiers)
              _RunModifierTile(
                modifier: runModifierById[id],
              ),
          ],
        ),
      ),
    );
  }
}

class _RunModifierTile extends StatelessWidget {
  const _RunModifierTile({
    required this.modifier,
  });

  final RunModifier? modifier;

  @override
  Widget build(BuildContext context) {
    if (modifier == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: double.infinity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1B2D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF22324A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              modifier!.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              modifier!.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8FA3BF),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
