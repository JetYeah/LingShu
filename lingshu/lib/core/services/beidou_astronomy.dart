import 'dart:math' as math;

/// 北斗七星真实天文位置（简化平球面算法）。
///
/// 原理：北斗是北天拱极星，围绕北天极旋转——周日圈（每小时 15°）+
/// 周年圈（每天约 1°）。旋转角由「当地恒星时 LST − 恒星赤经」决定，
/// 与四季/时刻天然联动（斗柄东指天下皆春，说的就是晚 8-9 点的周年指向）。
///
/// 屏幕投影：以天极（北极星方向）为中心，星的位置角 θ = (LST − RA)·15°/h，
/// 角半径 = 90° − Dec（北极距），线性缩放到屏幕坐标系。
class BeidouAstronomy {
  BeidouAstronomy._();

  /// 七星 J2000 赤经/赤纬（Hipparcos，度）。
  /// 顺序即连线顺序：天枢-天璇-天玑-天权-玉衡-开阳-摇光（斗口→柄尖）。
  static const _ras = [
    165.93, // 天枢 Dubhe   11h03m
    165.46, // 天璇 Merak   11h01m
    178.46, // 天玑 Phecda  11h53m
    183.86, // 天权 Megrez  12h15m
    193.51, // 玉衡 Alioth  12h54m
    203.98, // 开阳 Mizar   13h23m
    206.89, // 摇光 Alkaid  13h47m
  ];
  static const _decs = [
    61.75, // 天枢
    56.38, // 天璇
    53.69, // 天玑
    57.03, // 天权
    55.96, // 玉衡
    54.93, // 开阳
    49.31, // 摇光
  ];

  /// 七星屏幕坐标（像素）。以天极 (cx, cy) 为圆心、北极距折算半径，
  /// [radiusPx] 为「摇光轨道」的像素半径（调用方按画面尺寸给定，
  /// 保证任意旋转角七星都在画面内）。
  /// 等比投影不做拉伸——保持七星相对形状恒定（刚体旋转）。
  static List<({double x, double y})> starPositionsPx(DateTime now,
      {required double cx, required double cy, required double radiusPx}) {
    final lst = _localSiderealTime(now);
    const maxPoleDist = 41.0; // 摇光北极距 40.7°
    final out = <({double x, double y})>[];
    for (var i = 0; i < 7; i++) {
      final theta = _wrapDegrees(lst - _ras[i]) * math.pi / 180;
      final r = (90.0 - _decs[i]) / maxPoleDist * radiusPx;
      // 北天区星图方位（传统式盘·上南下北镜像系）：HA=0 星在天极正上方
      // （上中天，天顶一侧即正南）；HA 增大（向西）星向右侧移动——
      // 东升（左）西落（右），周日与周年皆顺时针绕极，读时方向与钟表一致。
      out.add((x: cx + r * math.sin(theta), y: cy - r * math.cos(theta)));
    }
    return out;
  }

  /// 天枢此刻屏幕角（度，顺时针自正上方）——「北斗钟」时针方向：
  /// 北极星→天枢虚线随北斗刚体旋转，恒星日 23h56m 转一周（≈15.0411°/时）。
  static double dubheAngle(DateTime now) =>
      _wrapDegrees(_localSiderealTime(now) - _ras[0]);

  /// 七星归一化坐标（0..1）：天极 (0.5, 0.30)，半径按 720×1600 参考画布
  /// 折算——仅用于测试；UI 请用 [starPositionsPx]。
  static List<({double x, double y})> starPositions(DateTime now) {
    return starPositionsPx(now, cx: 0.5, cy: 0.30, radiusPx: 0.42);
  }

  /// 当地恒星时（度）。GMST = 280.46061837 + 360.98564736629·d，
  /// d 为 J2000 起算的 UT 天数（含小数），加东经 116.4°（华北）。
  /// 实测校验：2026-10-06 20:00 北京 → LST ≈ 311.6°（与星图软件一致）。
  static double _localSiderealTime(DateTime now) {
    final d = _daysSinceJ2000(now);
    final gmst = 280.46061837 + 360.98564736629 * d;
    return _wrapDegrees(gmst + 116.4);
  }

  static double _daysSinceJ2000(DateTime now) {
    final utc = now.toUtc();
    final j2000 = DateTime.utc(2000, 1, 1, 12);
    return utc.difference(j2000).inMinutes / 1440.0;
  }

  static double _wrapDegrees(double d) {
    var v = d % 360.0;
    if (v < 0) v += 360.0;
    return v;
  }
}
