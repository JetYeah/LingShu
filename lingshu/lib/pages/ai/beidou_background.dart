import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// 北斗七星 · 呼吸星野背景：玄色渐变上 7 颗主星按斗形连线闪烁，
/// 散布小星微光摇曳。t ∈ [0,1) 为呼吸相位。
class BeidouBackground extends StatelessWidget {
  final double t; // 动画相位
  const BeidouBackground({super.key, required this.t});

  // 北斗七星斗形（天枢 天璇 天玑 天权 玉衡 开阳 摇光），归一化坐标
  static const _dipper = [
    (0.13, 0.34), // 天枢
    (0.27, 0.40), // 天璇
    (0.40, 0.35), // 天玑
    (0.50, 0.24), // 天权
    (0.62, 0.30), // 玉衡
    (0.76, 0.24), // 开阳
    (0.90, 0.14), // 摇光
  ];

  // 固定种子的小星（避免每帧随机跳动）
  static final _stars = List.generate(46, (i) {
    final r = math.Random(i * 77 + 13);
    return (r.nextDouble(), r.nextDouble() * 0.92, r.nextDouble());
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BeidouPainter(t),
      size: Size.infinite,
    );
  }
}

class _BeidouPainter extends CustomPainter {
  final double t;
  _BeidouPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // 玄色渐变底
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [LingShuColors.stageTop, LingShuColors.stageBottom],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // 散布小星：正弦微光，相位由第三随机数错开
    for (final (x, y, ph) in BeidouBackground._stars) {
      final a = 0.10 + 0.22 * (0.5 + 0.5 * math.sin((t * 2 * math.pi) + ph * 2 * math.pi));
      final twinkle = Paint()..color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(
          Offset(x * size.width, y * size.height), 0.8 + ph * 1.1, twinkle);
    }

    // 北斗主星：位置随视口缩放，斗形占上部约 45% 宽
    final pts = [
      for (final (nx, ny) in BeidouBackground._dipper)
        Offset(
          size.width * (0.04 + nx * 0.62),
          size.height * (0.06 + ny * 0.5),
        ),
    ];

    // 星间连线（斗口三边 + 柄），随呼吸微亮
    final breathe = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
    final linePaint = Paint()
      ..color = LingShuColors.goldSoft.withValues(alpha: 0.16 + 0.14 * breathe)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < pts.length - 1; i++) {
      canvas.drawLine(pts[i], pts[i + 1], linePaint);
    }

    // 主星：金色光晕呼吸 + 星体，各星相位依次错开，如斗转
    for (var i = 0; i < pts.length; i++) {
      final phase = (t + i * 0.11) % 1.0;
      final glow = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi));
      final c = pts[i];
      final radius = 2.2 + 1.6 * glow;
      canvas.drawCircle(
        c,
        radius * 4.2,
        Paint()
          ..color = LingShuColors.gold.withValues(alpha: 0.10 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        c,
        radius,
        Paint()..color = LingShuColors.goldSoft.withValues(alpha: 0.55 + 0.45 * glow),
      );
      canvas.drawCircle(
        c,
        radius * 0.45,
        Paint()..color = Colors.white.withValues(alpha: 0.5 + 0.5 * glow),
      );
    }
  }

  @override
  bool shouldRepaint(_BeidouPainter old) => old.t != t;
}
