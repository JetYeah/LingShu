import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/beidou_astronomy.dart';
import '../../core/theme.dart';

/// 北斗七星 · 呼吸星野背景（真实天文版）。
///
/// 七星按真实 J2000 坐标 + 当地恒星时绕天极旋转：随季节/时刻转动，
/// 斗柄指向暗合《鹗冠子》四时口诀（春东/夏南/秋西/冬北，晚 8-9 点）。
/// 每颗星有独立的呼吸周期与相位（3~7 秒，正弦明暗），如随机眨眼；
/// [t] 为动画相位（秒），星位置每分钟重算一次即可跟上真实天空。
class BeidouBackground extends StatelessWidget {
  final double t; // 动画秒数（驱动闪烁相位）
  final DateTime? now; // 观测时刻（默认当前；可注入测试/演示时刻）
  const BeidouBackground({super.key, required this.t, this.now});

  /// 散布小星（固定种子，避免每帧随机跳动）
  static final _stars = List.generate(46, (i) {
    final r = math.Random(i * 77 + 13);
    return (r.nextDouble(), r.nextDouble() * 0.92, r.nextDouble());
  });

  /// 七星呼吸参数：固定种子的随机周期(3~7s)与相位(0~2π)——每颗星
  /// 按自己的节奏明灭，如呼吸互不同步
  static final List<({double period, double phase})> _breath =
      List.generate(7, (i) {
    final r = math.Random(i * 991 + 7);
    return (
      period: 3.0 + r.nextDouble() * 4.0,
      phase: r.nextDouble() * 2 * math.pi,
    );
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BeidouPainter(t, now ?? DateTime.now()),
      size: Size.infinite,
    );
  }
}

class _BeidouPainter extends CustomPainter {
  final double t;
  final DateTime now;
  _BeidouPainter(this.t, this.now);

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
      final a =
          0.10 + 0.22 * (0.5 + 0.5 * math.sin((t * 2 * math.pi) + ph * 2 * math.pi));
      canvas.drawCircle(
          Offset(x * size.width, y * size.height), 0.8 + ph * 1.1,
          Paint()..color = Colors.white.withValues(alpha: a));
    }

    // 北斗主星：天极在画面上部 (宽/2, 高×0.11)；轨道半径压到
    // min(宽, 高×0.10)×0.92，使摇光最远点 (cy + r) 停在标题带之上、
    // Logo 区（约从 26% 高开始）之前——星野与品牌区不重叠
    final radius = math.min(size.width, size.height * 0.10) * 0.92;
    final pts = BeidouAstronomy.starPositionsPx(now,
        cx: size.width / 2,
        cy: size.height * 0.11,
        radiusPx: radius,
      ).map((s) => Offset(s.x, s.y)).toList();

    // 星间连线（斗口→柄尖一条折线，随呼吸微亮）
    final breathe = 0.5 + 0.5 * math.sin(t * 2 * math.pi / 6);
    final linePaint = Paint()
      ..color = LingShuColors.goldSoft.withValues(alpha: 0.16 + 0.14 * breathe)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < pts.length - 1; i++) {
      canvas.drawLine(pts[i], pts[i + 1], linePaint);
    }

    // 主星：独立呼吸周期 + 相位，金色光晕明灭如眨眼
    for (var i = 0; i < pts.length; i++) {
      final breath = BeidouBackground._breath[i];
      final wave =
          math.sin((t / breath.period) * 2 * math.pi + breath.phase);
      final glow = 0.35 + 0.65 * (0.5 + 0.5 * wave);
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
        Paint()
          ..color = LingShuColors.goldSoft
              .withValues(alpha: 0.55 + 0.45 * glow),
      );
      canvas.drawCircle(
        c,
        radius * 0.45,
        Paint()..color = Colors.white.withValues(alpha: 0.5 + 0.5 * glow),
      );
    }
  }

  @override
  bool shouldRepaint(_BeidouPainter old) => old.t != t || old.now != now;
}
