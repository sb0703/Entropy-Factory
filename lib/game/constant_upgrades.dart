import 'dart:math' as math;

import 'game_state.dart';

/// 常数升级类型枚举
enum ConstantUpgradeType {
  /// 生产倍率提升
  productionMultiplier,

  /// 游戏速度提升
  speedMultiplier,

  /// 离线收益时长上限提升
  offlineLimitHours,
}

/// 常数升级定义类
///
/// 定义了通过“宇宙常数”资源购买的永久升级项目。
class ConstantUpgradeDefinition {
  const ConstantUpgradeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.baseCost,
    required this.costGrowth,
    required this.effectPerLevel,
    required this.maxLevel,
  });

  /// 唯一标识符
  final String id;

  /// 显示名称
  final String name;

  /// 描述文本
  final String description;

  /// 升级类型
  final ConstantUpgradeType type;

  /// 基础造价（第1级的价格）
  final double baseCost;

  /// 造价增长系数
  final double costGrowth;

  /// 每级提升的效果数值
  final double effectPerLevel;

  /// 最大等级
  final int maxLevel;
}

/// 常数效果类
///
/// 汇总了所有常数升级带来的全局加成。
class ConstantEffects {
  const ConstantEffects({
    required this.productionMultiplier,
    required this.speedMultiplier,
    required this.offlineLimitSeconds,
  });

  /// 全局生产倍率（影响所有资源产出）
  final double productionMultiplier;

  /// 全局速度倍率（加快游戏进程）
  final double speedMultiplier;

  /// 离线收益计算的最大时长（秒）
  final double offlineLimitSeconds;
}

/// 基础离线时长（小时）
const double baseOfflineHours = 4;

/// 最大可能的离线时长（小时，即使升级也无法超过此限制）
const double maxOfflineHours = 24;

/// 所有常数升级项目的定义列表
const List<ConstantUpgradeDefinition> constantUpgradeDefinitions = [
  ConstantUpgradeDefinition(
    id: 'production_boost',
    name: '产出强化',
    description: '全局产出 +10%',
    type: ConstantUpgradeType.productionMultiplier,
    baseCost: 10,
    costGrowth: 1.5,
    effectPerLevel: 0.10,
    maxLevel: 20,
  ),
  ConstantUpgradeDefinition(
    id: 'speed_boost',
    name: '时间压缩',
    description: '全局速度 +5%',
    type: ConstantUpgradeType.speedMultiplier,
    baseCost: 15,
    costGrowth: 1.6,
    effectPerLevel: 0.05,
    maxLevel: 20,
  ),
  ConstantUpgradeDefinition(
    id: 'offline_limit',
    name: '离线时长',
    description: '离线收益时长 +2 小时',
    type: ConstantUpgradeType.offlineLimitHours,
    baseCost: 8,
    costGrowth: 1.4,
    effectPerLevel: 2,
    maxLevel: 10,
  ),
];

/// 通过 ID 快速查找常数升级定义的映射表
final Map<String, ConstantUpgradeDefinition> constantUpgradeById = {
  for (final def in constantUpgradeDefinitions) def.id: def,
};

/// 计算指定等级的升级成本
double constantUpgradeCost(ConstantUpgradeDefinition def, int level) {
  return def.baseCost * math.pow(def.costGrowth, level).toDouble();
}

/// 获取当前升级等级
int constantUpgradeLevel(GameState state, String id) {
  return state.constantUpgrades[id] ?? 0;
}

/// 计算当前所有常数升级的总效果
ConstantEffects computeConstantEffects(GameState state) {
  var productionMultiplier = 1.0;
  var speedMultiplier = 1.0;
  var offlineHours = baseOfflineHours;

  for (final def in constantUpgradeDefinitions) {
    final level = constantUpgradeLevel(state, def.id);
    if (level <= 0) {
      continue;
    }
    switch (def.type) {
      case ConstantUpgradeType.productionMultiplier:
        productionMultiplier += level * def.effectPerLevel;
        break;
      case ConstantUpgradeType.speedMultiplier:
        speedMultiplier += level * def.effectPerLevel;
        break;
      case ConstantUpgradeType.offlineLimitHours:
        offlineHours += level * def.effectPerLevel;
        break;
    }
  }

  // 限制最大离线时长
  if (offlineHours > maxOfflineHours) {
    offlineHours = maxOfflineHours;
  }

  return ConstantEffects(
    productionMultiplier: productionMultiplier,
    speedMultiplier: speedMultiplier,
    offlineLimitSeconds: offlineHours * 60 * 60,
  );
}
