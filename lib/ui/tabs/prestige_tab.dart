import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/big_number.dart';
import '../../game/constant_upgrades.dart';
import '../../game/game_controller.dart';
import '../../game/game_state.dart';
import '../../game/number_format.dart';
import '../../game/prestige_challenges.dart';
import '../../game/prestige_rules.dart';

class PrestigeTab extends ConsumerWidget {
  const PrestigeTab({super.key});

  Future<void> _playPrestigeTransition(BuildContext context) {
    return _playPrestigeTransitionOverlay(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final laws = state.resource(ResourceType.law);
    final constants = state.resource(ResourceType.constant);
    final preview = controller.prestigePreview();
    final canPrestige = controller.canPrestige();
    final activeChallengeId = state.activeChallengeId;
    final completedChallenges = state.completedChallenges;
    final moduleSlots = unlockedModuleSlots(state);
    final permanentBonus = permanentProductionBonus(state);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Text(
          '升维将重置进度，换取常数与永久强化',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF8FA3BF),
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '升维预估',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  '当前定律',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF8FA3BF),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatNumber(laws),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  '预计获得常数',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF8FA3BF),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatNumber(preview),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  '常数 = 向下取整(√定律 × ${constantFactor.toStringAsFixed(0)})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF8FA3BF),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '每 ${lawThreshold.toStringAsFixed(0)} 蓝图自动转化为 1 定律',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF8FA3BF),
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '永久解锁',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '永久模块槽：$moduleSlots',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF8FA3BF),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '永久产出加成：+${(permanentBonus * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFF5C542),
                      ),
                ),
                const SizedBox(height: 10),
                for (final unlock in permanentUnlockDefinitions)
                  _UnlockTile(
                    unlock: unlock,
                    unlocked: state.permanentUnlocks.contains(unlock.id),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '升维将重置',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                const _Bullet(text: '碎片、零件、蓝图、定律'),
                const _Bullet(text: '大部分设施'),
                const _Bullet(text: '配比设置'),
                const _Bullet(text: '已购研究'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '挑战升维',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                if (activeChallengeId != null)
                  _ActiveChallengeBanner(
                    challenge: prestigeChallenges.firstWhere(
                      (def) => def.id == activeChallengeId,
                      orElse: () => prestigeChallenges.first,
                    ),
                    onAbandon: controller.abandonChallenge,
                  ),
                if (activeChallengeId == null)
                  Text(
                    '完成挑战可获得永久解锁奖励。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8FA3BF),
                        ),
                  ),
                const SizedBox(height: 12),
                for (final challenge in prestigeChallenges)
                  _ChallengeTile(
                    challenge: challenge,
                    isActive: activeChallengeId == challenge.id,
                    isCompleted: completedChallenges.contains(challenge.id),
                    onStart: () => controller.startChallenge(challenge.id),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '保留内容',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                const _Bullet(text: '常数'),
                const _Bullet(text: '里程碑'),
                const _Bullet(text: '常数强化'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '常数强化',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '可用常数：${_formatNumber(constants)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF8FA3BF),
                      ),
                ),
                const SizedBox(height: 12),
                for (final def in constantUpgradeDefinitions)
                  _ConstantUpgradeTile(
                    def: def,
                    level: state.constantUpgrades[def.id] ?? 0,
                    available: constants,
                    onBuy: () => controller.buyConstantUpgrade(def.id),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Opacity(
            opacity: canPrestige ? 1 : 0.45,
            child: GestureDetector(
              onLongPress: () {
                if (!canPrestige) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('定律不足，无法升维')),
                  );
                  return;
                }
                _showPrestigeDialog(
                  context,
                  laws: laws,
                  preview: preview,
                  onConfirm: () async {
                    await _playPrestigeTransition(context);
                    if (!context.mounted) {
                      return;
                    }
                    controller.prestige();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('升维完成')),
                    );
                  },
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5CE1E6), Color(0xFFF5C542)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x445CE1E6),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  '长按升维',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Color(0xFF071018),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF5CE1E6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConstantUpgradeTile extends StatelessWidget {
  const _ConstantUpgradeTile({
    required this.def,
    required this.level,
    required this.available,
    required this.onBuy,
  });

  final ConstantUpgradeDefinition def;
  final int level;
  final BigNumber available;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final cost = BigNumber.fromDouble(constantUpgradeCost(def, level));
    final isMax = level >= def.maxLevel;
    final canBuy = !isMax && available >= cost;
    final costText = isMax ? '已满级' : '消耗常数：${_formatNumber(cost)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22324A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  def.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Text(
                'Lv.$level/${def.maxLevel}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF8FA3BF),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            def.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFB4C0D3),
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  costText,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isMax
                            ? const Color(0xFF8FA3BF)
                            : const Color(0xFFF5C542),
                      ),
                ),
              ),
              FilledButton(
                onPressed: canBuy ? onBuy : null,
                child: Text(isMax ? '已满级' : '购买'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _showPrestigeDialog(
  BuildContext context, {
  required BigNumber laws,
  required BigNumber preview,
  required VoidCallback onConfirm,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('确认升维'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前定律：${_formatNumber(laws)}'),
            const SizedBox(height: 6),
            Text('预计获得常数：${_formatNumber(preview)}'),
            const SizedBox(height: 12),
            Text(
              '将重置：碎片、零件、蓝图、定律、设施、配比、研究',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8FA3BF),
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              '将保留：常数、里程碑、常数强化',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8FA3BF),
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('确认升维'),
          ),
        ],
      );
    },
  );
}

