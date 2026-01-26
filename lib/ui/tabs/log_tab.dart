import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/game_controller.dart';
import '../../game/game_ui_state.dart';

class LogTab extends ConsumerStatefulWidget {
  const LogTab({super.key});

  @override
  ConsumerState<LogTab> createState() => _LogTabState();
}

class _LogTabState extends ConsumerState<LogTab> {
  bool _logsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameUiProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        _ArchiveCard(
          onExport: () async {
            final jsonText = controller.exportSave();
            await Clipboard.setData(ClipboardData(text: jsonText));
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('日志已复制到剪贴板')));
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
                SnackBar(content: Text(success ? '日志导入成功' : '日志导入失败')),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        _MilestoneCard(milestones: state.milestones),
        const SizedBox(height: 12),
        _LogHeader(
          expanded: _logsExpanded,
          onToggle: () {
            setState(() {
              _logsExpanded = !_logsExpanded;
            });
          },
        ),
        const SizedBox(height: 12),
        AnimatedCrossFade(
          firstChild: const _LogCollapsedMessage(),
          secondChild: _LogList(entries: state.logEntries),
          duration: const Duration(milliseconds: 200),
          crossFadeState: _logsExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
        ),
      ],
    );
  }
}

class _LogHeader extends StatelessWidget {
  const _LogHeader({required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '事件日志',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8FA3BF)),
          ),
        ),
        IconButton(
          onPressed: onToggle,
          icon: Icon(
            expanded ? Icons.expand_less : Icons.expand_more,
            color: const Color(0xFF8FA3BF),
          ),
          tooltip: expanded ? '收起日志' : '展开日志',
        ),
      ],
    );
  }
}

class _LogList extends StatelessWidget {
  const _LogList({required this.entries});

  final List<LogEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          '暂无日志',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF8FA3BF)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in entries) ...[
          _LogEntryCard(entry: entry),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _LogEntryCard extends StatelessWidget {
  const _LogEntryCard({required this.entry});

  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
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
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: const Color(0xFF8FA3BF)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogCollapsedMessage extends StatelessWidget {
  const _LogCollapsedMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22324A)),
      ),
      child: Text(
        '日志已折叠，展开以查看最近事件。',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF8FA3BF)),
      ),
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  const _ArchiveCard({required this.onExport, required this.onImport});

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
              '日志管理',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton(onPressed: onExport, child: const Text('导出存档')),
                FilledButton(onPressed: onImport, child: const Text('导入存档')),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '导入时请粘贴整个 JSON 字符串',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8FA3BF)),
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (milestones.isEmpty)
              Text(
                '暂无里程碑',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8FA3BF)),
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
                decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                milestone.title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                milestone.achieved ? '已解锁' : '未解锁',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: tone),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            milestone.description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF9CB0C9)),
          ),
          const SizedBox(height: 4),
          Text(
            milestone.effectText,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF8FA3BF)),
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
        title: const Text('导入日志'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: '填写导出日志字符串',
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
