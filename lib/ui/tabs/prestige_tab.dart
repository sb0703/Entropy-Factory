import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../../game/big_number.dart';
import '../../game/constant_upgrades.dart';
import '../../game/game_controller.dart';
import '../../game/game_state.dart';
import '../../game/number_format.dart';
import '../../game/prestige_challenges.dart';
import '../../game/prestige_rules.dart';
import '../effects/black_hole_effect.dart';

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
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8FA3BF)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: Card(
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
                  ),
                if (activeChallengeId == null)
                  Text(
                    '完成挑战可获得永久解锁奖励。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8FA3BF),
                    ),
                  ),
                if (activeChallengeId == null)
                  Text(
                    '挑战开启后不可取消，请谨慎选择。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFF5C542),
                    ),
                  ),
                const SizedBox(height: 12),
                for (final challenge in prestigeChallenges)
                  _ChallengeTile(
                    challenge: challenge,
                    isActive: activeChallengeId == challenge.id,
                    isCompleted: completedChallenges.contains(challenge.id),
                    onStart: () => _confirmStartChallenge(
                      context,
                      challenge: challenge,
                      onConfirm: () => controller.startChallenge(challenge.id),
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
                HapticFeedback.lightImpact();
                if (!canPrestige) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('定律不足，无法升维')));
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
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('升维完成')));
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
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
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFFB4C0D3)),
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8FA3BF)),
            ),
            const SizedBox(height: 6),
            Text(
              '将保留：常数、里程碑、常数强化',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8FA3BF)),
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
              HapticFeedback.lightImpact();
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
      return const _PrestigeTransition();
    },
  );
}

class _PrestigeTransition extends StatefulWidget {
  const _PrestigeTransition();

  @override
  State<_PrestigeTransition> createState() => _PrestigeTransitionState();
}

class _PrestigeTransitionState extends State<_PrestigeTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Star> _stars = [];
  final int _starCount = 300;

  @override
  void initState() {
    super.initState();
    _initStars();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  void _initStars() {
    _stars.clear();
    final random = math.Random();
    for (var i = 0; i < _starCount; i++) {
      _stars.add(Star(random: random));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // 1. 在最外层设置黑色背景
        return Container(
          color: Colors.black,
          child: SizedBox.expand(
            child: CustomPaint(
              painter: BlackHolePainter(
                stars: _stars,
                animationValue: _controller.value,
                isDevouring: true,
              ),
              // 2. 这里的 child 只需要负责布局文字，不要设置背景色
              child: Container(
                // color: Colors.black, // <--- 【关键】删掉这一行，或者改为 Colors.transparent
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 它的作用是把下面的文字往下挤，给 Painter 画的黑洞腾出空间
                    // 高度建议比 painter 里的半径大一点 (painter里半径是32)
                    const SizedBox(height: 80),
                    const SizedBox(height: 16),
                    // 主标题：升维中
                    Text(
                      '升  维  中', // 手动加空格或者靠 letterSpacing
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: .9,
                        ), // 不要纯白，稍微透一点背景色
                        fontSize: 24, // 稍微大一点
                        fontWeight: FontWeight.w200, // 【关键】极细字体，显得高级
                        letterSpacing: 12.0, // 【关键】巨大的字间距，营造呼吸感
                        shadows: [
                          Shadow(
                            color: Colors.cyanAccent.withValues(alpha: .5),
                            blurRadius: 10,
                          ), // 淡淡的辉光
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 副标题：改成英文或数据流，显得更像系统提示，而不是解说
                    Text(
                      'DIMENSION ASCENSION // SYSTEM REBOOT',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .4), // 很淡，作为装饰
                        fontSize: 10,
                        fontFamily: 'Courier', // 【关键】使用等宽字体(代码风)，像终端输出
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> _confirmStartChallenge(
  BuildContext context, {
  required PrestigeChallenge challenge,
  required VoidCallback onConfirm,
}) async {
  final first = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('确认开启挑战'),
        content: Text(
          '挑战「${challenge.title}」将重置当前进度，并且开启后无法取消。',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('继续'),
          ),
        ],
      );
    },
  );
  if (first != true || !context.mounted) {
    return;
  }
  final second = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('最后确认'),
        content: const Text('确定开始挑战？开启后无法取消。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('返回'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('开始挑战'),
          ),
        ],
      );
    },
  );
  if (second == true && context.mounted) {
    onConfirm();
  }
}

String _formatNumber(Object value) {
  return formatNumber(value);
}

class _UnlockTile extends StatelessWidget {
  const _UnlockTile({required this.unlock, required this.unlocked});

  final PermanentUnlock unlock;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8FA3BF)),
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
    final statusText = isCompleted ? '已完成' : (isActive ? '进行中' : '未开始');
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8FA3BF)),
          ),
          const SizedBox(height: 6),
          Text(
            '奖励：${permanentUnlockById[challenge.rewardUnlockId]?.title ?? '永久模块槽'}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8BE4B4)),
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
  const _ActiveChallengeBanner({required this.challenge});

  final PrestigeChallenge challenge;

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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFFB4C0D3)),
          ),
          const SizedBox(height: 10),
          Text(
            '挑战已开启，无法取消。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFFF5C542)),
          ),
        ],
      ),
    );
  }
}
