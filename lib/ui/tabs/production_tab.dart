import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/game_controller.dart';
import '../../game/game_ui_state.dart';
import '../../game/game_state.dart';
import '../../game/game_math.dart';
import '../../game/milestone_definitions.dart';
import '../../game/research_definitions.dart';
import '../../game/number_format.dart';
import '../../game/run_modifiers.dart';
import '../../game/constant_upgrades.dart';
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
                        '管理设施与配比，提升整体产能与定律进度。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8FA3BF),
                        ),
                      ),
                      const SizedBox(height: 12),
                      RateSummaryCard(summary: state.rateSummary),
                      const SizedBox(height: 12),
                      LawProgressCard(blueprints: blueprints, laws: laws),
                      const SizedBox(height: 16),
                      _StrategyPanel(
                        state: gameState,
                        uiState: state,
                        controller: controller,
                      ),
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
              '管理设施与配比，提升整体产能与定律进度。',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8FA3BF)),
            ),
            const SizedBox(height: 12),
            RateSummaryCard(summary: state.rateSummary),
            const SizedBox(height: 12),
            LawProgressCard(blueprints: blueprints, laws: laws),
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
            _StrategyPanel(
              state: gameState,
              uiState: state,
              controller: controller,
            ),
          ],
        );
      },
    );
  }
}

class _StrategyPanel extends StatelessWidget {
  const _StrategyPanel({
    required this.state,
    required this.uiState,
    required this.controller,
  });

  final GameState state;
  final GameUiState uiState;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final modifiers = state.runModifiers;
    final rerollsLeft = state.runRerollsLeft;
    final rerollCost = controller.runRerollCost(state);
    final canReroll =
        rerollsLeft > 0 && state.resource(ResourceType.blueprint) >= rerollCost;
    final summary = _summaryText(state);
    final loadPercent = _energyLoadPercent(state);
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
        title: Text(
          '策略面板',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$summary ｜ 负载 $loadPercent%',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8FA3BF)),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '本轮变体',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '可刷新 $rerollsLeft 次',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF8FA3BF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (modifiers.isEmpty)
            Text(
              '暂无变体词条',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8FA3BF)),
            )
          else
            for (final id in modifiers)
              _RunModifierTile(modifier: runModifierById[id]),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canReroll ? controller.rerollRunModifiers : null,
              child: Text('刷新词条（${_formatCost(rerollCost)} 蓝图）'),
            ),
          ),
          const SizedBox(height: 12),
          const RatioPanel(),
          const SizedBox(height: 16),
          const LayoutPanel(),
        ],
        ),
      ),
    );
  }
}

class _RunModifierTile extends StatelessWidget {
  const _RunModifierTile({required this.modifier});

  final RunModifier? modifier;

  @override
  Widget build(BuildContext context) {
    if (modifier == null) {
      return const SizedBox.shrink();
    }
    final tone = _toneForTier(modifier!.tier);
    final tierLabel = _tierLabel(modifier!.tier);
    return SizedBox(
      width: double.infinity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1B2D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tone.withAlpha(120)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    modifier!.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  tierLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: tone),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              modifier!.description,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8FA3BF)),
            ),
          ],
        ),
      ),
    );
  }
}

String _tierLabel(RunModifierTier tier) {
  switch (tier) {
    case RunModifierTier.positive:
      return '正面';
    case RunModifierTier.negative:
      return '负面';
    case RunModifierTier.chaos:
      return '混沌';
  }
}

Color _toneForTier(RunModifierTier tier) {
  switch (tier) {
    case RunModifierTier.positive:
      return const Color(0xFF8BE4B4);
    case RunModifierTier.negative:
      return const Color(0xFFFF6B6B);
    case RunModifierTier.chaos:
      return const Color(0xFFF5C542);
  }
}

String _formatCost(Object value) {
  return formatNumber(value);
}

String _summaryText(GameState state) {
  final modifierCount = state.runModifiers.length;
  final layoutText = state.isLayoutUnlocked
      ? '布局 ${state.layoutUnlockedCount} 格'
      : '布局未解锁';
  return '变体 $modifierCount 项 · $layoutText';
}

int _energyLoadPercent(GameState state) {
  final effects = computeResearchEffects(
    state,
  ).combine(computeMilestoneEffects(state));
  final constants = computeConstantEffects(state);
  final rates = GameRates.fromState(state, effects, constants);
  final baseEnergyProd =
      energyProductionPerSec(state, effects) * constants.productionMultiplier;
  final energyNeed = partSynthesisEnergyNeedPerSec(state, effects);
  final energySplit = effectiveEnergySplit(
    state: state,
    energyProd: baseEnergyProd,
    energyNeed: energyNeed,
  );
  final energyAvailable = rates.energyPerSec * energySplit;
  final available = energyAvailable <= 0 ? 0.0001 : energyAvailable;
  final load = (rates.energyNeedPerSec / available).clamp(0.0, 2.0);
  return (load * 100).round();
}
