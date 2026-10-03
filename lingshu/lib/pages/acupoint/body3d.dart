import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// 3D 向量
class V3 {
  final double x, y, z;
  const V3(this.x, this.y, this.z);
  V3 rotateY(double a) => V3(
      x * math.cos(a) + z * math.sin(a), y, -x * math.sin(a) + z * math.cos(a));
  V3 rotateX(double a) => V3(
      x, y * math.cos(a) - z * math.sin(a), y * math.sin(a) + z * math.cos(a));
  V3 add(V3 o) => V3(x + o.x, y + o.y, z + o.z);
}

/// 铜人身体部件（球体或胶囊体），坐标单位米，脚底为 0，头顶约 1.72，面向 +Z
class BodyPart {
  final V3 a; // 球体: 圆心 / 胶囊: 一端
  final V3? b; // 胶囊另一端
  final double r;
  const BodyPart(this.a, this.r, {this.b});
}

/// 人体建模（男/女两版），与穴位坐标同一坐标系
class Mannequin {
  final List<BodyPart> parts;
  const Mannequin(this.parts);

  static const double modelHeight = 1.72;

  static Mannequin male() => const Mannequin([
        // 头（+发髻）
        BodyPart(V3(0, 1.655, 0), 0.092),
        BodyPart(V3(0, 1.745, -0.030), 0.030),
        // 颈（上延入头内，弱化关节缝）
        BodyPart(V3(0, 1.545, -0.005), 0.052, b: V3(0, 1.635, 0)),
        // 躯干
        BodyPart(V3(0, 1.13, 0), 0.125, b: V3(0, 1.28, 0)),
        BodyPart(V3(0, 1.28, 0), 0.155, b: V3(0, 1.42, 0)),
        BodyPart(V3(0, 1.02, 0), 0.132, b: V3(0, 1.13, 0)),
        // 肩（三角肌，贴躯干）
        BodyPart(V3(0.155, 1.435, 0), 0.058),
        BodyPart(V3(-0.155, 1.435, 0), 0.058),
        // 手臂
        BodyPart(V3(0.183, 1.42, 0), 0.047, b: V3(0.228, 1.19, 0.005)),
        BodyPart(V3(-0.183, 1.42, 0), 0.047, b: V3(-0.228, 1.19, 0.005)),
        // 前臂顺延至掌（无独立大球关节）
        BodyPart(V3(0.228, 1.19, 0.005), 0.040, b: V3(0.322, 0.955, 0.028)),
        BodyPart(V3(-0.228, 1.19, 0.005), 0.040, b: V3(-0.322, 0.955, 0.028)),
        // 手掌（薄胶囊）
        BodyPart(V3(0.330, 0.940, 0.030), 0.026, b: V3(0.338, 0.902, 0.028)),
        BodyPart(V3(-0.330, 0.940, 0.030), 0.026, b: V3(-0.338, 0.902, 0.028)),
        // 腿
        BodyPart(V3(0.075, 1.00, 0), 0.075, b: V3(0.095, 0.52, 0.01)),
        BodyPart(V3(-0.075, 1.00, 0), 0.075, b: V3(-0.095, 0.52, 0.01)),
        BodyPart(V3(0.095, 0.52, 0.01), 0.055, b: V3(0.10, 0.09, -0.01)),
        BodyPart(V3(-0.095, 0.52, 0.01), 0.055, b: V3(-0.10, 0.09, -0.01)),
        // 脚
        BodyPart(V3(0.10, 0.038, 0.10), 0.038, b: V3(0.10, 0.038, 0.20)),
        BodyPart(V3(-0.10, 0.038, 0.10), 0.038, b: V3(-0.10, 0.038, 0.20)),
      ]);

