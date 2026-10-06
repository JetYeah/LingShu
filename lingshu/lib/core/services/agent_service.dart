import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/painting.dart'
    show FontWeight, TextPainter, TextSpan, TextStyle;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../db.dart';
import '../theme.dart';
import 'ocr_service.dart';

/// 智能体回复：文本 + 可选的趋势图 PNG
class AgentReply {
  final String text;
  final Uint8List? chart;
  final String? chartTitle;
  AgentReply({required this.text, this.chart, this.chartTitle});
}

/// 单张归档结果（供汇总文案）
class _ArchiveResult {
  final String title;
  final int metricCount;
  final bool dup;
  final String? error;
  _ArchiveResult(this.title, this.metricCount, {this.dup = false, this.error});
}

/// 灵枢 AI 管家：一个入口按意图自动分派到传统能力。
/// - 归档：无头复用「拍照归档」的识别与入库管线（OcrService.extract + 指标落库）
/// - 问询：查本地指标库并出统计 + 趋势图（Canvas 离屏渲染，不依赖 widget 树）
/// - 其余（养生咨询/看图答疑/闲聊）：直接由大模型作答
class AgentService {
  final OcrService ocr; // 复用 AI 识别配置（base_url / key / model）
  AgentService({required this.ocr});

  // 与 pages/records/records_page.dart 的 recordTypes 保持一致
  static const _recordTypes = ['病历', '检验报告', '影像报告', '处方', '体检报告', '其他'];

  /// 处理一次用户输入（文本 + 可选多张病历照片），返回回复与可选趋势图
  Future<AgentReply> handle({
    required AppDatabase db,
    required int profileId,
    String? message,
    List<String> imagePaths = const [],
    List<String> metricNames = const [],
  }) async {
    if (ocr.apiKey.isEmpty) {
      throw Exception('请先到「我的 → 设置」配置 AI 识别的 API Key');
    }

    final routing = await _route(message ?? '', imagePaths, metricNames);
    switch (routing.action?['name']) {
      case 'import_records':
        if (imagePaths.isEmpty) {
          return AgentReply(
              text:
                  '${routing.reply}\n\n（还没有收到图片：点输入框左侧的 ⊕ 选择病历照片后再发一次）');
        }
        final summary = await _archiveAll(db, profileId, imagePaths);
        return AgentReply(text: '${routing.reply}\n\n$summary');
      case 'query_metrics':
        final args = routing.action?['args'];
        final name = args is Map ? (args['metric']?.toString() ?? '') : '';
        var days = 7;
        if (args is Map) days = int.tryParse(args['days']?.toString() ?? '') ?? 7;
        if (days <= 0 || days > 365) days = 7;
        return _queryMetric(db, profileId, name, days, lead: routing.reply);
      default:
        return AgentReply(text: routing.reply);
    }
  }

  // ── 意图路由：一次视觉对话调用，模型只回 JSON ──

  Future<({String reply, Map<String, dynamic>? action})> _route(
      String message, List<String> imagePaths, List<String> metricNames) async {
    final parts = <Map<String, dynamic>>[
      {'type': 'text', 'text': _routingPrompt(metricNames, message)},
    ];
    for (final path in imagePaths.take(6)) {
      final bytes = await _compress(await File(path).readAsBytes());
      parts.add({
        'type': 'image_url',
        'image_url': {'url': 'data:image/jpeg;base64,${base64Encode(bytes)}'},
      });
    }
    final resp = await http.post(
      Uri.parse('${ocr.baseUrl}/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ocr.apiKey}',
      },
      body: jsonEncode({
        'model': ocr.model,
        'messages': [
          {'role': 'user', 'content': parts},
        ],
        'temperature': 0.3,
      }),
    ).timeout(const Duration(seconds: 90));
    if (resp.statusCode != 200) {
      throw Exception('接口返回 ${resp.statusCode}: ${resp.body}');
    }
    final body = jsonDecode(utf8.decode(resp.bodyBytes));
    final raw = body['choices']?[0]?['message']?['content']?.toString() ?? '';
    final txt =
        raw.replaceAll('```json', '').replaceAll('```', '').trim();
    final s = txt.indexOf('{');
    final e = txt.lastIndexOf('}');
    if (s < 0 || e <= s) {
      throw const FormatException('AI 返回内容无法解析');
    }
    final j = jsonDecode(txt.substring(s, e + 1)) as Map<String, dynamic>;
    var reply = (j['reply'] ?? '').toString().trim();
    if (reply.isEmpty) reply = '好的。';
    final action =
        j['action'] is Map<String, dynamic> ? j['action'] as Map<String, dynamic> : null;
    return (reply: reply, action: action);
  }

