import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'big_number.dart';
import 'constant_upgrades.dart';
import 'game_controller.dart';
import 'game_definitions.dart';
import 'game_math.dart';
import 'game_state.dart';
import 'milestone_definitions.dart';
import 'number_format.dart';
import 'research_definitions.dart';
import 'run_modifiers.dart';

@immutable
class ResourceDisplay {
  const ResourceDisplay({
    required this.type,
    required this.label,
    required this.amount,
    required this.value,
    required this.tone,
    this.isAlert = false,
  });

  final ResourceType type;
  final String label;
  final double amount;
  final String value;
  final Color tone;
  final bool isAlert;
}

@immutable
class RateSummary {
  const RateSummary({
    required this.shardsPerSec,
    required this.partsPerSec,
    required this.blueprintsPerMin,
    required this.energyPerSec,
    required this.synthesisEff,
  });

  final String shardsPerSec;
  final String partsPerSec;
  final String blueprintsPerMin;
  final String energyPerSec;
  final String synthesisEff;
}

@immutable
class BuildingDisplay {
  const BuildingDisplay({
    required this.id,
    required this.name,
    required this.count,
    required this.output,
    required this.outputResource,
    required this.description,
    required this.costText,
    this.affordabilityText,
    required this.canBuyOne,
    required this.canBuyTen,
    required this.canBuyMax,
    this.badge,
  });

  final String id;
  final String name;
  final int count;
  final String output;
  final ResourceType? outputResource;
  final String description;
  final String costText;
  final String? affordabilityText;
  final bool canBuyOne;
  final bool canBuyTen;
  final bool canBuyMax;
  final String? badge;
}

@immutable
class ResearchNodeDisplay {
  const ResearchNodeDisplay({
    required this.id,
    required this.branch,
    required this.title,
    required this.cost,
    required this.description,
    required this.prerequisiteText,
    required this.status,
    required this.canBuy,
  });

  final String id;
  final ResearchBranch branch;
  final String title;
  final String cost;
  final String description;
  final String prerequisiteText;
  final ResearchStatus status;
  final bool canBuy;
}

enum ResearchStatus { locked, available, purchased }

@immutable
class LogEntry {
  const LogEntry({
    required this.title,
    required this.detail,
    required this.timeLabel,
  });

  final String title;
  final String detail;
  final String timeLabel;
}

@immutable
class MilestoneDisplay {
  const MilestoneDisplay({
    required this.title,
    required this.description,
    required this.effectText,
    required this.achieved,
  });

  final String title;
  final String description;
  final String effectText;
  final bool achieved;
}

@immutable
class GameUiState {
  const GameUiState({
    required this.resources,
    required this.rateSummary,
    required this.buildings,
    required this.researchNodes,
    required this.milestones,
    required this.logEntries,
    required this.partBottleneck,
    required this.energyOverload,
  });

  final List<ResourceDisplay> resources;
  final RateSummary rateSummary;
  final List<BuildingDisplay> buildings;
  final List<ResearchNodeDisplay> researchNodes;
  final List<MilestoneDisplay> milestones;
  final List<LogEntry> logEntries;
  final bool partBottleneck;
  final bool energyOverload;

  static GameUiState fromState(
    GameState state,
    GameRates rates,
    ResearchEffects effects,
  ) {
    return GameUiState(
      resources: [
        ResourceDisplay(
          type: ResourceType.shard,
          label: '碎片',
          amount: state.resourceAsDouble(ResourceType.shard),
          value: _formatNumber(state.resource(ResourceType.shard)),
          tone: const Color(0xFF5CE1E6),
        ),
        ResourceDisplay(
          type: ResourceType.part,
          label: '零件',
          amount: state.resourceAsDouble(ResourceType.part),
          value: _formatNumber(state.resource(ResourceType.part)),
          tone: const Color(0xFF8BE4B4),
          isAlert: rates.partBottleneck,
        ),
        ResourceDisplay(
          type: ResourceType.blueprint,
          label: '蓝图',
          amount: state.resourceAsDouble(ResourceType.blueprint),
          value: _formatNumber(state.resource(ResourceType.blueprint)),
          tone: const Color(0xFFF5C542),
        ),
        ResourceDisplay(
          type: ResourceType.law,
          label: '定律',
          amount: state.resourceAsDouble(ResourceType.law),
          value: _formatNumber(state.resource(ResourceType.law)),
          tone: const Color(0xFF9D7CFF),
        ),
        ResourceDisplay(
          type: ResourceType.constant,
          label: '常数',
          amount: state.resourceAsDouble(ResourceType.constant),
          value: _formatNumber(state.resource(ResourceType.constant)),
          tone: const Color(0xFFF5F1E1),
        ),
      ],
      rateSummary: RateSummary(
        shardsPerSec: _formatSignedRate(rates.shardPerSec),
        partsPerSec: _formatSignedRate(rates.partNetPerSec),
        blueprintsPerMin: _formatSignedRate(rates.blueprintPerSec * 60),
        energyPerSec: _formatSignedRate(rates.energyPerSec),
        synthesisEff: _formatPercent(rates.synthesisEfficiency),
      ),
      buildings: [
        for (final def in buildingDefinitions)
          _buildBuildingDisplay(def, state, effects),
      ],
      researchNodes: [
        for (final def in researchDefinitions)
          _buildResearchDisplay(def, state),
      ],
      milestones: [
        for (final def in milestoneDefinitions)
          MilestoneDisplay(
            title: def.title,
            description: def.description,
            effectText: _milestoneEffectText(def.effects),
            achieved: state.milestonesAchieved.contains(def.id),
          ),
      ],
      logEntries: [
        for (final entry in state.logEntries)
          LogEntry(
            title: entry.title,
            detail: entry.detail,
            timeLabel: _formatLogTime(entry.timeMs),
          ),
      ],
      partBottleneck: rates.partBottleneck,
      energyOverload: rates.energyOverload,
    );
  }
}

