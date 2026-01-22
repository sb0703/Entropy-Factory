import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_definitions.dart';
import 'game_math.dart';
import 'game_state.dart';
import 'constant_upgrades.dart';
import 'milestone_definitions.dart';
import 'prestige_rules.dart';
import 'research_definitions.dart';
import 'synergy_rules.dart';
import 'number_format.dart';
import '../services/save_service.dart';

class GameController extends StateNotifier<GameState> {
  static const int _timeWarpDurationMs = 30000;
  static const int _timeWarpCooldownMs = 5 * 60 * 1000;
  static const int _timeWarpDurationPerLevelMs = 5000;
  static const int _timeWarpCooldownReductionPerLevelMs = 20000;
  static const int _timeWarpCooldownMinMs = 2 * 60 * 1000;
  static const double _timeWarpUpgradeBaseCost = 5;
  static const double _timeWarpUpgradeCostGrowth = 1.6;
  static const int _timeWarpMaxLevel = 6;
  static const int _overclockDurationMs = 20000;
  static const int _overclockCooldownMs = 3 * 60 * 1000;
  static const int _overclockDurationPerLevelMs = 4000;
  static const int _overclockCooldownReductionPerLevelMs = 15000;
  static const int _overclockCooldownMinMs = 90 * 1000;
  static const double _overclockUpgradeBaseCost = 4;
  static const double _overclockUpgradeCostGrowth = 1.5;
  static const int _overclockMaxLevel = 6;

