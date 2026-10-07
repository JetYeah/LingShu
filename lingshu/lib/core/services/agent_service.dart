import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/painting.dart'
    show FontWeight, TextPainter, TextSpan, TextStyle;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:lunar/lunar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../db.dart';
import '../theme.dart';
import 'agent_capabilities.dart';
import 'asr_service.dart' show parseVitalsFromSpeech;
import 'content_loader.dart';
import 'herb_repo.dart';
import 'notification_service.dart';
import 'ocr_service.dart';

/// 智能体回复：文本 + 可选的趋势图 PNG / 能力点选列表 / 页面跳转入口
class AgentReply {
  final String text;
  final Uint8List? chart;
  final String? chartTitle;
  final List<AgentCapability> capabilities; //「你能做什么」点选列表
  final String? route; // 可跳转的 app 内页面（白名单路径）
  final String? routeLabel;
  AgentReply({
    required this.text,
    this.chart,
    this.chartTitle,
    this.capabilities = const [],
    this.route,
    this.routeLabel,
  });
}

/// 单张归档结果（供汇总文案）
class _ArchiveResult {
  final String title;
  final int metricCount;
  final bool dup;
  final String? error;
  _ArchiveResult(this.title, this.metricCount, {this.dup = false, this.error});
}

/// 本地兜底路由（纯函数，供单测）：固定短语 → (action, args)。
/// 命中则跳过大模型直接执行；返回 null 交给模型路由。
/// 只收高置信短语——宁可漏给模型，不可错分派。
(String, Map<String, dynamic>)? localActionFor(
    String msg, Map<String, (String, String)> pages) {
  final t = msg.trim();
  if (t.isEmpty || t.length > 30) return null;
  if (RegExp('健康概览|健康汇总|整体(情况|状况)|身体(怎么样|总览)|健康(报告|总结)')
      .hasMatch(t)) {
    return ('health_summary', const {});
  }
  if (RegExp('在用(药|的药|药物)|吃了?哪些药|用药(清单|列表|安排)|药物清单|用(什么|哪些)药')
      .hasMatch(t)) {
    return ('list_medications', const {});
  }
  if (t.contains('药箱')) {
    return ('box_status', const {});
  }
  if (RegExp('(今天|今日|现在)(是)?(的)?(什么|啥|哪个)?(节气|时令)|节气养生')
      .hasMatch(t)) {
    return ('solar_term', const {});
  }
  if (RegExp('(我的)?体质(怎么样|如何|结果|辨识)?|怎么调养|调养(建议)?')
      .hasMatch(t)) {
    return ('constitution_query', const {});
  }
  if (RegExp('^(打开|进入|去|看看)').hasMatch(t)) {
    const alias = <String, List<String>>{
      'home': ['铜人', '经络', '首页'],
      'records': ['档案', '病历', '报告'],
      'import': ['拍照', '归档'],
      'metrics': ['指标', '追踪', '健康'],
      'firstaid': ['急救'],
      'profile': ['我的', '个人'],
      'medications': ['用药', '服药', '药物'],
      'family': ['成员', '家庭'],
      'constitution': ['体质'],
      'box': ['药箱'],
      'backup': ['备份', '恢复'],
      'settings': ['设置'],
    };
    for (final e in pages.entries) {
      final names = alias[e.key];
      if (names != null && names.any(t.contains)) {
        return ('navigate', {'page': e.key});
      }
    }
  }
  return null;
}

/// 中药库共享单例：AgentService 每次会话新建，879 味 JSON 只解析一次
final _sharedHerbRepo = HerbRepo();

/// 灵枢 AI 管家：一个入口按意图自动分派到 app 的全部能力。
/// - 归档 import_records：无头复用「拍照归档」的识别与入库管线
/// - 问询 query_metrics：查本地指标库并出统计 + 趋势图（Canvas 离屏渲染）
/// - 记录 record_metric：口述/文字报数落库（血压/心率/血糖/体重…）
/// - 用药 list/add/stop_medications：在用药物查询与提醒增停（含本地通知）
/// - 档案 query_records / 概览 health_summary / 体质 constitution_query / 药箱 box_status
/// - 百科 firstaid / herb_lookup / acupoint_lookup / solar_term：本地权威数据优先
/// - 其余（养生咨询/看图答疑/闲聊）：直接由大模型作答
class AgentService {
  final OcrService ocr; // 复用 AI 识别配置（base_url / key / model）
  final NotificationService? notifications; // null（单测）时跳过通知排期
  final ContentRepo content; // 经穴/急救/体质/节气静态内容
  final HerbRepo herbs; // 中药图鉴
  AgentService({
    required this.ocr,
    this.notifications,
    ContentRepo? content,
    HerbRepo? herbs,
  })  : content = content ?? ContentRepo(),
        herbs = herbs ?? _sharedHerbRepo;

  // 与 pages/records/records_page.dart 的 recordTypes 保持一致
  static const _recordTypes = ['病历', '检验报告', '影像报告', '处方', '体检报告', '其他'];

  // navigate 动作允许打开的页面白名单：key → (路由, 名称)
  static const pageTable = <String, (String, String)>{
    'home': ('/home', '经穴铜人'),
    'records': ('/records', '健康档案'),
    'import': ('/records/import', '拍照归档'),
    'metrics': ('/metrics', '健康追踪'),
    'firstaid': ('/firstaid', '急救指南'),
    'profile': ('/profile', '我的'),
    'medications': ('/medications', '用药提醒'),
    'family': ('/family', '家庭成员'),
    'constitution': ('/constitution', '体质辨识'),
    'box': ('/box', '家庭药箱'),
    'backup': ('/backup', '备份与恢复'),
    'settings': ('/settings', '设置'),
  };

