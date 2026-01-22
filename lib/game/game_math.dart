import 'dart:math' as math;

import 'big_number.dart';
import 'constant_upgrades.dart';
import 'game_definitions.dart';
import 'game_state.dart';
import 'research_definitions.dart';

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

  final double shardPerSec;
  final double partGainPerSec;
  final double partUsePerSec;
  final double blueprintPerSec;
  final double energyPerSec;
  final double synthesisEfficiency;
  final double shardConvertiblePerSec;
  final double partsToBlueprintPerSec;
  final double energyNeedPerSec;
  final bool partBottleneck;
  final bool energyOverload;

  double get partNetPerSec => partGainPerSec - partUsePerSec;

  factory GameRates.fromState(
    GameState state,
    ResearchEffects effects,
    ConstantEffects constants,
  ) {
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

    final energySplit = effectiveEnergySplit(
      state: state,
      energyProd: baseEnergyProd,
      energyNeed: energyNeed,
    );
    final energyAvailableBase = baseEnergyProd * energySplit;
    final overloadFactor = energyNeed <= 0
        ? 1.0
        : math.min(1.0, energyAvailableBase / energyNeed);
    final energyOverload = overloadFactor < 1.0;

    final shardProd = baseShardProd * overloadFactor;
    final energyProd = baseEnergyProd * overloadFactor;
    final shardConvertCap = baseShardConvertCap * overloadFactor;
    final partSynthesisCap = basePartSynthesisCap * overloadFactor;

    var shardConvertible = math.min(
      shardConvertCap,
      shardProd * state.shardToPartRatio,
    );

    if (state.keepShardReserve) {
      final maxByReserve = math.max(
        0.0,
        state.resourceAsDouble(ResourceType.shard) - state.shardReserveMin,
      );
      shardConvertible = math.min(shardConvertible, maxByReserve);
    }

    final partGain =
        shardConvertible /
        shardsPerPart *
        effects.shardToPartEfficiencyMultiplier;

    final energyAvailable = energyProd * energySplit;
    final efficiency = energyNeed <= 0
        ? 0.0
        : math.min(1.0, energyAvailable / energyNeed);

    var partsConvertible = partSynthesisCap * efficiency;
    final partBottleneck =
        state.resourceAsDouble(ResourceType.part) < partsConvertible;
    partsConvertible = math.min(
      partsConvertible,
      state.resourceAsDouble(ResourceType.part),
    );

    final blueprintPerSec =
        partsConvertible /
        partsPerBlueprint *
        effects.blueprintProductionMultiplier;

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

double shardProductionPerSec(GameState state, ResearchEffects effects) {
  return _sumOutput(state, BuildingType.shardProducer) *
      effects.shardProductionMultiplier;
}

double energyProductionPerSec(GameState state, ResearchEffects effects) {
  return _sumOutput(state, BuildingType.energyProducer);
}

double shardConversionCapacityPerSec(GameState state, ResearchEffects effects) {
  return _sumOutput(state, BuildingType.shardToPart) *
      effects.shardConversionCapacityMultiplier;
}

double partSynthesisCapacityPerSec(GameState state, ResearchEffects effects) {
  return _sumOutput(state, BuildingType.partToBlueprint);
}

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

double _sumOutput(GameState state, BuildingType type) {
  var total = 0.0;
  final layout = state.layoutGrid;
  final hasLayout = layout.isNotEmpty;

  for (final def in buildingDefinitions) {
    if (def.type != type) {
      continue;
    }
    final owned = state.buildingCount(def.id);
    if (owned <= 0) {
      continue;
    }
    if (!hasLayout) {
      total += def.baseOutputPerSec * owned;
      continue;
    }

    var placed = 0;
    for (var i = 0; i < layout.length; i++) {
      final placedId = layout[i];
      if (placedId == def.id) {
        placed += 1;
        final bonus = _adjacencyBonus(layout, i, def.type);
        total += def.baseOutputPerSec * bonus;
      }
    }
    final remaining = math.max(0, owned - placed);
    if (remaining > 0) {
      total += def.baseOutputPerSec * remaining;
    }
  }

  return total;
}

double _adjacencyBonus(
  List<String?> layout,
  int index,
  BuildingType type,
) {
  final neighbors = _neighborIndices(index);
  var bonus = 1.0;
  for (final n in neighbors) {
    final neighborId = layout[n];
    if (neighborId == null) {
      continue;
    }
    final neighborDef = buildingById[neighborId];
    if (neighborDef == null) {
      continue;
    }
    switch (type) {
      case BuildingType.shardProducer:
        if (neighborDef.type == BuildingType.energyProducer) {
          bonus += 0.2;
        }
        break;
      case BuildingType.shardToPart:
        if (neighborDef.type == BuildingType.shardProducer) {
          bonus += 0.1;
        }
        break;
      case BuildingType.partToBlueprint:
        if (neighborDef.type == BuildingType.shardToPart) {
          bonus += 0.1;
        }
        break;
      case BuildingType.energyProducer:
        if (neighborDef.type == BuildingType.shardProducer) {
          bonus += 0.05;
        }
        break;
    }
  }
  return bonus;
}

List<int> _neighborIndices(int index) {
  final row = index ~/ layoutColumns;
  final col = index % layoutColumns;
  final neighbors = <int>[];
  if (row > 0) {
    neighbors.add(index - layoutColumns);
  }
  if (row < layoutRows - 1) {
    neighbors.add(index + layoutColumns);
  }
  if (col > 0) {
    neighbors.add(index - 1);
  }
  if (col < layoutColumns - 1) {
    neighbors.add(index + 1);
  }
  return neighbors;
}

double effectiveEnergySplit({
  required GameState state,
  required double energyProd,
  required double energyNeed,
}) {
  if (energyProd <= 0) {
    return state.energyToSynthesisRatio;
  }
  switch (state.energyPriorityMode) {
    case EnergyPriorityMode.synthesisFirst:
      if (energyNeed <= 0) {
        return state.energyToSynthesisRatio;
      }
      return math.min(1.0, energyNeed / energyProd);
    case EnergyPriorityMode.conversionFirst:
      return state.energyToSynthesisRatio;
  }
}

BigNumber nextCost(
  BuildingDefinition def,
  int currentCount,
  ResearchEffects effects,
) {
  final growth = _effectiveGrowth(def, effects);
  if (growth == 1) {
    return BigNumber.fromDouble(def.baseCost);
  }
  final log10Value =
      math.log(def.baseCost) / math.ln10 +
      currentCount * (math.log(growth) / math.ln10);
  return BigNumber.fromLog10(log10Value);
}

BigNumber totalCost(
  BuildingDefinition def,
  int currentCount,
  int buyCount,
  ResearchEffects effects,
) {
  if (buyCount <= 0) {
    return BigNumber.zero;
  }
  final growth = _effectiveGrowth(def, effects);
  if (growth == 1) {
    return BigNumber.fromDouble(def.baseCost * buyCount);
  }
  final base = BigNumber.fromDouble(def.baseCost);
  final logGrowth = math.log(growth) / math.ln10;
  final growthPow = BigNumber.fromLog10(currentCount * logGrowth);
  final growthPowBuy = BigNumber.fromLog10(buyCount * logGrowth);
  final numerator = growthPowBuy.exponent > 6
      ? growthPowBuy
      : growthPowBuy - BigNumber.one;
  final total = base * growthPow * numerator;
  return total.dividedByDouble(growth - 1);
}

int maxAffordable(
  BuildingDefinition def,
  int currentCount,
  BigNumber currency,
  ResearchEffects effects,
) {
  if (currency <= BigNumber.zero) {
    return 0;
  }
  final growth = _effectiveGrowth(def, effects);
  if (growth == 1) {
    return (currency.toDouble() / def.baseCost).floor();
  }
  final logGrowth = math.log(growth) / math.ln10;
  final logBase = math.log(def.baseCost) / math.ln10;
  final logCurrency = currency.log10();
  if (!logCurrency.isFinite) {
    return 0;
  }
  final normalizedLog10 =
      logCurrency + math.log(growth - 1) / math.ln10 - logBase - currentCount * logGrowth;
  if (normalizedLog10 <= 0) {
    return 0;
  }
  final n = normalizedLog10 / logGrowth;
  return n.floor();
}

double _effectiveGrowth(BuildingDefinition def, ResearchEffects effects) {
  var growth = def.costGrowth;
  if (def.type == BuildingType.shardProducer) {
    growth = math.max(1.01, growth + effects.shardCostGrowthOffset);
  }
  return growth;
}
