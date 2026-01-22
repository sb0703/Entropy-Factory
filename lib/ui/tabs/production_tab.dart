import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/game_controller.dart';
import '../../game/game_ui_state.dart';
import '../../game/game_state.dart';
import '../widgets/building_card.dart';
import '../widgets/law_progress_card.dart';
import '../widgets/rate_summary_card.dart';
import '../widgets/ratio_panel.dart';
import '../effects/particle_layer.dart';
import '../widgets/resource_bar.dart';

class ProductionTab extends ConsumerWidget {
  const ProductionTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameUiProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final gameState = ref.watch(gameControllerProvider);
    final particleController = ref.read(particleControllerProvider);
    final anchorRegistry = ref.read(resourceAnchorRegistryProvider);
    final blueprints = gameState.resource(ResourceType.blueprint);
    final laws = gameState.resource(ResourceType.law);
    final constants = gameState.resource(ResourceType.constant);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final durationMs = controller.timeWarpDurationMs(gameState);
    final cooldownMs = controller.timeWarpCooldownMs(gameState);
    final activeRemainingMs =
        math.max(0, gameState.timeWarpEndsAtMs - nowMs);
    final cooldownRemainingMs =
        math.max(0, gameState.timeWarpCooldownEndsAtMs - nowMs);

    // 根据宽度切换双栏/单栏布局，避免小屏拥挤。
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (isWide) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 2,
                  child: Column(
                    children: [
                      Text(
                        '管理设施与配比，提升整体产能与定律进度',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF8FA3BF),
                            ),
                      ),
                      const SizedBox(height: 12),
                      RateSummaryCard(summary: state.rateSummary),
                      const SizedBox(height: 12),
                      LawProgressCard(
                        blueprints: blueprints,
                        laws: laws,
                      ),
                      const SizedBox(height: 16),
                      _ActiveSkillCard(
                        activeRemainingMs: activeRemainingMs,
                        cooldownRemainingMs: cooldownRemainingMs,
                        durationMs: durationMs,
                        cooldownMs: cooldownMs,
                        level: gameState.timeWarpLevel,
                        maxLevel: controller.timeWarpMaxLevel(),
                        upgradeCost:
                            controller.timeWarpUpgradeCost(gameState.timeWarpLevel),
                        availableConstants: constants,
                        onActivate: controller.activateTimeWarp,
                        onUpgrade: controller.buyTimeWarpUpgrade,
                      ),
                      const SizedBox(height: 16),
                      const RatioPanel(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: ListView.separated(
                    itemCount: state.buildings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final building = state.buildings[index];
                      return BuildingCard(
                        data: building,
                        onBuyOne: () => controller.buy(building.id, 1),
                        onBuyTen: () => controller.buy(building.id, 10),
                        onBuyMax: () => controller.buy(building.id, -1),
                        particleController: particleController,
                        anchorRegistry: anchorRegistry,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            Text(
              '管理设施与配比，提升整体产能与定律进度',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8FA3BF),
                  ),
            ),
            const SizedBox(height: 12),
            RateSummaryCard(summary: state.rateSummary),
            const SizedBox(height: 12),
            LawProgressCard(
              blueprints: blueprints,
              laws: laws,
            ),
            const SizedBox(height: 16),
            _ActiveSkillCard(
              activeRemainingMs: activeRemainingMs,
              cooldownRemainingMs: cooldownRemainingMs,
              durationMs: durationMs,
              cooldownMs: cooldownMs,
              level: gameState.timeWarpLevel,
              maxLevel: controller.timeWarpMaxLevel(),
              upgradeCost:
                  controller.timeWarpUpgradeCost(gameState.timeWarpLevel),
              availableConstants: constants,
              onActivate: controller.activateTimeWarp,
              onUpgrade: controller.buyTimeWarpUpgrade,
            ),
            const SizedBox(height: 16),
            for (final building in state.buildings) ...[
              BuildingCard(
                data: building,
                onBuyOne: () => controller.buy(building.id, 1),
                onBuyTen: () => controller.buy(building.id, 10),
                onBuyMax: () => controller.buy(building.id, -1),
                particleController: particleController,
                anchorRegistry: anchorRegistry,
              ),
              const SizedBox(height: 12),
            ],
            const RatioPanel(),
          ],
        );
      },
    );
  }
}

class _ActiveSkillCard extends StatelessWidget {
  const _ActiveSkillCard({
    required this.activeRemainingMs,
    required this.cooldownRemainingMs,
    required this.durationMs,
    required this.cooldownMs,
    required this.level,
    required this.maxLevel,
    required this.upgradeCost,
    required this.availableConstants,
    required this.onActivate,
    required this.onUpgrade,
  });

  final int activeRemainingMs;
  final int cooldownRemainingMs;
  final int durationMs;
  final int cooldownMs;
  final int level;
  final int maxLevel;
  final double upgradeCost;
  final double availableConstants;
  final VoidCallback onActivate;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final isActive = activeRemainingMs > 0;
    final isCooling = cooldownRemainingMs > 0 && !isActive;
    final canUse = !isActive && !isCooling;
    final label = isActive
        ? '持续中 ${_formatDuration(activeRemainingMs)}'
        : (isCooling ? '冷却中 ${_formatDuration(cooldownRemainingMs)}' : '可使用');
    final activeProgress =
        durationMs <= 0 ? 0.0 : activeRemainingMs / durationMs;
    final cooldownProgress = cooldownMs <= 0
        ? 0.0
        : (1 - cooldownRemainingMs / cooldownMs).clamp(0.0, 1.0);
    final skillProgress = isActive ? activeProgress : cooldownProgress;
    final isMaxLevel = level >= maxLevel;
    final canUpgrade = !isMaxLevel && availableConstants >= upgradeCost;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: CircularProgressIndicator(
                        value: skillProgress,
                        strokeWidth: 3,
                        backgroundColor: const Color(0xFF1E2A3D),
                        color: isActive
                            ? const Color(0xFF5CE1E6)
                            : (isCooling
                                ? const Color(0xFFF5C542)
                                : const Color(0xFF8BE4B4)),
                      ),
                    ),
                    const Icon(Icons.timelapse, color: Color(0xFF8FA3BF)),
                  ],
                ),
                const SizedBox(width: 10),
                Text(
                  '主动技能：时间扭曲',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Text(
                  'Lv.$level',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF8FA3BF),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '持续 ${_formatDuration(durationMs)}，游戏速度 x2（冷却 ${_formatDuration(cooldownMs)}）',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8FA3BF),
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isActive
                              ? const Color(0xFF5CE1E6)
                              : (isCooling
                                  ? const Color(0xFFF5C542)
                                  : const Color(0xFF8BE4B4)),
                        ),
                  ),
                ),
                FilledButton(
                  onPressed: canUse ? onActivate : null,
                  child: const Text('启动'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isMaxLevel
                        ? '已满级'
                        : '强化消耗：${upgradeCost.toStringAsFixed(1)} 常数',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isMaxLevel
                              ? const Color(0xFF8FA3BF)
                              : const Color(0xFFF5C542),
                        ),
                  ),
                ),
                OutlinedButton(
                  onPressed: canUpgrade ? onUpgrade : null,
                  child: Text(isMaxLevel ? '已满级' : '强化'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(int ms) {
  final seconds = (ms / 1000).ceil();
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  if (minutes > 0) {
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }
  return '${remaining}s';
}
