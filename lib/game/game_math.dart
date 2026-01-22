import 'dart:math' as math;

import 'game_definitions.dart';
import 'game_state.dart';
import 'research_definitions.dart';
import 'constant_upgrades.dart';

/// 游戏资源生产速率类
///
/// 用于计算和存储游戏中各种资源的每秒生产、消耗和转化速率。
/// 这些速率基于当前的游戏状态（GameState）、研究效果（ResearchEffects）和常量效果（ConstantEffects）计算得出。
class GameRates {
  const GameRates({
    required this.shardPerSec,
    required this.partGainPerSec,
    required this.partUsePerSec,
    required this.blueprintPerSec,
    required this.energyPerSec,
    required this.synthesisEfficiency,
    required this.shardConvertiblePerSec,
    required this.partsToBlueprintPerSec,
    required this.energyNeedPerSec,
    required this.partBottleneck,
    required this.energyOverload,
  });

  /// 碎片每秒生产量
  final double shardPerSec;

  /// 零件每秒获得量（通过转换碎片获得）
  final double partGainPerSec;

  /// 零件每秒消耗量（用于合成蓝图）
  final double partUsePerSec;

  /// 蓝图每秒生产量
  final double blueprintPerSec;

  /// 能量每秒生产量
  final double energyPerSec;

  /// 合成效率 (0.0 - 1.0)
  ///
  /// 受能量供应限制。如果能量不足，效率会降低。
  final double synthesisEfficiency;

  /// 实际每秒可转换的碎片数量
  ///
  /// 受限于转换能力、碎片产量和储备设置。
  final double shardConvertiblePerSec;

  /// 实际每秒用于合成蓝图的零件数量
  ///
  /// 受限于合成能力、零件库存和能量效率。
  final double partsToBlueprintPerSec;

  /// 每秒所需的能量总量（用于零件合成）
  final double energyNeedPerSec;

  /// 是否因为零件不足而限制了蓝图合成
  final bool partBottleneck;

  /// 是否出现能量过载
  final bool energyOverload;

  /// 零件每秒净增量（获得量 - 消耗量）
  double get partNetPerSec => partGainPerSec - partUsePerSec;

  /// 根据当前游戏状态计算各种速率
  ///
  /// [state] 当前游戏状态，包含资源数量、建筑数量等。
  /// [effects] 研究带来的加成效果。
  /// [constants] 全局常量效果（如生产倍率、速度倍率）。
  factory GameRates.fromState(
    GameState state,
    ResearchEffects effects,
    ConstantEffects constants,
  ) {
    // 计算基础生产速率，应用全局生产倍率
    final baseShardProd =
        shardProductionPerSec(state, effects) * constants.productionMultiplier;
    final baseEnergyProd =
        energyProductionPerSec(state, effects) * constants.productionMultiplier;
    final baseShardConvertCap =
        shardConversionCapacityPerSec(state, effects) *
        constants.productionMultiplier;
    final basePartSynthesisCap =
        partSynthesisCapacityPerSec(state, effects) *
        constants.productionMultiplier;
    final energyNeed = partSynthesisEnergyNeedPerSec(state, effects);

    // 能量过载时，对全局产出施加惩罚
    final energyAvailableBase = baseEnergyProd * state.energyToSynthesisRatio;
    final overloadFactor = energyNeed <= 0
        ? 1.0
        : math.min(1.0, energyAvailableBase / energyNeed);
    final energyOverload = overloadFactor < 1.0;

    final shardProd = baseShardProd * overloadFactor;
    final energyProd = baseEnergyProd * overloadFactor;
    final shardConvertCap = baseShardConvertCap * overloadFactor;
    final partSynthesisCap = basePartSynthesisCap * overloadFactor;

    // 计算实际可转换的碎片数量
    // 取转换能力和当前产量的较小值（受分配比例限制）
    var shardConvertible = math.min(
      shardConvertCap,
      shardProd * state.shardToPartRatio,
    );

    // 如果启用了保留碎片储备功能
    if (state.keepShardReserve) {
      // 计算超出储备量的可用碎片
      final maxByReserve = math.max(
        0.0,
        state.resource(ResourceType.shard) - state.shardReserveMin,
      );
      // 进一步限制可转换数量
      shardConvertible = math.min(shardConvertible, maxByReserve);
    }

    // 计算零件获得量
    // 碎片 -> 零件 的转换公式
    final partGain =
        shardConvertible /
        shardsPerPart *
        effects.shardToPartEfficiencyMultiplier;

    // 计算能量效率
    // 能量主要用于零件合成蓝图的过程
    final energyAvailable = energyProd * state.energyToSynthesisRatio;
    final efficiency = energyNeed <= 0
        ? 0.0
        : math.min(1.0, energyAvailable / energyNeed);

    // 计算实际可转换的零件数量（用于合成蓝图）
    // 基础能力 * 能量效率
    var partsConvertible = partSynthesisCap * efficiency;
    final partBottleneck = state.resource(ResourceType.part) < partsConvertible;
    // 不能超过当前拥有的零件数量
    partsConvertible = math.min(
      partsConvertible,
      state.resource(ResourceType.part),
    );

    // 计算蓝图产量
    // 零件 -> 蓝图 的转换公式
    final blueprintPerSec =
        partsConvertible /
        partsPerBlueprint *
        effects.blueprintProductionMultiplier;

    // 返回计算结果，应用全局速度倍率
    return GameRates(
      shardPerSec: shardProd * constants.speedMultiplier,
      partGainPerSec: partGain * constants.speedMultiplier,
      partUsePerSec: partsConvertible * constants.speedMultiplier,
      blueprintPerSec: blueprintPerSec * constants.speedMultiplier,
      energyPerSec: energyProd * constants.speedMultiplier,
      synthesisEfficiency: efficiency,
      shardConvertiblePerSec: shardConvertible * constants.speedMultiplier,
      partsToBlueprintPerSec: partsConvertible * constants.speedMultiplier,
      energyNeedPerSec: energyNeed * constants.speedMultiplier,
      partBottleneck: partBottleneck,
      energyOverload: energyOverload,
    );
  }
}