final gameUiProvider = Provider<GameUiState>((ref) {
  final state = ref.watch(gameControllerProvider);
  final effects = computeResearchEffects(state)
      .combine(computeMilestoneEffects(state))
      .combine(computeSynergyEffects(state))
      .combine(computeRunModifierEffects(state));
  final constants = computeConstantEffects(state);
  final rates = GameRates.fromState(state, effects, constants);
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final timeWarpMultiplier = state.timeWarpEndsAtMs > nowMs ? 2.0 : 1.0;
  final overclockActive = state.overclockEndsAtMs > nowMs;
  var adjustedRates = timeWarpMultiplier == 1.0
      ? rates
      : _scaleRates(rates, timeWarpMultiplier);
  if (overclockActive) {
    adjustedRates = _applyOverclock(adjustedRates, state);
  }
  return GameUiState.fromState(state, adjustedRates, effects);
});

GameRates _scaleRates(GameRates rates, double multiplier) {
  return GameRates(
    shardPerSec: rates.shardPerSec * multiplier,
    partGainPerSec: rates.partGainPerSec * multiplier,
    partUsePerSec: rates.partUsePerSec * multiplier,
    blueprintPerSec: rates.blueprintPerSec * multiplier,
    energyPerSec: rates.energyPerSec * multiplier,
    synthesisEfficiency: rates.synthesisEfficiency,
    shardConvertiblePerSec: rates.shardConvertiblePerSec * multiplier,
    partsToBlueprintPerSec: rates.partsToBlueprintPerSec * multiplier,
    energyNeedPerSec: rates.energyNeedPerSec * multiplier,
    partBottleneck: rates.partBottleneck,
    energyOverload: rates.energyOverload,
  );
}

GameRates _applyOverclock(GameRates rates, GameState state) {
  final multiplier = 1.4 + state.overclockLevel * 0.15;
  return GameRates(
    shardPerSec: rates.shardPerSec,
    partGainPerSec: rates.partGainPerSec * multiplier,
    partUsePerSec: rates.partUsePerSec * multiplier,
    blueprintPerSec: rates.blueprintPerSec * multiplier,
    energyPerSec: rates.energyPerSec,
    synthesisEfficiency: rates.synthesisEfficiency,
    shardConvertiblePerSec: rates.shardConvertiblePerSec * multiplier,
    partsToBlueprintPerSec: rates.partsToBlueprintPerSec * multiplier,
    energyNeedPerSec: rates.energyNeedPerSec,
    partBottleneck: rates.partBottleneck,
    energyOverload: rates.energyOverload,
  );
}

BuildingDisplay _buildBuildingDisplay(
  BuildingDefinition def,
  GameState state,
  ResearchEffects effects,
) {
  final count = state.buildingCount(def.id);
  final output = _outputText(def, state, count, effects);
  final badge = switch (def.type) {
    BuildingType.shardToPart => '配比',
    BuildingType.partToBlueprint => '能量',
    _ => null,
  };
  final currency = state.resource(def.costResource);
  final next = nextCost(def, count, effects);
  final costTen = totalCost(def, count, 10, effects);
  final maxBuy = maxAffordable(def, count, currency, effects);
  final resourceName = _resourceName(def.costResource);
  final costText = '成本：${_formatNumber(next)} $resourceName';
  final affordabilityText = maxBuy > 0 ? '可购买：$maxBuy' : '资源不足';
  final canBuyOne = currency >= next;
  final canBuyTen = maxBuy >= 10 && currency >= costTen;
  final canBuyMax = maxBuy > 0;
  final outputResource = _outputResourceFor(def.type);

  return BuildingDisplay(
    id: def.id,
    name: def.name,
    count: count,
    output: output,
    outputResource: outputResource,
    description: def.description,
    costText: costText,
    affordabilityText: affordabilityText,
    canBuyOne: canBuyOne,
    canBuyTen: canBuyTen,
    canBuyMax: canBuyMax,
    badge: badge,
  );
}

