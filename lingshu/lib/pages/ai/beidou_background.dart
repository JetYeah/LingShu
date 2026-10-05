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

  /// 闪烁编排：每颗星每 3 秒闪一次（白→亮黄→白，窗 0.8s），
  /// 起始时刻确定性错开——7 颗在 3s 内均匀占位（间隔 3/7≈0.43s），
  /// 窗 0.8s 下相邻两星最多重叠，任一时刻同时闪烁 ≤ 2 颗。
  static final List<double> _blinkStart = List.generate(7, (i) => i * 3.0 / 7);

  /// 星 i 在时刻 t 的闪烁强度 0..1（1=最亮黄）。周期 3s，闪烁窗 0.8s。
  static double _blinkGlow(int i, double t) {
    const cycle = 3.0, win = 0.8;
    final u = ((t - _blinkStart[i]) % cycle + cycle) % cycle;
    if (u > win) return 0; // 静默期：纯白
    // 白→黄→白：正弦半波
    return 0.5 - 0.5 * math.cos(u / win * 2 * math.pi);
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

    // 散布小星：正弦微光，相位由第三随机数错开
    for (final (x, y, ph) in BeidouBackground._stars) {
      final a =
          0.10 + 0.22 * (0.5 + 0.5 * math.sin((t * 2 * math.pi) + ph * 2 * math.pi));
      canvas.drawCircle(
          Offset(x * size.width, y * size.height), 0.8 + ph * 1.1,
          Paint()..color = Colors.white.withValues(alpha: a));
    }

    // 北斗主星：北天极 = 原 Logo 位置（中轴、高 34%）——北斗绕它流转，
    // 轨道半径 = 宽×0.42，横向近乎满屏
    final radius = size.width * 0.42;
    final pts = BeidouAstronomy.starPositionsPx(now,
        cx: size.width / 2,
        cy: size.height * 0.34,
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