/// 计算每秒碎片产量
///
/// 汇总所有碎片生产建筑的产出，并应用研究加成。
double shardProductionPerSec(GameState state, ResearchEffects effects) {
  return _sumOutput(state, BuildingType.shardProducer) *
      effects.shardProductionMultiplier;
}

/// 计算每秒能量产量
///
/// 汇总所有能量生产建筑的产出。
double energyProductionPerSec(GameState state, ResearchEffects effects) {
  return _sumOutput(state, BuildingType.energyProducer);
}

/// 计算每秒碎片转换能力（碎片 -> 零件）
///
/// 汇总所有碎片转换建筑的能力，并应用研究加成。
double shardConversionCapacityPerSec(GameState state, ResearchEffects effects) {
  return _sumOutput(state, BuildingType.shardToPart) *
      effects.shardConversionCapacityMultiplier;
}

/// 计算每秒零件合成能力（零件 -> 蓝图）
///
/// 汇总所有零件合成建筑的能力。
double partSynthesisCapacityPerSec(GameState state, ResearchEffects effects) {
  return _sumOutput(state, BuildingType.partToBlueprint);
}

/// 计算零件合成所需的能量（每秒）
///
/// 汇总所有零件合成建筑的能量消耗，并应用研究加成。
double partSynthesisEnergyNeedPerSec(GameState state, ResearchEffects effects) {
  var total = 0.0;
  for (final def in buildingDefinitions) {
    if (def.type != BuildingType.partToBlueprint) {
      continue;
    }
    total += def.energyCostPerSec * state.buildingCount(def.id);
  }
  return total * effects.energyNeedMultiplier;
}

/// 计算指定类型建筑的总产出
///
/// 遍历所有建筑定义，累加指定类型建筑的基础产出 * 当前数量。
double _sumOutput(GameState state, BuildingType type) {
  var total = 0.0;
  for (final def in buildingDefinitions) {
    if (def.type != type) {
      continue;
    }
    total += def.baseOutputPerSec * state.buildingCount(def.id);
  }
  return total;
}

/// 计算下一个建筑的造价
///
/// [def] 建筑定义
/// [currentCount] 当前拥有的数量
/// [effects] 研究效果（可能影响价格增长率）
double nextCost(
  BuildingDefinition def,
  int currentCount,
  ResearchEffects effects,
) {
  final growth = _effectiveGrowth(def, effects);
  return def.baseCost * math.pow(growth, currentCount).toDouble();
}

/// 计算购买多个建筑的总造价
///
/// [def] 建筑定义
/// [currentCount] 当前拥有的数量
/// [buyCount] 计划购买的数量
/// [effects] 研究效果
double totalCost(
  BuildingDefinition def,
  int currentCount,
  int buyCount,
  ResearchEffects effects,
) {
  if (buyCount <= 0) {
    return 0;
  }
  final growth = _effectiveGrowth(def, effects);
  if (growth == 1) {
    return def.baseCost * buyCount;
  }
  // 等比数列求和公式
  final growthPow = math.pow(growth, currentCount).toDouble();
  final numerator = math.pow(growth, buyCount).toDouble() - 1;
  return def.baseCost * growthPow * (numerator / (growth - 1));
}

/// 计算当前资金最多能购买多少个建筑
///
/// [def] 建筑定义
/// [currentCount] 当前拥有的数量
/// [currency] 当前拥有的货币量
/// [effects] 研究效果
int maxAffordable(
  BuildingDefinition def,
  int currentCount,
  double currency,
  ResearchEffects effects,
) {
  if (currency <= 0) {
    return 0;
  }
  final growth = _effectiveGrowth(def, effects);
  if (growth == 1) {
    return (currency / def.baseCost).floor();
  }
  // 逆向求解等比数列求和公式
  final growthPow = math.pow(growth, currentCount).toDouble();
  final normalized = (currency * (growth - 1)) / (def.baseCost * growthPow);
  if (normalized <= 0) {
    return 0;
  }
  final n = math.log(normalized + 1) / math.log(growth);
  return n.floor();
}

/// 获取实际的价格增长率
///
/// 某些研究效果可能会影响特定类型建筑的价格增长率。
double _effectiveGrowth(BuildingDefinition def, ResearchEffects effects) {
  var growth = def.costGrowth;
  if (def.type == BuildingType.shardProducer) {
    growth = math.max(1.01, growth + effects.shardCostGrowthOffset);
  }
  return growth;
}