  String _routingPrompt(List<String> metricNames, String message) {
    final metrics = metricNames.isEmpty ? '（暂无）' : metricNames.join('、');
    return '你是「灵枢」健康管家，面向一位中国个人/家庭用户，语气亲切、回复简体中文。'
        '用户已有的健康指标：$metrics\n'
        '用户这次的消息：「$message」，可能附带照片（见本条消息的图片部分）。\n'
        '请只输出一个 JSON 对象，不要任何其他文字、不要 markdown 围栏：\n'
        '{"reply": "给用户的回复，先直接回应诉求", "action": null}\n'
        'action 规则（三选一）：\n'
        '1. 照片是病历/检验报告/检查单等医疗文书，且用户想存档（说"归档/存一下/记录这张/帮我入档"等）→ '
        '{"name": "import_records"}，reply 简短说明正在归档即可。\n'
        '2. 用户想查看自己的健康指标数据或趋势（如"看看最近血糖""最近血压怎么样"）→ '
        '{"name": "query_metrics", "args": {"metric": "从用户已有指标里选最接近的名字", "days": 天数(默认7)}}。\n'
        '3. 其他情况（养生咨询、就照片内容提问、闲聊、急救常识等）→ action 为 null，直接在 reply 回答；'
        '涉及诊疗判断只给常识性建议并提醒就医，急救场景提醒拨打 120。\n'
        '注意：只有同时满足「确实附了医疗文书照片」和「用户表达归档意图」才选 1；只是问照片内容时选 3。';
  }

  Future<Uint8List> _compress(Uint8List raw) async {
    final decoded = img.decodeImage(raw);
    if (decoded == null) return raw;
    final c = decoded.width > 1600 ? img.copyResize(decoded, width: 1600) : decoded;
    return Uint8List.fromList(img.encodeJpg(c, quality: 85));
  }

  // ── 病历归档：无头复用「拍照归档」管线 ──

  Future<String> _archiveAll(
      AppDatabase db, int profileId, List<String> imagePaths) async {
    final results = <_ArchiveResult>[];
    for (final path in imagePaths.take(9)) {
      results.add(await _archiveOne(db, profileId, path));
    }
    final lines = <String>[];
    for (final r in results) {
      if (r.error != null) {
        lines.add('✕ 《${r.title}》归档失败：${r.error}');
      } else if (r.dup) {
        lines.add('↺ 《${r.title}》与已归档内容相同，已跳过');
      } else {
        lines.add('✓ 《${r.title}》已归档${r.metricCount > 0 ? '，并录入 ${r.metricCount} 项指标' : ''}');
      }
    }
    final ok = results.where((r) => r.error == null && !r.dup).length;
    return '归档完成：成功 $ok 张 / 共 ${results.length} 张\n${lines.join('\n')}\n'
        '可在「档案」页查看与修改。';
  }

  Future<_ArchiveResult> _archiveOne(
      AppDatabase db, int profileId, String path) async {
    try {
      final raw = await File(path).readAsBytes();
      // 内容级去重（与拍照归档一致：按原件字节哈希）
      final hash = md5.convert(raw).toString();
      final dup = await (db.select(db.medicalRecords)
            ..where((t) =>
                t.profileId.equals(profileId) & t.fileHash.equals(hash)))
          .getSingleOrNull();
      if (dup != null) return _ArchiveResult(dup.title, 0, dup: true);

      final r = await ocr.extract(await _compress(raw));

      // 原件拷贝到应用目录
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'records'));
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final ext = p.extension(path).isEmpty ? '.jpg' : p.extension(path);
      final stored = p.join(dir.path, '${const Uuid().v4()}$ext');
      await File(path).copy(stored);

      final type = _recordTypes.contains(r.docType) ? r.docType! : '其他';
      final date = r.recordDate ?? DateTime.now();
      final qualitative = [
        for (final m in r.metrics)
          if (m.value == null && m.textValue != null) '${m.name}：${m.textValue}',
      ];
      final note = [
        'AI 助手归档',
        if (qualitative.isNotEmpty) '定性结果：${qualitative.join('；')}',
      ].join('\n');
      final title = (r.title?.isNotEmpty == true)
          ? r.title!
          : '$type ${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

      await db.into(db.medicalRecords).insert(
            MedicalRecordsCompanion.insert(
              profileId: profileId,
              title: title,
              type: type,
              recordDate: date,
              hospital: Value(r.hospital),
              department: Value(r.department),
              note: Value(note),
              filePath: stored,
              fileType: 'image',
              fileHash: Value(hash),
              aiSummary: Value(r.summary),
            ),
          );