  /// 处理一次用户输入（文本 + 可选多张病历照片），返回回复与可选趋势图
  Future<AgentReply> handle({
    required AppDatabase db,
    required int profileId,
    String? message,
    List<String> imagePaths = const [],
    List<String> metricNames = const [],
  }) async {
    final msg = message ?? '';
    // 「你能做什么」本地直答：不请求模型，未配置 Key 也能发现能力
    if (imagePaths.isEmpty && isCapabilityQuestion(msg)) {
      return AgentReply(
        text: '我是灵枢 AI 健康管家，健康事务一句话直达。这些事都可以交给我，点一项直接开始：',
        capabilities: capabilityCatalog,
      );
    }
    if (ocr.apiKey.isEmpty) {
      throw Exception('请先到「我的 → 设置」配置 AI 识别的 API Key');
    }

    // 本地高置信兜底路由：固定短语直接分派，不依赖模型（弱模型遵从不稳、
    // 且省一次往返）。只兜名词性、无歧义的指令；其余仍交给模型路由。
    final local = _localAction(msg);
    if (imagePaths.isEmpty && local != null) {
      return runAction(
        db: db,
        profileId: profileId,
        action: local.$1,
        args: local.$2,
        lead: '好的，这就为您整理。',
        message: msg,
      );
    }

    final routing = await _route(msg, imagePaths, metricNames);
    final action = routing.action;
    final name = action?['name']?.toString() ?? '';
    if (action == null || name.isEmpty) {
      return AgentReply(text: routing.reply);
    }
    return runAction(
      db: db,
      profileId: profileId,
      action: name,
      args: action['args'] is Map
          ? Map<String, dynamic>.from(action['args'] as Map)
          : const {},
      lead: routing.reply,
      message: msg,
      imagePaths: imagePaths,
    );
  }

  /// 执行一个本地动作（handle 分派；单测直调）
  Future<AgentReply> runAction({
    required AppDatabase db,
    required int profileId,
    required String action,
    Map<String, dynamic> args = const {},
    String lead = '',
    String message = '',
    List<String> imagePaths = const [],
  }) async {
    switch (action) {
      case 'import_records':
        if (imagePaths.isEmpty) {
          return AgentReply(
              text:
                  '$lead\n\n（还没有收到图片：点输入框左侧的 ⊕ 选择病历照片后再发一次）');
        }
        final summary = await _archiveAll(db, profileId, imagePaths);
        return AgentReply(text: '$lead\n\n$summary');
      case 'query_metrics':
        final name = args['metric']?.toString() ?? '';
        var days = 7;
        days = int.tryParse(args['days']?.toString() ?? '') ?? 7;
        if (days <= 0 || days > 365) days = 7;
        return _queryMetric(db, profileId, name, days, lead: lead);
      case 'record_metric':
        return _recordMetric(db, profileId, args, message, lead);
      case 'list_medications':
        return _listMedications(db, profileId, lead);
      case 'add_medication':
        return _addMedication(db, profileId, args, lead);
      case 'stop_medication':
        return _stopMedication(db, profileId, args, lead);
      case 'query_records':
        return _queryRecords(db, profileId, args, lead);
      case 'health_summary':
        return _healthSummary(db, profileId, lead);
      case 'constitution_query':
        return _constitutionQuery(db, profileId, lead);
      case 'box_status':
        return _boxStatus(db, profileId, lead);
      case 'firstaid':
        return _firstAid(args, message, lead);
      case 'herb_lookup':
        return _herbLookup(args, message, lead);
      case 'acupoint_lookup':
        return _acupointLookup(args, message, lead);
      case 'solar_term':
        return _solarTerm(lead);
      case 'navigate':
        return _navigate(args, lead);
      default:
        return AgentReply(text: lead);
    }
  }

  // ── 意图路由：一次视觉对话调用，模型只回 JSON ──

