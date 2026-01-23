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
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final placedCounts = _placedCounts(state.layoutGrid);
    final nextLayoutId = _nextLayoutResearchId(state);

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
            const SizedBox(height: 4),
            Text(
              '辐射核心会削弱周围设施 -8%（可叠加，最低保留 50%）。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6F8198),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '效率说明：采集 +20%/能量，能量 +5%/采集，转换 +10%/采集，合成 +10%/转换。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6F8198),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '连线提示：青色连线表示获得相邻加成，红色连线表示受到辐射削弱。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6F8198),
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              '已解锁：${state.layoutUnlockedColumns}x${state.layoutUnlockedRows}（${state.layoutUnlockedCount} 格）',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8FA3BF),
                  ),
            ),
            if (nextLayoutId != null) ...[
              const SizedBox(height: 4),
              Text(
                '下一阶段：${researchTitle(nextLayoutId)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFF5C542),
                    ),
              ),
            ],
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
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 8.0;
                final maxWidth = constraints.maxWidth;
                final cellSize =
                    (maxWidth - spacing * (layoutColumns - 1)) / layoutColumns;
                final gridHeight =
                    cellSize * layoutRows + spacing * (layoutRows - 1);

                return SizedBox(
                  height: gridHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _LayoutLinkPainter(
                              layout: state.layoutGrid,
                              state: state,
                              cellSize: cellSize,
                              spacing: spacing,
                            ),
                          ),
                        ),
                      ),
                      GridView.builder(
                        itemCount: state.layoutGrid.length,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: layoutColumns,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          final unlocked = state.isLayoutSlotUnlocked(index);
                          final id = state.layoutGrid[index];
                          final def = id == null ? null : buildingById[id];
                          final bonus = def == null
                              ? 1.0
                              : _adjacencyBonus(
                                  state.layoutGrid,
                                  index,
                                  def.type,
                                  state,
                                );
                final highlightTone = bonus == 1.0
                    ? null
                    : (bonus > 1.0
                        ? const Color(0xFF5CE1E6)
                        : const Color(0xFFFF6B6B));
                          return _LayoutCell(
                            label: unlocked ? (def?.name ?? '空位') : '锁定',
                            tone: _toneFor(def?.type),
                            occupied: def != null && unlocked,
                            locked: !unlocked,
                            highlight: highlightTone,
                            onTap: () {
                              if (!unlocked) {
                                return;
                              }
                              setState(() {
                                _selectedIndex = index;
                              });
                              if (_selectedId == null) {
                                if (id != null) {
                                  controller.clearLayoutSlot(index);
                                }
                                return;
                              }
                              controller.placeBuildingInLayout(
                                _selectedId!,
                                index,
                              );
                            },
                            onLongPress: unlocked
                                ? () => controller.clearLayoutSlot(index)
                                : () {},
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _LayoutDetail(
              state: state,
              index: _selectedIndex,
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

class _LayoutDetail extends StatelessWidget {
  const _LayoutDetail({
    required this.state,
    required this.index,
  });

  final GameState state;
  final int? index;

  @override
  Widget build(BuildContext context) {
    if (index == null || index! < 0 || index! >= state.layoutGrid.length) {
      return Text(
        '提示：点击布局格位可查看邻接效率明细。',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6F8198),
            ),
      );
    }
    if (!state.isLayoutSlotUnlocked(index!)) {
      return Text(
        '该格位尚未解锁。',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6F8198),
            ),
      );
    }
    final id = state.layoutGrid[index!];
    if (id == null) {
      return Text(
        '该格位为空。',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6F8198),
            ),
      );
    }
    final def = buildingById[id];
    if (def == null) {
      return const SizedBox.shrink();
    }
    final detail = _adjacencyDetail(state.layoutGrid, index!, def.type, state);
    final bonusPercent = ((detail.bonus - 1) * 100).round();
    final summary = bonusPercent == 0
        ? '当前无邻接加成'
        : (bonusPercent > 0 ? '当前加成 +$bonusPercent%' : '当前削弱 $bonusPercent%');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '格位：${def.name}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          summary,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: bonusPercent >= 0
                    ? const Color(0xFF8FA3BF)
                    : const Color(0xFFFF9A9A),
              ),
        ),
        if (detail.entries.isNotEmpty) ...[
          const SizedBox(height: 6),
          for (final entry in detail.entries)
            Text(
              entry,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6F8198),
                  ),
            ),
        ],
      ],
    );
  }
}