      var n = 0;
      for (final m in r.metrics) {
        if (m.value == null) continue;
        try {
          if (await _saveMetric(db, profileId, m, date)) n++;
        } catch (_) {
          // 单项指标失败不阻断整张归档
        }
      }
      return _ArchiveResult(title, n);
    } catch (e) {
      return _ArchiveResult(p.basename(path), 0, error: '$e');
    }
  }

  /// 指标入库：同名/包含匹配已有指标，否则新建；同日同值去重。
  /// 与拍照归档页 _saveMetric 同一套规则。
  Future<bool> _saveMetric(
      AppDatabase db, int profileId, OcrMetric m, DateTime recordDate) async {
    final isBp = m.value2 != null ||
        m.name.contains('收缩') ||
        m.name.contains('高压') ||
        m.name.toLowerCase() == 'bp';
    Metric? metric;
    final exact = await (db.select(db.metrics)
          ..where((t) => t.profileId.equals(profileId) & t.name.equals(m.name)))
        .get();
    if (exact.isNotEmpty) {
      metric = exact.first;
    } else {
      final like = await (db.select(db.metrics)
            ..where((t) =>
                t.profileId.equals(profileId) & t.name.like('%${m.name}%')))
          .get();
      if (like.isNotEmpty) {
        metric = like.reduce((a, b) => a.name.length <= b.name.length ? a : b);
      }
    }
    if (metric != null) {
      if ((metric.tag == null || metric.tag!.isEmpty) &&
          (m.category?.isNotEmpty == true)) {
        await (db.update(db.metrics)..where((t) => t.id.equals(metric!.id)))
            .write(MetricsCompanion(tag: Value(m.category)));
      }
    } else {
      // 新建指标随路径种入指南参考限：血压收缩 90~139/舒张 60~89，
      // 血糖（餐前口径）3.9~6.1——趋势图与异常判定即时有据
      final isSugar = m.name.contains('血糖');
      metric = await db.into(db.metrics).insertReturning(
            MetricsCompanion.insert(
              profileId: profileId,
              code: isBp ? 'blood_pressure' : 'custom',
              name: m.name,
              unit: m.unit ?? '',
              dualValue: Value(isBp),
              tag: Value(
                  (m.category?.isNotEmpty == true) ? m.category : null),
              refLow: Value(isBp ? 60.0 : (isSugar ? 3.9 : null)),
              refHigh: Value(isBp ? 89.0 : (isSugar ? 6.1 : null)),
              refLow2: Value(isBp ? 90.0 : null),
              refHigh2: Value(isBp ? 139.0 : null),
            ),
          );
    }
    final metricId = metric.id; // 闭包内不做空提升，先取局部
    final dayStart =
        DateTime(recordDate.year, recordDate.month, recordDate.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final dup = await (db.select(db.metricValues)
          ..where((t) =>
              t.metricId.equals(metricId) &
              t.measuredAt.isBiggerOrEqualValue(dayStart) &
              t.measuredAt.isSmallerThanValue(dayEnd) &
              t.value1.equals(m.value!) &
              (m.value2 == null
                  ? t.value2.isNull()
                  : t.value2.equals(m.value2!))))
        .get();
    if (dup.isNotEmpty) return false;
    await db.into(db.metricValues).insert(MetricValuesCompanion.insert(
          metricId: metricId,
          value1: m.value!,
          value2: Value(m.value2),
          measuredAt: recordDate,
          source: const Value('ai'),
        ));
    return true;
  }

  // ── 指标问询：模糊匹配 + 统计 + 趋势图 ──

  Metric? _fuzzyMetric(List<Metric> metrics, String q) {
    if (q.isEmpty) return null;
    for (final m in metrics) {
      if (m.name == q) return m;
    }
    final hit = metrics
        .where((m) => m.name.contains(q) || q.contains(m.name))
        .toList();
    if (hit.isNotEmpty) {
      return hit.reduce((a, b) => a.name.length <= b.name.length ? a : b);
    }
    return null;
  }

  Future<AgentReply> _queryMetric(AppDatabase db, int profileId, String name,
      int days, {required String lead}) async {
    final metrics = await (db.select(db.metrics)
          ..where((t) => t.profileId.equals(profileId)))
        .get();
    final metric = _fuzzyMetric(metrics, name);
    if (metric == null) {
      final have = metrics.map((m) => m.name).toList();
      return AgentReply(
          text: '$lead\n\n没有找到「$name」相关的指标记录。'
              '${have.isEmpty ? '你还没有记录过指标，可以先在「用药提醒 → 日常记录」量一次血压/血糖，或把检验报告照片发给我归档。' : '目前已记录的指标有：${have.join('、')}。'}');
    }

    final cutoff = DateTime.now().subtract(Duration(days: days));
    var values = await (db.select(db.metricValues)
          ..where((t) =>
              t.metricId.equals(metric.id) &
              t.measuredAt.isBiggerOrEqualValue(cutoff))
          ..orderBy([(t) => OrderingTerm.asc(t.measuredAt)]))
        .get();
    var windowNote = '';
    if (values.isEmpty) {
      // 窗口内没数据：退回最近 15 条，避免"查无数据"的空回复
      values = await (db.select(db.metricValues)
            ..where((t) => t.metricId.equals(metric.id))
            ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)])
            ..limit(15))
          .get();
      if (values.isEmpty) {
        return AgentReply(
            text: '$lead\n\n「${metric.name}」还没有任何记录。'
                '可在「用药提醒 → 日常记录」快捷录入，或把检验报告照片发给我归档。');
      }
      values.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
      windowNote = '\n（最近 $days 天内没有记录，以下为最近 ${values.length} 条）';
    }

    String fmt(double d) =>
        d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toStringAsFixed(1);
    final v1s = values.map((v) => v.value1).toList();
    final latest = values.last;
    final avg = v1s.reduce((a, b) => a + b) / v1s.length;

    bool out(MetricValue v) {
      if (metric.dualValue) {
        return (metric.refHigh2 != null && v.value1 > metric.refHigh2!) ||
            (metric.refLow2 != null && v.value1 < metric.refLow2!) ||
            (metric.refHigh != null && (v.value2 ?? 0) > metric.refHigh!);
      }
      return (metric.refHigh != null && v.value1 > metric.refHigh!) ||
          (metric.refLow != null && v.value1 < metric.refLow!);
    }

    final outCount = values.where(out).length;
    final latestDate =
        '${latest.measuredAt.month.toString().padLeft(2, '0')}-${latest.measuredAt.day.toString().padLeft(2, '0')}'
        '${latest.timeLabel != null ? ' ${latest.timeLabel}' : ''}';
    final lines = <String>[
      lead,
      '「${metric.name} · 最近 $days 天」共 ${values.length} 条',
      if (metric.dualValue)
        '最新 ${fmt(latest.value1)}/${fmt(latest.value2 ?? 0)} ${metric.unit}（$latestDate）'
            ' · 收缩压平均 ${fmt(avg)} · 舒张压平均 ${fmt(values.map((v) => v.value2 ?? 0).reduce((a, b) => a + b) / values.length)}'
      else
        '最新 ${fmt(latest.value1)} ${metric.unit}（$latestDate）'
            ' · 平均 ${fmt(avg)} · 最低 ${fmt(v1s.reduce((a, b) => a < b ? a : b))} · 最高 ${fmt(v1s.reduce((a, b) => a > b ? a : b))}',
      if (metric.dualValue && (metric.refLow2 != null || metric.refHigh != null))
        '参考：收缩压 ${metric.refLow2 ?? '—'}~${metric.refHigh2 ?? '—'} · 舒张压 ${metric.refLow ?? '—'}~${metric.refHigh ?? '—'} mmHg · 超出 $outCount 条'
      else if (!metric.dualValue && (metric.refLow != null || metric.refHigh != null))
        '参考区间 ${metric.refLow ?? '—'}~${metric.refHigh ?? '—'} ${metric.unit} · 超出 $outCount 条',
      if (windowNote.isNotEmpty) windowNote.trim(),
    ];

    final chart = await renderTrendChart(
      title: '${metric.name} · 最近 $days 天',
      unit: metric.unit,
      points: [for (final v in values) (v.measuredAt, v.value1)],
      refLow: metric.dualValue ? metric.refLow2 : metric.refLow,
      refHigh: metric.dualValue ? metric.refHigh2 : metric.refHigh,
    );
    return AgentReply(
      text: lines.where((l) => l.isNotEmpty).join('\n'),
      chart: chart,
      chartTitle: '${metric.name}趋势',
    );
  }
}

