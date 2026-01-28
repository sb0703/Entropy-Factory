import 'package:flutter/material.dart';

import 'game_state.dart';

enum DailyTaskType { shardGain, blueprintGain, researchComplete }

class DailyTaskDefinition {
  const DailyTaskDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.goal,
    required this.rewardType,
    required this.rewardAmount,
    this.icon = Icons.check_circle_outline,
  });

  final String id;
  final String title;
  final String description;
  final DailyTaskType type;
  final double goal;
  final ResourceType rewardType;
  final double rewardAmount;
  final IconData icon;
}

const List<DailyTaskDefinition> dailyTaskDefinitions = [
  DailyTaskDefinition(
    id: 'task_shard_gain',
    title: '采集达人',
    description: '今日累计获取 100k 碎片',
    type: DailyTaskType.shardGain,
    goal: 100000,
    rewardType: ResourceType.shard,
    rewardAmount: 200000,
    icon: Icons.scatter_plot,
  ),
  DailyTaskDefinition(
    id: 'task_blueprint_gain',
    title: '蓝图收藏',
    description: '今日累计获取 500 蓝图',
    type: DailyTaskType.blueprintGain,
    goal: 500,
    rewardType: ResourceType.part,
    rewardAmount: 50000,
    icon: Icons.auto_awesome,
  ),
  DailyTaskDefinition(
    id: 'task_research_done',
    title: '知识拓展',
    description: '完成 1 项研究',
    type: DailyTaskType.researchComplete,
    goal: 1,
    rewardType: ResourceType.blueprint,
    rewardAmount: 300,
    icon: Icons.science,
  ),
];

class DailyTaskStatus {
  const DailyTaskStatus({
    required this.def,
    required this.progress,
    required this.completed,
    required this.claimed,
  });

  final DailyTaskDefinition def;
  final double progress;
  final bool completed;
  final bool claimed;
}

List<DailyTaskStatus> buildDailyTaskStatus(GameState state) {
  return [
    for (final def in dailyTaskDefinitions)
      DailyTaskStatus(
        def: def,
        progress: switch (def.type) {
          DailyTaskType.shardGain => state.dailyShardGain,
          DailyTaskType.blueprintGain => state.dailyBlueprintGain,
          DailyTaskType.researchComplete => state.dailyResearchCompleted.toDouble(),
        },
        completed: switch (def.type) {
          DailyTaskType.shardGain => state.dailyShardGain >= def.goal,
          DailyTaskType.blueprintGain => state.dailyBlueprintGain >= def.goal,
          DailyTaskType.researchComplete =>
            state.dailyResearchCompleted >= def.goal,
        },
        claimed: state.dailyTasksClaimed.contains(def.id),
      ),
  ];
}
