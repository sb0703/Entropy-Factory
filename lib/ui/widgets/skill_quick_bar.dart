import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/game_controller.dart';
import '../../game/game_state.dart';
import '../../game/skill_definitions.dart';
import '../../game/run_modifiers.dart';

/// 技能快捷栏：仅以图标形式展示已装配的主动技能，支持长按/点击触发。
class SkillQuickBar extends ConsumerWidget {
  const SkillQuickBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final skills = equippedActiveSkills(state);
    if (skills.isEmpty) {
      return const SizedBox.shrink();
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final hasGlobalBurst = state.unlockedSkills.contains('skill_global_burst');
    final disableActives = state.runModifiers.contains(runModifierDisableActives);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (disableActives)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0x33FF6B6B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF6B6B)),
              ),
              child: const Text(
                '本轮禁用主动技能（变体效果）',
                style: TextStyle(color: Color(0xFFFF6B6B)),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  '技能快捷栏',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF8FA3BF),
                      ),
                ),
              ),
              Text(
                state.autoCastEnabled ? '自动施放' : '手动施放',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF8FA3BF),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: !hasGlobalBurst ||
                      controller.isGlobalCooldownActive(state) ||
                      disableActives
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      controller.activateGlobalCooldownBurst();
                    },
              child: Text(
                !hasGlobalBurst
                    ? '解锁技能树「能量过载」后可用'
                    : disableActives
                        ? '本轮禁用主动技能'
                        : controller.isGlobalCooldownActive(state)
                        ? '全局冷却 ${_formatDuration(controller.globalCooldownRemainingMs(state))}'
                        : '全局释放',
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final skill in skills)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _SkillQuickButton(
                      skill: skill,
                      state: state,
                      controller: controller,
                      nowMs: nowMs,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillQuickButton extends StatelessWidget {
  const _SkillQuickButton({
    required this.skill,
    required this.state,
    required this.controller,
    required this.nowMs,
  });

  final SkillDefinition skill;
  final GameState state;
  final GameController controller;
  final int nowMs;

  @override
  Widget build(BuildContext context) {
    final runtime = _resolveRuntime(skill, state, controller, nowMs);
    final isActive = runtime.activeRemainingMs > 0;
    final isCooling = runtime.cooldownRemainingMs > 0 && !isActive;
    final canUse = !isActive && !isCooling;
    final progress = _progressValue(runtime);
    final ringColor = isActive
        ? const Color(0xFF5CE1E6)
        : (isCooling ? const Color(0xFFF5C542) : const Color(0xFF8BE4B4));

    return SizedBox(
      width: 68,
      child: Tooltip(
        message: '${skill.name}\n${_statusText(runtime)}',
        preferBelow: false,
        child: GestureDetector(
          onTap: canUse ? () => controller.activateSkill(skill.id) : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: const Color(0xFF1E2A3D),
                      color: ringColor,
                    ),
                  ),
                  Icon(skill.icon, color: const Color(0xFF8FA3BF)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _statusText(runtime),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ringColor,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _SkillRuntime _resolveRuntime(
    SkillDefinition skill,
    GameState state,
    GameController controller,
    int nowMs,
  ) {
    switch (skill.id) {
      case 'skill_time_warp':
        return _SkillRuntime(
          activeRemainingMs: math.max(0, state.timeWarpEndsAtMs - nowMs),
          cooldownRemainingMs:
              math.max(0, state.timeWarpCooldownEndsAtMs - nowMs),
          durationMs: controller.timeWarpDurationMs(state),
          cooldownMs: controller.timeWarpCooldownMs(state),
        );
      case 'skill_overclock':
        return _SkillRuntime(
          activeRemainingMs: math.max(0, state.overclockEndsAtMs - nowMs),
          cooldownRemainingMs:
              math.max(0, state.overclockCooldownEndsAtMs - nowMs),
          durationMs: controller.overclockDurationMs(state),
          cooldownMs: controller.overclockCooldownMs(state),
        );
      case 'skill_pulse':
        return _SkillRuntime(
          activeRemainingMs: 0,
          cooldownRemainingMs:
              math.max(0, state.pulseCooldownEndsAtMs - nowMs),
          durationMs: 0,
          cooldownMs: skill.cooldownMs,
        );
      default:
        return _SkillRuntime(
          activeRemainingMs: 0,
          cooldownRemainingMs: 0,
          durationMs: skill.durationMs,
          cooldownMs: skill.cooldownMs,
        );
    }
  }

  double _progressValue(_SkillRuntime runtime) {
    if (runtime.activeRemainingMs > 0 && runtime.durationMs > 0) {
      return runtime.activeRemainingMs / runtime.durationMs;
    }
    if (runtime.cooldownRemainingMs > 0 && runtime.cooldownMs > 0) {
      return (1 - runtime.cooldownRemainingMs / runtime.cooldownMs)
          .clamp(0.0, 1.0);
    }
    return 0.0;
  }

  String _statusText(_SkillRuntime runtime) {
    if (runtime.activeRemainingMs > 0) {
      return '持续 ${_formatDuration(runtime.activeRemainingMs)}';
    }
    if (runtime.cooldownRemainingMs > 0) {
      return '冷却 ${_formatDuration(runtime.cooldownRemainingMs)}';
    }
    return '就绪';
  }
}

class _SkillRuntime {
  const _SkillRuntime({
    required this.activeRemainingMs,
    required this.cooldownRemainingMs,
    required this.durationMs,
    required this.cooldownMs,
  });

  final int activeRemainingMs;
  final int cooldownRemainingMs;
  final int durationMs;
  final int cooldownMs;
}

String _formatDuration(int ms) {
  if (ms <= 0) {
    return '0s';
  }
  final seconds = (ms / 1000).ceil();
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  if (minutes > 0) {
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }
  return '${remaining}s';
}
