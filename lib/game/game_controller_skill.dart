part of 'game_controller.dart';

extension SkillOps on GameController {
  void activateSkill(String skillId) {
    if (_simState.runModifiers.contains(runModifierDisableActives)) {
      return;
    }
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

  int globalCooldownMs() => GameController._globalCooldownMs;

  void activateGlobalCooldownBurst() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (_simState.runModifiers.contains(runModifierDisableActives)) {
      return;
    }
    if (!_simState.unlockedSkills.contains('skill_global_burst')) {
      return;
    }
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
      _simState.copyWith(globalCooldownEndsAtMs: nowMs + GameController._globalCooldownMs),
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
        pulseCooldownEndsAtMs: nowMs + GameController._pulseCooldownMs,
      ),
    );
    _commitState(_simState.addLogEntry('主动技能', '资源脉冲启动'));
    return true;
  }

  void _autoCastActiveSkills(int nowMs) {
    if (!_simState.autoCastEnabled) {
      return;
    }
    if (_simState.runModifiers.contains(runModifierDisableActives)) {
      return;
    }
    if (_isGlobalCooldownActive(_simState, nowMs)) {
      return;
    }
    if (nowMs - _lastAutoCastMs < GameController._autoCastIntervalMs) {
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