class _LayoutCell extends StatelessWidget {
  const _LayoutCell({
    required this.label,
    required this.tone,
    required this.occupied,
    required this.locked,
    required this.highlight,
    required this.onTap,
    required this.onLongPress,
  });

  final String label;
  final Color tone;
  final bool occupied;
  final bool locked;
  final Color? highlight;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: locked ? const Color(0xFF0B1220) : const Color(0xFF0C1524),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: locked
                ? const Color(0x221C2A3A)
                : (highlight ?? (occupied
                        ? tone.withAlpha(160)
                        : const Color(0x331C2A3A))),
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: locked
                      ? const Color(0xFF3F4A5C)
                      : (occupied ? tone : const Color(0xFF8FA3BF)),
                ),
          ),
        ),
      ),
    );
  }
}

String? _nextLayoutResearchId(GameState state) {
  if (!state.researchPurchased.contains(layoutExpandResearchId)) {
    return layoutExpandResearchId;
  }
  if (!state.researchPurchased.contains(layoutMaxResearchId)) {
    return layoutMaxResearchId;
  }
  return null;
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

class _LayoutLinkPainter extends CustomPainter {
  _LayoutLinkPainter({
    required this.layout,
    required this.state,
    required this.cellSize,
    required this.spacing,
  });

  final List<String?> layout;
  final GameState state;
  final double cellSize;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final positivePaint = Paint()
      ..color = const Color(0xFF5CE1E6).withAlpha(120)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final negativePaint = Paint()
      ..color = const Color(0xFFFF6B6B).withAlpha(140)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var index = 0; index < layout.length; index++) {
      if (!state.isLayoutSlotUnlocked(index)) {
        continue;
      }
      final id = layout[index];
      if (id == null) {
        continue;
      }
      final def = buildingById[id];
      if (def == null) {
        continue;
      }
      for (final neighbor in _neighborIndices(index)) {
        if (neighbor <= index) {
          continue;
        }
        if (!state.isLayoutSlotUnlocked(neighbor)) {
          continue;
        }
        final neighborId = layout[neighbor];
        if (neighborId == null) {
          continue;
        }
        final neighborDef = buildingById[neighborId];
        if (neighborDef == null) {
          continue;
        }
        final linkType = _linkType(def.type, neighborDef, neighborId);
        if (linkType == null) {
          continue;
        }
        final paint =
            linkType == _LinkType.positive ? positivePaint : negativePaint;
        final start = _cellCenter(index);
        final end = _cellCenter(neighbor);
        canvas.drawLine(start, end, paint);
      }
    }
  }

  Offset _cellCenter(int index) {
    final row = index ~/ layoutColumns;
    final col = index % layoutColumns;
    final dx = col * (cellSize + spacing) + cellSize / 2;
    final dy = row * (cellSize + spacing) + cellSize / 2;
    return Offset(dx, dy);
  }

  @override
  bool shouldRepaint(covariant _LayoutLinkPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.state != state ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.spacing != spacing;
  }
}

enum _LinkType { positive, negative }

_LinkType? _linkType(
  BuildingType type,
  BuildingDefinition neighborDef,
  String neighborId,
) {
  if (neighborId == 'radiation_core' && type != BuildingType.energyProducer) {
    return _LinkType.negative;
  }
  switch (type) {
    case BuildingType.shardProducer:
      return neighborDef.type == BuildingType.energyProducer
          ? _LinkType.positive
          : null;
    case BuildingType.shardToPart:
      return neighborDef.type == BuildingType.shardProducer
          ? _LinkType.positive
          : null;
    case BuildingType.partToBlueprint:
      return neighborDef.type == BuildingType.shardToPart
          ? _LinkType.positive
          : null;
    case BuildingType.energyProducer:
      return neighborDef.type == BuildingType.shardProducer
          ? _LinkType.positive
          : null;
  }
}