  /// 本地兜底路由：返回 (action, args)，未命中返回 null。
  /// 只收高置信短语——宁可漏给模型，不可错分派。
  (String, Map<String, dynamic>)? _localAction(String msg) =>
      localActionFor(msg, pageTable);

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
        '你能直接操作 app 里的健康数据，也可以回答咨询。\n'
        '用户已有的健康指标：$metrics\n'
        '用户这次的消息：「$message」，可能附带照片（见本条消息的图片部分）。\n'
        '请只输出一个 JSON 对象，不要任何其他文字、不要 markdown 围栏：\n'
        '{"reply": "给用户的一句话回应，先直接回应诉求", "action": null}\n'
        'action 按诉求选一个（拿不准就 null 直接回答）：\n'
        '1 {"name":"import_records"} —— 照片是病历/检验报告等医疗文书，且用户想存档（说"归档/存一下/入档"）。'
        '只是问照片内容时不要选它。\n'
        '2 {"name":"query_metrics","args":{"metric":"从用户已有指标里选最接近的名字","days":7}} —— 查指标数据/趋势（"最近血糖怎么样"）。\n'
        '3 {"name":"record_metric","args":{"metric":"指标名","value":数,"value2":血压舒张压或null,"hr":心率或null,'
        '"date":"YYYY-MM-DD","timeLabel":"空腹/早餐后/早上/晚上等测量时点"}} —— 报测量值想记录'
        '（"记一下血压130/85 心率76""空腹血糖6.8""体重70"）。中文数字换算成阿拉伯数。\n'
        '4 {"name":"list_medications"} —— 查在用药物与服药安排。\n'
        '5 {"name":"add_medication","args":{"name":"药名","dosage":"剂量或null","times":["08:00","20:00"],'
        '"mealRelation":"餐前/餐后/睡前等或null","days":[1,2,3,4,5,6,7]}} —— 建用药提醒（"提醒我每天早晚吃××"）。'
        '口语时间换算成 24 小时制（早≈08:00、午≈12:00、晚≈20:00、睡前≈21:00）。\n'
        '6 {"name":"stop_medication","args":{"name":"药名"}} —— 停用/删除用药提醒。\n'
        '7 {"name":"query_records","args":{"keyword":"关键词或null","type":"病历|检验报告|影像报告|处方|体检报告|null"}} —— 查已归档的病历/报告。\n'
        '8 {"name":"health_summary"} —— 要健康汇总/整体概览。\n'
        '9 {"name":"constitution_query"} —— 查体质结论与调养建议。\n'
        '10 {"name":"box_status"} —— 查家庭药箱/药品到期情况。\n'
        '11 {"name":"firstaid","args":{"query":"场景关键词"}} —— 急救求助（烫伤/噎住/心梗/溺水…）。\n'
        '12 {"name":"herb_lookup","args":{"name":"中药名"}} —— 查某味中药的功效/禁忌。\n'
        '13 {"name":"acupoint_lookup","args":{"name":"穴位名"}} —— 查某穴位的位置/主治。\n'
        '14 {"name":"solar_term"} —— 问今日节气/时令养生。\n'
        '15 {"name":"navigate","args":{"page":"home|records|import|metrics|firstaid|profile|medications|family|constitution|box|backup|settings"}} —— 用户想打开某功能页。\n'
        'action 为 null 时直接在 reply 回答（养生咨询、就照片内容提问、闲聊、问你的能力边界等）；'
        '涉及诊疗判断只给常识性建议并提醒就医；急救场景先提醒拨打 120。\n'
        '注意：只有同时满足「确实附了医疗文书照片」和「用户表达归档意图」才选 1；'
        '查指标（动作 2）必须用用户已有指标名或其别名，用户没有的指标引导先记录。';
  }

  Future<Uint8List> _compress(Uint8List raw) async {
    final decoded = img.decodeImage(raw);
    if (decoded == null) return raw;
    final c = decoded.width > 1600 ? img.copyResize(decoded, width: 1600) : decoded;
    return Uint8List.fromList(img.encodeJpg(c, quality: 85));
  }

  // ── 通用小工具 ──

  double? _num(Object? v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '');

  DateTime? _day(Object? v) {
    final s = v?.toString() ?? '';
    if (s.isEmpty) return null;
    final d = DateTime.tryParse(s);
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  String _d2(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _md(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmt(double d) =>
      d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toStringAsFixed(1);

  String _clip(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…';

  /// 值是否超出指标参考区间（与指标页异常判定同一套规则）
  bool _outOfRange(Metric m, double v1, double? v2) {
    if (m.dualValue) {
      return (m.refHigh2 != null && v1 > m.refHigh2!) ||
          (m.refLow2 != null && v1 < m.refLow2!) ||
          (m.refHigh != null && (v2 ?? 0) > m.refHigh!) ||
          (m.refLow != null && (v2 ?? 0) < m.refLow!);
    }
    return (m.refHigh != null && v1 > m.refHigh!) ||
        (m.refLow != null && v1 < m.refLow!);
  }

  String _flag(Metric m, double v1, double? v2) =>
      (m.refLow == null && m.refHigh == null && m.refLow2 == null && m.refHigh2 == null)
          ? ''
          : (_outOfRange(m, v1, v2) ? ' ⚠️超出参考区间' : ' ✓正常');

  // ── 动作：口述记指标 ──

  /// 按名称找指标，没有则建（新建随路径种入指南参考限）
  Future<Metric> _resolveMetric(AppDatabase db, int profileId, String name,
      {bool? dual, String? unit, String? tag}) async {
    final metrics = await (db.select(db.metrics)
          ..where((t) => t.profileId.equals(profileId)))
        .get();
    final hit = _fuzzyMetric(metrics, name);
    if (hit != null) return hit;
    final isBp = dual == true || name.contains('血压') || name.contains('收缩');
    final isSugar = name.contains('血糖');
    final isHr = name.contains('心率') || name.contains('脉搏');
    return db.into(db.metrics).insertReturning(
          MetricsCompanion.insert(
            profileId: profileId,
            code: isBp ? 'blood_pressure' : (isHr ? 'heart_rate' : 'custom'),
            name: name,
            unit: unit ?? (isHr ? '次/分' : ''),
            dualValue: Value(isBp),
            tag: Value(tag ?? (isHr ? '基础体征' : null)),
            refLow: Value(isBp ? 60.0 : (isSugar ? 3.9 : (isHr ? 60.0 : null))),
            refHigh: Value(isBp ? 89.0 : (isSugar ? 6.1 : (isHr ? 100.0 : null))),
            refLow2: Value(isBp ? 90.0 : null),
            refHigh2: Value(isBp ? 139.0 : null),
          ),
        );
  }

  /// 测量值落库（与指标页同一套去重规则：同指标+同日+同时点+同值视为重复），返回是否新插入
  Future<bool> _insertMetricValue(AppDatabase db, Metric metric, double v1,
      double? v2, DateTime when,
      {String? timeLabel, String? note}) async {
    final dayStart = DateTime(when.year, when.month, when.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final dup = await (db.select(db.metricValues)
          ..where((t) =>
              t.metricId.equals(metric.id) &
              t.measuredAt.isBiggerOrEqualValue(dayStart) &
              t.measuredAt.isSmallerThanValue(dayEnd) &
              t.value1.equals(v1) &
              (v2 == null ? t.value2.isNull() : t.value2.equals(v2)) &
              (timeLabel == null
                  ? t.timeLabel.isNull()
                  : t.timeLabel.equals(timeLabel))))
        .get();
    if (dup.isNotEmpty) return false;
    await db.into(db.metricValues).insert(MetricValuesCompanion.insert(
          metricId: metric.id,
          value1: v1,
          value2: Value(v2),
          measuredAt: when,
          note: Value(note),
          timeLabel: Value(timeLabel),
        ));
    return true;
  }

  Future<AgentReply> _recordMetric(AppDatabase db, int profileId,
      Map<String, dynamic> args, String message, String lead) async {
    var name = args['metric']?.toString().trim() ?? '';
    var v1 = _num(args['value']);
    var v2 = _num(args['value2'] ?? args['dia']);
    var hr = _num(args['hr']);
    var timeLabel = (args['timeLabel'] ?? args['period'])?.toString().trim();
    if (timeLabel?.isEmpty == true) timeLabel = null;
    var date = _day(args['date']);

    // 模型没提取出数值时，退回口述解析（与指标页语音录入同一套规则）
    if (v1 == null && message.isNotEmpty) {
      final v = parseVitalsFromSpeech(message);
      if (v != null) {
        if (v.dia != null) {
          v1 = v.sys;
          v2 = v2 ?? v.dia;
          hr = hr ?? v.hr;
          if (name.isEmpty) name = '血压';
        } else {
          v1 = v.sys;
          if (name.isEmpty &&
              RegExp('血糖|葡萄糖|空腹').hasMatch(message)) {
            name = '血糖';
          }
        }
        date ??= v.date;
        timeLabel = timeLabel ?? v.period;
      }
    }
    if (v1 == null && hr == null) {
      return AgentReply(
          text: '$lead\n\n还没有解析到数值，可以这样对我说：'
              '\n· 记一下 血压130/85 心率76'
              '\n· 昨天早上 血压一百四/九十'
              '\n· 空腹血糖6.8'
              '\n· 体重70公斤 体温36.8');
    }
    if (v1 != null && name.isEmpty) {
      // 没给指标名时按值形态猜：双值→血压
      if (v2 != null) {
        name = '血压';
      } else {
        return AgentReply(
            text: '$lead\n\n要记到哪个指标呢？说一下指标名，比如「血糖 5.8」「体重 70」。');
      }
    }

    final now = DateTime.now();
    final when = date ?? DateTime(now.year, now.month, now.day);
    final lines = <String>[if (lead.isNotEmpty) lead];
    if (v1 != null) {
      final metric =
          await _resolveMetric(db, profileId, name, dual: v2 != null ? true : null, unit: args['unit']?.toString());
      final ok = await _insertMetricValue(db, metric, v1, v2, when,
          timeLabel: timeLabel, note: 'AI 管家录入');
      final valText = metric.dualValue
          ? '${_fmt(v1)}/${v2 != null ? _fmt(v2) : '—'}'
          : '${_fmt(v1)}${metric.unit.isEmpty ? '' : ' ${metric.unit}'}';
      lines.add(ok
          ? '已记录：${metric.name} $valText（${_md(when)}${timeLabel != null ? ' $timeLabel' : ''}）${_flag(metric, v1, v2)}'
          : '当天该时点已有相同数值，未重复记录');
    }
    if (hr != null) {
      final hrMetric = await _resolveMetric(db, profileId, '心率');
      final ok = await _insertMetricValue(db, hrMetric, hr, null, when,
          note: v1 != null ? '与血压同测' : null);
      lines.add(ok
          ? '心率 ${_fmt(hr)} 次/分（${_md(when)}）${_flag(hrMetric, hr, null)}'
          : '心率当天已有相同数值，未重复记录');
    }
    return AgentReply(text: lines.join('\n'));
  }

  // ── 动作：用药查询 / 建提醒 / 停用 ──

  Future<List<Medication>> _activeMeds(AppDatabase db, int profileId) async {
    return (db.select(db.medications)
          ..where((m) => m.profileId.equals(profileId) & m.active.equals(true))
          ..orderBy([(m) => OrderingTerm.asc(m.id)]))
        .get();
  }

  String _daysText(String? daysJson) {
    if (daysJson == null) return '每天';
    final days = (jsonDecode(daysJson) as List)
        .map((e) => int.parse(e.toString()))
        .toSet();
    if (days.isEmpty || days.length == 7) return '每天';
    const names = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return days.map((d) => names[d]).join('、');
  }

  Future<AgentReply> _listMedications(
      AppDatabase db, int profileId, String lead) async {
    final meds = await _activeMeds(db, profileId);
    if (meds.isEmpty) {
      return AgentReply(
          text: '$lead\n\n当前没有在用的药物。可以对我说「提醒我每天早上8点吃××」，'
              '或到「我的 → 用药提醒」手动添加。');
    }
    final lines = <String>[
      if (lead.isNotEmpty) lead,
      '当前在用药物 ${meds.length} 种：',
      for (final m in meds)
        '· ${m.name}${m.dosage?.isNotEmpty == true ? '（${m.dosage}）' : ''}'
        ' ${_daysText(m.daysOfWeek)} ${(jsonDecode(m.timesOfDay) as List).cast<String>().join('、')}'
        '${m.mealRelation?.isNotEmpty == true ? ' · ${m.mealRelation}' : ''}',
    ];
    return AgentReply(
        text: lines.join('\n'),
        route: '/medications',
        routeLabel: '用药提醒');
  }

  Future<AgentReply> _addMedication(AppDatabase db, int profileId,
      Map<String, dynamic> args, String lead) async {
    final name = args['name']?.toString().trim() ?? '';
    if (name.isEmpty) {
      return AgentReply(
          text: '$lead\n\n要建哪种药的提醒呢？比如「提醒我每天早晚8点吃氨氯地平」。');
    }
    // 时间点归一：口语时段映射为 24 小时制，非法项丢弃
    final times = <String>{};
    final rawTimes = args['times'];
    if (rawTimes is List) {
      for (final t in rawTimes) {
        final s = t.toString().trim();
        if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(s)) {
          times.add(s.padLeft(5, '0'));
        } else {
          times.add(switch (s) {
            '早' || '早上' || '早晨' || '早餐前' || '早餐后' => '08:00',
            '午' || '中午' || '午餐前' || '午餐后' => '12:00',
            '晚' || '晚上' || '晚餐前' || '晚餐后' => '20:00',
            '睡前' => '21:00',
            _ => '',
          });
        }
      }
    }
    times.remove('');
    if (times.isEmpty) times.add('08:00');
    final sorted = times.toList()..sort();
    final days = <int>{};
    final rawDays = args['days'];
    if (rawDays is List) {
      for (final d in rawDays) {
        final n = int.tryParse(d.toString());
        if (n != null && n >= 1 && n <= 7) days.add(n);
      }
    }
    if (days.length == 7) days.clear();
    final dosage = args['dosage']?.toString().trim();
    final meal = args['mealRelation']?.toString().trim();

    final medId = await db.into(db.medications).insert(
          MedicationsCompanion.insert(
            profileId: profileId,
            name: name,
            dosage: Value(dosage?.isEmpty == true ? null : dosage),
            mealRelation: Value(meal?.isEmpty == true ? null : meal),
            timesOfDay: jsonEncode(sorted),
            daysOfWeek: Value(days.isEmpty ? null : jsonEncode(days.toList()..sort())),
          ),
        );
    // 通知排期失败不阻断：App 启动/进用药页会整体重排兜底
    var notifyNote = '';
    try {
      await notifications?.rescheduleMedication(
        medicationId: medId,
        times: sorted,
        days: days,
        title: '灵枢 · 用药提醒',
        body: '$name${dosage?.isNotEmpty == true ? '（$dosage）' : ''}'
            '${meal?.isNotEmpty == true ? ' · $meal服用' : ' · 服用'}',
      );
    } catch (e) {
      notifyNote = '\n（提醒通知排期未完成，打开「用药提醒」页会自动补排）';
      debugPrint('[agent] reschedule failed: $e');
    }
    final dayText = days.isEmpty ? '每天' : _daysText(jsonEncode(days.toList()));
    return AgentReply(
        text: '$lead\n\n已创建用药提醒：\n'
            '· $name${dosage?.isNotEmpty == true ? '（$dosage）' : ''}'
            ' $dayText ${sorted.join('、')}${meal?.isNotEmpty == true ? ' $meal' : ''}服用$notifyNote\n'
            '想停用时对我说「停用$name」即可。',
        route: '/medications',
        routeLabel: '用药提醒');
  }

  Future<AgentReply> _stopMedication(AppDatabase db, int profileId,
      Map<String, dynamic> args, String lead) async {
    final q = args['name']?.toString().trim() ?? '';
    if (q.isEmpty) {
      return AgentReply(text: '$lead\n\n要停用哪种药？说全名即可，比如「停用氨氯地平」。');
    }
    final meds = await _activeMeds(db, profileId);
    var hit = meds.where((m) => m.name == q).toList();
    if (hit.isEmpty) {
      hit = meds.where((m) => m.name.contains(q) || q.contains(m.name)).toList();
    }
    if (hit.isEmpty) {
      return AgentReply(
          text: '$lead\n\n没有找到在用药物「$q」。'
              '${meds.isEmpty ? '当前没有在用药物。' : '目前在用：${meds.map((m) => m.name).join('、')}。'}');
    }
    if (hit.length > 1) {
      return AgentReply(
          text: '$lead\n\n有多条药物与「$q」相关：${hit.map((m) => m.name).join('、')}，'
              '请说全名以免停错。');
    }
    final med = hit.first;
    await (db.update(db.medications)..where((t) => t.id.equals(med.id)))
        .write(const MedicationsCompanion(active: Value(false)));
    // 先落库再后台取消通知：串行数百次平台调用需数秒，不能挡住回复
    unawaited(() async {
      try {
        await notifications?.cancelForMedication(med.id);
      } catch (_) {}
    }());
    return AgentReply(
        text: '$lead\n\n已停用「${med.name}」，提醒将不再弹出，历史记录保留。'
            '需要恢复请到「我的 → 用药提醒」开启。',
        route: '/medications',
        routeLabel: '用药提醒');
  }

  // ── 动作：档案查询 ──

  Future<AgentReply> _queryRecords(AppDatabase db, int profileId,
      Map<String, dynamic> args, String lead) async {
    final keyword = args['keyword']?.toString().trim() ?? '';
    final type = args['type']?.toString().trim() ?? '';
    var q = db.select(db.medicalRecords)
      ..where((r) => r.profileId.equals(profileId));
    if (type.isNotEmpty && _recordTypes.contains(type)) {
      q = q..where((r) => r.type.equals(type));
    }
    final all = await (q..orderBy([(r) => OrderingTerm.desc(r.recordDate)]))
        .get();
    if (all.isEmpty) {
      return AgentReply(
          text: '$lead\n\n档案库还是空的。把病历/报告照片发给我，说「归档」即可；'
              '也可以到「档案」页点 ⊕ 拍照导入。',
          route: '/records',
          routeLabel: '健康档案');
    }
    final hits = keyword.isEmpty
        ? all
        : all
            .where((r) =>
                r.title.contains(keyword) ||
                (r.hospital ?? '').contains(keyword) ||
                (r.department ?? '').contains(keyword) ||
                (r.aiSummary ?? '').contains(keyword) ||
                (r.note ?? '').contains(keyword))
            .toList();
    if (hits.isEmpty) {
      return AgentReply(
          text: '$lead\n\n没有找到与「$keyword」相关的档案（库中共 ${all.length} 份）。',
          route: '/records',
          routeLabel: '健康档案');
    }
    final shown = hits.take(8).toList();
    return AgentReply(
        text: [
          if (lead.isNotEmpty) lead,
          '档案库共 ${all.length} 份${keyword.isNotEmpty ? '，与「$keyword」相关 ${hits.length} 份' : ''}，最近 ${shown.length} 份：',
          for (final r in shown)
            '· [${r.type}] ${r.title}（${_d2(r.recordDate)}'
            '${r.hospital?.isNotEmpty == true ? ' · ${r.hospital}' : ''}'
            '${r.department?.isNotEmpty == true ? ' ${r.department}' : ''}）',
          if (hits.length > shown.length) '……另有 ${hits.length - shown.length} 份较早档案',
        ].join('\n'),
        route: '/records',
        routeLabel: '健康档案');
  }

  // ── 动作：健康概览 ──

  Future<AgentReply> _healthSummary(
      AppDatabase db, int profileId, String lead) async {
    final profile = await db.getProfile(profileId);
    final lines = <String>[if (lead.isNotEmpty) lead];
    final now = DateTime.now();

    // 基本信息
    var head = '「${profile?.name ?? '我'}';
    final birth = profile?.birthday;
    if (birth != null) {
      var age = now.year - birth.year;
      if (DateTime(now.year, birth.month, birth.day).isAfter(now)) age--;
      head += ' · $age 岁';
    }
    head += ' · ${profile?.gender == 'male' ? '男' : '女'}」健康概览';
    lines.add(head);

    // 档案
    final records = await (db.select(db.medicalRecords)
          ..where((r) => r.profileId.equals(profileId))
          ..orderBy([(r) => OrderingTerm.desc(r.recordDate)]))
        .get();
    if (records.isEmpty) {
      lines.add('📁 档案库：空（把病历/报告照片发给我即可归档）');
    } else {
      final byType = <String, int>{};
      for (final r in records) {
        byType[r.type] = (byType[r.type] ?? 0) + 1;
      }
      final top = (byType.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .take(3)
          .map((e) => '${e.key} ${e.value}')
          .join('、');
      final latest = records.first;
      lines.add('📁 档案库：${records.length} 份（$top）· 最近《${latest.title}》${_md(latest.recordDate)}');
    }

    // 指标：预设关键项的最新值（血压/血糖/心率/体重/体温/血氧）
    final metrics = await (db.select(db.metrics)
          ..where((t) => t.profileId.equals(profileId)))
        .get();
    if (metrics.isEmpty) {
      lines.add('📊 指标：还没有记录，可对我说「记一下 血压130/85」开始');
    } else {
      final priority = [
        'blood_pressure', 'blood_sugar', 'heart_rate', 'weight', 'temperature', 'blood_oxygen',
      ];
      final ordered = metrics.toList()
        ..sort((a, b) {
          final ai = priority.indexOf(a.code), bi = priority.indexOf(b.code);
          return (ai < 0 ? 99 : ai).compareTo(bi < 0 ? 99 : bi);
        });
      final metricLines = <String>[];
      for (final m in ordered.take(6)) {
        final latest = await (db.select(db.metricValues)
              ..where((v) => v.metricId.equals(m.id))
              ..orderBy([(v) => OrderingTerm.desc(v.measuredAt)])
              ..limit(1))
            .get();
        if (latest.isEmpty) continue;
        final v = latest.first;
        final val = m.dualValue
            ? '${_fmt(v.value1)}/${_fmt(v.value2 ?? 0)}'
            : _fmt(v.value1);
        metricLines.add('${m.name} $val'
            '${m.unit.isEmpty ? '' : ' ${m.unit}'}'
            '（${_md(v.measuredAt)}${v.timeLabel != null ? ' ${v.timeLabel}' : ''}）'
            '${_flag(m, v.value1, v.value2)}');
      }
      lines.add(metricLines.isEmpty
          ? '📊 指标：已建 ${metrics.length} 项，还没有测量值'
          : '📊 指标（最新）：${metricLines.join(' · ')}');
    }

    // 用药
    final meds = await _activeMeds(db, profileId);
    lines.add(meds.isEmpty
        ? '💊 在用药物：无'
        : '💊 在用药物：${meds.length} 种（${meds.map((m) => m.name).take(6).join('、')}${meds.length > 6 ? ' 等' : ''}）');

    // 药箱
    final box = await _boxMeds(db, profileId);
    if (box.isEmpty) {
      lines.add('🧰 家庭药箱：还没有建立（「我的 → 家庭药箱」拍照入库，我帮你盯临期）');
    } else {
      final expired = box
          .where((b) => b.expireDate.isBefore(DateTime(now.year, now.month, now.day)))
          .length;
      final soon = box
          .where((b) =>
              !b.expireDate.isBefore(DateTime(now.year, now.month, now.day)) &&
              b.expireDate.isBefore(now.add(const Duration(days: 90))))
          .length;
      lines.add('🧰 家庭药箱：共 ${box.length} 项'
          '${expired > 0 ? ' · ⚠️ 已过期 $expired 项' : ''}'
          '${soon > 0 ? ' · 3 个月内到期 $soon 项' : ''}');
    }

    // 体质
    final c = profile?.constitution;
    lines.add((c == null || c.isEmpty)
        ? '☯️ 体质：未辨识（「我的 → 体质辨识」或对我说「怎么测体质」）'
        : '☯️ 体质：$c');

    // 今日节气
    await content.load();
    final jieqi = Lunar.fromDate(now).getJieQi();
    final term = content.terms.where((t) => t.name == jieqi).firstOrNull;
    if (term != null) {
      lines.add('🗓 今日${term.name}（${term.element}）：${_clip(term.tip, 40)}');
    }

    return AgentReply(text: lines.join('\n'));
  }

  // ── 动作：体质与调养 ──

  Future<AgentReply> _constitutionQuery(
      AppDatabase db, int profileId, String lead) async {
    await content.load();
    final profile = await db.getProfile(profileId);
    final c = profile?.constitution;
    if (c == null || c.isEmpty) {
      return AgentReply(
          text: '$lead\n\n你还没有做过体质辨识。九种体质（平和/气虚/阳虚/阴虚/痰湿/湿热/血瘀/气郁/特禀）'
              '各有一套食养起居建议，回答一套问卷即可得出结果。',
          route: '/constitution',
          routeLabel: '开始体质辨识');
    }
    final hit = content.constitutions.where((k) =>
        k.name == c || c.contains(k.name) || k.name.contains(c) ||
        c.contains(k.name.replaceAll('质', '')));
    if (hit.isEmpty) {
      return AgentReply(
          text: '$lead\n\n档案里记录的体质是「$c」，暂未匹配到对应调养方案，可到体质页复测。',
          route: '/constitution',
          routeLabel: '体质辨识');
    }
    final k = hit.first;
    return AgentReply(
        text: [
          if (lead.isNotEmpty) lead,
          '☯️ 体质：${k.name}\n${k.desc}',
          '【调养建议】',
          for (final e in k.advice.entries) '· ${e.key}：${e.value}',
        ].join('\n'),
        route: '/constitution',
        routeLabel: '体质辨识');
  }

  // ── 动作：药箱盘点 ──

  /// 当前成员所属家庭组的全部药箱药品（按到期日升序）
  Future<List<BoxMedicine>> _boxMeds(AppDatabase db, int profileId) async {
    final fams = await (db.select(db.familyMembers)
          ..where((t) => t.profileId.equals(profileId)))
        .get();
    if (fams.isEmpty) return const [];
    final ids = fams.map((f) => f.familyId).toSet();
    final all = await db.select(db.boxMedicines).get();
    return (all.where((b) => ids.contains(b.familyId)).toList()
          ..sort((a, b) => a.expireDate.compareTo(b.expireDate)));
  }

  Future<AgentReply> _boxStatus(
      AppDatabase db, int profileId, String lead) async {
    final box = await _boxMeds(db, profileId);
    if (box.isEmpty) {
      return AgentReply(
          text: '$lead\n\n还没有可用的家庭药箱。到「我的 → 家庭药箱」把药品拍照入库，'
              '到期前 6/3/1 个月我会自动提醒。',
          route: '/box',
          routeLabel: '家庭药箱');
    }
    final today = DateTime.now();
    DateTime ds(DateTime d) => DateTime(d.year, d.month, d.day);
    final lines = <String>[
      if (lead.isNotEmpty) lead,
      '药箱共 ${box.length} 项（按到期先后）：',
    ];
    for (final b in box.take(15)) {
      final days = ds(b.expireDate).difference(ds(today)).inDays;
      lines.add(days < 0
          ? '· ${b.name} — ${_d2(b.expireDate)} 已过期 ${-days} 天 ⚠️'
          : '· ${b.name} — ${_d2(b.expireDate)} 剩 $days 天${days <= 90 ? '（临近到期）' : ''}');
    }
    if (box.length > 15) lines.add('……另有 ${box.length - 15} 项');
    return AgentReply(text: lines.join('\n'), route: '/box', routeLabel: '家庭药箱');
  }

  // ── 动作：急救指南 ──

  Future<AgentReply> _firstAid(
      Map<String, dynamic> args, String message, String lead) async {
    await content.load();
    var q = (args['query'] ?? args['scenario'] ?? '').toString().trim();
    if (q.isEmpty) q = message.trim();
    final scenarios = content.firstAid;
    FirstAidScenario? hit;
    if (q.isNotEmpty) {
      final byTitle = scenarios.where((s) => s.title.contains(q)).toList();
      if (byTitle.isNotEmpty) {
        hit = byTitle.reduce((a, b) => a.title.length <= b.title.length ? a : b);
      } else {
        final loose = scenarios.where((s) =>
            s.id == q ||
            s.category.contains(q) ||
            s.summary.contains(q) ||
            s.steps.any((st) => st.contains(q)));
        if (loose.isNotEmpty) hit = loose.first;
      }
    }
    if (hit == null) {
      final byCat = <String, List<String>>{};
      for (final s in scenarios) {
        byCat.putIfAbsent(s.category, () => []).add(s.title);
      }
      return AgentReply(
          text: [
            if (lead.isNotEmpty) lead,
            '内置 ${scenarios.length} 个急救场景，按类目：',
            for (final e in byCat.entries) '${e.key}：${e.value.join('、')}',
            '告诉我场景名，或直接描述发生了什么。⚠️ 情况危急时请立即拨打 120！',
          ].join('\n'));
    }
    return AgentReply(
        text: [
          if (lead.isNotEmpty) lead,
          '🚨《${hit.title}》（${hit.category}）',
          if (hit.emergency) '⚠️ 紧急场景：如情况危急，请立即拨打 120！',
          hit.summary,
          '【处理步骤】',
          for (var i = 0; i < hit.steps.length; i++) '${i + 1}. ${hit.steps[i]}',
          if (hit.warnings.isNotEmpty) ...[
            '【注意】',
            for (final w in hit.warnings) '· $w',
          ],
        ].join('\n'),
        route: '/firstaid/${hit.id}',
        routeLabel: hit.title);
  }

  // ── 动作：中药图鉴 ──

  Future<AgentReply> _herbLookup(
      Map<String, dynamic> args, String message, String lead) async {
    var q = (args['name'] ?? args['query'] ?? '').toString().trim();
    if (q.isEmpty) q = message.trim();
    if (q.isEmpty) {
      return AgentReply(text: '$lead\n\n想查哪味药？比如「黄芪的功效和禁忌」。');
    }
    final all = await herbs.all();
    var hit = all.where((h) => h.name == q).toList();
    if (hit.isEmpty) hit = all.where((h) => h.name.contains(q)).toList();
    if (hit.isEmpty) hit = all.where((h) => h.alias.contains(q)).toList();
    if (hit.isEmpty) {
      final lower = q.toLowerCase();
      hit = all
          .where((h) =>
              h.pinyin.toLowerCase().contains(lower) ||
              h.py.join(' ').toLowerCase().contains(lower))
          .toList();
    }
    if (hit.isEmpty) {
      final chars = q.split('');
      final near = all
          .where((h) => h.name.split('').any((ch) => ch.trim().isNotEmpty && chars.contains(ch)))
          .map((h) => h.name)
          .take(6)
          .toList();
      return AgentReply(
          text: '$lead\n\n图鉴（879 味）里没有找到「$q」'
              '${near.isNotEmpty ? '，名字相近的有：${near.join('、')}' : ''}。'
              '可换别名或别名中的字再试。');
    }
    final h = hit.first;
    return AgentReply(
        text: [
          if (lead.isNotEmpty) lead,
          '🌿 ${h.name}（${h.pinyinDisplay}）',
          if (h.intro.isNotEmpty) h.intro,
          if (h.type.isNotEmpty) '· 性味归经：${_clip(h.type, 80)}',
          if (h.effect.isNotEmpty) '· 功效：${_clip(h.effect, 120)}',
          if (h.usage.isNotEmpty) '· 用法主治：${_clip(h.usage, 150)}',
          if (h.taboo.isNotEmpty) '· 禁忌：${_clip(h.taboo, 100)}',
          for (final f in h.formulas.take(2)) '· 验方：${_clip(f, 90)}',
          '（具体用药请遵医嘱；「我的 → 中药图鉴」可看药材与原植物照片）',
        ].join('\n'));
  }

  // ── 动作：穴位查询 ──

  Future<AgentReply> _acupointLookup(
      Map<String, dynamic> args, String message, String lead) async {
    await content.load();
    var q = (args['name'] ?? args['query'] ?? '').toString().trim();
    if (q.isEmpty) q = message.trim();
    if (q.isEmpty) {
      return AgentReply(text: '$lead\n\n想查哪个穴位？比如「合谷穴在哪」。');
    }
    final pts = content.acupoints;
    var hit = pts.where((a) => a.name == q || a.name == '$q穴').toList();
    if (hit.isEmpty) hit = pts.where((a) => a.name.contains(q)).toList();
    if (hit.isEmpty) {
      final lower = q.toLowerCase();
      hit = pts
          .where((a) =>
              a.pinyin.toLowerCase().contains(lower) ||
              a.code.toLowerCase() == lower)
          .toList();
    }
    if (hit.isEmpty) {
      final common = pts.where((a) => a.common).map((a) => a.name).take(10).toList();
      return AgentReply(
          text: '$lead\n\n没找到穴位「$q」。可以试试：${common.join('、')}…'
              '（首页「经穴铜人」可按部位浏览全部穴位）',
          route: '/home',
          routeLabel: '经穴铜人');
    }
    final a = hit.first;
    final merName = content.meridianMap[a.meridian]?.name ?? a.meridian;
    return AgentReply(
        text: [
          if (lead.isNotEmpty) lead,
          '⚡ ${a.name}（${a.pinyin}）· $merName',
          if (a.location.isNotEmpty) '· 定位：${a.location}',
          if (a.indications.isNotEmpty) '· 主治：${_clip(a.indications, 120)}',
          if (a.effect.isNotEmpty) '· 功效：${_clip(a.effect, 100)}',
          if (a.method.isNotEmpty) '· 手法：${_clip(a.method, 100)}',
          '（首页「经穴铜人」可查看三维位置）',
        ].join('\n'),
        route: '/home',
        routeLabel: '经穴铜人');
  }

  // ── 动作：节气养生 ──

  Future<AgentReply> _solarTerm(String lead) async {
    await content.load();
    final now = DateTime.now();
    final lunar = Lunar.fromDate(now);
    final name = lunar.getJieQi();
    final t = content.terms.where((x) => x.name == name).firstOrNull;
    return AgentReply(
        text: [
          if (lead.isNotEmpty) lead,
          '🗓 今日·$name${t != null ? '（${t.element}）' : ''}',
          if (t != null) t.tip,
          '农历${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}'
              ' · ${lunar.getYearInGanZhi()}年',
        ].join('\n'));
  }

  // ── 动作：打开功能页 ──

  Future<AgentReply> _navigate(Map<String, dynamic> args, String lead) async {
    final key = args['page']?.toString().trim() ?? '';
    final hit = pageTable[key];
    if (hit == null) {
      return AgentReply(
          text: '$lead\n\n可以为你打开这些页面：'
              '${AgentService.pageTable.values.map((v) => v.$2).join('、')}。说「打开××」即可。');
    }
    return AgentReply(
        text: '$lead\n\n已为你备好入口，点下方按钮打开「${hit.$2}」。',
        route: hit.$1,
        routeLabel: hit.$2);
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
              '${have.isEmpty ? '你还没有记录过指标，可以先对我说「记一下 血压130/85」，或把检验报告照片发给我归档。' : '目前已记录的指标有：${have.join('、')}。'}');
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
                '可对我说「记一下 ${metric.name} ××」，或把检验报告照片发给我归档。');
      }
      values.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
      windowNote = '\n（最近 $days 天内没有记录，以下为最近 ${values.length} 条）';
    }

    final v1s = values.map((v) => v.value1).toList();
    final latest = values.last;
    final avg = v1s.reduce((a, b) => a + b) / v1s.length;

    final outCount =
        values.where((v) => _outOfRange(metric, v.value1, v.value2)).length;
    final latestDate =
        '${latest.measuredAt.month.toString().padLeft(2, '0')}-${latest.measuredAt.day.toString().padLeft(2, '0')}'
        '${latest.timeLabel != null ? ' ${latest.timeLabel}' : ''}';
    final lines = <String>[
      lead,
      '「${metric.name} · 最近 $days 天」共 ${values.length} 条',
      if (metric.dualValue)
        '最新 ${_fmt(latest.value1)}/${_fmt(latest.value2 ?? 0)} ${metric.unit}（$latestDate）'
            ' · 收缩压平均 ${_fmt(avg)} · 舒张压平均 ${_fmt(values.map((v) => v.value2 ?? 0).reduce((a, b) => a + b) / values.length)}'
      else
        '最新 ${_fmt(latest.value1)} ${metric.unit}（$latestDate）'
            ' · 平均 ${_fmt(avg)} · 最低 ${_fmt(v1s.reduce((a, b) => a < b ? a : b))} · 最高 ${_fmt(v1s.reduce((a, b) => a > b ? a : b))}',
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
