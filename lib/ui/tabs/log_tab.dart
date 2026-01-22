import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/game_controller.dart';
import '../../game/game_ui_state.dart';

class LogTab extends ConsumerWidget {
  const LogTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameUiProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final showEmpty = state.logEntries.isEmpty;

    // 顶部固定存档与里程碑，其后显示事件日志。
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: showEmpty ? 4 : state.logEntries.length + 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            '记录关键事件、里程碑与存档操作',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF8FA3BF),
                ),
          );
        }

        if (index == 1) {
          return _ArchiveCard(
            onExport: () async {
              final jsonText = controller.exportSave();
              await Clipboard.setData(ClipboardData(text: jsonText));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('存档已复制到剪贴板')),
                );
              }
            },
            onImport: () async {
              final jsonText = await _showImportDialog(context);
              if (jsonText == null || jsonText.trim().isEmpty) {
                return;
              }
              final success = await controller.importSave(jsonText.trim());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '存档导入成功' : '存档导入失败'),
                  ),
                );
              }
            },
          );
        }

        if (index == 2) {
          return _MilestoneCard(milestones: state.milestones);
        }

        if (showEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '暂无记录',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF8FA3BF),
                  ),
            ),
          );
        }

        final entry = state.logEntries[index - 3];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF5C542),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.detail,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF9CB0C9),
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  entry.timeLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF8FA3BF),
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  const _ArchiveCard({
    required this.onExport,
    required this.onImport,
  });

  final VoidCallback onExport;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '存档管理',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton(
                  onPressed: onExport,
                  child: const Text('复制存档'),
                ),
                FilledButton(
                  onPressed: onImport,
                  child: const Text('导入存档'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '导入会覆盖当前进度',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8FA3BF),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.milestones});

  final List<MilestoneDisplay> milestones;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '里程碑',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            if (milestones.isEmpty)
              Text(
                '暂无里程碑',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8FA3BF),
                    ),
              ),
            for (final milestone in milestones) ...[
              _MilestoneRow(milestone: milestone),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.milestone});

  final MilestoneDisplay milestone;

  @override
  Widget build(BuildContext context) {
    final tone = milestone.achieved
        ? const Color(0xFF8BE4B4)
        : const Color(0xFF8FA3BF);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1524),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: tone,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                milestone.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                milestone.achieved ? '已达成' : '未达成',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: tone,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            milestone.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF9CB0C9),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            milestone.effectText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF8FA3BF),
                ),
          ),
        ],
      ),
    );
  }
}

Future<String?> _showImportDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('导入存档'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: '粘贴存档文本',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('导入'),
          ),
        ],
      );
    },
  );
}