double _adjacencyBonus(
  List<String?> layout,
  int index,
  BuildingType type,
  GameState state,
) {
  final neighbors = _neighborIndices(index);
  var bonus = 1.0;
  for (final n in neighbors) {
    if (!state.isLayoutSlotUnlocked(n)) {
      continue;
    }
    final neighborId = layout[n];
    if (neighborId == null) {
      continue;
    }
    final neighborDef = buildingById[neighborId];
    if (neighborDef == null) {
      continue;
    }
    if (neighborId == 'radiation_core' && type != BuildingType.energyProducer) {
      bonus -= 0.08;
      continue;
    }
    switch (type) {
      case BuildingType.shardProducer:
        if (neighborDef.type == BuildingType.energyProducer) {
          bonus += 0.2;
        }
        break;
      case BuildingType.shardToPart:
        if (neighborDef.type == BuildingType.shardProducer) {
          bonus += 0.1;
        }
        break;
      case BuildingType.partToBlueprint:
        if (neighborDef.type == BuildingType.shardToPart) {
          bonus += 0.1;
        }
        break;
      case BuildingType.energyProducer:
        if (neighborDef.type == BuildingType.shardProducer) {
          bonus += 0.05;
        }
        break;
    }
  }
  return bonus.clamp(0.5, 2.0);
}

List<int> _neighborIndices(int index) {
  final row = index ~/ layoutColumns;
  final col = index % layoutColumns;
  final neighbors = <int>[];
  if (row > 0) {
    neighbors.add(index - layoutColumns);
  }
  if (row < layoutRows - 1) {
    neighbors.add(index + layoutColumns);
  }
  if (col > 0) {
    neighbors.add(index - 1);
  }
  if (col < layoutColumns - 1) {
    neighbors.add(index + 1);
  }
  return neighbors;
}

class _AdjacencyDetail {
  const _AdjacencyDetail({
    required this.bonus,
    required this.entries,
  });

  final double bonus;
  final List<String> entries;
}

_AdjacencyDetail _adjacencyDetail(
  List<String?> layout,
  int index,
  BuildingType type,
  GameState state,
) {
  final neighbors = _neighborIndices(index);
  var bonus = 1.0;
  final entries = <String>[];
  var energyLinks = 0;
  var shardLinks = 0;
  var converterLinks = 0;
  var radiationLinks = 0;

  for (final n in neighbors) {
    if (!state.isLayoutSlotUnlocked(n)) {
      continue;
    }
    final neighborId = layout[n];
    if (neighborId == null) {
      continue;
    }
    if (neighborId == 'radiation_core' && type != BuildingType.energyProducer) {
      radiationLinks += 1;
      bonus -= 0.08;
      continue;
    }
    final neighborDef = buildingById[neighborId];
    if (neighborDef == null) {
      continue;
    }
    switch (type) {
      case BuildingType.shardProducer:
        if (neighborDef.type == BuildingType.energyProducer) {
          energyLinks += 1;
          bonus += 0.2;
        }
        break;
      case BuildingType.shardToPart:
        if (neighborDef.type == BuildingType.shardProducer) {
          shardLinks += 1;
          bonus += 0.1;
        }
        break;
      case BuildingType.partToBlueprint:
        if (neighborDef.type == BuildingType.shardToPart) {
          converterLinks += 1;
          bonus += 0.1;
        }
        break;
      case BuildingType.energyProducer:
        if (neighborDef.type == BuildingType.shardProducer) {
          shardLinks += 1;
          bonus += 0.05;
        }
        break;
    }
  }

  if (energyLinks > 0 && type == BuildingType.shardProducer) {
    entries.add('相邻能量设施 x$energyLinks：采集 +${energyLinks * 20}%');
  }
  if (shardLinks > 0 && type == BuildingType.shardToPart) {
    entries.add('相邻采集设施 x$shardLinks：转换 +${shardLinks * 10}%');
  }
  if (converterLinks > 0 && type == BuildingType.partToBlueprint) {
    entries.add('相邻转换设施 x$converterLinks：合成 +${converterLinks * 10}%');
  }
  if (shardLinks > 0 && type == BuildingType.energyProducer) {
    entries.add('相邻采集设施 x$shardLinks：能量 +${shardLinks * 5}%');
  }
  if (radiationLinks > 0) {
    entries.add('辐射核心 x$radiationLinks：效率 -${radiationLinks * 8}%');
  }

  return _AdjacencyDetail(
    bonus: bonus.clamp(0.5, 2.0),
    entries: entries,
  );
}
