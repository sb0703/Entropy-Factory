import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/game_controller.dart';
import '../../game/game_definitions.dart';
import '../../game/game_state.dart';
import '../../game/research_definitions.dart';

class LayoutPanel extends ConsumerStatefulWidget {
  const LayoutPanel({super.key});

  @override
  ConsumerState<LayoutPanel> createState() => _LayoutPanelState();
}

class _LayoutPanelState extends ConsumerState<LayoutPanel> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final placedCounts = _placedCounts(state.layoutGrid);

    if (!state.isLayoutUnlocked) {
      final layoutResearch = researchById[layoutUnlockResearchId];
      final costText = layoutResearch == null
          ? '请在研究中解锁设施布局功能。'
          : '在研究中解锁：${researchTitle(layoutResearch.id)}（消耗 ${layoutResearch.costBlueprints.toStringAsFixed(0)} 蓝图）';
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '设施布局（未解锁）',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                '解锁后可放置设施并获得邻接协同加成。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8FA3BF),
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                costText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFF5C542),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '设施布局',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              '相邻设施将触发协同加成。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8FA3BF),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '规则：采集邻接能量 +20%，转换邻接采集 +10%，合成邻接转换 +10%，能量邻接采集 +5%。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6F8198),
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              '布局格位：${state.layoutGrid.length}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8FA3BF),
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final def in buildingDefinitions)
                  _BuildChip(
                    id: def.id,
                    name: def.name,
                    available: state.buildingCount(def.id) -
                        (placedCounts[def.id] ?? 0),
                    selected: _selectedId == def.id,
                    onSelected: (selected) {
                      setState(() {
                        _selectedId = selected ? def.id : null;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              itemCount: state.layoutGrid.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: layoutColumns,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final id = state.layoutGrid[index];
                final def = id == null ? null : buildingById[id];
                return _LayoutCell(
                  label: def?.name ?? '空位',
                  tone: _toneFor(def?.type),
                  occupied: def != null,
                  onTap: () {
                    if (_selectedId == null) {
                      if (id != null) {
                        controller.clearLayoutSlot(index);
                      }
                      return;
                    }
                    controller.placeBuildingInLayout(_selectedId!, index);
                  },
                  onLongPress: () => controller.clearLayoutSlot(index),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildChip extends StatelessWidget {
  const _BuildChip({
    required this.id,
    required this.name,
    required this.available,
    required this.selected,
    required this.onSelected,
  });

  final String id;
  final String name;
  final int available;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final enabled = available > 0;
    return ChoiceChip(
      label: Text('$name (${available > 0 ? available : 0})'),
      selected: selected,
      onSelected: enabled ? onSelected : null,
    );
  }
}

class _LayoutCell extends StatelessWidget {
  const _LayoutCell({
    required this.label,
    required this.tone,
    required this.occupied,
    required this.onTap,
    required this.onLongPress,
  });

  final String label;
  final Color tone;
  final bool occupied;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0C1524),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: occupied ? tone.withAlpha(160) : const Color(0x331C2A3A),
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: occupied ? tone : const Color(0xFF8FA3BF),
                ),
          ),
        ),
      ),
    );
  }
}

Map<String, int> _placedCounts(List<String?> grid) {
  final counts = <String, int>{};
  for (final id in grid) {
    if (id == null) {
      continue;
    }
    counts[id] = (counts[id] ?? 0) + 1;
  }
  return counts;
}

Color _toneFor(BuildingType? type) {
  switch (type) {
    case BuildingType.shardProducer:
      return const Color(0xFF5CE1E6);
    case BuildingType.shardToPart:
      return const Color(0xFF8BE4B4);
    case BuildingType.partToBlueprint:
      return const Color(0xFFF5C542);
    case BuildingType.energyProducer:
      return const Color(0xFF9D7CFF);
    default:
      return const Color(0xFF8FA3BF);
  }
}
