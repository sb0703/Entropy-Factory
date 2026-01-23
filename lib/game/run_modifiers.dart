import 'dart:math' as math;

import 'game_state.dart';
import 'research_definitions.dart';

enum RunModifierTier { positive, negative, chaos }

class RunModifier {
  const RunModifier({
    required this.id,
    required this.title,
    required this.description,
    required this.tier,
    required this.effects,
  });

  final String id;
  final String title;
  final String description;
  final RunModifierTier tier;
  final ResearchEffects effects;
}

const List<RunModifier> runModifiers = [
  RunModifier(
    id: 'run_shard_rush',
    title: '碎片奔涌',
    description: '碎片产出 +40%，转换产能 -10%。',
    tier: RunModifierTier.chaos,
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
    description: '蓝图产出 +30%，碎片转换效率 -10%。',
    tier: RunModifierTier.chaos,
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
    tier: RunModifierTier.chaos,
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
    description: '碎片转换效率 +20%，蓝图产出 -10%。',
    tier: RunModifierTier.chaos,
    effects: ResearchEffects(
      shardProductionMultiplier: 1.0,
      shardCostGrowthOffset: 0.0,
      shardToPartEfficiencyMultiplier: 1.2,
      shardConversionCapacityMultiplier: 1.0,
      blueprintProductionMultiplier: 0.9,
      energyNeedMultiplier: 1.0,
    ),
  ),
  RunModifier(
    id: 'run_peak_output',
    title: '峰值输出',
    description: '采集产出 +25%，转换产能 +15%。',
    tier: RunModifierTier.positive,
    effects: ResearchEffects(
      shardProductionMultiplier: 1.25,
      shardCostGrowthOffset: 0.0,
      shardToPartEfficiencyMultiplier: 1.0,
      shardConversionCapacityMultiplier: 1.15,
      blueprintProductionMultiplier: 1.0,
      energyNeedMultiplier: 1.0,
    ),
  ),
  RunModifier(
    id: 'run_blueprint_bloom',
    title: '蓝图盛放',
    description: '蓝图产出 +20%，能耗 -10%。',
    tier: RunModifierTier.positive,
    effects: ResearchEffects(
      shardProductionMultiplier: 1.0,
      shardCostGrowthOffset: 0.0,
      shardToPartEfficiencyMultiplier: 1.0,
      shardConversionCapacityMultiplier: 1.0,
      blueprintProductionMultiplier: 1.2,
      energyNeedMultiplier: 0.9,
    ),
  ),
  RunModifier(
    id: 'run_sparse_energy',
    title: '稀薄能场',
    description: '能耗 +15%，合成效率降低。',
    tier: RunModifierTier.negative,
    effects: ResearchEffects(
      shardProductionMultiplier: 1.0,
      shardCostGrowthOffset: 0.0,
      shardToPartEfficiencyMultiplier: 1.0,
      shardConversionCapacityMultiplier: 1.0,
      blueprintProductionMultiplier: 1.0,
      energyNeedMultiplier: 1.15,
    ),
  ),
  RunModifier(
    id: 'run_rust_pressure',
    title: '锈蚀压力',
    description: '采集产出 -20%，转换效率 -10%。',
    tier: RunModifierTier.negative,
    effects: ResearchEffects(
      shardProductionMultiplier: 0.8,
      shardCostGrowthOffset: 0.0,
      shardToPartEfficiencyMultiplier: 0.9,
      shardConversionCapacityMultiplier: 1.0,
      blueprintProductionMultiplier: 1.0,
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

List<String> rollRunModifiers(
  math.Random random, {
  int positive = 1,
  int negative = 1,
  int chaos = 1,
}) {
  final positives = runModifiers
      .where((mod) => mod.tier == RunModifierTier.positive)
      .toList()
    ..shuffle(random);
  final negatives = runModifiers
      .where((mod) => mod.tier == RunModifierTier.negative)
      .toList()
    ..shuffle(random);
  final chaoses = runModifiers
      .where((mod) => mod.tier == RunModifierTier.chaos)
      .toList()
    ..shuffle(random);

  final picks = <String>[];
  picks.addAll(positives.take(positive).map((e) => e.id));
  picks.addAll(negatives.take(negative).map((e) => e.id));
  picks.addAll(chaoses.take(chaos).map((e) => e.id));
  return picks;
}
