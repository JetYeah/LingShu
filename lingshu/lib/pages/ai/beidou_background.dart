import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/beidou_astronomy.dart';
import '../../core/theme.dart';

/// 北斗七星 · 呼吸星野背景（真实天文版）。
///
/// 三层同心圆构图（圆心 = 原天极/原 Logo 位）：
///   ① 中心：北极星（金色星芒，恒定不闪）；
///   ② 内圈：二十四节气环（每格 15°，斗柄每天扫过约 1°，一格约 15 天；
///      环整体对齐使斗柄此刻正指当前节气，其余节气随之展开）；
///   ③ 外圈：北斗七星真实轨道（J2000 坐标 + 当地恒星时，随季节/时刻流转，
///      十月晚八点斗柄西垂，与真实星空一致）。
/// 另在轨道四正位标注 东南西北 方位（上北下南左西右东，朝北观星图式）。
/// 闪烁：每 3 秒一窗随机选 1~2 颗呼吸（白→亮黄→白）。
class BeidouBackground extends StatelessWidget {
  final double t; // 动画秒数（驱动闪烁相位）
  final DateTime? now; // 观测时刻（默认当前；可注入测试/演示时刻）
  const BeidouBackground({super.key, required this.t, this.now});

  /// 二十四节气名（k=0 立春，黄经 315°起，每 15°一格）
  static const solarTerms = [
    '立春', '雨水', '惊蛰', '春分', '清明', '谷雨',
    '立夏', '小满', '芒种', '夏至', '小暑', '大暑',
    '立秋', '处暑', '白露', '秋分', '寒露', '霜降',
    '立冬', '小雪', '大雪', '冬至', '小寒', '大寒',
  ];

  /// 当前节气序号（按日近似：立春≈年内第 35 天，每节气≈15.218 天）
  static int currentTermIndex(DateTime now) {
    final doy = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    final k = (((doy - 35) % 365 + 365) % 365) / 15.218;
    return k.floor() % 24;
  }

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
    final pole = Offset(size.width / 2, size.height * 0.35);
    final pts = BeidouAstronomy.starPositionsPx(now,
        cx: pole.dx,
        cy: pole.dy,
        radiusPx: radius,
      ).map((s) => Offset(s.x, s.y)).toList();

    // ── 二十四节气环（内圈，r=轨道×0.56）──
    // 环整体旋转对齐：第 k(当前节气) 格中心 = 此刻摇光（柄尖）实指方向；
    // 其余节气 15°/格 展开——斗柄每天扫约 1°，一格≈15 天，即「斗转星移」。
    _paintSolarTermRing(canvas, pole, radius, pts[6]);

    // ── 方位标注（轨道外四正位：上北下南左西右东，朝北观星图式）──
    _paintCardinalMarks(canvas, pole, radius);

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

  /// 二十四节气环：传统斗建固定盘（罗盘式）。
  /// 立春钉在寅位（罗盘方位 60°，东偏北），此后每节气固定 15° 逆时针排布
  /// （斗柄周年视运动方向）。盘不随时钟旋转——黄昏时斗柄大致指着当前
  /// 节气，其他时刻的偏离量即「时辰」（斗转星移可读时）。
  void _paintSolarTermRing(
      Canvas canvas, Offset pole, double radius, Offset tip) {
    final ringR = radius * 0.56;
    final kNow = BeidouBackground.currentTermIndex(now);

    // 淡环底圈
    canvas.drawCircle(
      pole,
      ringR,
      Paint()
        ..color = LingShuColors.goldSoft.withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    for (var k = 0; k < 24; k++) {
      // 固定盘：立春 60°（寅位），斗柄周年沿角度递减方向扫格
      final ang = (60.0 - k * 15.0) * math.pi / 180;
      final dx = math.sin(ang), dy = -math.cos(ang);
      final pos = Offset(pole.dx + dx * ringR, pole.dy + dy * ringR);
      final isCurrent = k == kNow;

      // 刻度点
      canvas.drawCircle(
        pos,
        isCurrent ? 2.2 : 1.1,
        Paint()
          ..color = isCurrent
              ? const Color(0xFFFFD873).withValues(alpha: 0.9)
              : LingShuColors.paper.withValues(alpha: 0.30),
      );

      // 节气名：罗盘式排布——文字底边朝环心外侧（沿切线旋转），
      // 当前节气金色放大，其余纸色微光
      final tp = TextPainter(
        text: TextSpan(
          text: BeidouBackground.solarTerms[k],
          style: TextStyle(
            fontSize: isCurrent ? 11 : 9.5,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent
                ? const Color(0xFFFFD873)
                : LingShuColors.paper.withValues(alpha: 0.38),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final center = Offset(
        pole.dx + dx * (ringR + 14 + tp.height / 2),
        pole.dy + dy * (ringR + 14 + tp.height / 2),
      );
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(ang); // 顶部正立、两侧竖排、底部倒立（罗盘式）
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  /// 方位标注：轨道外四正位——上北、下南、左西、右东（朝北观星图式）
  void _paintCardinalMarks(Canvas canvas, Offset pole, double radius) {
    const marks = [
      ('北', 0.0),
      ('东', 90.0),
      ('南', 180.0),
      ('西', 270.0),
    ];
    for (final (name, deg) in marks) {
      final a = deg * math.pi / 180;
      final pos = Offset(
        pole.dx + math.sin(a) * (radius + 26),
        pole.dy - math.cos(a) * (radius + 26),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: LingShuColors.paper.withValues(alpha: 0.55),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_BeidouPainter old) => old.t != t || old.now != now;
}