  GameController() : super(GameState.initial()) {
    // 固定节拍推进游戏状态，保持数值稳定。
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick(1));
    _init();
  }

  Timer? _timer;
  Timer? _saveTimer;
  final SaveService _saveService = SaveService();

  void tick(double dtSeconds) {
    // 汇总研究/里程碑/常数的增益，并用同一帧时长完成产出与转化。
    final effects = _currentEffects(state);
    final constants = _currentConstants(state);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final timeWarpMultiplier = _isTimeWarpActive(state, nowMs) ? 2.0 : 1.0;
    final effectiveDt =
        dtSeconds * constants.speedMultiplier * timeWarpMultiplier;
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

    final shardProd = baseShardProd * overloadFactor;
    final energyProd = baseEnergyProd * overloadFactor;
    final overclockBoost = _isOverclockActive(state, nowMs)
        ? overclockMultiplier(state)
        : 1.0;
    final shardConvertCap = baseShardConvertCap * overloadFactor * overclockBoost;
    final partSynthesisCap = basePartSynthesisCap * overloadFactor * overclockBoost;

    // 读取资源快照，避免中途被更新影响计算。
    var shards = state.resource(ResourceType.shard);
    var parts = state.resource(ResourceType.part);
    var blueprints = state.resource(ResourceType.blueprint);
    var laws = state.resource(ResourceType.law);

    shards += shardProd * effectiveDt;

    var shardConvertible = math.min(
      shardConvertCap * effectiveDt,
      shardProd * state.shardToPartRatio * effectiveDt,
    );

    if (state.keepShardReserve) {
      final maxByReserve = math.max(0.0, shards - state.shardReserveMin);
      shardConvertible = math.min(shardConvertible, maxByReserve);
    }

    shardConvertible = math.min(shardConvertible, shards);
    shards -= shardConvertible;
    parts +=
        shardConvertible /
        shardsPerPart *
        effects.shardToPartEfficiencyMultiplier;

    final energyAvailable = energyProd * energySplit * effectiveDt;
    final energyNeeded = energyNeed * effectiveDt;
    final efficiency = energyNeeded <= 0
        ? 0.0
        : math.min(1.0, energyAvailable / energyNeeded);

    var partsConvertible = partSynthesisCap * efficiency * effectiveDt;
    partsConvertible = math.min(partsConvertible, parts);
    parts -= partsConvertible;
    blueprints +=
        partsConvertible /
        partsPerBlueprint *
        effects.blueprintProductionMultiplier;

    // 蓝图达到阈值时自动生成定律。
    final lawGain = lawsFromBlueprints(blueprints);
    if (lawGain > 0) {
      blueprints -= lawGain * lawThreshold;
      laws += lawGain;
    }

    var nextState = state.copyWith(
      resources: {
        ...state.resources,
        ResourceType.shard: shards,
        ResourceType.part: parts,
        ResourceType.blueprint: blueprints,
        ResourceType.law: laws,
      },
    );
    nextState = _applyMilestones(nextState);
    state = nextState;
  }

  Future<void> _init() async {
    // 启动时载入存档，并补算离线收益。
    final loaded = await _saveService.loadState();
    if (loaded != null) {
      state = _applyMilestones(loaded);
    }

    final lastSeenMs = await _saveService.loadLastSeenMs();
    if (lastSeenMs != null) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final deltaSeconds = (nowMs - lastSeenMs) / 1000;
      if (deltaSeconds > 1) {
        final constants = _currentConstants(state);
        final offlineSeconds = math.min(
          deltaSeconds,
          constants.offlineLimitSeconds,
        );
        // 离线模拟前记录资源快照，便于生成收益日志。
        final before = Map<ResourceType, double>.from(state.resources);
        _simulateOffline(offlineSeconds);
        _recordOfflineGain(before);
      }
    }

    _saveTimer ??= Timer.periodic(const Duration(seconds: 5), (_) => _save());
  }

  void _recordOfflineGain(Map<ResourceType, double> before) {
    // 汇总离线期间的净增长，并写入日志。
    final gainedShard =
        state.resource(ResourceType.shard) - (before[ResourceType.shard] ?? 0);
    final gainedPart =
        state.resource(ResourceType.part) - (before[ResourceType.part] ?? 0);
    final gainedBlueprint =
        state.resource(ResourceType.blueprint) -
        (before[ResourceType.blueprint] ?? 0);

    final parts = <String>[];
    if (gainedShard > 0) {
      parts.add('碎片 +${_formatNumber(gainedShard)}');
    }
    if (gainedPart > 0) {
      parts.add('零件 +${_formatNumber(gainedPart)}');
    }
    if (gainedBlueprint > 0) {
      parts.add('蓝图 +${_formatNumber(gainedBlueprint)}');
    }

    if (parts.isEmpty) {
      return;
    }

    final detail = parts.join('，');
    state = state.addLogEntry('离线收益', detail);
  }

  void buy(String buildingId, int quantity) {
    // 处理设施购买与成本扣除，支持一次购买最大数量。
    final def = buildingById[buildingId];
    if (def == null) {
      return;
    }

    final effects = _currentEffects(state);
    final currentCount = state.buildingCount(buildingId);
    final resourceType = def.costResource;
    final currency = state.resource(resourceType);

    final buyCount = quantity == -1
        ? maxAffordable(def, currentCount, currency, effects)
        : quantity;

    if (buyCount <= 0) {
      return;
    }

    final cost = totalCost(def, currentCount, buyCount, effects);
    if (currency < cost) {
      return;
    }

    state = state.copyWith(
      resources: {...state.resources, resourceType: currency - cost},
      buildings: {...state.buildings, buildingId: currentCount + buyCount},
    );
  }

  void setShardToPartRatio(double value) {
    state = state.copyWith(shardToPartRatio: value.clamp(0.1, 0.9).toDouble());
  }

  void setKeepShardReserve(bool value) {
    state = state.copyWith(keepShardReserve: value);
  }

  void setEnergySplit(double value) {
    state = state.copyWith(
      energyToSynthesisRatio: value.clamp(0.1, 0.9).toDouble(),
    );
  }

  void setEnergyPriorityMode(EnergyPriorityMode mode) {
    state = state.copyWith(energyPriorityMode: mode);
  }

  void placeBuildingInLayout(String buildingId, int index) {
    if (index < 0 || index >= state.layoutGrid.length) {
      return;
    }
    if (!buildingById.containsKey(buildingId)) {
      return;
    }
    final layout = List<String?>.from(state.layoutGrid);
    final placedCounts = _placedCounts(layout);
    final current = layout[index];
    if (current == buildingId) {
      return;
    }
    if (current != null) {
      placedCounts[current] = math.max(0, (placedCounts[current] ?? 1) - 1);
      layout[index] = null;
    }
    final totalOwned = state.buildingCount(buildingId);
    final used = placedCounts[buildingId] ?? 0;
    if (totalOwned - used <= 0) {
      state = state.copyWith(layoutGrid: layout);
      return;
    }
    layout[index] = buildingId;
    state = state.copyWith(layoutGrid: layout);
  }

  void clearLayoutSlot(int index) {
    if (index < 0 || index >= state.layoutGrid.length) {
      return;
    }
    final layout = List<String?>.from(state.layoutGrid);
    layout[index] = null;
    state = state.copyWith(layoutGrid: layout);
  }

  Map<String, int> _placedCounts(List<String?> layout) {
    final counts = <String, int>{};
    for (final id in layout) {
      if (id == null) {
        continue;
      }
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  void buyResearch(String researchId) {
    // 校验前置研究与蓝图成本，成功后解锁效果。
    final def = researchById[researchId];
    if (def == null) {
      return;
    }
    if (state.researchPurchased.contains(def.id)) {
      return;
    }
    if (!researchPrerequisitesMet(state, def)) {
      return;
    }
    final currency = state.resource(ResourceType.blueprint);
    if (currency < def.costBlueprints) {
      return;
    }

    final updatedResearch = {...state.researchPurchased, def.id};
    state = state.copyWith(
      resources: {
        ...state.resources,
        ResourceType.blueprint: currency - def.costBlueprints,
      },
      researchPurchased: updatedResearch,
    );

    state = state.addLogEntry('研究完成', '已解锁 ${researchTitle(def.id)}');
  }

  void buyConstantUpgrade(String upgradeId) {
    // 常数强化为永久升级，直接写入状态。
    final def = constantUpgradeById[upgradeId];
    if (def == null) {
      return;
    }

    final currentLevel = state.constantUpgrades[upgradeId] ?? 0;
    if (currentLevel >= def.maxLevel) {
      return;
    }

    final cost = constantUpgradeCost(def, currentLevel);
    final currency = state.resource(ResourceType.constant);
    if (currency < cost) {
      return;
    }

    state = state.copyWith(
      resources: {...state.resources, ResourceType.constant: currency - cost},
      constantUpgrades: {
        ...state.constantUpgrades,
        upgradeId: currentLevel + 1,
      },
    );

    state = state.addLogEntry('常数强化', '${def.name} +1');
  }

  void activateTimeWarp() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs < state.timeWarpCooldownEndsAtMs) {
      return;
    }
    final durationMs = timeWarpDurationMs(state);
    final cooldownMs = timeWarpCooldownMs(state);
    state = state.copyWith(
      timeWarpEndsAtMs: nowMs + durationMs,
      timeWarpCooldownEndsAtMs: nowMs + cooldownMs,
    );
    state = state.addLogEntry('主动技能', '时间扭曲启动');
  }

  void activateOverclock() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs < state.overclockCooldownEndsAtMs) {
      return;
    }
    final durationMs = overclockDurationMs(state);
    final cooldownMs = overclockCooldownMs(state);
    state = state.copyWith(
      overclockEndsAtMs: nowMs + durationMs,
      overclockCooldownEndsAtMs: nowMs + cooldownMs,
    );
    state = state.addLogEntry('主动技能', '手动超频启动');
  }

  int overclockDurationMs(GameState state) {
    return _overclockDurationMs +
        state.overclockLevel * _overclockDurationPerLevelMs;
  }

  int overclockCooldownMs(GameState state) {
    final reduced = _overclockCooldownMs -
        state.overclockLevel * _overclockCooldownReductionPerLevelMs;
    return math.max(_overclockCooldownMinMs, reduced);
  }

  int overclockMaxLevel() => _overclockMaxLevel;

  double overclockMultiplier(GameState state) {
    return 1.4 + state.overclockLevel * 0.15;
  }

  double overclockUpgradeCost(int level) {
    return _overclockUpgradeBaseCost *
        math.pow(_overclockUpgradeCostGrowth, level).toDouble();
  }

  void buyOverclockUpgrade() {
    final level = state.overclockLevel;
    if (level >= _overclockMaxLevel) {
      return;
    }
    final cost = overclockUpgradeCost(level);
    final currency = state.resource(ResourceType.constant);
    if (currency < cost) {
      return;
    }
    state = state.copyWith(
      resources: {...state.resources, ResourceType.constant: currency - cost},
      overclockLevel: level + 1,
    );
    state = state.addLogEntry('技能强化', '手动超频 Lv.${level + 1}');
  }

  int timeWarpDurationMs(GameState state) {
    return _timeWarpDurationMs +
        state.timeWarpLevel * _timeWarpDurationPerLevelMs;
  }

  int timeWarpCooldownMs(GameState state) {
    final reduced = _timeWarpCooldownMs -
        state.timeWarpLevel * _timeWarpCooldownReductionPerLevelMs;
    return math.max(_timeWarpCooldownMinMs, reduced);
  }

  int timeWarpMaxLevel() => _timeWarpMaxLevel;

  double timeWarpUpgradeCost(int level) {
    return _timeWarpUpgradeBaseCost *
        math.pow(_timeWarpUpgradeCostGrowth, level).toDouble();
  }

  void buyTimeWarpUpgrade() {
    final level = state.timeWarpLevel;
    if (level >= _timeWarpMaxLevel) {
      return;
    }
    final cost = timeWarpUpgradeCost(level);
    final currency = state.resource(ResourceType.constant);
    if (currency < cost) {
      return;
    }
    state = state.copyWith(
      resources: {...state.resources, ResourceType.constant: currency - cost},
      timeWarpLevel: level + 1,
    );
    state = state.addLogEntry('技能强化', '时间扭曲 Lv.${level + 1}');
  }

  String exportSave() {
    return _saveService.exportState(state);
  }

  Future<bool> importSave(String jsonText) async {
    final imported = _saveService.importState(jsonText);
    if (imported == null) {
      return false;
    }
    state = imported.addLogEntry('存档导入', '已载入存档');
    await _saveService.saveState(state);
    return true;
  }

  Future<void> _save() async {
    await _saveService.saveState(state);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _saveTimer?.cancel();
    _save();
    super.dispose();
  }

  ResearchEffects _currentEffects(GameState state) {
    // 合并研究与里程碑效果，避免重复计算。
    final research = computeResearchEffects(state);
    final milestones = computeMilestoneEffects(state);
    final synergy = computeSynergyEffects(state);
    return research.combine(milestones).combine(synergy);
  }

  ConstantEffects _currentConstants(GameState state) {
    // 常数强化带来的全局倍率与离线上限。
    return computeConstantEffects(state);
  }

  GameState _applyMilestones(GameState current) {
    // 解锁新里程碑并记录日志。
    final newly = findNewMilestones(current);
    if (newly.isEmpty) {
      return current;
    }
    var next = current.copyWith(
      milestonesAchieved: {
        ...current.milestonesAchieved,
        ...newly.map((e) => e.id),
      },
    );
    for (final def in newly) {
      next = next.addLogEntry('里程碑达成', '${def.title}：${def.description}');
    }
    return next;
  }

  void _simulateOffline(double seconds) {
    // 离线期间按总秒数一次性推进资源，避免逐秒循环。
    final effects = _currentEffects(state);
    final constants = _currentConstants(state);
    final effectiveSeconds = seconds * constants.speedMultiplier;
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

    final shardProd = baseShardProd * overloadFactor;
    final energyProd = baseEnergyProd * overloadFactor;
    final shardConvertCap = baseShardConvertCap * overloadFactor;
    final partSynthesisCap = basePartSynthesisCap * overloadFactor;

    var shards = state.resource(ResourceType.shard);
    var parts = state.resource(ResourceType.part);
    var blueprints = state.resource(ResourceType.blueprint);
    var laws = state.resource(ResourceType.law);

    shards += shardProd * effectiveSeconds;

    var shardConvertible = math.min(
      shardConvertCap * effectiveSeconds,
      shardProd * state.shardToPartRatio * effectiveSeconds,
    );

    if (state.keepShardReserve) {
      final maxByReserve = math.max(0.0, shards - state.shardReserveMin);
      shardConvertible = math.min(shardConvertible, maxByReserve);
    }

    shardConvertible = math.min(shardConvertible, shards);
    shards -= shardConvertible;
    parts +=
        shardConvertible /
        shardsPerPart *
        effects.shardToPartEfficiencyMultiplier;

    // 研究解锁后允许离线合成蓝图。
    if (offlineSynthesisUnlocked(state)) {
      final energyAvailable = energyProd * energySplit * effectiveSeconds;
      final energyNeeded = energyNeed * effectiveSeconds;
      final efficiency = energyNeeded <= 0
          ? 0.0
          : math.min(1.0, energyAvailable / energyNeeded);

      var partsConvertible = partSynthesisCap * efficiency * effectiveSeconds;
      partsConvertible = math.min(partsConvertible, parts);
      parts -= partsConvertible;
      blueprints +=
          partsConvertible /
          partsPerBlueprint *
          effects.blueprintProductionMultiplier;
    }

    final lawGain = lawsFromBlueprints(blueprints);
    if (lawGain > 0) {
      blueprints -= lawGain * lawThreshold;
      laws += lawGain;
    }

    var nextState = state.copyWith(
      resources: {
        ...state.resources,
        ResourceType.shard: shards,
        ResourceType.part: parts,
        ResourceType.blueprint: blueprints,
        ResourceType.law: laws,
      },
    );
    nextState = _applyMilestones(nextState);
    state = nextState;
  }

  double prestigePreview() {
    return constantsFromLaws(state.resource(ResourceType.law));
  }

  bool canPrestige() {
    return state.resource(ResourceType.law) >= 1;
  }

  void prestige() {
    // 升维重置进度，保留常数与永久强化。
    if (!canPrestige()) {
      return;
    }
    final gain = prestigePreview();
    if (gain <= 0) {
      return;
    }
    final base = GameState.initial();
    final retainedConstants = state.resource(ResourceType.constant) + gain;
    final nextState = base.copyWith(
      resources: {...base.resources, ResourceType.constant: retainedConstants},
      constantUpgrades: {...state.constantUpgrades},
      milestonesAchieved: state.milestonesAchieved,
      logEntries: state.logEntries,
    );
    state = nextState.addLogEntry('升维完成', '获得常数 +${_formatNumber(gain)}');
  }

  bool _isTimeWarpActive(GameState state, int nowMs) {
    return state.timeWarpEndsAtMs > nowMs;
  }

  bool _isOverclockActive(GameState state, int nowMs) {
    return state.overclockEndsAtMs > nowMs;
  }
}

final gameControllerProvider = StateNotifierProvider<GameController, GameState>(
  (ref) {
    return GameController();
  },
);

String _formatNumber(double value) {
  return formatNumber(value);
}
