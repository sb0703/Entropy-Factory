import 'dart:math' as math;

import 'game_state.dart';
import 'research_definitions.dart';

/// 设施协同加成：根据设施数量触发类型协同。
ResearchEffects computeSynergyEffects(GameState state) {
  final energyCount = state.buildingCount('fusion');
  final shardCount = state.buildingCount('miner') +
      state.buildingCount('drill') +
      state.buildingCount('core_rig') +
      state.buildingCount('orbital_array');
  final converterCount = state.buildingCount('compressor');
  final blueprintCount = state.buildingCount('furnace');

  final shardBonus = 1 + 0.02 * (energyCount ~/ 5);
  final conversionBonus = 1 + 0.02 * (shardCount ~/ 10);
  final efficiencyBonus = 1 + 0.02 * (converterCount ~/ 8);
  final blueprintBonus = 1 + 0.03 * (blueprintCount ~/ 5);
  final adjacencyPairs = math.min(energyCount, shardCount);
  final adjacencyBonus = 1 + 0.01 * (adjacencyPairs ~/ 5);

  return ResearchEffects.base.copyWith(
    shardProductionMultiplier: shardBonus * adjacencyBonus,
    shardConversionCapacityMultiplier: conversionBonus,
    shardToPartEfficiencyMultiplier: efficiencyBonus,
    blueprintProductionMultiplier: blueprintBonus,
  );
}
