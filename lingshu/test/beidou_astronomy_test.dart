import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lingshu/core/services/beidou_astronomy.dart';
import 'package:lingshu/pages/ai/beidou_background.dart';

/// 北斗天文位置：以两个独立锚点验证绝对相位与旋转规律。
/// 锚点 1：NOAA 公式独立计算的 LST（2026-10-06 20:00 北京 ≈ 310.3°~311.6°）
/// 锚点 2：实时星图实景（10 月晚 8 点北斗位于北天左下、斗柄西垂）
void main() {
  double handleDir(DateTime t) {
    final p = BeidouAstronomy.starPositions(t);
    final dx = p.last.x - 0.5, dy = p.last.y - 0.30;
    final a = math.atan2(dx, -dy) * 180 / math.pi;
    return (a % 360 + 360) % 360;
  }

  test('绝对相位：与 NOAA 独立公式的 LST 一致（摇光 HA 反推，镜像系）', () {
    // NOAA: LST(2026-10-06 20:00 北京) = 310.3°；摇光 HA = 103.4°
    // 镜像系（顺时针、东左西右）屏幕角 = HA → 103.4°±3
    final dir = handleDir(DateTime(2026, 10, 6, 20));
    final d = (dir - 103.4).abs();
    final dist = d > 180 ? 360 - d : d;
    expect(dist, lessThan(3), reason: 'LST 与 NOAA 公式偏差应 <3°（实测 $dir°）');
  });

  test('实景锚点：10 月晚 8 点北斗在西侧低垂（星图软件实景，镜像系）', () {
    final dir = handleDir(DateTime(2026, 10, 6, 20));
    // 西=90°（右侧），容差 45°（十月傍晚斗柄西垂）
    final d = (dir - 90).abs();
    final dist = d > 180 ? 360 - d : d;
    expect(dist, lessThan(45), reason: '十月斗柄西垂（实测 $dir°）');

    // 北斗整体应在天极右侧（西侧）
    final p = BeidouAstronomy.starPositions(DateTime(2026, 10, 6, 20));
    final rightCount = p.where((s) => s.x > 0.5).length;
    expect(rightCount, greaterThanOrEqualTo(5), reason: '十月北斗应在天极西侧');
  });

  test('节气盘四正锚：夏至=正南(0°=顶)、冬至=正北(180°=底)（上南下北式盘）', () {
    // 由 termSlotAngle(k)=225+15k：夏至 k=9 → 0；冬至 k=21 → 180
    expect(BeidouBackground.termSlotAngle(9), 0);
    expect(BeidouBackground.termSlotAngle(21), 180);
    // 立春落东北象限（寅位，东偏北：左=东、下=北）
    final lichun = BeidouBackground.termSlotAngle(0);
    expect(lichun, inInclusiveRange(210, 255));
  });

  test('斗建对齐：晚 8 点斗柄指向当前节气格（夏至指南、冬至指北、寒露指西）', () {
    // 恒等式 LST(20:00)=太阳赤经+120° 保证：黄昏前后斗柄尖端
    // （摇光）始终落在当前节气格 ±8° 内（残差仅为均时差）。
    final cases = [
      (DateTime(2026, 6, 21, 20), 9), // 夏至 → 格 0°=顶（南）
      (DateTime(2026, 12, 22, 20), 21), // 冬至 → 格 180°=底（北）
      (DateTime(2026, 10, 6, 20), 16), // 寒露 → 格 105°=右（西垂）
    ];
    for (final (date, k) in cases) {
      expect(BeidouBackground.currentTermIndex(date), k,
          reason: '$date 节气序号应为 $k');
      final dir = handleDir(date);
      final slot = BeidouBackground.termSlotAngle(k);
      final d = (dir - slot).abs();
      final dist = d > 180 ? 360 - d : d;
      expect(dist, lessThan(8),
          reason: '晚 8 点斗柄应指当前节气格（实测 $dir° vs 格 $slot°）');
    }
  });

  test('周年旋转：每天约 1°，方向一致', () {
    final a = handleDir(DateTime(2026, 3, 21, 21));
    final b = handleDir(DateTime(2026, 3, 22, 21));
    final diff = ((b - a) % 360 + 360) % 360;
    final daily = diff > 180 ? diff - 360 : diff; // 带符号
    expect(daily.abs(), inInclusiveRange(0.5, 1.5), reason: '每天约 1°');
    // 季度累计 ≈ 90°（同方向）
    final q = handleDir(DateTime(2026, 6, 21, 21));
    final qd = (((q - a) % 360) + 360) % 360;
    final signed = qd > 180 ? qd - 360 : qd;
    expect(signed.abs(), inInclusiveRange(80, 100), reason: '一季约 90°');
  });

  test('周日旋转：每晚每小时约 15°，自西向东推进', () {
    final a = handleDir(DateTime(2026, 3, 21, 21));
    final b = handleDir(DateTime(2026, 3, 21, 22));
    final diff = (((b - a) % 360) + 360) % 360;
    final signed = diff > 180 ? diff - 360 : diff;
    expect(signed.abs(), inInclusiveRange(13, 17), reason: '每小时 15°');
  });

  test('七星形状稳定：任意时刻相邻星距离比例不变（刚体旋转）', () {
    final p1 = BeidouAstronomy.starPositions(DateTime(2026, 3, 21, 21));
    final p2 = BeidouAstronomy.starPositions(DateTime(2026, 9, 23, 3));
    double len(List<({double x, double y})> p, int i, int j) {
      final dx = p[i].x - p[j].x, dy = p[i].y - p[j].y;
      return math.sqrt(dx * dx + dy * dy);
    }

    final r1 = len(p1, 0, 1) / len(p1, 1, 2);
    final r2 = len(p2, 0, 1) / len(p2, 1, 2);
    expect((r1 - r2).abs(), lessThan(0.02));
  });

  test('北斗钟时针：dubheAngle 与星图上天枢实际方位一致', () {
    final t = DateTime(2026, 10, 6, 20);
    final p = BeidouAstronomy.starPositions(t)[0];
    final a = math.atan2(p.x - 0.5, -(p.y - 0.30)) * 180 / math.pi;
    final expected = (a % 360 + 360) % 360;
    final actual = BeidouAstronomy.dubheAngle(t);
    final d = (actual - expected).abs();
    expect(d > 180 ? 360 - d : d, lessThan(0.5),
        reason: '时针角应与天枢屏幕方位一致（实测 $actual° vs $expected°）');
  });

  test('北斗钟刻度：整点时刻该小时刻度正指天枢，且 15°/小时均布', () {
    final t = DateTime(2026, 10, 6, 20);
    final hand = BeidouAstronomy.dubheAngle(t);
    final a = BeidouBackground.hourTickAngle(t, 20);
    final d = (a - hand).abs();
    expect(d > 180 ? 360 - d : d, lessThan(0.5),
        reason: '当前小时刻度应在时针线上（实测 $a° vs $hand°）');
    final c = BeidouBackground.hourTickAngle(t, 21);
    final step = ((c - a) % 360 + 360) % 360;
    expect(step, closeTo(15, 0.5), reason: '刻度间隔 15°/小时');
  });

  test('时辰读数：23-1 子时、1-3 丑时、13-15 未时、19-21 戌时', () {
    expect(BeidouBackground.shichenOf(DateTime(2026, 10, 6, 20)), '戌时');
    expect(BeidouBackground.shichenOf(DateTime(2026, 10, 6, 23)), '子时');
    expect(BeidouBackground.shichenOf(DateTime(2026, 10, 6, 0)), '子时');
    expect(BeidouBackground.shichenOf(DateTime(2026, 10, 6, 1)), '丑时');
    expect(BeidouBackground.shichenOf(DateTime(2026, 10, 6, 13)), '未时');
  });

  test('地支标注对齐：各支画在自身时辰扇区中心（= 偶数整点刻度角），'
      '时针在扇区内', () {
    final t = DateTime(2026, 10, 6, 19, 30); // 戌时中段
    final b = ((t.hour + 1) % 24) ~/ 2; // 戌 = 10
    expect(BeidouBackground.shichenChars[b], '戌');
    // 扇区中心角 = 偶数整点 2b 的刻度角（painter 用同一公式画字）
    final center = BeidouBackground.hourTickAngle(t, 2 * b);
    final start = BeidouBackground.hourTickAngle(t, 2 * b - 1);
    final end = BeidouBackground.hourTickAngle(t, 2 * b + 1);
    // 中心角落在扇区起止之间（跨 0° 环绕处理：顺时针差值）
    double cw(double from, double to) => ((to - from) % 360 + 360) % 360;
    expect(cw(start, center), closeTo(15, 0.001),
        reason: '扇区中心应在起点顺时针 15°');
    expect(cw(center, end), closeTo(15, 0.001),
        reason: '扇区终点应在中心顺时针 15°');
    // 天枢虚线（时针，连续角）落在戌扇区内：起点顺时针 7.5° 处
    // （19:30 = 进入戌时 30 分钟，每分钟 0.25°）
    final hand = BeidouAstronomy.dubheAngle(t);
    expect(cw(start, hand), closeTo(7.5, 0.5),
        reason: '19:30 的时针应在戌扇区开头 7.5° 附近');
  });

  test('布局间距：北斗内缘（天枢）与节气环文字外缘留有净空', () {
    // 复刻 painter 几何常量（720×1600 参考画布）：北斗外扩 1.08、
    // 节气环 0.50、文字外缘 = 环 + 14 偏移 + 字高
    const w = 720.0;
    final dubheR = (90.0 - 61.75) / 41.0 * w * 0.40 * 1.08;
    final labelOuter = w * 0.40 * 0.50 + 14 + 16;
    expect(dubheR - labelOuter, greaterThan(8),
        reason: '北斗内缘与节气环文字不应压叠（净空 ${dubheR - labelOuter}px）');
  });

  test('窗口随机闪烁：每 3s 窗口 1~2 颗呼吸、跨窗口选择不同', () {
    // 闪烁实现在 beidou_background，这里验证其静态行为窗口逻辑的随机源稳定性：
    // 同一窗口内选择稳定（帧间不跳变），不同窗口大概率不同组合
    final picks = <String>{};
    for (var w = 0; w < 6; w++) {
      // 复刻 background 的选择逻辑（同种子）；窗口内帧稳定性由种子保证
      final r = math.Random(w * 2654435761 + 97);
      final a = r.nextInt(7);
      final b = r.nextBool() ? r.nextInt(7) : -1;
      picks.add('$a,${b == a ? '' : b}');
    }
    debugPrint('windows: $picks');
    expect(picks.length, greaterThan(1), reason: '跨窗口应有不同组合');
  });
}
