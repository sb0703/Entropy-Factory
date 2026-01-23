import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/constant_upgrades.dart';
import '../../game/game_controller.dart';
import '../../game/game_math.dart';
import '../../game/game_state.dart';
import '../../game/milestone_definitions.dart';
import '../../game/research_definitions.dart';

class RatioPanel extends ConsumerWidget {
  const RatioPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final effects =
        computeResearchEffects(state).combine(computeMilestoneEffects(state));
    final constants = computeConstantEffects(state);
    final rates = GameRates.fromState(state, effects, constants);
    final baseEnergyProd =
        energyProductionPerSec(state, effects) * constants.productionMultiplier;
    final energyNeed = partSynthesisEnergyNeedPerSec(state, effects);
    final energySplit = effectiveEnergySplit(
      state: state,
      energyProd: baseEnergyProd,
      energyNeed: energyNeed,
    );
    final energyAvailable = rates.energyPerSec * energySplit;

    // 管理碎片/能量分配的控制面板。
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '配比设置',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            _SliderRow(
              label: '碎片→零件',
              valueLabel: '${(state.shardToPartRatio * 100).round()}%',
              value: state.shardToPartRatio,
              onChanged: controller.setShardToPartRatio,
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              value: state.keepShardReserve,
              onChanged: controller.setKeepShardReserve,
              title: const Text('保留碎片库存'),
              subtitle: Text('最低 ${state.shardReserveMin.round()}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 20, color: Color(0x331C2A3A)),
            _SliderRow(
              label: '能量分配',
              valueLabel:
                  '${(state.energyToSynthesisRatio * 100).round()}% 用于合成',
              value: state.energyToSynthesisRatio,
              onChanged: controller.setEnergySplit,
            ),
            const SizedBox(height: 8),
            Text(
              '剩余 ${((1 - state.energyToSynthesisRatio) * 100).round()}% 用于转换',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8FA3BF),
                  ),
            ),
            const SizedBox(height: 12),
            _PriorityToggle(
              mode: state.energyPriorityMode,
              onChanged: controller.setEnergyPriorityMode,
            ),
            const SizedBox(height: 12),
            _EnergyFlowMeter(
              availablePerSec: energyAvailable,
              needPerSec: rates.energyNeedPerSec,
              efficiency: rates.synthesisEfficiency,
              isOverload: rates.energyOverload,
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              valueLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8FA3BF),
                  ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0.1,
          max: 0.9,
          divisions: 8,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PriorityToggle extends StatelessWidget {
  const _PriorityToggle({
    required this.mode,
    required this.onChanged,
  });

  final EnergyPriorityMode mode;
  final ValueChanged<EnergyPriorityMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '能量优先级',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        SegmentedButton<EnergyPriorityMode>(
          segments: const [
            ButtonSegment(
              value: EnergyPriorityMode.synthesisFirst,
              label: Text('合成优先'),
            ),
            ButtonSegment(
              value: EnergyPriorityMode.conversionFirst,
              label: Text('转换优先'),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (value) => onChanged(value.first),
        ),
      ],
    );
  }
}

class _EnergyFlowMeter extends StatefulWidget {
  const _EnergyFlowMeter({
    required this.availablePerSec,
    required this.needPerSec,
    required this.efficiency,
    required this.isOverload,
  });

  final double availablePerSec;
  final double needPerSec;
  final double efficiency;
  final bool isOverload;

  @override
  State<_EnergyFlowMeter> createState() => _EnergyFlowMeterState();
}

class _EnergyFlowMeterState extends State<_EnergyFlowMeter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flowController;

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _flowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.availablePerSec <= 0
        ? 0.0001
        : widget.availablePerSec;
    final load = (widget.needPerSec / available).clamp(0.0, 2.0);
    final isOverload = widget.isOverload || load > 1.0;
    final displayPercent = (load * 100).round();
    final efficiencyPercent =
        (widget.efficiency * 100).clamp(0, 100).round();

    return AnimatedBuilder(
      animation: _flowController,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '能量负载',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  isOverload
                      ? '过载 $displayPercent%'
                      : '负载 $displayPercent%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isOverload
                            ? const Color(0xFFFF6B6B)
                            : const Color(0xFF8FA3BF),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '供给 ${_formatRate(widget.availablePerSec)} / 秒',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF8FA3BF),
                      ),
                ),
                Text(
                  '需求 ${_formatRate(widget.needPerSec)} / 秒',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF8FA3BF),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final fillWidth = width * load.clamp(0.0, 1.0);
                  final shimmerOffset = (width + 40) * _flowController.value;
                  final fillColor = isOverload
                      ? const Color(0xFFFF6B6B)
                      : Theme.of(context).colorScheme.primary;

                  return Stack(
                    children: [
                      Container(
                        height: 8,
                        color: const Color(0xFF142236),
                      ),
                      Container(
                        height: 8,
                        width: fillWidth,
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: isOverload
                            ? null
                            : Stack(
                                children: [
                                  Positioned(
                                    left: shimmerOffset - 40,
                                    top: -6,
                                    child: Container(
                                      width: 40,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0x0019F2FF),
                                            Color(0xAAFFFFFF),
                                            Color(0x0019F2FF),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isOverload
                  ? '过载警告：合成效率下降'
                  : '合成效率 $efficiencyPercent%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isOverload
                        ? const Color(0xFFFF9A9A)
                        : const Color(0xFF8FA3BF),
                  ),
            ),
          ],
        );
      },
    );
  }
}

String _formatRate(double value) {
  return value.toStringAsFixed(1);
}
