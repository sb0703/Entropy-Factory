import 'package:flutter/material.dart';

import 'game_state.dart';
import 'research_definitions.dart';

enum SkillType { active, passive }

class SkillDefinition {
  const SkillDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.icon,
    this.costBlueprints = 0,
    this.costSkillPoints = 0,
    this.prerequisites = const [],
    this.cooldownMs = 0,
    this.durationMs = 0,
  });

  final String id;
  final String name;
  final String description;
  final SkillType type;
  final IconData icon;
  final double costBlueprints;
  final int costSkillPoints;
  final List<String> prerequisites;
  final int cooldownMs;
  final int durationMs;
}

const List<SkillDefinition> skillDefinitions = [
  SkillDefinition(
    id: 'skill_time_warp',
    name: '时间扭曲',
    description: '短时间内游戏速度翻倍。',
    type: SkillType.active,
    icon: Icons.timelapse,
    costBlueprints: 20,
    cooldownMs: 5 * 60 * 1000,
    durationMs: 30000,
  ),
  SkillDefinition(
    id: 'skill_overclock',
    name: '手动超频',
    description: '短时间内转换与合成效率提升。',
    type: SkillType.active,
    icon: Icons.flash_on,
    costBlueprints: 30,
    cooldownMs: 3 * 60 * 1000,
    durationMs: 20000,
    prerequisites: ['skill_time_warp'],
  ),
  SkillDefinition(
    id: 'skill_pulse',
    name: '资源脉冲',
    description: '立刻获得一小段时间的碎片产出。',
    type: SkillType.active,
    icon: Icons.bolt,
    costBlueprints: 25,
    cooldownMs: 90 * 1000,
    prerequisites: ['skill_shard_boost'],
  ),
  SkillDefinition(
    id: 'skill_shard_boost',
    name: '采集增幅',
    description: '碎片产出 +15%。',
    type: SkillType.passive,
    icon: Icons.scatter_plot,
    costSkillPoints: 1,
  ),
  SkillDefinition(
    id: 'skill_conversion_boost',
    name: '转化加速',
    description: '碎片转化效率 +15%。',
    type: SkillType.passive,
    icon: Icons.compare_arrows,
    costSkillPoints: 1,
    prerequisites: ['skill_shard_boost'],
  ),
  SkillDefinition(
    id: 'skill_capacity_boost',
    name: '通道扩容',
    description: '转化设施产能 +20%。',
    type: SkillType.passive,
    icon: Icons.view_module,
    costSkillPoints: 1,
    prerequisites: ['skill_shard_boost'],
  ),
  SkillDefinition(
    id: 'skill_blueprint_boost',
    name: '蓝图优化',
    description: '蓝图产出 +20%。',
    type: SkillType.passive,
    icon: Icons.auto_awesome,
    costSkillPoints: 2,
    prerequisites: ['skill_conversion_boost'],
  ),
  SkillDefinition(
    id: 'skill_energy_saver',
    name: '能量节流',
    description: '合成能耗 -10%。',
    type: SkillType.passive,
    icon: Icons.battery_saver,
    costSkillPoints: 1,
    prerequisites: ['skill_conversion_boost'],
  ),
  SkillDefinition(
    id: 'skill_cost_stabilizer',
    name: '稳定增殖',
    description: '采集成本增长 -0.02。',
    type: SkillType.passive,
    icon: Icons.timeline,
    costSkillPoints: 2,
    prerequisites: ['skill_shard_boost'],
  ),
];

final Map<String, SkillDefinition> skillById = {
  for (final def in skillDefinitions) def.id: def,
};

bool skillPrerequisitesMet(GameState state, SkillDefinition def) {
  return def.prerequisites.every(state.unlockedSkills.contains);
}

ResearchEffects computeSkillEffects(GameState state) {
  var effects = ResearchEffects.base;
  for (final id in state.equippedSkills) {
    final def = skillById[id];
    if (def == null || def.type != SkillType.passive) {
      continue;
    }
    switch (def.id) {
      case 'skill_shard_boost':
        effects = effects.copyWith(
          shardProductionMultiplier: effects.shardProductionMultiplier * 1.15,
        );
        break;
      case 'skill_conversion_boost':
        effects = effects.copyWith(
          shardToPartEfficiencyMultiplier:
              effects.shardToPartEfficiencyMultiplier * 1.15,
        );
        break;
      case 'skill_capacity_boost':
        effects = effects.copyWith(
          shardConversionCapacityMultiplier:
              effects.shardConversionCapacityMultiplier * 1.20,
        );
        break;
      case 'skill_blueprint_boost':
        effects = effects.copyWith(
          blueprintProductionMultiplier:
              effects.blueprintProductionMultiplier * 1.20,
        );
        break;
      case 'skill_energy_saver':
        effects = effects.copyWith(
          energyNeedMultiplier: effects.energyNeedMultiplier * 0.90,
        );
        break;
      case 'skill_cost_stabilizer':
        effects = effects.copyWith(
          shardCostGrowthOffset: effects.shardCostGrowthOffset - 0.02,
        );
        break;
    }
  }
  return effects;
}

List<SkillDefinition> equippedActiveSkills(GameState state) {
  final result = <SkillDefinition>[];
  for (final id in state.equippedSkills) {
    final def = skillById[id];
    if (def != null && def.type == SkillType.active) {
      result.add(def);
    }
  }
  return result;
}
