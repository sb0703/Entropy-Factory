import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Particle {
  Particle({
    required this.start,
    required this.end,
    required this.color,
    required this.startMs,
    required this.durationMs,
    required this.controlOffset,
    required this.size,
  });

  final Offset start;
  final Offset end;
  final Color color;
  final int startMs;
  final int durationMs;
  final Offset controlOffset;
  final double size;
}

class ParticleController extends ChangeNotifier {
  final List<Particle> _particles = <Particle>[];
  final math.Random _random = math.Random();

  List<Particle> get particles => List<Particle>.unmodifiable(_particles);

  void emit({
    required Offset start,
    required Offset end,
    required Color color,
    int count = 6,
  }) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < count; i++) {
      final jitter = Offset(
        (_random.nextDouble() - 0.5) * 18,
        (_random.nextDouble() - 0.5) * 18,
      );
      final arc = Offset(
        (_random.nextDouble() - 0.5) * 60,
        (_random.nextDouble() - 0.5) * 40,
      );
      _particles.add(
        Particle(
          start: start + jitter,
          end: end,
          color: color,
          startMs: nowMs,
          durationMs: 420 + _random.nextInt(240),
          controlOffset: arc,
          size: 4 + _random.nextDouble() * 2,
        ),
      );
    }
    notifyListeners();
  }

  void purgeExpired(int nowMs) {
    _particles.removeWhere(
      (particle) => nowMs - particle.startMs > particle.durationMs,
    );
  }
}

final particleControllerProvider =
    ChangeNotifierProvider<ParticleController>((ref) {
  return ParticleController();
});

class ParticleLayer extends ConsumerStatefulWidget {
  const ParticleLayer({super.key});

  @override
  ConsumerState<ParticleLayer> createState() => _ParticleLayerState();
}

class _ParticleLayerState extends ConsumerState<ParticleLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (mounted) {
        setState(() {});
      }
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(particleControllerProvider);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    controller.purgeExpired(nowMs);
    final renderBox = context.findRenderObject() as RenderBox?;
    final origin = (renderBox != null && renderBox.hasSize)
        ? renderBox.localToGlobal(Offset.zero)
        : Offset.zero;

    return IgnorePointer(
      child: CustomPaint(
        painter: _ParticlePainter(
          particles: controller.particles,
          nowMs: nowMs,
          origin: origin,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.particles,
    required this.nowMs,
    required this.origin,
  });

  final List<Particle> particles;
  final int nowMs;
  final Offset origin;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final elapsed = nowMs - particle.startMs;
      if (elapsed < 0 || elapsed > particle.durationMs) {
        continue;
      }
      final t = elapsed / particle.durationMs;
      final eased = 1 - math.pow(1 - t, 3).toDouble();
      final start = particle.start - origin;
      final end = particle.end - origin;
      final control = (start + end) / 2 + particle.controlOffset;
      final pos = _quadraticBezier(start, control, end, eased);
      final alpha = (255 * (1 - eased)).round().clamp(0, 255);

      final paint = Paint()
        ..color = particle.color.withAlpha(alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.particles != particles || oldDelegate.nowMs != nowMs;
  }
}

Offset _quadraticBezier(Offset p0, Offset p1, Offset p2, double t) {
  final oneMinusT = 1 - t;
  return p0 * (oneMinusT * oneMinusT) +
      p1 * (2 * oneMinusT * t) +
      p2 * (t * t);
}
