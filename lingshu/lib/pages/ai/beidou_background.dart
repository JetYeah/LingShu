import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/beidou_astronomy.dart';
import '../../core/theme.dart';

/// 北斗七星 · 呼吸星野背景（真实天文版）。
///
/// 三层同心圆构图（圆心 = 原天极/原 Logo 位）：
///   ① 中心：北极星（金色星芒，恒定不闪）；
///   ② 内圈：二十四节气固定盘（罗盘式，每格 15°，不随时钟旋转；
///      黄昏斗柄指当前节气，其余时刻的偏离量即「时辰」——斗转星移可读时）；
///      盘内侧北斗钟：24 小时刻度 + 十二地支时辰标注（北极星→天枢虚线为
///      时针，指在哪支当下便是哪时辰，当前时辰金色高亮）；
///   ③ 外圈：北斗七星真实轨道（J2000 坐标 + 当地恒星时，随季节/时刻流转，
///      十月晚八点斗柄西垂，与真实星空一致）。
/// 另在轨道四正位标注 东南西北 方位（上南下北左东右西，传统式盘方位）。
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

  /// 节气 k 在固定盘上的屏幕角（度，顺时针自正上方）。
  /// 四正锚：夏至=正南(0°=顶)、冬至=正北(180°=底)；晚 8 点斗柄即指
  /// 当前节气格（LST(20:00)=太阳赤经+120° 恒等式保证周年对齐）。
  static double termSlotAngle(int k) => (225.0 + k * 15.0) % 360.0;

  /// 十二时辰地支名（子时 23-1 点起，每时辰 2 小时）
  static const shichenChars = [
    '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
  ];

  /// 当前时辰读数（如「戌时」）：(小时+1)÷2 映射十二时辰。
  static String shichenOf(DateTime now) =>
      '${shichenChars[((now.hour + 1) % 24) ~/ 2]}时';

  /// 北斗钟表盘基准角（0 时刻度的角位置）：随时针（天枢虚线）逐帧重锚，
  /// 恒星日/太阳日的累计漂移由重锚吸收——当前小时刻度恒在时针线上。
  static double hourDialBase(DateTime now) =>
      BeidouAstronomy.dubheAngle(now) -
      (now.hour + now.minute / 60.0) * 15.0;

  /// 小时 H 的刻度角（度，顺时针自正上方；15°/格均布，随节气周转 1°/天）。
  static double hourTickAngle(DateTime now, int h) =>
      (hourDialBase(now) + h * 15.0) % 360.0;

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
    // 北斗整体外扩 8%（刚体缩放，七星相对形状不变）：与内圈节气环拉开间距
    final starOrbit = radius * 1.08;
    final pts = BeidouAstronomy.starPositionsPx(now,
        cx: pole.dx,
        cy: pole.dy,
        radiusPx: starOrbit,
      ).map((s) => Offset(s.x, s.y)).toList();

    // ── 二十四节气固定盘（内圈，r=轨道×0.50）──
    // 盘不随时钟旋转（斗建固定盘）：晚 8 点斗柄指当前节气格，
    // 其余节气 15°/格 顺时针展开——斗柄每天扫约 1°，一格≈15 天。
    _paintSolarTermRing(canvas, pole, radius, pts[6]);

    // ── 北斗钟：24 小时刻度 + 十二地支时辰标注（节气盘内侧）──
    _paintHourDial(canvas, pole, radius);
    _paintBranchChars(canvas, pole, radius);

    // ── 方位标注（轨道外四正位：上南下北左东右西，传统式盘方位）──
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

  /// 二十四节气固定盘：传统斗建罗盘式（上南下北）。
  /// 四正锚定：夏至=正南(0°=顶)、冬至=正北(180°=底)，从立春起每气顺时针
  /// +15°。盘不随时钟旋转——晚 8 点斗柄大致指着当前节气格，其他时刻的
  /// 偏离量即「时辰」（斗转星移可读时）。
  void _paintSolarTermRing(
      Canvas canvas, Offset pole, double radius, Offset tip) {
    final ringR = radius * 0.50; // 内移让位：环与北斗轨道间留出时辰刻度带
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
      // 固定盘（斗建四正锚）：夏至=正南(0°=顶)、冬至=正北(180°=底)，
      // 与斗柄顺时针周年同向排布——从立春起顺时针每气 +15°
      final ang = BeidouBackground.termSlotAngle(k) * math.pi / 180;
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

  /// 北斗钟 24 小时刻度：节气盘内侧，15°/格均布（0/6/12/18 四正时加长，
  /// 当前小时金色高亮）。表盘基准随时针（北极星→天枢虚线）重锚——
  /// 当前小时刻度恒在时针线上；20 时刻度 ≈ 当前节气格顺时针 +41°
  /// （天枢相对柄尖的固定超前角）。
  void _paintHourDial(Canvas canvas, Offset pole, double orbitR) {
    final base = BeidouBackground.hourDialBase(now);
    for (var h = 0; h < 24; h++) {
      final a = (base + h * 15.0) * math.pi / 180;
      final dir = Offset(math.sin(a), -math.cos(a));
      final major = h % 6 == 0; // 子夜 0、卯 6、午 12、酉 18
      final isNow = h == now.hour;
      canvas.drawLine(
        pole + dir * (orbitR * (major ? 0.400 : 0.415)),
        pole + dir * (orbitR * 0.455),
        Paint()
          ..color = isNow
              ? const Color(0xFFFFD873).withValues(alpha: 0.90)
              : LingShuColors.paper.withValues(alpha: major ? 0.38 : 0.20)
          ..strokeWidth = isNow ? 1.8 : (major ? 1.2 : 0.9),
      );
    }
  }

  /// 十二地支时辰标注：画在北斗钟表盘各时辰扇区中心（= 偶数整点刻度角，
  /// 子对 0 时、午对 12 时、戌对 20 时……），随表盘随时针重锚——
  /// 北极星→天枢虚线（时针）指在哪支，当下便是哪时辰；
  /// 当前时辰金色高亮，其余纸色微光。罗盘式旋排与节气名一致。
  void _paintBranchChars(Canvas canvas, Offset pole, double orbitR) {
    final base = BeidouBackground.hourDialBase(now);
    final nowBranch = ((now.hour + 1) % 24) ~/ 2;
    for (var b = 0; b < 12; b++) {
      final ang = (base + 2 * b * 15.0) * math.pi / 180;
      final dir = Offset(math.sin(ang), -math.cos(ang));
      final isNow = b == nowBranch;
      final tp = TextPainter(
        text: TextSpan(
          text: BeidouBackground.shichenChars[b],
          style: TextStyle(
            fontSize: isNow ? 11.5 : 9.5,
            fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
            color: isNow
                ? const Color(0xFFFFD873)
                : LingShuColors.paper.withValues(alpha: 0.40),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final center = pole + dir * (orbitR * 0.352);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(ang); // 罗盘式：顶部正立、两侧竖排、底部倒立
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  /// 方位标注：轨道外四正位——上南、下北、左东、右西（传统式盘方位，
  /// 上南下北；与顺时针周日运动自洽：东升在左、西落在右）
  void _paintCardinalMarks(Canvas canvas, Offset pole, double radius) {
    const marks = [
      ('南', 0.0),
      ('西', 90.0),
      ('北', 180.0),
      ('东', 270.0),
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