ResourceType? _outputResourceFor(BuildingType type) {
  switch (type) {
    case BuildingType.shardProducer:
      return ResourceType.shard;
    case BuildingType.shardToPart:
      return ResourceType.part;
    case BuildingType.partToBlueprint:
      return ResourceType.blueprint;
    case BuildingType.energyProducer:
      return null;
  }
}

ResearchNodeDisplay _buildResearchDisplay(
  ResearchDefinition def,
  GameState state,
) {
  final isPurchased = state.researchPurchased.contains(def.id);
  final prereqOk = researchPrerequisitesMet(state, def);
  final cost = BigNumber.fromDouble(def.costBlueprints);
  final canBuy =
      !isPurchased &&
      prereqOk &&
      state.resource(ResourceType.blueprint) >= cost;
  final status = isPurchased
      ? ResearchStatus.purchased
      : (prereqOk ? ResearchStatus.available : ResearchStatus.locked);
  final prereqText = def.prerequisites.isEmpty
      ? '无'
      : def.prerequisites.map(researchTitle).join('、');

  return ResearchNodeDisplay(
    id: def.id,
    branch: def.branch,
    title: researchTitle(def.id),
    description: researchDescription(def.id),
    cost: '蓝图 x${def.costBlueprints.toStringAsFixed(0)}',
    prerequisiteText: prereqText,
    status: status,
    canBuy: canBuy,
  );
}

String _outputText(
  BuildingDefinition def,
  GameState state,
  int count,
  ResearchEffects effects,
) {
  switch (def.type) {
    case BuildingType.shardProducer:
      return '+${_formatNumber(def.baseOutputPerSec * count * effects.shardProductionMultiplier)} / 秒';
    case BuildingType.energyProducer:
      return '+${_formatNumber(def.baseOutputPerSec * count)} 能量 / 秒';
    case BuildingType.shardToPart:
      return '碎片→零件（${(state.shardToPartRatio * 100).round()}%）';
    case BuildingType.partToBlueprint:
      return '零件→蓝图（${_formatNumber(def.baseOutputPerSec * count * effects.blueprintProductionMultiplier)} / 秒）';
  }
}

String _resourceName(ResourceType type) {
  switch (type) {
    case ResourceType.shard:
      return '碎片';
    case ResourceType.part:
      return '零件';
    case ResourceType.blueprint:
      return '蓝图';
    case ResourceType.law:
      return '定律';
    case ResourceType.constant:
      return '常数';
  }
}

String _milestoneEffectText(ResearchEffects effects) {
  final parts = <String>[];
  if (effects.shardProductionMultiplier != 1.0) {
    parts.add('采集产出 x${_formatFixed(effects.shardProductionMultiplier)}');
  }
  if (effects.shardCostGrowthOffset != 0.0) {
    final sign = effects.shardCostGrowthOffset > 0 ? '+' : '';
    parts.add(
      '采集成本增长 $sign${effects.shardCostGrowthOffset.toStringAsFixed(2)}',
    );
  }
  if (effects.shardToPartEfficiencyMultiplier != 1.0) {
    parts.add(
      '碎片转化效率 x${_formatFixed(effects.shardToPartEfficiencyMultiplier)}',
    );
  }
  if (effects.shardConversionCapacityMultiplier != 1.0) {
    parts.add(
      '转换产能 x${_formatFixed(effects.shardConversionCapacityMultiplier)}',
    );
  }
  if (effects.blueprintProductionMultiplier != 1.0) {
    parts.add('蓝图产出 x${_formatFixed(effects.blueprintProductionMultiplier)}');
  }
  if (effects.energyNeedMultiplier != 1.0) {
    parts.add('合成能耗 x${_formatFixed(effects.energyNeedMultiplier)}');
  }
  return parts.isEmpty ? '无加成' : parts.join(' / ');
}

String _formatLogTime(int timeMs) {
  if (timeMs == 0) {
    return '刚刚';
  }
  final now = DateTime.now().millisecondsSinceEpoch;
  final diffSeconds = ((now - timeMs) / 1000).round();
  if (diffSeconds < 60) {
    return '刚刚';
  }
  final diffMinutes = (diffSeconds / 60).round();
  if (diffMinutes < 60) {
    return '$diffMinutes 分钟前';
  }
  final diffHours = (diffMinutes / 60).round();
  if (diffHours < 24) {
    return '$diffHours 小时前';
  }
  final diffDays = (diffHours / 24).round();
  return '$diffDays 天前';
}

String _formatPercent(double value) {
  return '${(value * 100).clamp(0, 100).round()}%';
}

String _formatSignedRate(double value) {
  final sign = value >= 0 ? '+' : '';
  return '$sign${_formatNumber(value)}';
}

String _formatNumber(Object value) {
  return formatNumber(value);
}

String _formatFixed(double value) {
  return formatFixed(value);
}
