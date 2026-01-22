import 'package:flutter/material.dart';

import '../../game/game_ui_state.dart';

class RateSummaryCard extends StatelessWidget {
  const RateSummaryCard({super.key, required this.summary});

  final RateSummary summary;

  @override
  Widget build(BuildContext context) {
    // 汇总展示关键产能指标。
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '产能概览',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
            ),
            const SizedBox(height: 12),
            _SummaryRow(label: '碎片 / 秒', value: summary.shardsPerSec),
            _SummaryRow(label: '零件 / 秒', value: summary.partsPerSec),
            _SummaryRow(label: '蓝图 / 分钟', value: summary.blueprintsPerMin),
            const Divider(height: 20, color: Color(0x331C2A3A)),
            _SummaryRow(label: '能量 / 秒', value: summary.energyPerSec),
            _SummaryRow(label: '合成效率', value: summary.synthesisEff),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF8FA3BF),
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
