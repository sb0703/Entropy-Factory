import 'package:flutter/foundation.dart';

import 'big_number.dart';
import 'game_state.dart';
import 'research_definitions.dart';

@immutable
class MilestoneDefinition {
  const MilestoneDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.isAchieved,
    required this.effects,
  });

  final String id;
  final String title;
  final String description;
  final bool Function(GameState state) isAchieved;
  final ResearchEffects effects;
}

final List<MilestoneDefinition> milestoneDefinitions = [
  MilestoneDefinition(
    id: 'milestone_shard_10000',
    title: '碎片突破',
    description: '碎片达到 1 万',
    isAchieved: (state) =>
        state.resource(ResourceType.shard) >= BigNumber.fromDouble(10000),
    effects: ResearchEffects.base.copyWith(
      shardProductionMultiplier: 1.1,
    ),
  ),
  MilestoneDefinition(
    id: 'milestone_part_100',
    title: '零件起步',
    description: '零件达到 100',
    isAchieved: (state) =>
        state.resource(ResourceType.part) >= BigNumber.fromDouble(100),
    effects: ResearchEffects.base.copyWith(
      shardToPartEfficiencyMultiplier: 1.1,
    ),
  ),
  MilestoneDefinition(
    id: 'milestone_blueprint_10',
    title: '蓝图成形',
    description: '蓝图达到 10',
    isAchieved: (state) =>
        state.resource(ResourceType.blueprint) >= BigNumber.fromDouble(10),
    effects: ResearchEffects.base.copyWith(
      blueprintProductionMultiplier: 1.1,
    ),
  ),
  MilestoneDefinition(
    id: 'milestone_miner_10',
    title: '采集扩张',
    description: '矿机达到 10 台',
    isAchieved: (state) => state.buildingCount('miner') >= 10,
    effects: ResearchEffects.base.copyWith(
      shardCostGrowthOffset: -0.01,
    ),
  ),
];

ResearchEffects computeMilestoneEffects(GameState state) {
  var effects = ResearchEffects.base;
  for (final def in milestoneDefinitions) {
    if (state.milestonesAchieved.contains(def.id)) {
      effects = effects.combine(def.effects);
    }
  }
  return effects;
}

List<MilestoneDefinition> findNewMilestones(GameState state) {
  final newly = <MilestoneDefinition>[];
  for (final def in milestoneDefinitions) {
    if (!state.milestonesAchieved.contains(def.id) && def.isAchieved(state)) {
      newly.add(def);
    }
  }
  return newly;
}
