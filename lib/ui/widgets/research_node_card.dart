import 'package:flutter/material.dart';

import '../../game/game_ui_state.dart';

class ResearchNodeCard extends StatelessWidget {
  const ResearchNodeCard({
    super.key,
    required this.node,
    this.isSelected = false,
    this.onTap,
  });

  final ResearchNodeDisplay node;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // 通过状态颜色与标识文本提示研究可用性。
    final tone = _toneFor(node.status, node.canBuy, context);
    final statusLabel = _statusLabel(node);
    final cardColor = isSelected ? const Color(0xFF16233B) : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                node.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                node.cost,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8FA3BF),
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: tone,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: tone,
                          letterSpacing: 0.8,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(ResearchNodeDisplay node) {
    if (node.status == ResearchStatus.available && !node.canBuy) {
      return '资源不足';
    }
    switch (node.status) {
      case ResearchStatus.available:
        return '可购买';
      case ResearchStatus.purchased:
        return '已购买';
      case ResearchStatus.locked:
        return '锁定';
    }
  }

  Color _toneFor(
    ResearchStatus status,
    bool canBuy,
    BuildContext context,
  ) {
    if (status == ResearchStatus.available && !canBuy) {
      return const Color(0xFFF5C542);
    }
    switch (status) {
      case ResearchStatus.available:
        return Theme.of(context).colorScheme.primary;
      case ResearchStatus.purchased:
        return const Color(0xFF8BE4B4);
      case ResearchStatus.locked:
        return const Color(0xFF7D8CA1);
    }
  }
}