  static Mannequin female() => const Mannequin([
        BodyPart(V3(0, 1.655, 0), 0.088),
        BodyPart(V3(0, 1.738, -0.028), 0.028),
        BodyPart(V3(0, 1.545, -0.005), 0.047, b: V3(0, 1.632, 0)),
        BodyPart(V3(0, 1.13, 0), 0.104, b: V3(0, 1.28, 0)),
        BodyPart(V3(0, 1.28, 0), 0.145, b: V3(0, 1.42, 0)),
        BodyPart(V3(0, 1.02, 0), 0.142, b: V3(0, 1.13, 0)),
        BodyPart(V3(0.07, 1.335, 0.112), 0.052),
        BodyPart(V3(-0.07, 1.335, 0.112), 0.052),
        BodyPart(V3(0.140, 1.435, 0), 0.052),
        BodyPart(V3(-0.140, 1.435, 0), 0.052),
        BodyPart(V3(0.170, 1.42, 0), 0.042, b: V3(0.215, 1.19, 0.005)),
        BodyPart(V3(-0.170, 1.42, 0), 0.042, b: V3(-0.215, 1.19, 0.005)),
        BodyPart(V3(0.215, 1.19, 0.005), 0.036, b: V3(0.308, 0.955, 0.028)),
        BodyPart(V3(-0.215, 1.19, 0.005), 0.036, b: V3(-0.308, 0.955, 0.028)),
        BodyPart(V3(0.316, 0.940, 0.030), 0.024, b: V3(0.323, 0.905, 0.028)),
        BodyPart(V3(-0.316, 0.940, 0.030), 0.024, b: V3(-0.323, 0.905, 0.028)),
        BodyPart(V3(0.070, 1.00, 0), 0.078, b: V3(0.092, 0.52, 0.01)),
        BodyPart(V3(-0.070, 1.00, 0), 0.078, b: V3(-0.092, 0.52, 0.01)),
        BodyPart(V3(0.092, 0.52, 0.01), 0.05, b: V3(0.098, 0.09, -0.01)),
        BodyPart(V3(-0.092, 0.52, 0.01), 0.05, b: V3(-0.098, 0.09, -0.01)),
        BodyPart(V3(0.098, 0.036, 0.10), 0.036, b: V3(0.098, 0.036, 0.195)),
        BodyPart(V3(-0.098, 0.036, 0.10), 0.036, b: V3(-0.098, 0.036, 0.195)),
      ]);
}

/// 简单 3D 相机：绕目标点旋转 + 缩放投影
class Camera3D {
  double yaw;
  double pitch;
  double zoom;
  final V3 target;
  Camera3D({
    this.yaw = 0,
    this.pitch = 0,
    required this.zoom,
    this.target = const V3(0, 0.88, 0),
  });

  Offset? project(V3 p, Size size) {
    final t = p.add(V3(-target.x, -target.y, -target.z));
    final r = t.rotateY(yaw).rotateX(pitch);
    return Offset(size.width / 2 + r.x * zoom, size.height / 2 - r.y * zoom);
  }

  double depthFactor(V3 p) {
    final t = p.add(V3(-target.x, -target.y, -target.z));
    return t.rotateY(yaw).rotateX(pitch).z;
  }
}

class AcupointDot {
  final String code;
  final String name;
  final String meridian;
  final List<double>? pos;
  final bool common;
  const AcupointDot({
    required this.code,
    required this.name,
    required this.meridian,
    required this.common,
    this.pos,
  });
}

/// ── 玄色舞台 · 白玉经穴铜人 ────────────────────────────────────────────
/// 多 pass 软件渲染：投影 → 柱面渐变体积 → 景深雾化 → 边缘光，
/// 选中经络以鎏金样条贯穿，穴位为金环靶心点。
class MannequinPainter extends CustomPainter {
  final Mannequin mannequin;
  final Camera3D camera;
  final List<AcupointDot> acupoints;
  final String? highlightMeridian;
  final Set<String> dimCodes;
  final String? selectedCode; // 选中的穴位（呼吸脉动 + 名牌）
  final double phase; // 0..1 动画相位

  MannequinPainter({
    required this.mannequin,
    required this.camera,
    required this.acupoints,
    this.highlightMeridian,
    this.dimCodes = const {},
    this.selectedCode,
    this.phase = 0,
    super.repaint,
  });

  // 玄色舞台
  static const stageTop = Color(0xFF202B38);
  static const stageBottom = Color(0xFF0D131C);
  static const stageFog = Color(0xFF16202B);

  // 白玉瓷材质
  static const jadeLight = Color(0xFFF8F4EA);
  static const jadeMid = Color(0xFFDBD5C7);
  static const jadeDark = Color(0xFF8C97A3);

  // 鎏金
  static const gold = Color(0xFFD4AF6E);
  static const goldDeep = Color(0xFFB08D57);

  // 光照方向（屏幕空间，左上）
  static const lightDx = -0.62, lightDy = -0.78;

