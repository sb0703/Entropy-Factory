import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'big_number.dart';
import 'constant_upgrades.dart';
import 'game_definitions.dart';
import 'game_math.dart';
import 'game_state.dart';
import 'milestone_definitions.dart';
import 'number_format.dart';
import 'prestige_challenges.dart';
import 'prestige_rules.dart';
import 'research_definitions.dart';
import 'run_modifiers.dart';
import 'skill_definitions.dart';
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
  static const int _simTickMs = 100;
  static const int _uiSyncMs = 500;
  static const int _pulseCooldownMs = 90 * 1000;
  static const int _runRerollsMax = 2;
  static const int _globalCooldownMs = 6 * 60 * 1000;
  static const int _autoCastIntervalMs = 1000;

  GameController() : super(GameState.initial()) {
    _simState = state;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _lastSimMs = nowMs;
    _lastUiSyncMs = nowMs;
    _simTimer = Timer.periodic(
      const Duration(milliseconds: _simTickMs),
      (_) => _onSimTick(),
    );
    _init();
  }

  Timer? _simTimer;
  Timer? _saveTimer;
  final SaveService _saveService = SaveService();
  late GameState _simState;
  int _lastSimMs = 0;
  int _lastUiSyncMs = 0;
  int _lastAutoCastMs = 0;

  void _onSimTick() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final dtSeconds = (nowMs - _lastSimMs) / 1000;
    _lastSimMs = nowMs;
    if (dtSeconds <= 0) {
      return;
    }
    _simulate(dtSeconds);
    _autoCastActiveSkills(nowMs);
    if (nowMs - _lastUiSyncMs >= _uiSyncMs) {
      state = _simState;
      _lastUiSyncMs = nowMs;
    }
  }

  void _simulate(double dtSeconds) {
    final effects = _currentEffects(_simState);
    final constants = _currentConstants(_simState);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final timeWarpMultiplier =
        _isTimeWarpActive(_simState, nowMs) ? 2.0 : 1.0;
    final effectiveDt =
        dtSeconds * constants.speedMultiplier * timeWarpMultiplier;
    final baseShardProd =
        shardProductionPerSec(_simState, effects) *
        constants.productionMultiplier;
    final baseEnergyProd =
        energyProductionPerSec(_simState, effects) *
        constants.productionMultiplier;
    final baseShardConvertCap =
        shardConversionCapacityPerSec(_simState, effects) *
        constants.productionMultiplier;
    final basePartSynthesisCap =
        partSynthesisCapacityPerSec(_simState, effects) *
        constants.productionMultiplier;
    final energyNeed = partSynthesisEnergyNeedPerSec(_simState, effects);
    final energySplit = effectiveEnergySplit(
      state: _simState,
      energyProd: baseEnergyProd,
      energyNeed: energyNeed,
    );
    final energyAvailableBase = baseEnergyProd * energySplit;
    final overloadFactor = energyNeed <= 0
        ? 1.0
        : math.min(1.0, energyAvailableBase / energyNeed);

    final shardProd = baseShardProd * overloadFactor;
    final energyProd = baseEnergyProd * overloadFactor;
    final overclockBoost = _isOverclockActive(_simState, nowMs)
        ? overclockMultiplier(_simState)
        : 1.0;
    final shardConvertCap = baseShardConvertCap * overloadFactor * overclockBoost;
    final partSynthesisCap = basePartSynthesisCap * overloadFactor * overclockBoost;

    var shards = _simState.resource(ResourceType.shard);
    var parts = _simState.resource(ResourceType.part);
    var blueprints = _simState.resource(ResourceType.blueprint);
    var laws = _simState.resource(ResourceType.law);

    shards = shards + BigNumber.fromDouble(shardProd * effectiveDt);

    var shardConvertible = math.min(
      shardConvertCap * effectiveDt,
      shardProd * _simState.shardToPartRatio * effectiveDt,
    );

    if (_simState.keepShardReserve) {
      final maxByReserve = math.max(
        0.0,
        shards.toDouble() - _simState.shardReserveMin,
      );
      shardConvertible = math.min(shardConvertible, maxByReserve);
    }

    shardConvertible = math.min(shardConvertible, shards.toDouble());
    shards = shards - BigNumber.fromDouble(shardConvertible);
    parts = parts +
        BigNumber.fromDouble(
          shardConvertible /
              shardsPerPart *
              effects.shardToPartEfficiencyMultiplier,
        );

    final energyAvailable = energyProd * energySplit * effectiveDt;
    final energyNeeded = energyNeed * effectiveDt;
    final efficiency = energyNeeded <= 0
        ? 0.0
        : math.min(1.0, energyAvailable / energyNeeded);

    var partsConvertible = partSynthesisCap * efficiency * effectiveDt;
    partsConvertible = math.min(partsConvertible, parts.toDouble());
    parts = parts - BigNumber.fromDouble(partsConvertible);
    blueprints = blueprints +
        BigNumber.fromDouble(
          partsConvertible /
              partsPerBlueprint *
              effects.blueprintProductionMultiplier,
        );

    final lawGain = lawsFromBlueprints(blueprints);
    if (lawGain > BigNumber.zero) {
      blueprints = blueprints - lawGain.timesDouble(lawThreshold);
      laws = laws + lawGain;
    }

    var nextState = _simState.copyWith(
      resources: {
        ..._simState.resources,
        ResourceType.shard: shards,
        ResourceType.part: parts,
        ResourceType.blueprint: blueprints,
        ResourceType.law: laws,
      },
    );
    nextState = _applyMilestones(nextState);
    _simState = nextState;
  }

  Future<void> _init() async {
    final loaded = await _saveService.loadState();
    if (loaded != null) {
      _simState = _applyMilestones(loaded);
      state = _simState;
    } else {
      _simState = state;
    }
    if (_simState.runModifiers.isEmpty) {
      _simState = _simState.copyWith(
        runModifiers: _rollRunModifiers(),
        runRerollsLeft: _runRerollsMax,
      );
      state = _simState;
      _lastUiSyncMs = DateTime.now().millisecondsSinceEpoch;
    }

    final lastSeenMs = await _saveService.loadLastSeenMs();
    if (lastSeenMs != null) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final deltaSeconds = (nowMs - lastSeenMs) / 1000;
      if (deltaSeconds > 1) {
        final constants = _currentConstants(_simState);
        final offlineSeconds = math.min(
          deltaSeconds,
          constants.offlineLimitSeconds,
        );
        final before = Map<ResourceType, BigNumber>.from(_simState.resources);
        _simulateOffline(offlineSeconds);
        _recordOfflineGain(before, offlineSeconds);
      }
    }

    _saveTimer ??= Timer.periodic(const Duration(seconds: 5), (_) => _save());
  }

  void _recordOfflineGain(
    Map<ResourceType, BigNumber> before,
    double offlineSeconds,
  ) {
    final gainedShard =
        _simState.resource(ResourceType.shard) -
        (before[ResourceType.shard] ?? BigNumber.zero);
    final gainedPart =
        _simState.resource(ResourceType.part) -
        (before[ResourceType.part] ?? BigNumber.zero);
    final gainedBlueprint =
        _simState.resource(ResourceType.blueprint) -
        (before[ResourceType.blueprint] ?? BigNumber.zero);

    final parts = <String>[];
    if (gainedShard > BigNumber.zero) {
      parts.add('碎片 +${_formatNumber(gainedShard)}');
    }
    if (gainedPart > BigNumber.zero) {
      parts.add('零件 +${_formatNumber(gainedPart)}');
    }
    if (gainedBlueprint > BigNumber.zero) {
      parts.add('蓝图 +${_formatNumber(gainedBlueprint)}');
    }

    if (parts.isEmpty) {
      return;
    }

    final duration = _formatOfflineDuration(offlineSeconds);
    final detail = '离线时长 $duration，按产能公式结算：${parts.join('，')}';
    _commitState(_simState.addLogEntry('离线收益', detail));
  }

  void _commitState(GameState next) {
    _simState = next;
    state = _simState;
    _lastUiSyncMs = DateTime.now().millisecondsSinceEpoch;
  }

  void buy(String buildingId, int quantity) {
    final def = buildingById[buildingId];
    if (def == null) {
      return;
    }
    if (buildingId == 'radiation_core' && !_simState.isLayoutUnlocked) {
      return;
    }
    if (!_canBuyInChallenge(def)) {
      return;
    }

    final effects = _currentEffects(_simState);
    final currentCount = _simState.buildingCount(buildingId);
    final resourceType = def.costResource;
    final currency = _simState.resource(resourceType);

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

    _commitState(
      _simState.copyWith(
        resources: {..._simState.resources, resourceType: currency - cost},
        buildings: {..._simState.buildings, buildingId: currentCount + buyCount},
      ),
    );
  }

  void setShardToPartRatio(double value) {
    _commitState(
      _simState.copyWith(shardToPartRatio: value.clamp(0.1, 0.9).toDouble()),
    );
  }

  void setKeepShardReserve(bool value) {
    _commitState(_simState.copyWith(keepShardReserve: value));
  }

  void setEnergySplit(double value) {
    _commitState(
      _simState.copyWith(
        energyToSynthesisRatio: value.clamp(0.1, 0.9).toDouble(),
      ),
    );
  }

  void setEnergyPriorityMode(EnergyPriorityMode mode) {
    _commitState(_simState.copyWith(energyPriorityMode: mode));
  }

  void setAutoCastEnabled(bool value) {
    _commitState(_simState.copyWith(autoCastEnabled: value));
  }

  void placeBuildingInLayout(String buildingId, int index) {
    if (!_simState.isLayoutUnlocked) {
      return;
    }
    if (index < 0 || index >= _simState.layoutGrid.length) {
      return;
    }
    if (!_simState.isLayoutSlotUnlocked(index)) {
      return;
    }
    if (!buildingById.containsKey(buildingId)) {
      return;
    }
    final layout = List<String?>.from(_simState.layoutGrid);
    final placedCounts = _placedCounts(layout);
    final current = layout[index];
    if (current == buildingId) {
      return;
    }
    if (current != null) {
      placedCounts[current] = math.max(0, (placedCounts[current] ?? 1) - 1);
      layout[index] = null;
    }
    final totalOwned = _simState.buildingCount(buildingId);
    final used = placedCounts[buildingId] ?? 0;
    if (totalOwned - used <= 0) {
      _commitState(_simState.copyWith(layoutGrid: layout));
      return;
    }
    layout[index] = buildingId;
    _commitState(_simState.copyWith(layoutGrid: layout));
  }

  void clearLayoutSlot(int index) {
    if (!_simState.isLayoutUnlocked) {
      return;
    }
    if (index < 0 || index >= _simState.layoutGrid.length) {
      return;
    }
    if (!_simState.isLayoutSlotUnlocked(index)) {
      return;
    }
    final layout = List<String?>.from(_simState.layoutGrid);
    layout[index] = null;
    _commitState(_simState.copyWith(layoutGrid: layout));
  }

  void moveLayoutSlot(int from, int to) {
    if (!_simState.isLayoutUnlocked) {
      return;
    }
    if (from < 0 ||
        to < 0 ||
        from >= _simState.layoutGrid.length ||
        to >= _simState.layoutGrid.length) {
      return;
    }
    if (!_simState.isLayoutSlotUnlocked(from) ||
        !_simState.isLayoutSlotUnlocked(to)) {
      return;
    }
    final layout = List<String?>.from(_simState.layoutGrid);
    final fromVal = layout[from];
    final toVal = layout[to];
    // If nothing to move, skip.
    if (fromVal == null && toVal == null) {
      return;
    }
    layout[from] = toVal;
    layout[to] = fromVal;
    _commitState(_simState.copyWith(layoutGrid: layout));
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
    final def = researchById[researchId];
    if (def == null) {
      return;
    }
    if (_simState.researchPurchased.contains(def.id)) {
      return;
    }
    if (!researchPrerequisitesMet(_simState, def)) {
      return;
    }
    final currency = _simState.resource(ResourceType.blueprint);
    final cost = BigNumber.fromDouble(def.costBlueprints);
    if (currency < cost) {
      return;
    }

    final updatedResearch = {..._simState.researchPurchased, def.id};
    _commitState(
      _simState.copyWith(
        resources: {
          ..._simState.resources,
          ResourceType.blueprint: currency - cost,
        },
        researchPurchased: updatedResearch,
      ),
    );

    _commitState(_simState.addLogEntry('研究完成', '已解锁 ${researchTitle(def.id)}'));
  }

  void buyConstantUpgrade(String upgradeId) {
    final def = constantUpgradeById[upgradeId];
    if (def == null) {
      return;
    }

    final currentLevel = _simState.constantUpgrades[upgradeId] ?? 0;
    if (currentLevel >= def.maxLevel) {
      return;
    }

    final cost = BigNumber.fromDouble(constantUpgradeCost(def, currentLevel));
    final currency = _simState.resource(ResourceType.constant);
    if (currency < cost) {
      return;
    }

    _commitState(
      _simState.copyWith(
        resources: {
          ..._simState.resources,
          ResourceType.constant: currency - cost,
        },
        constantUpgrades: {
          ..._simState.constantUpgrades,
          upgradeId: currentLevel + 1,
        },
      ),
    );

    _commitState(_simState.addLogEntry('常数强化', '${def.name} +1'));
  }

  void startChallenge(String challengeId) {
    if (_simState.activeChallengeId != null) {
      return;
    }
    if (_simState.completedChallenges.contains(challengeId)) {
      return;
    }
    final challenge = prestigeChallenges.firstWhere(
      (def) => def.id == challengeId,
      orElse: () => PrestigeChallenge(
        id: '',
        title: '',
        description: '',
        rewardUnlockId: '',
        requirementMet: _alwaysFalse,
      ),
    );
    if (challenge.id.isEmpty) {
      return;
    }
    final base = GameState.initial();
    final nextState = base.copyWith(
      resources: {
        ...base.resources,
        ResourceType.constant: _simState.resource(ResourceType.constant),
      },
      constantUpgrades: {..._simState.constantUpgrades},
      milestonesAchieved: _simState.milestonesAchieved,
      logEntries: _simState.logEntries,
      activeChallengeId: challengeId,
      completedChallenges: {..._simState.completedChallenges},
      permanentUnlocks: {..._simState.permanentUnlocks},
      runModifiers: _rollRunModifiers(),
      runRerollsLeft: _runRerollsMax,
      skillPoints: _simState.skillPoints,
      unlockedSkills: {..._simState.unlockedSkills},
      equippedSkills: [..._simState.equippedSkills],
      pulseCooldownEndsAtMs: 0,
    );
    _commitState(nextState.addLogEntry('挑战升维', '进入挑战：${challenge.title}'));
  }

  void abandonChallenge() {
    if (_simState.activeChallengeId == null) {
      return;
    }
    final base = GameState.initial();
    final nextState = base.copyWith(
      resources: {
        ...base.resources,
        ResourceType.constant: _simState.resource(ResourceType.constant),
      },
      constantUpgrades: {..._simState.constantUpgrades},
      milestonesAchieved: _simState.milestonesAchieved,
      logEntries: _simState.logEntries,
      activeChallengeId: null,
      completedChallenges: {..._simState.completedChallenges},
      permanentUnlocks: {..._simState.permanentUnlocks},
      runModifiers: _rollRunModifiers(),
      runRerollsLeft: _runRerollsMax,
      skillPoints: _simState.skillPoints,
      unlockedSkills: {..._simState.unlockedSkills},
      equippedSkills: [..._simState.equippedSkills],
      pulseCooldownEndsAtMs: 0,
    );
    _commitState(nextState.addLogEntry('挑战升维', '已放弃当前挑战'));
  }

  void activateTimeWarp() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs < _simState.timeWarpCooldownEndsAtMs) {
      return;
    }
    final durationMs = timeWarpDurationMs(_simState);
    final cooldownMs = timeWarpCooldownMs(_simState);
    _commitState(
      _simState.copyWith(
        timeWarpEndsAtMs: nowMs + durationMs,
        timeWarpCooldownEndsAtMs: nowMs + cooldownMs,
      ),
    );
    _commitState(_simState.addLogEntry('主动技能', '时间扭曲启动'));
  }

  void activateOverclock() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs < _simState.overclockCooldownEndsAtMs) {
      return;
    }
    final durationMs = overclockDurationMs(_simState);
    final cooldownMs = overclockCooldownMs(_simState);
    _commitState(
      _simState.copyWith(
        overclockEndsAtMs: nowMs + durationMs,
        overclockCooldownEndsAtMs: nowMs + cooldownMs,
      ),
    );
    _commitState(_simState.addLogEntry('主动技能', '手动超频启动'));
  }

  int overclockDurationMs(GameState state) {
    return _overclockDurationMs + state.overclockLevel * _overclockDurationPerLevelMs;
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

  BigNumber overclockUpgradeCost(int level) {
    return BigNumber.fromDouble(
      _overclockUpgradeBaseCost *
          math.pow(_overclockUpgradeCostGrowth, level).toDouble(),
    );
  }

  void buyOverclockUpgrade() {
    final level = _simState.overclockLevel;
    if (level >= _overclockMaxLevel) {
      return;
    }
    final cost = overclockUpgradeCost(level);
    final currency = _simState.resource(ResourceType.constant);
    if (currency < cost) {
      return;
    }
    _commitState(
      _simState.copyWith(
        resources: {
          ..._simState.resources,
          ResourceType.constant: currency - cost,
        },
        overclockLevel: level + 1,
      ),
    );
    _commitState(_simState.addLogEntry('技能强化', '手动超频 Lv.${level + 1}'));
  }

  int timeWarpDurationMs(GameState state) {
    return _timeWarpDurationMs + state.timeWarpLevel * _timeWarpDurationPerLevelMs;
  }

  int timeWarpCooldownMs(GameState state) {
    final reduced = _timeWarpCooldownMs -
        state.timeWarpLevel * _timeWarpCooldownReductionPerLevelMs;
    return math.max(_timeWarpCooldownMinMs, reduced);
  }

  int timeWarpMaxLevel() => _timeWarpMaxLevel;

  BigNumber timeWarpUpgradeCost(int level) {
    return BigNumber.fromDouble(
      _timeWarpUpgradeBaseCost *
          math.pow(_timeWarpUpgradeCostGrowth, level).toDouble(),
    );
  }

  void buyTimeWarpUpgrade() {
    final level = _simState.timeWarpLevel;
    if (level >= _timeWarpMaxLevel) {
      return;
    }
    final cost = timeWarpUpgradeCost(level);
    final currency = _simState.resource(ResourceType.constant);
    if (currency < cost) {
      return;
    }
    _commitState(
      _simState.copyWith(
        resources: {
          ..._simState.resources,
          ResourceType.constant: currency - cost,
        },
        timeWarpLevel: level + 1,
      ),
    );
    _commitState(_simState.addLogEntry('技能强化', '时间扭曲 Lv.${level + 1}'));
  }

  String exportSave() {
    return _saveService.exportState(_simState);
  }

  Future<bool> importSave(String jsonText) async {
    final imported = _saveService.importState(jsonText);
    if (imported == null) {
      return false;
    }
    _commitState(imported.addLogEntry('存档导入', '已载入存档'));
    await _saveService.saveState(_simState);
    return true;
  }

  Future<void> _save() async {
    await _saveService.saveState(_simState);
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    _saveTimer?.cancel();
    _save();
    super.dispose();
  }

  ResearchEffects _currentEffects(GameState state) {
    final research = computeResearchEffects(state);
    final milestones = computeMilestoneEffects(state);
    final synergy = computeSynergyEffects(state);
    final modifiers = computeRunModifierEffects(state);
    final skills = computeSkillEffects(state);
    return research.combine(milestones).combine(synergy).combine(modifiers).combine(skills);
  }

  ConstantEffects _currentConstants(GameState state) {
    final base = computeConstantEffects(state);
    final bonus = permanentProductionBonus(state);
    if (bonus <= 0) {
      return base;
    }
    return ConstantEffects(
      productionMultiplier: base.productionMultiplier * (1 + bonus),
      speedMultiplier: base.speedMultiplier,
      offlineLimitSeconds: base.offlineLimitSeconds,
    );
  }

  GameState _applyMilestones(GameState current) {
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
      next = next.addLogEntry('里程碑达成', '${def.title}，${def.description}');
    }
    return next;
  }

  void _simulateOffline(double seconds) {
    // 离线收益按公式一次性结算，避免逐秒循环造成卡顿。
    final effects = _currentEffects(_simState);
    final constants = _currentConstants(_simState);
    final effectiveSeconds = math.max(0.0, seconds) * constants.speedMultiplier;
    if (effectiveSeconds <= 0) {
      return;
    }
    final baseShardProd =
        shardProductionPerSec(_simState, effects) *
        constants.productionMultiplier;
    final baseEnergyProd =
        energyProductionPerSec(_simState, effects) *
        constants.productionMultiplier;
    final baseShardConvertCap =
        shardConversionCapacityPerSec(_simState, effects) *
        constants.productionMultiplier;
    final basePartSynthesisCap =
        partSynthesisCapacityPerSec(_simState, effects) *
        constants.productionMultiplier;
    final energyNeed = partSynthesisEnergyNeedPerSec(_simState, effects);
    final energySplit = effectiveEnergySplit(
      state: _simState,
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

    var shards = _simState.resource(ResourceType.shard);
    var parts = _simState.resource(ResourceType.part);
    var blueprints = _simState.resource(ResourceType.blueprint);
    var laws = _simState.resource(ResourceType.law);

    shards = shards + BigNumber.fromDouble(shardProd * effectiveSeconds);

    var shardConvertible = math.min(
      shardConvertCap * effectiveSeconds,
      shardProd * _simState.shardToPartRatio * effectiveSeconds,
    );

    if (_simState.keepShardReserve) {
      final maxByReserve = math.max(
        0.0,
        shards.toDouble() - _simState.shardReserveMin,
      );
      shardConvertible = math.min(shardConvertible, maxByReserve);
    }

    shardConvertible = math.min(shardConvertible, shards.toDouble());
    shards = shards - BigNumber.fromDouble(shardConvertible);
    parts = parts +
        BigNumber.fromDouble(
          shardConvertible /
              shardsPerPart *
              effects.shardToPartEfficiencyMultiplier,
        );

    if (offlineSynthesisUnlocked(_simState)) {
      final energyAvailable = energyProd * energySplit * effectiveSeconds;
      final energyNeeded = energyNeed * effectiveSeconds;
      final efficiency = energyNeeded <= 0
          ? 0.0
          : math.min(1.0, energyAvailable / energyNeeded);

      var partsConvertible = partSynthesisCap * efficiency * effectiveSeconds;
      partsConvertible = math.min(partsConvertible, parts.toDouble());
      parts = parts - BigNumber.fromDouble(partsConvertible);
      blueprints = blueprints +
          BigNumber.fromDouble(
            partsConvertible /
                partsPerBlueprint *
                effects.blueprintProductionMultiplier,
          );
    }

    final lawGain = lawsFromBlueprints(blueprints);
    if (lawGain > BigNumber.zero) {
      blueprints = blueprints - lawGain.timesDouble(lawThreshold);
      laws = laws + lawGain;
    }

    var nextState = _simState.copyWith(
      resources: {
        ..._simState.resources,
        ResourceType.shard: shards,
        ResourceType.part: parts,
        ResourceType.blueprint: blueprints,
        ResourceType.law: laws,
      },
    );
    nextState = _applyMilestones(nextState);
    _commitState(nextState);
  }

  BigNumber prestigePreview() {
    return constantsFromLaws(_simState.resource(ResourceType.law));
  }

  bool canPrestige() {
    if (_simState.resource(ResourceType.law) < BigNumber.fromInt(1)) {
      return false;
    }
    final challenge = _activeChallenge();
    if (challenge == null) {
      return true;
    }
    return challenge.requirementMet(_simState);
  }

  void prestige() {
    if (!canPrestige()) {
      return;
    }
    final gain = prestigePreview();
    if (gain <= BigNumber.zero) {
      return;
    }
    final challenge = _activeChallenge();
    final base = GameState.initial();
    final retainedConstants = _simState.resource(ResourceType.constant) + gain;
    final completedChallenges = {..._simState.completedChallenges};
    final permanentUnlocks = {..._simState.permanentUnlocks};
    if (challenge != null) {
      completedChallenges.add(challenge.id);
      permanentUnlocks.add(challenge.rewardUnlockId);
    }
    final nextState = base.copyWith(
      resources: {...base.resources, ResourceType.constant: retainedConstants},
      constantUpgrades: {..._simState.constantUpgrades},
      milestonesAchieved: _simState.milestonesAchieved,
      logEntries: _simState.logEntries,
      activeChallengeId: null,
      completedChallenges: completedChallenges,
      permanentUnlocks: permanentUnlocks,
      runModifiers: _rollRunModifiers(),
      runRerollsLeft: _runRerollsMax,
      skillPoints: _simState.skillPoints,
      unlockedSkills: {..._simState.unlockedSkills},
      equippedSkills: [..._simState.equippedSkills],
      pulseCooldownEndsAtMs: 0,
    );
    _commitState(
      nextState.addLogEntry('升维完成', '获得常数 +${_formatNumber(gain)}'),
    );
  }

  bool _isTimeWarpActive(GameState state, int nowMs) {
    return state.timeWarpEndsAtMs > nowMs;
  }

  bool _isOverclockActive(GameState state, int nowMs) {
    return state.overclockEndsAtMs > nowMs;
  }

  PrestigeChallenge? _activeChallenge() {
    final id = _simState.activeChallengeId;
    if (id == null) {
      return null;
    }
    for (final def in prestigeChallenges) {
      if (def.id == id) {
        return def;
      }
    }
    return null;
  }

  bool _canBuyInChallenge(BuildingDefinition def) {
    final challenge = _activeChallenge();
    if (challenge == null || challenge.allowedBuildingTypes == null) {
      return true;
    }
    return challenge.allowedBuildingTypes!.contains(def.type);
  }

  List<String> _rollRunModifiers() {
    final seed = DateTime.now().millisecondsSinceEpoch ^
        _simState.resources.hashCode ^
        _simState.buildings.hashCode;
    final random = math.Random(seed);
    return rollRunModifiers(random);
  }

  int runRerollsMax() => _runRerollsMax;

  BigNumber runRerollCost(GameState state) {
    final used = _runRerollsMax - state.runRerollsLeft;
    final cost = 8 * math.pow(2, math.max(0, used)).toDouble();
    return BigNumber.fromDouble(cost);
  }

  void rerollRunModifiers() {
    if (_simState.runRerollsLeft <= 0) {
      return;
    }
    final cost = runRerollCost(_simState);
    final currency = _simState.resource(ResourceType.blueprint);
    if (currency < cost) {
      return;
    }
    final next = _rollRunModifiers();
    _commitState(
      _simState.copyWith(
        resources: {
          ..._simState.resources,
          ResourceType.blueprint: currency - cost,
        },
        runModifiers: next,
        runRerollsLeft: _simState.runRerollsLeft - 1,
      ),
    );
    _commitState(_simState.addLogEntry('变体刷新', '刷新本轮变体词条'));
  }

  int maxSkillSlots(GameState state) {
    return math.min(5, 3 + unlockedModuleSlots(state));
  }

  BigNumber skillPointCost(int current) {
    final base = 50.0;
    final growth = 1.35;
    final cost = base * math.pow(growth, current).toDouble();
    return BigNumber.fromDouble(cost);
  }

  void buySkillPoint() {
    final cost = skillPointCost(_simState.skillPoints);
    final currency = _simState.resource(ResourceType.blueprint);
    if (currency < cost) {
      return;
    }
    _commitState(
      _simState.copyWith(
        resources: {
          ..._simState.resources,
          ResourceType.blueprint: currency - cost,
        },
        skillPoints: _simState.skillPoints + 1,
      ),
    );
  }

  void unlockSkillWithBlueprints(String skillId) {
    final def = skillById[skillId];
    if (def == null || def.costBlueprints <= 0) {
      return;
    }
    if (_simState.unlockedSkills.contains(skillId)) {
      return;
    }
    if (!skillPrerequisitesMet(_simState, def)) {
      return;
    }
    final cost = BigNumber.fromDouble(def.costBlueprints);
    final currency = _simState.resource(ResourceType.blueprint);
    if (currency < cost) {
      return;
    }
    final next = {..._simState.unlockedSkills, skillId};
    _commitState(
      _simState.copyWith(
        resources: {
          ..._simState.resources,
          ResourceType.blueprint: currency - cost,
        },
        unlockedSkills: next,
      ),
    );
  }

  void unlockSkillWithPoints(String skillId) {
    final def = skillById[skillId];
    if (def == null || def.costSkillPoints <= 0) {
      return;
    }
    if (_simState.unlockedSkills.contains(skillId)) {
      return;
    }
    if (!skillPrerequisitesMet(_simState, def)) {
      return;
    }
    if (_simState.skillPoints < def.costSkillPoints) {
      return;
    }
    final next = {..._simState.unlockedSkills, skillId};
    _commitState(
      _simState.copyWith(
        skillPoints: _simState.skillPoints - def.costSkillPoints,
        unlockedSkills: next,
      ),
    );
  }

  void toggleEquipSkill(String skillId) {
    if (!_simState.unlockedSkills.contains(skillId)) {
      return;
    }
    final equipped = [..._simState.equippedSkills];
    if (equipped.contains(skillId)) {
      equipped.remove(skillId);
      _commitState(_simState.copyWith(equippedSkills: equipped));
      return;
    }
    if (equipped.length >= maxSkillSlots(_simState)) {
      return;
    }
    equipped.add(skillId);
    _commitState(_simState.copyWith(equippedSkills: equipped));
  }

  void activateSkill(String skillId) {
    if (_isGlobalCooldownActive(_simState, DateTime.now().millisecondsSinceEpoch)) {
      return;
    }
    if (!_simState.equippedSkills.contains(skillId)) {
      return;
    }
    _activateSkillInternal(skillId, DateTime.now().millisecondsSinceEpoch);
  }

  bool isGlobalCooldownActive(GameState state) {
    return _isGlobalCooldownActive(state, DateTime.now().millisecondsSinceEpoch);
  }

  int globalCooldownRemainingMs(GameState state) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return math.max(0, state.globalCooldownEndsAtMs - nowMs);
  }

  int globalCooldownMs() => _globalCooldownMs;

  void activateGlobalCooldownBurst() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (_isGlobalCooldownActive(_simState, nowMs)) {
      return;
    }
    final activeSkills = equippedActiveSkills(_simState);
    if (activeSkills.isEmpty) {
      return;
    }
    var triggered = false;
    for (final skill in activeSkills) {
      triggered = _activateSkillInternal(skill.id, nowMs) || triggered;
    }
    if (!triggered) {
      return;
    }
    _commitState(
      _simState.copyWith(globalCooldownEndsAtMs: nowMs + _globalCooldownMs),
    );
    _commitState(_simState.addLogEntry('全局冷却', '触发全局释放，进入冷却'));
  }

  bool _activateSkillInternal(String skillId, int nowMs) {
    if (!_simState.equippedSkills.contains(skillId)) {
      return false;
    }
    switch (skillId) {
      case 'skill_time_warp':
        return _activateTimeWarpInternal(nowMs);
      case 'skill_overclock':
        return _activateOverclockInternal(nowMs);
      case 'skill_pulse':
        return _activatePulseInternal(nowMs);
    }
    return false;
  }

  bool _activateTimeWarpInternal(int nowMs) {
    if (nowMs < _simState.timeWarpCooldownEndsAtMs) {
      return false;
    }
    final durationMs = timeWarpDurationMs(_simState);
    final cooldownMs = timeWarpCooldownMs(_simState);
    _commitState(
      _simState.copyWith(
        timeWarpEndsAtMs: nowMs + durationMs,
        timeWarpCooldownEndsAtMs: nowMs + cooldownMs,
      ),
    );
    _commitState(_simState.addLogEntry('主动技能', '时间扭曲启动'));
    return true;
  }

  bool _activateOverclockInternal(int nowMs) {
    if (nowMs < _simState.overclockCooldownEndsAtMs) {
      return false;
    }
    final durationMs = overclockDurationMs(_simState);
    final cooldownMs = overclockCooldownMs(_simState);
    _commitState(
      _simState.copyWith(
        overclockEndsAtMs: nowMs + durationMs,
        overclockCooldownEndsAtMs: nowMs + cooldownMs,
      ),
    );
    _commitState(_simState.addLogEntry('主动技能', '手动超频启动'));
    return true;
  }

  bool _activatePulseInternal(int nowMs) {
    if (nowMs < _simState.pulseCooldownEndsAtMs) {
      return false;
    }
    final effects = _currentEffects(_simState);
    final constants = _currentConstants(_simState);
    final shardGain = shardProductionPerSec(_simState, effects) *
        constants.productionMultiplier * 10;
    final nextShards = _simState.resource(ResourceType.shard) +
        BigNumber.fromDouble(shardGain);
    _commitState(
      _simState.copyWith(
        resources: {
          ..._simState.resources,
          ResourceType.shard: nextShards,
        },
        pulseCooldownEndsAtMs: nowMs + _pulseCooldownMs,
      ),
    );
    _commitState(_simState.addLogEntry('主动技能', '资源脉冲启动'));
    return true;
  }

  void _autoCastActiveSkills(int nowMs) {
    if (!_simState.autoCastEnabled) {
      return;
    }
    if (_isGlobalCooldownActive(_simState, nowMs)) {
      return;
    }
    if (nowMs - _lastAutoCastMs < _autoCastIntervalMs) {
      return;
    }
    var triggered = false;
    for (final skill in equippedActiveSkills(_simState)) {
      triggered = _activateSkillInternal(skill.id, nowMs) || triggered;
    }
    if (triggered) {
      _lastAutoCastMs = nowMs;
    }
  }

  bool _isGlobalCooldownActive(GameState state, int nowMs) {
    return state.globalCooldownEndsAtMs > nowMs;
  }
}

final gameControllerProvider = StateNotifierProvider<GameController, GameState>(
  (ref) {
    return GameController();
  },
);

String _formatNumber(Object value) {
  return formatNumber(value);
}

bool _alwaysFalse(GameState state) => false;

String _formatOfflineDuration(double seconds) {
  final totalSeconds = seconds.round();
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  if (hours > 0) {
    return '$hours 小时 $minutes 分钟';
  }
  if (minutes > 0) {
    return '$minutes 分钟';
  }
  return '${math.max(1, totalSeconds)} 秒';
}