Future<void> _playPrestigeTransitionOverlay(BuildContext context) async {
  if (!context.mounted) {
    return;
  }
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xCC050B12),
    transitionDuration: const Duration(milliseconds: 650),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _PrestigeTransition(animation: animation);
    },
  );
}

class _PrestigeTransition extends StatefulWidget {
  const _PrestigeTransition({required this.animation});

  final Animation<double> animation;

  @override
  State<_PrestigeTransition> createState() => _PrestigeTransitionState();
}

class _PrestigeTransitionState extends State<_PrestigeTransition> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeOutCubic,
    );
    final glowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    final warpScale = Tween<double>(begin: 0.92, end: 1.06).animate(curved);
    final warpRotation = Tween<double>(begin: -0.06, end: 0.06).animate(curved);
    final shimmerScale = Tween<double>(begin: 0.6, end: 1.4).animate(curved);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: curved,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.1,
                      colors: [
                        Color.lerp(
                          const Color(0xFF1B2B4B),
                          const Color(0xFF0B0F16),
                          curved.value,
                        )!,
                        const Color(0xFF04070D),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: curved,
              builder: (context, child) {
                return Transform.scale(
                  scale: warpScale.value,
                  child: Transform.rotate(
                    angle: warpRotation.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF5CE1E6),
                      Color(0x00243B5A),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: glowOpacity,
              child: Transform.scale(
                scale: shimmerScale.value,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF5C542).withAlpha(180),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: glowOpacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '升维中…',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '空间扭曲 · 逻辑重组',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFB4C0D3),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatNumber(Object value) {
    return formatNumber(value);
}

class _UnlockTile extends StatelessWidget {
  const _UnlockTile({
    required this.unlock,
    required this.unlocked,
  });

  final PermanentUnlock unlock;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked ? const Color(0xFF5CE1E6) : const Color(0xFF22324A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            unlock.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: unlocked
                      ? const Color(0xFF5CE1E6)
                      : const Color(0xFFE6EDF7),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            unlock.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF8FA3BF),
                ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({
    required this.challenge,
    required this.isActive,
    required this.isCompleted,
    required this.onStart,
  });

  final PrestigeChallenge challenge;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final statusText = isCompleted
        ? '已完成'
        : (isActive ? '进行中' : '未开始');
    final canStart = !isCompleted && !isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22324A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  challenge.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Text(
                statusText,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isCompleted
                          ? const Color(0xFF8BE4B4)
                          : (isActive
                              ? const Color(0xFFF5C542)
                              : const Color(0xFF8FA3BF)),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            challenge.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF8FA3BF),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '奖励：${permanentUnlockById[challenge.rewardUnlockId]?.title ?? '永久模块槽'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF8BE4B4),
                ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: canStart ? onStart : null,
              child: Text(isActive ? '进行中' : '开始挑战'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveChallengeBanner extends StatelessWidget {
  const _ActiveChallengeBanner({
    required this.challenge,
    required this.onAbandon,
  });

  final PrestigeChallenge challenge;
  final VoidCallback onAbandon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2B4B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5C542)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '当前挑战：${challenge.title}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF5C542),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            challenge.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFB4C0D3),
                ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onAbandon,
              child: const Text('放弃挑战'),
            ),
          ),
        ],
      ),
    );
  }
}