  @override
  void paint(Canvas canvas, Size size) {
    _paintStage(canvas, size);

    // 部件按深度排序（远→近），计算景深 frontness
    final draws = <_PartDraw>[];
    for (final part in mannequin.parts) {
      final mid = part.b == null
          ? part.a
          : V3((part.a.x + part.b!.x) / 2, (part.a.y + part.b!.y) / 2,
              (part.a.z + part.b!.z) / 2);
      draws.add(_PartDraw(part, camera.depthFactor(mid)));
    }
    double dMin = draws.map((d) => d.depth).reduce(math.min);
    double dMax = draws.map((d) => d.depth).reduce(math.max);
    final span = (dMax - dMin).clamp(0.0001, 10.0);
    for (final d in draws) {
      d.frontness = 1.0 - (d.depth - dMin) / span; // 1=最前 0=最后
    }
    draws.sort((a, b) => b.depth.compareTo(a.depth));

    // Pass 1: 落影（统一先画，避免影盖身体）
    for (final d in draws) {
      _paintShadow(canvas, size, d);
    }
    // Pass 2: 身体
    for (final d in draws) {
      _paintBody(canvas, size, d);
    }
    // Pass 3: 经络鎏金样条
    if (highlightMeridian != null) {
      _paintMeridianPath(canvas, size);
    }
    // Pass 4: 穴位
    _paintAcupoints(canvas, size);
  }

