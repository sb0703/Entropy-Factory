import 'dart:math' as math;

import 'game_state.dart';
import 'research_definitions.dart';

class RunModifier {
  const RunModifier({
    required this.id,
    required this.title,
    required this.description,
    required this.effects,
  });

  final String id;
  final String title;
  final String description;
  final ResearchEffects effects;
}

const List<RunModifier> runModifiers = [
  RunModifier(
    id: 'run_shard_rush',
    title: '碎片奔涌',
    description: '碎片产出 +40%，转换产能 -10%。',
    effects: ResearchEffects(
      shardProductionMultiplier: 1.4,
      shardCostGrowthOffset: 0.0,
      shardToPartEfficiencyMultiplier: 1.0,
      shardConversionCapacityMultiplier: 0.9,
      blueprintProductionMultiplier: 1.0,
      energyNeedMultiplier: 1.0,
    ),
  ),
  RunModifier(
    id: 'run_blueprint_focus',
    title: '蓝图倾斜',
    description: '蓝图产出 +30%，碎片转化效率 -10%。',
    effects: ResearchEffects(
      shardProductionMultiplier: 1.0,
      shardCostGrowthOffset: 0.0,
      shardToPartEfficiencyMultiplier: 0.9,
      shardConversionCapacityMultiplier: 1.0,
      blueprintProductionMultiplier: 1.3,
      energyNeedMultiplier: 1.0,
    ),
  ),
  RunModifier(
    id: 'run_energy_surge',
    title: '能量激荡',
    description: '能耗 -15%，但碎片成本增长 +0.01。',
    effects: ResearchEffects(
      shardProductionMultiplier: 1.0,
      shardCostGrowthOffset: 0.01,
      shardToPartEfficiencyMultiplier: 1.0,
      shardConversionCapacityMultiplier: 1.0,
      blueprintProductionMultiplier: 1.0,
      energyNeedMultiplier: 0.85,
    ),
  ),
  RunModifier(
    id: 'run_precision_forge',
    title: '精密锻造',
    description: '碎片转化效率 +20%，蓝图产出 -10%。',
    effects: ResearchEffects(
      shardProductionMultiplier: 1.0,
      shardCostGrowthOffset: 0.0,
      shardToPartEfficiencyMultiplier: 1.2,
      shardConversionCapacityMultiplier: 1.0,
      blueprintProductionMultiplier: 0.9,
      energyNeedMultiplier: 1.0,
    ),
  ),
];

final Map<String, RunModifier> runModifierById = {
  for (final def in runModifiers) def.id: def,
};

ResearchEffects computeRunModifierEffects(GameState state) {
  var effects = ResearchEffects.base;
  for (final id in state.runModifiers) {
    final def = runModifierById[id];
    if (def != null) {
      effects = effects.combine(def.effects);
    }
  }
  return effects;
}

List<String> rollRunModifiers(math.Random random, {int count = 2}) {
  final pool = [...runModifiers];
  pool.shuffle(random);
  return pool.take(math.min(count, pool.length)).map((e) => e.id).toList();
}
