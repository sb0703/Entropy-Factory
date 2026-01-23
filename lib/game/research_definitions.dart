import 'package:flutter/foundation.dart';

import 'game_state.dart';

/// 研究分支枚举
enum ResearchBranch {
  /// 工业：偏重资源生产
  industry,

  /// 算法：偏重转换效率
  algorithm,

  /// 宇宙：偏重高级功能与合成
  cosmos,
}

/// 研究项目定义
@immutable
class ResearchDefinition {
  const ResearchDefinition({
    required this.id,
    required this.branch,
    required this.costBlueprints,
    this.prerequisites = const [],
  });

  /// 唯一标识符
  final String id;

  /// 所属分支
  final ResearchBranch branch;

  /// 研发成本（蓝图数量）
  final double costBlueprints;

  /// 前置研究 ID 列表
  final List<String> prerequisites;
}

/// 研究效果
@immutable
class ResearchEffects {
  const ResearchEffects({
    required this.shardProductionMultiplier,
    required this.shardCostGrowthOffset,
    required this.shardToPartEfficiencyMultiplier,
    required this.shardConversionCapacityMultiplier,
    required this.blueprintProductionMultiplier,
    required this.energyNeedMultiplier,
  });

  /// 基础效果（无加成）
  static const base = ResearchEffects(
    shardProductionMultiplier: 1.0,
    shardCostGrowthOffset: 0.0,
    shardToPartEfficiencyMultiplier: 1.0,
    shardConversionCapacityMultiplier: 1.0,
    blueprintProductionMultiplier: 1.0,
    energyNeedMultiplier: 1.0,
  );

  /// 碎片产量倍率
  final double shardProductionMultiplier;

  /// 碎片设施造价增长偏移（负数表示降低增长速度）
  final double shardCostGrowthOffset;

  /// 碎片转零件效率倍率
  final double shardToPartEfficiencyMultiplier;

  /// 碎片转换产能倍率
  final double shardConversionCapacityMultiplier;

  /// 蓝图产量倍率
  final double blueprintProductionMultiplier;

  /// 能量需求倍率（越小越节能）
  final double energyNeedMultiplier;

  /// 合并两个效果对象（乘法叠加）
  ResearchEffects combine(ResearchEffects other) {
    return ResearchEffects(
      shardProductionMultiplier:
          shardProductionMultiplier * other.shardProductionMultiplier,
      shardCostGrowthOffset:
          shardCostGrowthOffset + other.shardCostGrowthOffset,
      shardToPartEfficiencyMultiplier:
          shardToPartEfficiencyMultiplier *
          other.shardToPartEfficiencyMultiplier,
      shardConversionCapacityMultiplier:
          shardConversionCapacityMultiplier *
          other.shardConversionCapacityMultiplier,
      blueprintProductionMultiplier:
          blueprintProductionMultiplier * other.blueprintProductionMultiplier,
      energyNeedMultiplier: energyNeedMultiplier * other.energyNeedMultiplier,
    );
  }

  /// 复制并修改部分属性
  ResearchEffects copyWith({
    double? shardProductionMultiplier,
    double? shardCostGrowthOffset,
    double? shardToPartEfficiencyMultiplier,
    double? shardConversionCapacityMultiplier,
    double? blueprintProductionMultiplier,
    double? energyNeedMultiplier,
  }) {
    return ResearchEffects(
      shardProductionMultiplier:
          shardProductionMultiplier ?? this.shardProductionMultiplier,
      shardCostGrowthOffset:
          shardCostGrowthOffset ?? this.shardCostGrowthOffset,
      shardToPartEfficiencyMultiplier:
          shardToPartEfficiencyMultiplier ??
          this.shardToPartEfficiencyMultiplier,
      shardConversionCapacityMultiplier:
          shardConversionCapacityMultiplier ??
          this.shardConversionCapacityMultiplier,
      blueprintProductionMultiplier:
          blueprintProductionMultiplier ?? this.blueprintProductionMultiplier,
      energyNeedMultiplier: energyNeedMultiplier ?? this.energyNeedMultiplier,
    );
  }
}

/// 游戏内所有研究项目的定义列表
const List<ResearchDefinition> researchDefinitions = [
  ResearchDefinition(
    id: 'industry_1',
    branch: ResearchBranch.industry,
    costBlueprints: 5,
  ),
  ResearchDefinition(
    id: 'industry_2',
    branch: ResearchBranch.industry,
    costBlueprints: 12,
    prerequisites: ['industry_1'],
  ),
  ResearchDefinition(
    id: 'industry_3',
    branch: ResearchBranch.industry,
    costBlueprints: 30,
    prerequisites: ['industry_2'],
  ),
  ResearchDefinition(
    id: 'industry_layout',
    branch: ResearchBranch.industry,
    costBlueprints: 20,
    prerequisites: ['industry_2'],
  ),
  ResearchDefinition(
    id: 'industry_layout_2',
    branch: ResearchBranch.industry,
    costBlueprints: 45,
    prerequisites: ['industry_layout'],
  ),
  ResearchDefinition(
    id: 'industry_layout_3',
    branch: ResearchBranch.industry,
    costBlueprints: 75,
    prerequisites: ['industry_layout_2'],
  ),
  ResearchDefinition(
    id: 'algorithm_1',
    branch: ResearchBranch.algorithm,
    costBlueprints: 8,
  ),
  ResearchDefinition(
    id: 'algorithm_2',
    branch: ResearchBranch.algorithm,
    costBlueprints: 18,
    prerequisites: ['algorithm_1'],
  ),
  ResearchDefinition(
    id: 'algorithm_3',
    branch: ResearchBranch.algorithm,
    costBlueprints: 40,
    prerequisites: ['algorithm_2'],
  ),
  ResearchDefinition(
    id: 'algorithm_4',
    branch: ResearchBranch.algorithm,
    costBlueprints: 60,
    prerequisites: ['algorithm_3'],
  ),
  ResearchDefinition(
    id: 'cosmos_1',
    branch: ResearchBranch.cosmos,
    costBlueprints: 15,
  ),
  ResearchDefinition(
    id: 'cosmos_2',
    branch: ResearchBranch.cosmos,
    costBlueprints: 30,
    prerequisites: ['cosmos_1'],
  ),
  ResearchDefinition(
    id: 'cosmos_3',
    branch: ResearchBranch.cosmos,
    costBlueprints: 50,
    prerequisites: ['cosmos_2'],
  ),
  ResearchDefinition(
    id: 'cosmos_4',
    branch: ResearchBranch.cosmos,
    costBlueprints: 80,
    prerequisites: ['cosmos_3'],
  ),
];

