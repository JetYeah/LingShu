// 调试探针：用公开成员反推摇光 HA / LST，验证星图锚点（dart run tool/dbg3.dart）
// ignore_for_file: avoid_print
import 'dart:math' as math;
import 'package:lingshu/core/services/beidou_astronomy.dart';

void main() {
  // 用公开成员反推 LST：摇光 HA = 360 - ang
  for (final (label, t) in [
    ('6-21 23:00', DateTime(2026, 6, 21, 23)),
    ('10-06 20:00', DateTime(2026, 10, 6, 20)),
    ('3-21 23:00', DateTime(2026, 3, 21, 23)),
  ]) {
    final p = BeidouAstronomy.starPositionsPx(t,
        cx: 0, cy: 0, radiusPx: 1);
    final tip = p.last;
    final ang = (math.atan2(tip.x, -tip.y) * 180 / math.pi % 360 + 360) % 360;
    final ha = (360 - ang) % 360;
    final lst = (ha + 206.89) % 360;
    print('$label 屏幕方位=$ang° 摇光HA=$ha° 反推LST=$lst°');
  }
}
