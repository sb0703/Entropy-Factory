import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/game_controller.dart';
import '../../game/game_ui_state.dart';
import '../../game/research_definitions.dart';
import '../widgets/research_node_card.dart';

class ResearchTab extends ConsumerStatefulWidget {
  const ResearchTab({super.key});

  @override
  ConsumerState<ResearchTab> createState() => _ResearchTabState();
}

class _ResearchTabState extends ConsumerState<ResearchTab> {
  ResearchBranch _branch = ResearchBranch.industry;
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameUiProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final nodes = state.researchNodes
        .where((node) => node.branch == _branch)
        .toList(growable: false);
    final selectedNode = _resolveSelection(nodes);

    // 左侧节点选择，右侧（或底部）展示详情与购买入口。
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          _BranchSelector(
            selected: _branch,
            onChanged: (branch) {
              setState(() {
                _branch = branch;
                _selectedId = null;
              });
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '消耗蓝图解锁研究，获得永久加成',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8FA3BF),
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: nodes.length,
                    itemBuilder: (context, index) {
                      final node = nodes[index];
                      return ResearchNodeCard(
                        node: node,
                        isSelected: node.id == selectedNode?.id,
                        onTap: () {
                          setState(() {
                            _selectedId = node.id;
                          });
                        },
                      );
                    },
                  ),
                ),
                if (MediaQuery.of(context).size.width >= 900) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _ResearchDetailPanel(
                      node: selectedNode,
                      onPurchase: selectedNode == null
                          ? null
                          : () => controller.buyResearch(selectedNode.id),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (MediaQuery.of(context).size.width < 900) ...[
            const SizedBox(height: 12),
            _ResearchDetailPanel(
              node: selectedNode,
              onPurchase: selectedNode == null
                  ? null
                  : () => controller.buyResearch(selectedNode.id),
            ),
          ],
        ],
      ),
    );
  }

  ResearchNodeDisplay? _resolveSelection(List<ResearchNodeDisplay> nodes) {
    if (nodes.isEmpty) {
      return null;
    }
    for (final node in nodes) {
      if (node.id == _selectedId) {
        return node;
      }
    }
    return nodes.first;
  }
}

class _BranchSelector extends StatelessWidget {
  const _BranchSelector({
    required this.selected,
    required this.onChanged,
  });

  final ResearchBranch selected;
  final ValueChanged<ResearchBranch> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ResearchBranch>(
      segments: const [
        ButtonSegment(value: ResearchBranch.industry, label: Text('工业')),
        ButtonSegment(value: ResearchBranch.algorithm, label: Text('算法')),
        ButtonSegment(value: ResearchBranch.cosmos, label: Text('宇宙')),
      ],
      selected: {selected},
      onSelectionChanged: (value) {
        onChanged(value.first);
      },
    );
  }
}

class _ResearchDetailPanel extends StatelessWidget {
  const _ResearchDetailPanel({
    required this.node,
    required this.onPurchase,
  });

  final ResearchNodeDisplay? node;
  final VoidCallback? onPurchase;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: node == null
            ? Center(
                child: Text(
                  '请选择研究节点',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF8FA3BF),
                      ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node!.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '效果',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF8FA3BF),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    node!.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '成本',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF8FA3BF),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    node!.cost,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '前置：${node!.prerequisiteText}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8FA3BF),
                        ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: node!.canBuy ? onPurchase : null,
                    child: const Text('购买'),
                  ),
                ],
              ),
      ),
    );
  }
}
