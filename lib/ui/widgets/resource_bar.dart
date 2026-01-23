import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/game_ui_state.dart';
import '../../game/game_state.dart';
import '../effects/resource_anchor_registry.dart';

final resourceAnchorRegistryProvider = Provider<ResourceAnchorRegistry>((ref) {
  return ResourceAnchorRegistry();
});

class ResourceBar extends ConsumerStatefulWidget {
  const ResourceBar({super.key});

  @override
  ConsumerState<ResourceBar> createState() => _ResourceBarState();
}

class _ResourceBarState extends ConsumerState<ResourceBar> {
  final Map<ResourceType, GlobalKey> _pillKeys = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameUiProvider);
    final registry = ref.read(resourceAnchorRegistryProvider);

    // 顶部资源条按当前状态动态渲染。
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          for (final resource in state.resources)
            ResourcePill(
              key: _pillKeys.putIfAbsent(
                resource.type,
                () => registry.keyFor(resource.type),
              ),
              label: resource.label,
              amount: resource.amount,
              value: resource.value,
              tone: resource.tone,
              isAlert: resource.isAlert,
            ),
          if (state.partBottleneck)
            _AlertPill(text: '零件不足，蓝图合成受限'),
          if (state.energyOverload)
            _AlertPill(text: '能量过载，合成效率下降'),
        ],
      ),
    );
  }
}

class ResourcePill extends StatefulWidget {
  const ResourcePill({
    super.key,
    required this.label,
    required this.amount,
    required this.value,
    required this.tone,
    this.isAlert = false,
  });

  final String label;
  final double amount;
  final String value;
  final Color tone;
  final bool isAlert;

  @override
  State<ResourcePill> createState() => _ResourcePillState();
}

class _ResourcePillState extends State<ResourcePill>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  late final AnimationController _particleController;
  late final Animation<double> _particleOpacity;
  late final Animation<Alignment> _particleAlignment;
  double _lastAmount = 0;
  int _lastParticleMs = 0;

  @override
  void initState() {
    super.initState();
    _lastAmount = widget.amount;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
    if (widget.isAlert) {
      _pulseController.repeat(reverse: true);
    }

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _particleOpacity = CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    );
    _particleAlignment =
        AlignmentTween(
          begin: const Alignment(-0.6, 0.8),
          end: const Alignment(0.6, -0.6),
        ).animate(
          CurvedAnimation(
            parent: _particleController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void didUpdateWidget(covariant ResourcePill oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (widget.amount > _lastAmount + 0.0001 &&
        !_particleController.isAnimating &&
        nowMs - _lastParticleMs > 350) {
      _lastParticleMs = nowMs;
      _particleController.forward(from: 0);
    }
    _lastAmount = widget.amount;
    if (widget.isAlert && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isAlert && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseTone = widget.isAlert ? const Color(0xFFFF6B6B) : widget.tone;
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _particleController]),
      builder: (context, child) {
        final pulseValue = widget.isAlert ? _pulse.value : 0.0;
        final borderAlpha = (115 + 80 * pulseValue).round();
        final dotAlpha = (160 + 70 * pulseValue).round();
        final shadowAlpha = (38 + 30 * pulseValue).round();

        final particleVisible = _particleController.value > 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0C1524),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: baseTone.withAlpha(borderAlpha)),
                boxShadow: [
                  BoxShadow(
                    color: baseTone.withAlpha(shadowAlpha),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: baseTone.withAlpha(dotAlpha),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      color: baseTone.withAlpha(217),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 96,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        widget.value,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (particleVisible)
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: _particleAlignment.value,
                    child: Opacity(
                      opacity: 1 - _particleOpacity.value,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: baseTone.withAlpha(200),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: baseTone.withAlpha(120),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AlertPill extends StatefulWidget {
  const _AlertPill({required this.text});

  final String text;

  @override
  State<_AlertPill> createState() => _AlertPillState();
}

class _AlertPillState extends State<_AlertPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final borderAlpha = (120 + 80 * _pulse.value).round();
        final bgAlpha = (36 + 24 * _pulse.value).round();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2B1518).withAlpha(bgAlpha),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFF6B6B).withAlpha(borderAlpha)),
          ),
          child: Text(
            widget.text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFFF9A9A),
                  fontWeight: FontWeight.w600,
                ),
          ),
        );
      },
    );
  }
}