/// 通过 ID 快速查找研究定义的映射表
final Map<String, ResearchDefinition> researchById = {
  for (final def in researchDefinitions) def.id: def,
};

/// 检查是否满足研究的前置条件
bool researchPrerequisitesMet(GameState state, ResearchDefinition def) {
  return def.prerequisites.every(state.researchPurchased.contains);
}

/// 计算当前已购买研究的总效果
ResearchEffects computeResearchEffects(GameState state) {
  var effects = ResearchEffects.base;
  for (final id in state.researchPurchased) {
    switch (id) {
      case 'industry_1':
        effects = effects.copyWith(
          shardProductionMultiplier: effects.shardProductionMultiplier * 2.0,
        );
        break;
      case 'industry_2':
        effects = effects.copyWith(
          shardCostGrowthOffset: effects.shardCostGrowthOffset - 0.02,
        );
        break;
      case 'industry_3':
        effects = effects.copyWith(
          shardProductionMultiplier: effects.shardProductionMultiplier * 1.5,
        );
        break;
      case 'algorithm_1':
        effects = effects.copyWith(
          shardToPartEfficiencyMultiplier:
              effects.shardToPartEfficiencyMultiplier * 1.2,
        );
        break;
      case 'algorithm_2':
        effects = effects.copyWith(
          shardConversionCapacityMultiplier:
              effects.shardConversionCapacityMultiplier * 1.2,
        );
        break;
      case 'algorithm_3':
        effects = effects.copyWith(
          shardToPartEfficiencyMultiplier:
              effects.shardToPartEfficiencyMultiplier * 1.25,
        );
        break;
      case 'algorithm_4':
        effects = effects.copyWith(
          shardConversionCapacityMultiplier:
              effects.shardConversionCapacityMultiplier * 1.3,
        );
        break;
      case 'cosmos_1':
        effects = effects.copyWith(
          energyNeedMultiplier: effects.energyNeedMultiplier * 0.9,
        );
        break;
      case 'cosmos_2':
        effects = effects.copyWith(
          blueprintProductionMultiplier:
              effects.blueprintProductionMultiplier * 1.25,
        );
        break;
      case 'cosmos_3':
        effects = effects.copyWith(
          blueprintProductionMultiplier:
              effects.blueprintProductionMultiplier * 1.35,
        );
        break;
      case 'cosmos_4':
        effects = effects.copyWith(
          energyNeedMultiplier: effects.energyNeedMultiplier * 0.85,
        );
        break;
    }
  }
  return effects;
}

/// 获取研究项目的标题
String researchTitle(String id) {
  switch (id) {
    case 'industry_1':
      return '工业-1';
    case 'industry_2':
      return '工业-2';
    case 'industry_3':
      return '工业-3';
    case 'industry_layout':
      return '设施布局-1';
    case 'industry_layout_2':
      return '设施布局-2';
    case 'industry_layout_3':
      return '设施布局-3';
    case 'algorithm_1':
      return '算法-1';
    case 'algorithm_2':
      return '算法-2';
    case 'algorithm_3':
      return '算法-3';
    case 'algorithm_4':
      return '算法-4';
    case 'cosmos_1':
      return '宇宙-1';
    case 'cosmos_2':
      return '宇宙-2';
    case 'cosmos_3':
      return '宇宙-3';
    case 'cosmos_4':
      return '宇宙-4';
    default:
      return id;
  }
}

/// 获取研究项目的描述
String researchDescription(String id) {
  switch (id) {
    case 'industry_1':
      return '采集设施产出 x2';
    case 'industry_2':
      return '采集设施成本增长 -0.02';
    case 'industry_3':
      return '采集设施产出 +50%';
    case 'industry_layout':
      return '解锁设施布局（3x3）与邻接加成';
    case 'industry_layout_2':
      return '布局扩展至 4x4';
    case 'industry_layout_3':
      return '布局扩展至 5x4';
    case 'algorithm_1':
      return '碎片转换效率 +20%';
    case 'algorithm_2':
      return '转换设施产能 +20%';
    case 'algorithm_3':
      return '碎片转换效率 +25%';
    case 'algorithm_4':
      return '转换设施产能 +30%';
    case 'cosmos_1':
      return '合成能耗 -10%';
    case 'cosmos_2':
      return '蓝图产出 +25%，解锁离线合成';
    case 'cosmos_3':
      return '蓝图产出 +35%';
    case 'cosmos_4':
      return '合成能耗 -15%';
    default:
      return '效果未知';
  }
}

/// 检查是否解锁了离线合成功能
bool offlineSynthesisUnlocked(GameState state) {
  return state.researchPurchased.contains('cosmos_2');
}
