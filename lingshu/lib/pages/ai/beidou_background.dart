import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/beidou_astronomy.dart';
import '../../core/theme.dart';

/// 北斗七星 · 呼吸星野背景（真实天文版）。
///
/// 七星按真实 J2000 坐标 + 当地恒星时绕北天极旋转：随季节/时刻转动，
/// 斗柄指向暗合《鹗冠子》四时口诀（春东/夏南/秋西/冬北，晚 8-9 点）。
/// 北天极位于原 Logo 位置（页面中轴偏上），北斗绕它流转。
/// 闪烁：每约 3 秒一轮，任一时刻至多 2 颗星处于闪烁中——平常白色，
/// 闪烁时渐变为亮黄再回到白色。
class BeidouBackground extends StatelessWidget {
  final double t; // 动画秒数（驱动闪烁相位）
  final DateTime? now; // 观测时刻（默认当前；可注入测试/演示时刻）
  const BeidouBackground({super.key, required this.t, this.now});

  /// 散布小星（固定种子，避免每帧随机跳动）
  static final _stars = List.generate(46, (i) {
    final r = math.Random(i * 77 + 13);
    return (r.nextDouble(), r.nextDouble() * 0.92, r.nextDouble());
  });

  /// 闪烁编排：每 3 秒一个窗口，从 7 颗中随机挑 1~2 颗，被选中的星在
  /// 该窗口内做一次完整呼吸（白→亮黄→白，3s 一息）；下个窗口重新随机。
  /// 选择以窗口序号为种子——同一窗口内逐帧稳定，跨窗口随机变化。
  static double _blinkGlow(int i, double t) {
    final window = t ~/ 3;
    final r = math.Random(window * 2654435761 + 97);
    final pickA = r.nextInt(7);
    final pickB = r.nextBool() ? r.nextInt(7) : -1; // 约 50% 窗口挑 2 颗
    if (i != pickA && i != pickB) return 0; // 未选中：纯白静默
    final u = (t % 3) / 3; // 窗口内进度 0..1
    return 0.5 - 0.5 * math.cos(u * 2 * math.pi); // 一次完整呼吸
  }

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

    // 散布小星：4~9 秒缓慢微光（相位由第三随机数错开），衬托主星呼吸
    for (final (x, y, ph) in BeidouBackground._stars) {
      final period = 4.0 + ph * 5.0;
      final a = 0.10 +
          0.20 * (0.5 + 0.5 * math.sin((t / period + ph) * 2 * math.pi));
      canvas.drawCircle(
          Offset(x * size.width, y * size.height), 0.8 + ph * 1.1,
          Paint()..color = Colors.white.withValues(alpha: a));
    }

    // 北斗主星：北天极 = 原 Logo 中心（中轴、屏高 35%）——北斗绕它流转；
    // 轨道半径 = 宽×0.40，强化「绕原 Logo 位置旋转」的观感
    final radius = size.width * 0.40;
    final pts = BeidouAstronomy.starPositionsPx(now,
        cx: size.width / 2,
        cy: size.height * 0.35,
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

    // 北极星→天枢 虚线（寻星指引：斗口天枢方向即北极星所在，
    // 经典口诀「天璇天枢连线延长五倍抵北辰」）
    final pole = Offset(size.width / 2, size.height * 0.35);
    final dashPaint = Paint()
      ..color = LingShuColors.goldSoft.withValues(alpha: 0.35)
      ..strokeWidth = 1.2;
    {
      final end = pts[0]; // 天枢（斗口第一颗）
      final dx = end.dx - pole.dx, dy = end.dy - pole.dy;
      const dashLen = 7.0, gapLen = 6.0;
      var s = 0.0;
      final total = math.sqrt(dx * dx + dy * dy);
      while (s < total) {
        final e = math.min(s + dashLen, total);
        canvas.drawLine(
          Offset(pole.dx + dx * s / total, pole.dy + dy * s / total),
          Offset(pole.dx + dx * e / total, pole.dy + dy * e / total),
          dashPaint,
        );
        s = e + gapLen;
      }
    }

    // 北极星：金色星芒（参考实时星图样式）——十字光芒 + 光晕 + 亮芯，
    // 位于原 Logo 中心，恒定不闪（众星绕转的定盘星）
    {
      const gold = Color(0xFFFFE9A8);
      const core = Color(0xFFFFD873);
      // 光晕
      canvas.drawCircle(
        pole,
        16,
        Paint()
          ..color = core.withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      // 十字星芒（四条渐细的长菱形）
      final spikePaint = Paint()..color = gold.withValues(alpha: 0.55);
      for (var k = 0; k < 2; k++) {
        final path = Path();
        if (k == 0) {
          path.moveTo(pole.dx, pole.dy - 22);
          path.lineTo(pole.dx + 2.2, pole.dy);
          path.lineTo(pole.dx, pole.dy + 22);
          path.lineTo(pole.dx - 2.2, pole.dy);
        } else {
          path.moveTo(pole.dx - 22, pole.dy);
          path.lineTo(pole.dx, pole.dy + 2.2);
          path.lineTo(pole.dx + 22, pole.dy);
          path.lineTo(pole.dx, pole.dy - 2.2);
        }
        path.close();
        canvas.drawPath(path, spikePaint);
      }
      // 亮芯
      canvas.drawCircle(pole, 3.2, Paint()..color = core);
      canvas.drawCircle(
          pole, 1.6, Paint()..color = const Color(0xFFFFFFFF));
    }

    // 主星：闪烁编排驱动——任一时刻 ≤2 颗，白→亮黄→白（1.4s 完成一次），
    // 静默期纯白微光
    const starWhite = Color(0xFFF2EFE6);
    const starGold = Color(0xFFFFD873);
    for (var i = 0; i < pts.length; i++) {
      final glow = BeidouBackground._blinkGlow(i, t); // 0..1
      final c = pts[i];
      // 颜色：白 → 亮黄 → 白；星体小巧
      final color = Color.lerp(starWhite, starGold, glow)!;
      final radius = 2.1 + 1.3 * glow;

      // 光晕（同色系，随呼吸胀缩）
      canvas.drawCircle(
        c,
        radius * 3.2,
        Paint()
          ..color = color.withValues(alpha: 0.10 + 0.16 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      // 星体
      canvas.drawCircle(
        c,
        radius,
        Paint()..color = color.withValues(alpha: 0.82 + 0.18 * glow),
      );
      // 芯
      canvas.drawCircle(
        c,
        radius * 0.5,
        Paint()..color = Colors.white.withValues(alpha: 0.55 + 0.45 * glow),
      );
    }
  }

  @override
  bool shouldRepaint(_BeidouPainter old) => old.t != t || old.now != now;
}
