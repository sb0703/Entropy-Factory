import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/big_number.dart';
import '../../game/game_controller.dart';
import '../../game/game_state.dart';
import '../../game/number_format.dart';
import '../../game/skill_definitions.dart';

class SkillTab extends ConsumerStatefulWidget {
  const SkillTab({super.key});

  @override
  ConsumerState<SkillTab> createState() => _SkillTabState();
}

class _SkillTabState extends ConsumerState<SkillTab> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final skills = skillDefinitions;
    final selected = _resolveSelection(skills);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              _SkillHeader(state: gameState, controller: controller),
              const SizedBox(height: 12),
              Expanded(
                child: isWide
                    ? Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _SkillGrid(
                              skills: skills,
                              selectedId: selected?.id,
                              onSelect: (def) {
                                setState(() {
                                  _selectedId = def.id;
                                });
                              },
                              state: gameState,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _SkillDetailPanel(
                              skill: selected,
                              state: gameState,
                              controller: controller,
                            ),
                          ),
                        ],
                      )
                    : _SkillGrid(
                        skills: skills,
                        selectedId: selected?.id,
                        onSelect: (def) {
                          setState(() {
                            _selectedId = def.id;
                          });
                          _showSkillDetailSheet(def);
                        },
                        state: gameState,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSkillDetailSheet(SkillDefinition skill) async {
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFF0B1321),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _SkillDetailPanel(
              skill: skill,
              state: ref.read(gameControllerProvider),
              controller: ref.read(gameControllerProvider.notifier),
            ),
          ),
        );
      },
    );
  }

  SkillDefinition? _resolveSelection(List<SkillDefinition> skills) {
    if (skills.isEmpty) {
      return null;
    }
    for (final skill in skills) {
      if (skill.id == _selectedId) {
        return skill;
      }
    }
    return skills.first;
  }
}

class _SkillHeader extends StatelessWidget {
  const _SkillHeader({required this.state, required this.controller});

  final GameState state;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final slots = controller.maxSkillSlots(state);
    final equipped = state.equippedSkills
        .map((id) => skillById[id]?.name ?? id)
        .toList();
    final skillPointCost = controller.skillPointCost(state.skillPoints);
    final canBuySkillPoint =
        state.resource(ResourceType.blueprint) >= skillPointCost;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '技能树',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          '解锁后需要装配到技能槽中，主动技能可在任意页面快速启用',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: const Color(0xFF8FA3BF)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(label: '技能点', value: '${state.skillPoints}'),
            _InfoChip(
              label: '技能槽',
              value: '${state.equippedSkills.length}/$slots',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (equipped.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final name in equipped) Chip(label: Text(name))],
          )
        else
          Text(
            '当前未装配技能',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: const Color(0xFF8FA3BF)),
          ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '兑换技能点：消耗 ${_formatNumber(skillPointCost)} 蓝图',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8FA3BF),
                        ),
                  ),
                ),
                FilledButton(
                  onPressed: canBuySkillPoint ? controller.buySkillPoint : null,
                  child: const Text('兑换'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B2D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF22324A)),
      ),
      child: Text(
        '$label：$value',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: const Color(0xFF8FA3BF)),
      ),
    );
  }
}

class _SkillGrid extends StatelessWidget {
  const _SkillGrid({
    required this.skills,
    required this.selectedId,
    required this.onSelect,
    required this.state,
  });

  final List<SkillDefinition> skills;
  final String? selectedId;
  final ValueChanged<SkillDefinition> onSelect;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final def = skills[index];
        final isSelected = def.id == selectedId;
        final isUnlocked = state.unlockedSkills.contains(def.id);
        final prereqMet = skillPrerequisitesMet(state, def);
        return _SkillNodeCard(
          skill: def,
          isSelected: isSelected,
          isUnlocked: isUnlocked,
          prereqMet: prereqMet,
          onTap: () => onSelect(def),
        );
      },
    );
  }
}

class _SkillNodeCard extends StatelessWidget {
  const _SkillNodeCard({
    required this.skill,
    required this.isSelected,
    required this.isUnlocked,
    required this.prereqMet,
    required this.onTap,
  });

