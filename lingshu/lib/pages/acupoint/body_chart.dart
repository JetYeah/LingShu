import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../core/theme.dart';
import '../../core/services/content_loader.dart';

/// 三视图经穴挂图：正面/背面/侧面，红线经络 + 金点穴位（数据来自医学网格投影）
class BodyChartView extends StatefulWidget {
  final List<Acupoint> acupoints;
  final String view; // front / back / side
  final String filter; // COMMON / ALL / 经络 code
  final ValueChanged<Acupoint> onPointTap;
  final String? spotlight; // 搜索定位态：该穴高亮闪烁，其余穴位/经络灰掉
  final VoidCallback? onSpotlightDismiss; // 定位态下点击其他区域

  const BodyChartView({
    super.key,
    required this.acupoints,
    required this.view,
    required this.filter,
    required this.onPointTap,
    this.spotlight,
    this.onSpotlightDismiss,
  });

  @override
  State<BodyChartView> createState() => BodyChartViewState();
}

class BodyChartViewState extends State<BodyChartView>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _data;
  String? _selected;
  late Map<String, AcupointMeta> _meta;
  final _ctrl = TransformationController();
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
        ..repeat();

  @override
  void initState() {
    super.initState();
    _meta = {
      for (final a in widget.acupoints)
        a.code: AcupointMeta(
            meridian: a.meridian, common: a.common, name: a.name),
    };
    rootBundle
        .loadString('assets/data/body_views.json')
        .then((s) => mounted ? setState(() => _data = jsonDecode(s)) : null);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  double get _scale => _ctrl.value.getMaxScaleOnAxis();

  void clearSelection() {
    if (mounted) setState(() => _selected = null);
  }

  /// 选中穴位；返回其可见的视图名（页面据此切换 Tab），找不到返回 null
  String? focus(String code) {
    final views = _data?['views'];
    if (views is! Map<String, dynamic>) return null;
    for (final entry in views.entries) {
      final pts = (entry.value['points'] as List).cast<Map<String, dynamic>>();
      if (pts.any((p) => p['c'] == code)) {
        setState(() => _selected = code);
        return entry.key;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _visiblePoints() {
    final v = _data?['views']?[widget.view];
    if (v == null) return const [];
    final pts = (v['points'] as List).cast<Map<String, dynamic>>();
    if (widget.filter == 'ALL') return pts;
    if (widget.filter == 'COMMON') {
      return pts.where((p) {
        final ap = _meta[p['c']];
        return ap == null ? true : ap.common;
      }).toList();
    }
    return pts.where((p) => _meta[p['c']]?.meridian == widget.filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final v = _data?['views']?[widget.view];
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _ctrl]),
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          // 舞台渐变放在 InteractiveViewer 之外：缩放只作用于人体/经络/穴位
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [LingShuColors.stageTop, LingShuColors.stageBottom],
              ),
            ),
            child: InteractiveViewer(
              transformationController: _ctrl,
              maxScale: 8,
              minScale: 1,
              boundaryMargin: const EdgeInsets.all(80),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _handleTap(d.localPosition, size),
                  child: CustomPaint(
                    size: size,
                    painter: _ChartPainter(
                      view: v,
                      filter: widget.filter,
                      selected: _selected,
                      phase: _pulse.value,
                      pointMeta: _meta,
                      scale: _scale,
                      spotlight: widget.spotlight,
                    ),
                  ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleTap(Offset local, Size size) {
    final v = _data?['views']?[widget.view];
    if (v == null) return;
    final layout = _layout(size, (v['aspect'] as num).toDouble());
    // 命中半径按当前缩放折算：屏幕上始终约 20px，放大后密集穴也能分开点
    final best0 = (22 / _scale).clamp(4.0, 22.0);
    double best = best0;
    String? code;
    for (final p in _visiblePoints()) {
      final d = (Offset((p['x'] as num).toDouble() * layout.bodyH + layout.offX,
                  (p['y'] as num).toDouble() * layout.bodyH + layout.offY) -
              local)
          .distance;
      if (d < best) {
        best = d;
        code = p['c'] as String;
      }
    }
    // 定位态：目标穴可能被筛选器（常用穴/经络）隐藏，单独纳入命中
    final sp = widget.spotlight;
    if (sp != null && code != sp) {
      final pts = (v['points'] as List).cast<Map<String, dynamic>>();
      for (final p in pts) {
        if (p['c'] != sp) continue;
        final d = (Offset((p['x'] as num).toDouble() * layout.bodyH + layout.offX,
                    (p['y'] as num).toDouble() * layout.bodyH + layout.offY) -
                local)
            .distance;
        if (d < best) {
          best = d;
          code = sp;
        }
        break;
      }
    }
    // 定位态下点到目标穴以外：退出定位；若点中其他穴位则照常选中并弹详情
    if (sp != null && code != sp) {
      if (code != null) {
        setState(() => _selected = code);
        final ap = widget.acupoints.where((a) => a.code == code).firstOrNull;
        if (ap != null) widget.onPointTap(ap);
      }
      widget.onSpotlightDismiss?.call();
      return;
    }
    if (code != null) {
      setState(() => _selected = code);
      final ap = widget.acupoints.where((a) => a.code == code).firstOrNull;
      if (ap != null) widget.onPointTap(ap);
    }
  }
}

class AcupointMeta {
  final String meridian;
  final bool common;
  final String name;
  const AcupointMeta({required this.meridian, required this.common, required this.name});
}

class _ChartLayout {
  final double bodyH, offX, offY;
  const _ChartLayout(this.bodyH, this.offX, this.offY);
}

_ChartLayout _layout(Size size, double aspect) {
  const padV = 14.0, padH = 18.0;
  final bodyH = math.min(size.height - 2 * padV,
      (size.width - 2 * padH) / math.max(aspect, 0.05));
  final bodyW = bodyH * aspect;
  return _ChartLayout(
      bodyH, (size.width - bodyW) / 2, (size.height - bodyH) / 2);
}

class _ChartPainter extends CustomPainter {
  final Map<String, dynamic>? view;
  final String filter;
  final String? selected;
  final double phase;
  final Map<String, AcupointMeta> pointMeta;
  final double scale; // 当前缩放：点/线做反向补偿，放大后不再跟着变粗变大
  final String? spotlight; // 搜索定位态：此穴闪烁高亮，其余灰掉

  _ChartPainter({
    required this.view,
    required this.filter,
    required this.selected,
    required this.phase,
    required this.pointMeta,
    this.scale = 1,
    this.spotlight,
  });

  static const red = Color(0xFFB03A2E);
  static const vermilion = Color(0xFFE34234); // 奇经八脉专用朱砂红
  static const goldDot = Color(0xFFD9AE62);
  static const _extraVessels = {
    'RN', 'DU', 'CHONG', 'DAI', 'YINQIAO', 'YANGQIAO', 'YINWEI', 'YANGWEI'
  };

  /// Catmull-Rom 样条转三次贝塞尔：经络点投影折线 → 圆滑循行曲线
  Path _smooth(List<Offset> pts) {
    if (pts.length < 3) {
      final p = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        p.lineTo(pts[i].dx, pts[i].dy);
      }
      return p;
    }
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = i == 0 ? pts[0] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : p2;
      p.cubicTo(
          p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6,
          p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6,
          p2.dx, p2.dy);
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final v = view;
    if (v == null) return;
    final aspect = (v['aspect'] as num).toDouble();
    final layout = _layout(size, aspect);

    Offset map(dynamic x, dynamic y) => Offset(
        layout.offX + (x as num).toDouble() * layout.bodyH,
        layout.offY + (y as num).toDouble() * layout.bodyH);

    // 身体轮廓：暗面填充 + 金色发丝边
    final outline = (v['outline'] as List).cast<dynamic>();
    if (outline.isNotEmpty) {
      final path = Path();
      for (var i = 0; i < outline.length; i++) {
        final pt = map(outline[i][0], outline[i][1]);
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      path.close();
      canvas.drawPath(
          path,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A3646), Color(0xFF1A2430)],
            ).createShader(Rect.fromLTWH(
                layout.offX, layout.offY, layout.bodyH * aspect, layout.bodyH)));
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = LingShuColors.gold.withValues(alpha: 0.35));
    }

    // 红色经络线：细线 + 样条平滑（选定经络加亮，其余半透明；定位态下再压一档）
    // 奇经八脉为朱砂红且第二遍再画：冲带跷维六脉与十二正经高度重叠（共享交会穴），
    // 同色同层时完全被盖住，肉眼只见任督两条正中线
    final lw = (1.5 / scale).clamp(0.55, 2.0);
    final lineDimBase = spotlight == null ? 0.15 : 0.06;
    final lines = (v['lines'] as List).cast<Map<String, dynamic>>();
    for (final isExtra in [false, true]) {
      for (final line in lines) {
        final m = line['m'] as String;
        if (_extraVessels.contains(m) != isExtra) continue;
        final emphasized = filter == m;
        final alpha = (filter == 'ALL' || filter == 'COMMON' || emphasized)
            ? (emphasized ? 1.0 : (spotlight == null ? 0.55 : 0.30))
            : lineDimBase;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = emphasized ? lw + 0.6 : lw
          ..color = (isExtra ? vermilion : red).withValues(alpha: alpha);
        for (final run
            in (line['runs'] as List).cast<List<dynamic>>()) {
          final pts = [
            for (var i = 0; i < run.length; i++)
              map(run[i][0], run[i][1]),
          ];
          canvas.drawPath(_smooth(pts), paint);
        }
      }
    }

    // 金色穴位点 + 选中态（半径随缩放反向补偿：放大时点距拉开而点不长大）
    // 定位态：目标穴闪烁高亮 + 名牌，其余穴位变暗灰点
    final dot = (2.5 / scale).clamp(0.9, 2.5);
    final vis = _visible(v);
    for (final p in vis) {
      final c = map(p['x'], p['y']);
      final isSpot = spotlight != null && spotlight == p['c'];
      final isSel = selected == p['c'];
      if (isSpot) {
        _spotlightDot(canvas, c, dot, scale);
        continue;
      }
      if (spotlight != null) {
        canvas.drawCircle(
            c,
            dot * 0.9,
            Paint()
              ..color = const Color(0xFF93A0AC).withValues(alpha: 0.28));
        continue;
      }
      if (isSel) {
        final glowR = 11 + 4 * math.sin(phase * 2 * math.pi);
        canvas.drawCircle(
            c,
            glowR,
            Paint()
              ..color = goldDot.withValues(alpha: 0.18)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(
            c,
            7,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = goldDot.withValues(alpha: 0.95));
        canvas.drawCircle(c, 3.0, Paint()..color = goldDot);
        _tag(canvas, c, _nameOf(p['c'] as String));
        continue;
      }
      canvas.drawCircle(
          c + const Offset(0.5, 0.8),
          dot,
          Paint()
            ..color = const Color(0xFF060B12).withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2));
      canvas.drawCircle(c, dot, Paint()..color = goldDot);
    }

    // 定位态目标穴被筛选器隐藏时，单独补画（保证任何筛选下都能看到搜索结果）
    if (spotlight != null && !vis.any((p) => p['c'] == spotlight)) {
      final pts = (v['points'] as List).cast<Map<String, dynamic>>();
      for (final p in pts) {
        if (p['c'] != spotlight) continue;
        _spotlightDot(canvas, map(p['x'], p['y']), dot, scale);
        break;
      }
    }
  }

  /// 定位态目标穴：大号呼吸光圈 + 金点 + 名牌（比普通选中更醒目）
  void _spotlightDot(Canvas canvas, Offset c, double dot, double scale) {
    final pulse = 0.5 + 0.5 * math.sin(phase * 2 * math.pi);
    final glowR = 14 + 7 * pulse;
    canvas.drawCircle(
        c,
        glowR,
        Paint()
          ..color = goldDot.withValues(
              alpha: 0.10 + 0.16 * (1 - pulse))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawCircle(
        c,
        9 + 2 * pulse,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (1.8 / scale).clamp(0.8, 2.2)
          ..color = goldDot.withValues(alpha: 0.55 + 0.4 * pulse));
    canvas.drawCircle(
        c + const Offset(0.5, 0.8),
        dot * 1.5,
        Paint()
          ..color = const Color(0xFF060B12).withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
    canvas.drawCircle(c, dot * 1.5, Paint()..color = goldDot);
    _tag(canvas, c, _nameOf(spotlight!));
  }

  List<Map<String, dynamic>> _visible(Map<String, dynamic> v) {
    final pts = (v['points'] as List).cast<Map<String, dynamic>>();
    if (filter == 'ALL') return pts;
    if (filter == 'COMMON') {
      return pts.where((p) => pointMeta[p['c']]?.common ?? true).toList();
    }
    return pts.where((p) => pointMeta[p['c']]?.meridian == filter).toList();
  }

  String _nameOf(String code) => pointMeta[code]?.name ?? code;

  void _tag(Canvas canvas, Offset at, String name) {
    final tp = TextPainter(
      text: const TextSpan(),
      textDirection: TextDirection.ltr,
    );
    tp.text = TextSpan(
        text: name,
        style: const TextStyle(
            fontFamily: 'SerifSC',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: Color(0xFFF2E6C9)));
    tp.layout();
    final p = at + const Offset(12, -30);
    final r = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: p + Offset(tp.width / 2, tp.height / 2),
            width: tp.width + 14,
            height: tp.height + 8),
        const Radius.circular(6));
    canvas.drawRRect(r, Paint()..color = const Color(0xFF0D131C).withValues(alpha: 0.78));
    canvas.drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = LingShuColors.gold.withValues(alpha: 0.5));
    tp.paint(canvas, p);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.view != view ||
      old.filter != filter ||
      old.selected != selected ||
      old.phase != phase ||
      old.scale != scale ||
      old.spotlight != spotlight;
}