  // ── 舞台 ──
  void _paintStage(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [stageTop, stageBottom],
          ).createShader(rect));

    // 人物身后的柔光
    final glow = camera.project(const V3(0, 1.1, -0.3), size);
    if (glow != null) {
      canvas.drawCircle(
          glow,
          math.max(size.width, size.height) * 0.42,
          Paint()
            ..shader = RadialGradient(colors: [
              const Color(0xFFC8A96B).withValues(alpha: 0.14),
              const Color(0xFFC8A96B).withValues(alpha: 0.0),
            ]).createShader(Rect.fromCircle(center: glow, radius: size.width * 0.45)));
    }

    // 漂浮微尘（固定伪随机分布，随 phase 缓明灭）
    final rand = math.Random(7);
    for (var i = 0; i < 26; i++) {
      final dx = rand.nextDouble() * size.width;
      final dy = rand.nextDouble() * size.height * 0.9;
      final tw = 0.5 + 0.5 * math.sin(phase * 2 * math.pi + i * 1.7);
      final a = 0.04 + 0.10 * tw * rand.nextDouble();
      canvas.drawCircle(
          Offset(dx, dy),
          0.8 + rand.nextDouble() * 1.4,
          Paint()..color = Color(0xFFE8D5A8).withValues(alpha: a));
    }

    // 地台：暗影 + 双金环
    final floor = camera.project(const V3(0, 0.005, 0.10), size);
    if (floor != null) {
      canvas.drawOval(
          Rect.fromCenter(
              center: floor, width: size.width * 0.42, height: size.width * 0.115),
          Paint()
            ..shader = RadialGradient(colors: [
              const Color(0xFF000000).withValues(alpha: 0.55),
              const Color(0xFF000000).withValues(alpha: 0.0),
            ]).createShader(Rect.fromCircle(
                center: floor, radius: size.width * 0.24)));
      canvas.drawOval(
          Rect.fromCenter(
              center: floor, width: size.width * 0.34, height: size.width * 0.09),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = gold.withValues(alpha: 0.26));
      canvas.drawOval(
          Rect.fromCenter(
              center: floor, width: size.width * 0.26, height: size.width * 0.068),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.7
            ..color = gold.withValues(alpha: 0.14));
    }
  }

  // ── 落影 ──
  void _paintShadow(Canvas canvas, Size size, _PartDraw d) {
    final a = camera.project(d.part.a, size);
    final r = d.part.r * camera.zoom;
    if (a == null) return;
    if (d.part.b == null) {
      _shadowPaint(canvas, a, a, r);
    } else {
      final b = camera.project(d.part.b!, size);
      if (b != null) _shadowPaint(canvas, a, b, r);
    }
  }

  void _shadowPaint(Canvas canvas, Offset a, Offset b, double r) {
    const off = Offset(9, 15);
    final path = _stadium(a + off, b + off, r);
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF04070C).withValues(alpha: 0.34)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
  }

  // ── 身体：白玉瓷 ──
  void _paintBody(Canvas canvas, Size size, _PartDraw d) {
    final a = camera.project(d.part.a, size);
    final r = d.part.r * camera.zoom;
    if (a == null) return;

    if (d.part.b == null) {
      // 球体（头/肩/发髻）：径向渐变 + 镜面高光
      canvas.drawCircle(
          a,
          r,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.4, -0.45),
              radius: 1.25,
              colors: const [jadeLight, jadeMid, jadeDark],
              stops: const [0.05, 0.55, 1.0],
            ).createShader(Rect.fromCircle(center: a, radius: r)));
      if (r > 8) {
        // 釉面镜面高光点
        canvas.drawCircle(
            a + Offset(-r * 0.34, -r * 0.38),
            r * 0.16,
            Paint()
              ..color = const Color(0xFFFFFFF5).withValues(alpha: 0.55)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5));
      }
      _edgeAndFog(
          canvas, Path()..addOval(Rect.fromCircle(center: a, radius: r)), d);
    } else {
      final b = camera.project(d.part.b!, size);
      if (b == null) return;
      final path = _stadium(a, b, r);
      final len = (b - a).distance;
      if (len < 0.5) {
        canvas.drawCircle(
            a,
            r,
            Paint()
              ..shader = RadialGradient(
                center: const Alignment(-0.4, -0.45),
                radius: 1.25,
                colors: const [jadeLight, jadeMid, jadeDark],
                stops: const [0.05, 0.55, 1.0],
              ).createShader(Rect.fromCircle(center: a, radius: r)));
        _edgeAndFog(
            canvas, Path()..addOval(Rect.fromCircle(center: a, radius: r)), d);
        return;
      }
      // 圆柱明暗：垂直于轴向的线性渐变，亮侧对齐全局光源
      final u = (b - a) / len;
      final n = Offset(-u.dy, u.dx);
      final align = n.dx * lightDx + n.dy * lightDy;
      final lightN = align >= 0 ? n : -n;
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      final begin = mid + lightN * r * 1.6;
      final end = mid - lightN * r * 1.6;
      canvas.drawPath(
          path,
          Paint()
            ..shader = ui.Gradient.linear(
              begin,
              end,
              const [jadeLight, jadeMid, jadeDark],
              const [0.06, 0.5, 1.0],
            ));
      // 受光侧釉面高光带（沿胶囊受光边）
      final inset = r * 0.55;
      _edgeAndFog(canvas, path, d,
          lightEdgeA: a + u * r * 0.35 + lightN * inset,
          lightEdgeB: b - u * r * 0.35 + lightN * inset,
          edgeR: r);
    }
  }

  /// 边缘光（釉面）+ 景深雾化
  void _edgeAndFog(Canvas canvas, Path path, _PartDraw d,
      {Offset? lightEdgeA, Offset? lightEdgeB, double? edgeR}) {
    // 受光侧釉面高光带：沿胶囊受光边描一条柔化亮线
    if (lightEdgeA != null && lightEdgeB != null) {
      canvas.drawLine(
          lightEdgeA,
          lightEdgeB,
          Paint()
            ..strokeWidth = math.max((edgeR ?? 4) * 0.42, 2)
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFFFFFFF2).withValues(alpha: 0.34)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2));
    }
    // 整圈极细描边（雕塑感）
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9
          ..color = const Color(0xFF6B7684).withValues(alpha: 0.35));
    // 背侧部件向舞台色退隐
    final fog = (1 - d.frontness) * 0.5;
    if (fog > 0.02) {
      canvas.drawPath(
          path,
          Paint()
            ..color = stageFog.withValues(alpha: fog)
            ..blendMode = BlendMode.srcOver);
    }
  }

  // ── 经络鎏金样条 ──
  void _paintMeridianPath(Canvas canvas, Size size) {
    final pts = acupoints
        .where((p) =>
            p.meridian == highlightMeridian &&
            p.pos != null &&
            _numOf(p.code) != null)
        .toList()
      ..sort((x, y) => _numOf(x.code)!.compareTo(_numOf(y.code)!));
    if (pts.length < 2) return;

    final projected = <Offset>[];
    for (final p in pts) {
      final s = camera.project(V3(p.pos![0], p.pos![1], p.pos![2]), size);
      if (s != null) projected.add(s);
    }
    if (projected.length < 2) return;

    final path = _catmullRom(projected);
    final shimmer = 0.85 + 0.15 * math.sin(phase * 2 * math.pi);

    // 外发光
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 6.5
          ..color = gold.withValues(alpha: 0.20 * shimmer)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    // 金线
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 2.0
          ..color = gold.withValues(alpha: 0.95 * shimmer));
  }

  int? _numOf(String code) {
    final m = RegExp(r'(\d+)$').firstMatch(code);
    return m == null ? null : int.parse(m.group(1)!);
  }

  Path _catmullRom(List<Offset> p) {
    final path = Path()..moveTo(p[0].dx, p[0].dy);
    for (var i = 0; i < p.length - 1; i++) {
      final p0 = p[i - 1 < 0 ? 0 : i - 1];
      final p1 = p[i];
      final p2 = p[i + 1];
      final p3 = p[i + 2 > p.length - 1 ? p.length - 1 : i + 2];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  // ── 穴位：金环靶心 ──
  void _paintAcupoints(Canvas canvas, Size size) {
    final pulse = 0.5 + 0.5 * math.sin(phase * 2 * math.pi);

    final dots = <_DotDraw>[];
    for (final ap in acupoints) {
      if (ap.pos == null) continue;
      final s = camera.project(V3(ap.pos![0], ap.pos![1], ap.pos![2]), size);
      if (s == null) continue;
      if (s.dx < -20 || s.dy < -20 || s.dx > size.width + 20 || s.dy > size.height + 20) {
        continue;
      }
      dots.add(_DotDraw(ap, s));
    }
    dots.sort((a, b) => camera
        .depthFactor(V3(a.ap.pos![0], a.ap.pos![1], a.ap.pos![2]))
        .compareTo(camera.depthFactor(
            V3(b.ap.pos![0], b.ap.pos![1], b.ap.pos![2]))));

    for (final d in dots) {
      final ap = d.ap;
      final isHi = highlightMeridian == null
          ? ap.common
          : ap.meridian == highlightMeridian;
      final isDim = dimCodes.contains(ap.code);
      final isSelected = selectedCode == ap.code;

      if (isSelected) {
        // 呼吸光环
        final glowR = 11 + 6 * pulse;
        canvas.drawCircle(
            d.screen,
            glowR,
            Paint()
              ..color = gold.withValues(alpha: 0.14 + 0.12 * pulse)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(
            d.screen,
            8.5,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4
              ..color = gold.withValues(alpha: 0.9));
        canvas.drawCircle(d.screen, 3.6, Paint()..color = gold);
        _drawLabel(canvas, d.screen, ap.name);
        continue;
      }

      if (isDim) {
        canvas.drawCircle(
            d.screen, 2.0, Paint()..color = gold.withValues(alpha: 0.22));
        continue;
      }
      if (!isHi && highlightMeridian != null) continue;

      final baseR = isHi ? 3.2 : 2.6;
      // 接触投影（贴体感）
      canvas.drawCircle(
          d.screen + const Offset(0.8, 1.2),
          baseR + 1.2,
          Paint()
            ..color = const Color(0xFF0A0F16).withValues(alpha: 0.30)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
      canvas.drawCircle(
          d.screen,
          baseR + 3.2,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1
            ..color = gold.withValues(alpha: isHi ? 0.55 : 0.4));
      canvas.drawCircle(
          d.screen,
          baseR,
          Paint()
            ..color =
                isHi ? const Color(0xFFE9CE93) : gold.withValues(alpha: 0.85));
    }
  }

  void _drawLabel(Canvas canvas, Offset at, String name) {
    final tp = TextPainter(
      text: TextSpan(
        text: name,
        style: const TextStyle(
          fontFamily: 'SerifSC',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
          color: Color(0xFFF2E6C9),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final p = at + const Offset(14, -26);
    // 名牌底
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: p + Offset(tp.width / 2, tp.height / 2),
                width: tp.width + 16,
                height: tp.height + 8),
            const Radius.circular(6)),
        Paint()..color = const Color(0xFF0D131C).withValues(alpha: 0.72));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: p + Offset(tp.width / 2, tp.height / 2),
                width: tp.width + 16,
                height: tp.height + 8),
            const Radius.circular(6)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = gold.withValues(alpha: 0.45));
    tp.paint(canvas, p);
  }

  /// 胶囊轮廓（两端圆 + 矩形，非零填充并集）
  Path _stadium(Offset a, Offset b, double r) {
    final path = Path();
    final len = (b - a).distance;
    if (len < 0.001) {
      return path..addOval(Rect.fromCircle(center: a, radius: r));
    }
    final u = (b - a) / len;
    final n = Offset(-u.dy, u.dx);
    path.addOval(Rect.fromCircle(center: a, radius: r));
    path.addOval(Rect.fromCircle(center: b, radius: r));
    path.addPolygon([
      a + n * r,
      b + n * r,
      b - n * r,
      a - n * r,
    ], true);
    return path;
  }

  @override
  bool shouldRepaint(covariant MannequinPainter old) => true;
}

class _PartDraw {
  final BodyPart part;
  final double depth;
  double frontness = 0.5;
  _PartDraw(this.part, this.depth);
}

class _DotDraw {
  final AcupointDot ap;
  final Offset screen;
  _DotDraw(this.ap, this.screen);
}
