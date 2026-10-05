import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lingshu/core/services/beidou_astronomy.dart';

/// 北斗天文位置：验证绕极旋转与季节指向（斗柄东指天下皆春）
void main() {
  // 星序：天枢-天璇-天玑-天权-玉衡-开阳-摇光（摇光=柄尖）
  double dirDeg(DateTime t) {
    final p = BeidouAstronomy.starPositions(t);
    final cx = 0.5, cy = 0.28; // 天极中心
    final tip = p.last; // 摇光（柄尖）
    final dx = tip.x - cx, dy = tip.y - cy;
    // 屏幕方位角：上=0°（北），右=90°（东），顺时针
    final a = 180.0 / 3.141592653589793 * math.atan2(dx, -dy);
    return (a % 360 + 360) % 360;
  }

  test('经典口诀：晚 21 时斗柄指向四季节点（东春/南夏/西秋/北冬）', () {
    // 斗柄指向按《鹗冠子》：春东/夏南/秋西/北冬（晚 8-9 点观测）
    // 春分 3-21 21:00 → 指东（方位角≈90°）
    final spring = dirDeg(DateTime(2026, 3, 21, 21));
    // 夏至 6-21 21:00 → 指南（≈180°）
    final summer = dirDeg(DateTime(2026, 6, 21, 21));
    // 秋分 9-23 21:00 → 指西（≈270°）
    final autumn = dirDeg(DateTime(2026, 9, 23, 21));
    // 冬至 12-21 21:00 → 指北（≈0/360°）
    final winter = dirDeg(DateTime(2026, 12, 21, 21));

    double dist(double a, double b) {
      var d = (a - b).abs() % 360;
      return d > 180 ? 360 - d : d;
    }

    debugPrint('春=${spring.toStringAsFixed(0)}° 夏=${summer.toStringAsFixed(0)}° '
        '秋=${autumn.toStringAsFixed(0)}° 冬=${winter.toStringAsFixed(0)}°');
    // 口诀是大致指向，允许 ±60° 容差（季节宽泛对应）
    expect(dist(spring, 90), lessThan(60), reason: '春分斗柄指东');
    expect(dist(summer, 180), lessThan(60), reason: '夏至斗柄指南');
    expect(dist(autumn, 270), lessThan(60), reason: '秋分斗柄指西');
    expect(dist(winter, 0), lessThan(60), reason: '冬至斗柄指北');
  });

  test('周年旋转：同一时刻每天转约 1°，一季度转约 90°', () {
    final a = dirDeg(DateTime(2026, 3, 21, 21));
    final b = dirDeg(DateTime(2026, 3, 22, 21));
    var d = (b - a).abs() % 360;
    d = d > 180 ? 360 - d : d;
    expect(d, inInclusiveRange(0.5, 1.5), reason: '每天约 1°');

    final q = dirDeg(DateTime(2026, 6, 21, 21));
    var qd = ((q - a) % 360).abs();
    qd = qd > 180 ? 360 - qd : qd;
    expect(qd, inInclusiveRange(80, 100), reason: '一季度约 90°');
  });

  test('周日旋转：同一晚每小时转约 15°', () {
    final a = dirDeg(DateTime(2026, 3, 21, 21));
    final b = dirDeg(DateTime(2026, 3, 21, 22));
    var d = (b - a).abs() % 360;
    d = d > 180 ? 360 - d : d;
    expect(d, inInclusiveRange(13, 17), reason: '每小时约 15°');
  });

  test('七星形状稳定：任意时刻相邻星距离比例不变（刚体旋转）', () {
    final p1 = BeidouAstronomy.starPositions(DateTime(2026, 3, 21, 21));
    final p2 = BeidouAstronomy.starPositions(DateTime(2026, 9, 23, 3));
    double len(List<({double x, double y})> p, int i, int j) {
      final dx = p[i].x - p[j].x, dy = p[i].y - p[j].y;
      return math.sqrt(dx * dx + dy * dy);
    }

    // 天枢-天璇 / 天璇-天玑 的比值应恒定（刚体）
    final r1 = len(p1, 0, 1) / len(p1, 1, 2);
    final r2 = len(p2, 0, 1) / len(p2, 1, 2);
    expect((r1 - r2).abs(), lessThan(0.02));
  });
}
