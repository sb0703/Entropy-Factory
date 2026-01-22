import 'package:flutter/material.dart';

import '../../game/big_number.dart';
import '../../game/number_format.dart';
import '../../game/prestige_rules.dart';

class LawProgressCard extends StatelessWidget {
  const LawProgressCard({
    super.key,
    required this.blueprints,
    required this.laws,
  });

  final BigNumber blueprints;
  final BigNumber laws;

  @override
  Widget build(BuildContext context) {
    final progress = (lawThreshold <= 0)
        ? 0.0
        : (blueprints.toDouble() / lawThreshold).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '定律进度',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              '当前定律：${_formatNumber(laws)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF8FA3BF),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '蓝图：${_formatNumber(blueprints)} / ${lawThreshold.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8FA3BF),
                  ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0xFF142236),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '达到阈值自动生成定律',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6F8198),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatNumber(Object value) {
  return formatNumber(value);
}
