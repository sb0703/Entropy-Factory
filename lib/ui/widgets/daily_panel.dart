import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/daily_tasks.dart';
import '../../game/event_cards.dart';
import '../../game/game_controller.dart';

/// 首页顶部的精简每日事件/任务入口，点击展开底部弹窗查看详情与领取奖励。
class DailyPanel extends ConsumerWidget {
  const DailyPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final eventId = state.activeEventCardId;
    final eventCard = eventId == null ? null : eventCardById[eventId];
    final eventActive =
        eventCard != null && state.activeEventExpiresAtMs > nowMs;
    final eventRemaining = eventActive
        ? Duration(milliseconds: state.activeEventExpiresAtMs - nowMs)
        : Duration.zero;

    final tasks = buildDailyTaskStatus(state);
    final unclaimed = tasks.where((t) => t.completed && !t.claimed).length;
    final eventLabel = eventActive
        ? '${eventCard.title} · 剩余 ${_formatDuration(eventRemaining)}'
        : '今日暂无事件卡';

    if (!eventActive && tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: const Color(0xFF0F1B2D),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _showDailySheet(
              context: context,
              eventCard: eventCard,
              eventActive: eventActive,
              remaining: eventRemaining,
              tasks: tasks,
              controller: controller,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 18, color: Color(0xFF5CE1E6)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '每日事件与任务',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        eventLabel,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: const Color(0xFF8FA3BF)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: unclaimed > 0
                        ? const Color(0xFF1E2A3D)
                        : const Color(0x331E2A3D),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: unclaimed > 0
                          ? const Color(0xFF8BE4B4)
                          : const Color(0xFF22324A),
                    ),
                  ),
                  child: Text(
                    '任务 ${tasks.length} | 可领 $unclaimed',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: unclaimed > 0
                              ? const Color(0xFF8BE4B4)
                              : const Color(0xFF8FA3BF),
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Color(0xFF8FA3BF)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showDailySheet({
  required BuildContext context,
  required EventCard? eventCard,
  required bool eventActive,
  required Duration remaining,
  required List<DailyTaskStatus> tasks,
  required GameController controller,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0B1524),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF22324A),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '今日事件与任务',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            if (eventActive && eventCard != null)
              _EventBanner(card: eventCard, remaining: remaining)
            else
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1B2D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF22324A)),
                ),
                child: Text(
                  '今日暂无事件卡',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: const Color(0xFF8FA3BF)),
                ),
              ),
            const SizedBox(height: 12),
            _TaskList(tasks: tasks, controller: controller),
          ],
        ),
      );
    },
  );
}

class _EventBanner extends StatelessWidget {
  const _EventBanner({required this.card, required this.remaining});

  final EventCard card;
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x332196F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2196F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(card.description,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: const Color(0xFF8FA3BF))),
          const SizedBox(height: 6),
          Text(
            '剩余时间：${_formatDuration(remaining)}',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: const Color(0xFF5CE1E6)),
          ),
        ],
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({required this.tasks, required this.controller});

  final List<DailyTaskStatus> tasks;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Text(
        '今日暂无每日任务',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: const Color(0xFF8FA3BF)),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final progress =
            ((task.progress / task.def.goal).clamp(0.0, 1.0)).toDouble();
        final canClaim = task.completed && !task.claimed;
        return Container(
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
                  Icon(task.def.icon,
                      size: 20,
                      color: task.completed
                          ? const Color(0xFF8BE4B4)
                          : const Color(0xFF8FA3BF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.def.title,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  FilledButton(
                    onPressed: canClaim
                        ? () {
                            controller.claimDailyTask(task.def.id);
                          }
                        : null,
                    child: Text(task.claimed ? '已领取' : '领取'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                task.def.description,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: const Color(0xFF8FA3BF)),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFF0B1524),
                color: task.completed
                    ? const Color(0xFF8BE4B4)
                    : const Color(0xFF5CE1E6),
                minHeight: 6.0,
              ),
              const SizedBox(height: 4),
              Text(
                '${task.progress.toStringAsFixed(0)} / ${task.def.goal.toStringAsFixed(0)}',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: const Color(0xFF8FA3BF)),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _formatDuration(Duration d) {
  if (d.isNegative || d.inSeconds <= 0) return '已结束';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  if (h > 0) return '$h小时${m.toString().padLeft(2, '0')}分';
  if (m > 0) return '$m分${s.toString().padLeft(2, '0')}秒';
  return '$s秒';
}
