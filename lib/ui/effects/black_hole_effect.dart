import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProBlackHolePage(),
    ),
  );
}

class ProBlackHolePage extends StatefulWidget {
  const ProBlackHolePage({super.key});

  @override
  State<ProBlackHolePage> createState() => _ProBlackHolePageState();
}

class _ProBlackHolePageState extends State<ProBlackHolePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Star> stars = [];
  final int starCount = 300; // 粒子数量
  bool isDevouring = false;

  @override
  void initState() {
    super.initState();
    _initStars();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // 旋转周期
    )..repeat();
  }

  void _initStars() {
    stars.clear();
    final random = Random();
    for (int i = 0; i < starCount; i++) {
      stars.add(Star(random: random));
    }
  }

  void _toggleDevour() {
    setState(() {
      isDevouring = !isDevouring;
    });
    // 吞噬时重置部分粒子状态以产生冲击感
    if (isDevouring) {
      // 可选：添加震动反馈
    } else {
      _initStars(); // 重置回平静状态
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. 动态绘制层
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: BlackHolePainter(
                    stars: stars,
                    animationValue: _controller.value,
                    isDevouring: isDevouring,
                  ),
                );
              },
            ),
          ),

          // 2. UI 交互层
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  isDevouring ? "EVENT HORIZON COLLAPSE" : "STABLE ORBIT",
                  style: TextStyle(
                    color: isDevouring ? Colors.redAccent : Colors.cyanAccent,
                    letterSpacing: 5,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _toggleDevour,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDevouring ? Colors.red : Colors.cyan,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDevouring ? Colors.red : Colors.cyan)
                              .withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      isDevouring ? Icons.stop : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- 数据模型 ---
class Star {
  double angle;
  double distance;
  double speed;
  double brightness;
  double trailLength;
  Color color;

  Star({required Random random})
    : angle = random.nextDouble() * 2 * pi,
      distance = 100 + random.nextDouble() * 300, // 分布在 100~400 之间
      speed = 0.005 + random.nextDouble() * 0.01,
      brightness = random.nextDouble(),
      trailLength = 5.0 + random.nextDouble() * 15.0,
      // 生成“星际”配色：青色、橙色、紫色
      color = _getRandomColor(random);

  static Color _getRandomColor(Random random) {
    final colors = [
      const Color(0xFF00E5FF), // 青色
      const Color(0xFFFF5252), // 橙红
      const Color(0xFFE040FB), // 紫色
      Colors.white, // 白热
    ];
    return colors[random.nextInt(colors.length)];
  }
}

// --- 核心渲染器 ---
class BlackHolePainter extends CustomPainter {
  final List<Star> stars;
  final double animationValue;
  final bool isDevouring;

  BlackHolePainter({
    required this.stars,
    required this.animationValue,
    required this.isDevouring,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint();

    // --- 1. 背景光晕 (稍微调淡一点) ---
    if (!isDevouring || animationValue % 1.0 < 0.5) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      // 让背景转慢一点，和前景拉开层次
      canvas.rotate(animationValue * 2 * pi * 0.05);

      final Rect rect = Rect.fromCircle(center: Offset.zero, radius: 300);
      paint.shader = SweepGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF4FC3F7).withValues(alpha: .05), // 极淡的青色
          const Color(0xFFAB47BC).withValues(alpha: 0.08), // 极淡的紫色
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.6, 1.0],
      ).createShader(rect);

      paint.blendMode = BlendMode.plus;
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, 300, paint);
      canvas.restore();
    }

    // --- 2. 粒子流 (核心修改：统一色调 & 基于距离的颜色) ---
    paint.shader = null;
    paint.style = PaintingStyle.stroke;
    paint.strokeCap = StrokeCap.round;

    for (var star in stars) {
      // --- 运动逻辑 (保持不变) ---
      if (isDevouring) {
        star.speed += 0.0005;
        star.distance -= star.speed * 8; // 吸入速度稍慢一点，看清轨迹
        star.angle += star.speed * 0.8;
        star.trailLength += 0.5;
      } else {
        star.angle += star.speed;
        star.distance += sin(animationValue * 5 + star.angle) * 0.3;
      }

      // 重置逻辑
      if (star.distance < 25) {
        if (isDevouring) {
          star.color = Colors.transparent;
        } else {
          star.distance = 320 + Random().nextDouble() * 50;
          star.speed = 0.003 + Random().nextDouble() * 0.005; // 速度差异化
        }
      }

      if (star.color == Colors.transparent) continue;

      // --- 【关键修改】视觉渲染 ---

      final rect = Rect.fromCircle(center: center, radius: star.distance);

      // A. 计算进度 (0.0 表示在中心，1.0 表示在边缘)
      // 我们用这个进度来控制颜色
      double t = (star.distance - 30) / 300;
      t = t.clamp(0.0, 1.0); // 限制在 0~1 之间

      // B. 物理配色 (Accretion Disk Physics)
      // 靠近中心(t=0): 炽热的金/橙色 (Colors.amberAccent)
      // 远离中心(t=1): 寒冷的青/蓝色 (Colors.cyanAccent)
      // 这里的 Color.lerp 会自动帮你算渐变
      final color = Color.lerp(Colors.orangeAccent, Colors.cyanAccent, t);

      // C. 动态透明度
      // 边缘透明，中间亮，产生深邃感
      double opacity = star.brightness * (isDevouring ? 0.8 : 0.5);
      // 离中心越近，越亮
      opacity = (opacity + (1 - t) * 0.5).clamp(0.0, 1.0);

      paint.color = color!.withValues(alpha: opacity);

      // D. 线条更细
      // 只有极少数粒子比较粗，大部分都很细
      paint.strokeWidth = (star.brightness > 0.8) ? 1.5 : 0.6;

      // E. 绘制
      final sweepAngle =
          -(star.trailLength * (isDevouring ? 0.04 : 0.015)) /
          (star.distance / 100);
      canvas.drawArc(rect, star.angle, sweepAngle, false, paint);
    }

    // --- 3. 中心黑洞 (加深一点红光) ---
    paint.style = PaintingStyle.fill;
    paint.blendMode = BlendMode.srcOver;
    paint.color = Colors.black;

    // 阴影改为暗红色，配合内圈的金色粒子
    canvas.drawShadow(
      Path()..addOval(Rect.fromCircle(center: center, radius: 32)),
      isDevouring ? const Color(0xFFD50000) : Colors.cyan.withValues(alpha: .5),
      30,
      true,
    );
    canvas.drawCircle(center, 32, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