  final SkillDefinition skill;
  final bool isSelected;
  final bool isUnlocked;
  final bool prereqMet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typeLabel = skill.type == SkillType.active ? '主动' : '被动';
    final status = isUnlocked ? '已解锁' : (prereqMet ? '可解锁' : '未满足');
    return Card(
      clipBehavior: Clip.antiAlias,
      color: isSelected ? const Color(0xFF16233B) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1E2A3D),
                    child: Icon(skill.icon, color: const Color(0xFF8FA3BF)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      skill.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                typeLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF8FA3BF),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isUnlocked
                          ? const Color(0xFF8BE4B4)
                          : (prereqMet
                              ? const Color(0xFFF5C542)
                              : const Color(0xFF8FA3BF)),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillDetailPanel extends StatelessWidget {
  const _SkillDetailPanel({
    required this.skill,
    required this.state,
    required this.controller,
  });

  final SkillDefinition? skill;
  final GameState state;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    if (skill == null) {
      return const SizedBox.shrink();
    }
    final def = skill!;
    final isUnlocked = state.unlockedSkills.contains(def.id);
    final isEquipped = state.equippedSkills.contains(def.id);
    final prereqMet = skillPrerequisitesMet(state, def);
    final prereqText = def.prerequisites.isEmpty
        ? '无'
        : def.prerequisites.map((id) => skillById[id]?.name ?? id).join('、');

    final blueprintCost = BigNumber.fromDouble(def.costBlueprints);
    final canUseBlueprints = def.costBlueprints > 0;
    final canUnlockBlueprints =
        canUseBlueprints &&
        prereqMet &&
        state.resource(ResourceType.blueprint) >= blueprintCost &&
        !isUnlocked;

    final canUsePoints = def.costSkillPoints > 0;
    final canUnlockPoints =
        canUsePoints &&
        prereqMet &&
        state.skillPoints >= def.costSkillPoints &&
        !isUnlocked;

    final slotLimit = controller.maxSkillSlots(state);
    final canEquip =
        isUnlocked && (isEquipped || state.equippedSkills.length < slotLimit);

    final isActive = def.type == SkillType.active;
    final cooldownMs = _cooldownMs(def, state, controller);
    final durationMs = _durationMs(def, state, controller);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF1E2A3D),
                  child: Icon(def.icon, color: const Color(0xFF8FA3BF)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    def.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  def.type == SkillType.active ? '主动' : '被动',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF8FA3BF),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              def.description,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: const Color(0xFF8FA3BF)),
            ),
            if (isActive) ...[
              const SizedBox(height: 10),
              Text(
                '持续 ${_formatDuration(durationMs)}，冷却 ${_formatDuration(cooldownMs)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: const Color(0xFF8FA3BF)),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '前置：$prereqText',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: prereqMet
                        ? const Color(0xFF8FA3BF)
                        : const Color(0xFFF5C542),
                  ),
            ),
            const SizedBox(height: 12),
            if (!isUnlocked) ...[
              if (canUseBlueprints)
                Text(
                  '消耗：${_formatNumber(blueprintCost)} 蓝图',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF8FA3BF),
                      ),
                ),
              if (canUsePoints)
                Text(
                  '消耗：${def.costSkillPoints} 技能点',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF8FA3BF),
                      ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (canUseBlueprints)
                    FilledButton(
                      onPressed: canUnlockBlueprints
                          ? () => controller.unlockSkillWithBlueprints(def.id)
                          : null,
                      child: const Text('使用蓝图解锁'),
                    ),
                  if (canUseBlueprints && canUsePoints)
                    const SizedBox(width: 8),
                  if (canUsePoints)
                    OutlinedButton(
                      onPressed: canUnlockPoints
                          ? () => controller.unlockSkillWithPoints(def.id)
                          : null,
                      child: const Text('使用技能点解锁'),
                    ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  FilledButton(
                    onPressed: canEquip
                        ? () => controller.toggleEquipSkill(def.id)
                        : null,
                    child: Text(isEquipped ? '卸下' : '装配'),
                  ),
                  const SizedBox(width: 8),
                  if (!canEquip && !isEquipped)
                    Text(
                      '技能槽已满',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFF5C542),
                          ),
                    ),
                ],
              ),
            ],
            if (_shouldShowUpgrade(def.id)) ...[
              const SizedBox(height: 12),
              _SkillUpgradeRow(
                skillId: def.id,
                state: state,
                controller: controller,
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _shouldShowUpgrade(String skillId) {
    return skillId == 'skill_time_warp' || skillId == 'skill_overclock';
  }

  int _cooldownMs(
    SkillDefinition def,
    GameState state,
    GameController controller,
  ) {
    switch (def.id) {
      case 'skill_time_warp':
        return controller.timeWarpCooldownMs(state);
      case 'skill_overclock':
        return controller.overclockCooldownMs(state);
      default:
        return def.cooldownMs;
    }
  }

  int _durationMs(
    SkillDefinition def,
    GameState state,
    GameController controller,
  ) {
    switch (def.id) {
      case 'skill_time_warp':
        return controller.timeWarpDurationMs(state);
      case 'skill_overclock':
        return controller.overclockDurationMs(state);
      default:
        return def.durationMs;
    }
  }
}

class _SkillUpgradeRow extends StatelessWidget {
  const _SkillUpgradeRow({
    required this.skillId,
    required this.state,
    required this.controller,
  });

  final String skillId;
  final GameState state;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final isTimeWarp = skillId == 'skill_time_warp';
    final level = isTimeWarp ? state.timeWarpLevel : state.overclockLevel;
    final maxLevel = isTimeWarp
        ? controller.timeWarpMaxLevel()
        : controller.overclockMaxLevel();
    final cost = isTimeWarp
        ? controller.timeWarpUpgradeCost(level)
        : controller.overclockUpgradeCost(level);
    final canUpgrade =
        level < maxLevel && state.resource(ResourceType.constant) >= cost;

    return Row(
      children: [
        Expanded(
          child: Text(
            '强化等级 Lv.$level / $maxLevel，消耗 ${_formatNumber(cost)} 常数',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: level >= maxLevel
                      ? const Color(0xFF8FA3BF)
                      : const Color(0xFFF5C542),
                ),
          ),
        ),
        OutlinedButton(
          onPressed: canUpgrade
              ? (isTimeWarp
                  ? controller.buyTimeWarpUpgrade
                  : controller.buyOverclockUpgrade)
              : null,
          child: Text(level >= maxLevel ? '已满级' : '强化'),
        ),
      ],
    );
  }
}

String _formatNumber(Object value) {
  return formatNumber(value);
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
