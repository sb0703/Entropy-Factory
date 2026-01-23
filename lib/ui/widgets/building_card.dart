import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/game_ui_state.dart';
import '../../game/game_state.dart';
import '../effects/particle_layer.dart';
import '../effects/resource_anchor_registry.dart';

class BuildingCard extends StatefulWidget {
  const BuildingCard({
    super.key,
    required this.data,
    required this.onBuyOne,
    required this.onBuyTen,
    required this.onBuyMax,
    required this.particleController,
    required this.anchorRegistry,
  });

  final BuildingDisplay data;
  final VoidCallback onBuyOne;
  final VoidCallback onBuyTen;
  final VoidCallback onBuyMax;
  final ParticleController particleController;
  final ResourceAnchorRegistry anchorRegistry;

  @override
  State<BuildingCard> createState() => _BuildingCardState();
}

class _BuildingCardState extends State<BuildingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.02), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerPulse() {
    if (_pulseController.isAnimating) {
      return;
    }
    _pulseController.forward(from: 0);
  }

  void _handleBuy(VoidCallback onBuy) {
    // 购买时触发轻量级反馈与粒子效果。
    _triggerPulse();
    HapticFeedback.lightImpact();
    _emitParticle();
    onBuy();
  }

  void _emitParticle() {
    final output = widget.data.outputResource;
    if (output == null) {
      return;
    }
    final cardBox = context.findRenderObject() as RenderBox?;
    if (cardBox == null) {
      return;
    }
    final targetKey = widget.anchorRegistry.keyForType(output);
    final targetContext = targetKey?.currentContext;
    if (targetContext == null) {
      return;
    }
    final targetBox = targetContext.findRenderObject() as RenderBox?;
    if (targetBox == null) {
      return;
    }
    final start = cardBox.localToGlobal(cardBox.size.center(Offset.zero));
    final end = targetBox.localToGlobal(targetBox.size.center(Offset.zero));
    widget.particleController.emit(
      start: start,
      end: end,
      color: _toneFor(output),
    );
  }

  Color _toneFor(ResourceType type) {
    switch (type) {
      case ResourceType.shard:
        return const Color(0xFF5CE1E6);
      case ResourceType.part:
        return const Color(0xFF8BE4B4);
      case ResourceType.blueprint:
        return const Color(0xFFF5C542);
      case ResourceType.law:
        return const Color(0xFF9D7CFF);
      case ResourceType.constant:
        return const Color(0xFFF5F1E1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    // 将卡片整体包裹在缩放动画中。
    return ScaleTransition(
      scale: _pulseScale,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  _CountPill(count: data.count),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data.output,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                data.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF9CB0C9),
                    ),
              ),
              const Divider(height: 18, color: Color(0x331C2A3A)),
              Text(
                data.costText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8FA3BF),
                    ),
              ),
              if (data.affordabilityText != null)
                Text(
                  data.affordabilityText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6F8198),
                      ),
                ),
              if (data.badge != null) ...[
                const SizedBox(height: 10),
                _Badge(label: data.badge!),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionButton(
                    label: '购买',
                    onPressed: data.canBuyOne
                        ? () => _handleBuy(widget.onBuyOne)
                        : null,
                    isPrimary: true,
                  ),
                  _ActionButton(
                    label: '买10',
                    onPressed: data.canBuyTen
                        ? () => _handleBuy(widget.onBuyTen)
                        : null,
                  ),
                  _ActionButton(
                    label: '买最大',
                    onPressed: data.canBuyMax
                        ? () => _handleBuy(widget.onBuyMax)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF0B1C2E),
        border: Border.all(color: const Color(0x335CE1E6)),
      ),
      child: Text(
        '数量 $count',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF18263A),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.1,
              color: const Color(0xFF8FA3BF),
            ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  Timer? _repeatTimer;

  void _startRepeat() {
    if (widget.onPressed == null) {
      return;
    }
    widget.onPressed!();
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(
      const Duration(milliseconds: 120),
      (_) => widget.onPressed?.call(),
    );
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(const Size(88, 40)),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
    return GestureDetector(
      onLongPressStart: (_) => _startRepeat(),
      onLongPressEnd: (_) => _stopRepeat(),
      onLongPressCancel: _stopRepeat,
      child: OutlinedButton(
        style: baseStyle.merge(
          OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary.withAlpha(
                    widget.isPrimary ? 200 : 102,
                  ),
              width: widget.isPrimary ? 1.4 : 1,
            ),
          ),
        ),
        onPressed: widget.onPressed,
        child: Text(widget.label),
      ),
    );
  }
}