// ── 趋势图离屏渲染：dart:ui Canvas 直绘，不需要 widget 树 ──

Future<Uint8List?> renderTrendChart({
  required String title,
  required String unit,
  required List<(DateTime, double)> points,
  double? refLow,
  double? refHigh,
}) async {
  if (points.isEmpty) return null;
  const w = 680.0, h = 360.0;
  const left = 76.0, right = 30.0, top = 84.0, bottom = 58.0;
  const dpr = 2.0; // 输出 2x 像素保证清晰：画布先 scale，再按逻辑坐标绘制
  final recorder = ui.PictureRecorder();
  final c = ui.Canvas(recorder)
    ..scale(dpr, dpr)
    ..drawRect(const ui.Rect.fromLTWH(0, 0, w, h),
        ui.Paint()..color = const ui.Color(0xFFFFFFFF));

  TextPainter tp(String s, double size,
          {ui.Color color = LingShuColors.ink, bool bold = false}) =>
      TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            color: color,
            fontSize: size,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            fontFamily: 'SerifSC',
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

  // 标题
  final titleTp = tp(title, 26, bold: true);
  titleTp.paint(c, const ui.Offset(left - 8, 26));
  final subTp = tp('共 ${points.length} 条 · 单位 $unit', 16,
      color: LingShuColors.inkSoft);
  subTp.paint(c, ui.Offset(left - 8, 26 + 34));

  // y 值域
  final ys = points.map((e) => e.$2).toList()
    ..addAll([?refHigh, ?refLow]);
  var minY = ys.reduce((a, b) => a < b ? a : b);
  var maxY = ys.reduce((a, b) => a > b ? a : b);
  final padY = (maxY - minY) * 0.15 + 0.5;
  minY -= padY;
  maxY += padY;
  final plotW = w - left - right, plotH = h - top - bottom;
  double dx(int i) =>
      left + (points.length == 1 ? plotW / 2 : i * plotW / (points.length - 1));
  double dy(double v) => top + (maxY - v) / (maxY - minY) * plotH;

  // 网格 + y 轴标签（4 段，取整显示）
  final grid = ui.Paint()
    ..color = LingShuColors.cardBorder
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1;
  for (var i = 0; i <= 4; i++) {
    final y = top + plotH * i / 4;
    final v = maxY - (maxY - minY) * i / 4;
    c.drawLine(ui.Offset(left, y), ui.Offset(w - right, y), grid);
    tp(v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1), 15,
            color: LingShuColors.inkSoft)
        .paint(c, ui.Offset(left - 66, y - 10));
  }

  // 参考区间带（有上下限时填充）
  if (refLow != null && refHigh != null) {
    final band = ui.Rect.fromLTRB(left, dy(refHigh), w - right, dy(refLow));
    c.drawRect(band, ui.Paint()..color = WuXing.wood.withValues(alpha: 0.10));
    tp('参考区间', 14, color: WuXing.wood.withValues(alpha: 0.9))
        .paint(c, ui.Offset(w - right - 60, dy(refHigh) - 20));
  }

  // 折线 + 点
  final linePath = ui.Path();
  for (var i = 0; i < points.length; i++) {
    final o = ui.Offset(dx(i), dy(points[i].$2));
    if (i == 0) {
      linePath.moveTo(o.dx, o.dy);
    } else {
      linePath.lineTo(o.dx, o.dy);
    }
  }
  c.drawPath(
      linePath,
      ui.Paint()
        ..color = WuXing.wood
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = ui.StrokeCap.round
        ..strokeJoin = ui.StrokeJoin.round);
  final dotFill = ui.Paint()..color = WuXing.wood;
  final dotStroke = ui.Paint()
    ..color = const ui.Color(0xFFFFFFFF)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 3;
  for (var i = 0; i < points.length; i++) {
    final o = ui.Offset(dx(i), dy(points[i].$2));
    c.drawCircle(o, 6, dotStroke);
    c.drawCircle(o, 4.5, dotFill);
  }
  // 末点数值
  final lastV = points.last.$2;
  final lastLabel = tp(
      lastV == lastV.roundToDouble()
          ? lastV.toStringAsFixed(0)
          : lastV.toStringAsFixed(1),
      20,
      bold: true,
      color: WuXing.wood);
  final lx = (dx(points.length - 1) + 10 + lastLabel.width)
          .clamp(0.0, w - right) -
      lastLabel.width;
  lastLabel.paint(c, ui.Offset(lx, dy(lastV) - 26));

  // x 轴日期（首/中/尾）
  String d2(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  final idxSet = <int>{
    0,
    (points.length - 1) ~/ 2,
    points.length - 1,
  };
  for (final i in idxSet) {
    final t = tp(d2(points[i].$1), 15, color: LingShuColors.inkSoft);
    t.paint(c, ui.Offset(dx(i).clamp(left, w - right) - t.width / 2, h - bottom + 14));
  }

  final image = await recorder
      .endRecording()
      .toImage((w * dpr).round(), (h * dpr).round());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data?.buffer.asUint8List();
}
