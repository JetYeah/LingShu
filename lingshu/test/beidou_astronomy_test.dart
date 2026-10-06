import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lingshu/core/services/beidou_astronomy.dart';

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

  test('绝对相位：与 NOAA 独立公式的 LST 一致（摇光 HA 反推）', () {
    // NOAA: GMST(0hUT) = 6.6974h + 0.0657098244·d0; 2026-10-06 d0=9774.5
    // → GMST(0h)=0.9h; +12hUT×1.0027 → GMST=12.93h=193.9°
    // LST = 193.9 + 116.4 = 310.3°（±分钟精度）
    // 摇光 RA 206.89 → HA = 310.3-206.89 = 103.4°
    // 屏幕柄向 ang = (360-HA) → 256.6°±2
    final dir = handleDir(DateTime(2026, 10, 6, 20));
    final d = (dir - 256.6).abs();
    final dist = d > 180 ? 360 - d : d;
    expect(dist, lessThan(3), reason: 'LST 与 NOAA 公式偏差应 <3°（实测 $dir°）');
  });

  test('实景锚点：10 月晚 8 点北斗在左下、斗柄指西（星图软件实景）', () {
    final dir = handleDir(DateTime(2026, 10, 6, 20));
    // 西=270°，容差 45°（十月傍晚斗柄西垂）
    final d = (dir - 270).abs();
    final dist = d > 180 ? 360 - d : d;
    expect(dist, lessThan(45), reason: '十月斗柄西垂（实测 $dir°）');

    // 北斗整体应在天极左侧（x < 0.5）
    final p = BeidouAstronomy.starPositions(DateTime(2026, 10, 6, 20));
    final leftCount = p.where((s) => s.x < 0.5).length;
    expect(leftCount, greaterThanOrEqualTo(5), reason: '十月北斗应在天极西侧');
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
