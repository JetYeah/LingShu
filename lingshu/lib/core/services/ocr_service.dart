import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// 视觉大模型提取结果
class OcrResult {
  final String? title;
  final String? docType;
  final String? hospital;
  final String? department;
  final DateTime? recordDate;
  final String? summary;
  final List<OcrMetric> metrics;

  OcrResult({
    this.title,
    this.docType,
    this.hospital,
    this.department,
    this.recordDate,
    this.summary,
    required this.metrics,
  });

  factory OcrResult.empty() =>
      OcrResult(metrics: []);
}

class OcrMetric {
  final String name;
  final String? category; // 身体系统/功能归类（心血管/肝胆/血糖…）
  final double? value;
  final double? value2;
  final String? unit;
  final String? textValue; // 定性结果（阴性/阳性等），无数值时使用
  OcrMetric({
    required this.name,
    this.category,
    this.value,
    this.value2,
    this.unit,
    this.textValue,
  });
}

/// 一组指向同一检查项的相似指标名：keep 为保留/统一命名的规范名，merge 为待合并的别名
class MetricMergeGroup {
  final String keep;
  final List<String> merge;
  MetricMergeGroup({required this.keep, required this.merge});
}

/// 指标的 AI 医学解读结果
class MetricKnowledge {
  final String explanation; // 指标是什么、异常常见于哪些情况
  final String criteria; // 常用评判标准/参考区间
  final double? refLow; // 成人常用参考下限（按指标单位）
  final double? refHigh; // 上限
  MetricKnowledge({
    required this.explanation,
    required this.criteria,
    this.refLow,
    this.refHigh,
  });
}


/// 拍照识药的初步判断结果
class HerbGuess {
  final String name; // 最可能的中药/植物名
  final String? latin;
  final String confidence; // 高 / 中 / 低
  final String features; // 判断依据的外观特征
  final String? usage; // 常见用途一句话
  final String? caution; // 特别提醒（毒性等）
  HerbGuess({
    required this.name,
    this.latin,
    required this.confidence,
    required this.features,
    this.usage,
    this.caution,
  });
}

// 顶部插入 HerbGuess 类后由下面 append 到 OcrService 内部方法
/// 从处方/说明书中提取的一种药的用法草稿
class MedDraft {
  final String name;
  final String? dosage;
  final String? mealRelation; // 餐前/餐中/餐后/空腹/睡前
  final List<String> times; // "HH:mm"
  final String? note;
  MedDraft({
    required this.name,
    this.dosage,
    this.mealRelation,
    required this.times,
    this.note,
  });
}

/// 药箱药品识别结果（AI 从药盒/药品包装多张照片提取）
class BoxMedDraft {
  final String? name;
  final DateTime? expireDate; // 解析失败/未识别为 null，由用户补填
  final String rawExpire; // 原文有效期表述，供用户核对
  final String? usage; // 用法用量/说明
  BoxMedDraft(
      {this.name, this.expireDate, this.rawExpire = '', this.usage});
}

/// 药箱 AI 找药结果：matches 为清单编号（0 起），reason 为一句话筛选依据
class BoxMatchResult {
  final List<int> matches;
  final String reason;
  BoxMatchResult({required this.matches, required this.reason});
}

/// AI 返回值可能是 num，也可能是 "阴性"、"1.5 mg/L"、"<0.05" 等字符串
(double?, String?) _numOf(dynamic v) {
  if (v == null) return (null, null);
  if (v is num) return (v.toDouble(), null);
  final s = v.toString().trim();
  if (s.isEmpty) return (null, null);
  final direct = double.tryParse(s);
  if (direct != null) return (direct, null);
  // "1.5 mg/L"、"<0.05"：剥前缀取前导数字
  final m = RegExp(r'^[<>≈≤≥]?\s*(\d+(?:\.\d+)?)').firstMatch(s);
  if (m != null) return (double.tryParse(m.group(1)!), null);
  // 定性文本（阴性/阳性/未见异常…）
  return (null, s);
}

/// 视觉大模型识别服务（默认 GLM-4V，OpenAI 兼容协议，可在设置中配置）
class OcrService {
  static const defaultBaseUrl = 'https://open.bigmodel.cn/api/paas/v4';
  static const defaultModel = 'glm-4v-flash';

  final String baseUrl;
  final String apiKey;
  final String model;

  OcrService({
    required this.baseUrl,
    required this.apiKey,
    this.model = defaultModel,
  });

  static const _prompt = '''
你是医疗档案数字化助手。请阅读这张医疗文书照片（病历、检验报告、检查报告、处方、体检报告等），提取以下信息，只输出 JSON，不要输出任何其他文字：
{
  "title": "报告/文书标题",
  "docType": "病历|检验报告|影像报告|处方|体检报告|其他 之一",
  "hospital": "医院名称（如无则 null）",
  "department": "科室（如无则 null）",
  "date": "检查/就诊日期，格式 YYYY-MM-DD（如无则 null）",
  "summary": "一句话概括主要内容和结论",
  "metrics": [
    {"name": "指标名（如 收缩压/空腹血糖/血红蛋白）", "category": "所属类别（心血管|肝胆|肾脏|血糖|血脂|血常规|凝血功能|电解质|甲状腺|感染免疫|骨骼关节|消化|呼吸|泌尿生殖|肿瘤标志物|病理检查|维生素与代谢|基础体征|其他 之一）", "value": 数值或定性文字（阴性/阳性等定性结果直接填文字）, "value2": 数值或null(血压舒张压等), "unit": "单位或null"}
  ]
}
只提取照片中确实出现的指标，最多 15 条。''';

  /// 对无标签的指标名做文本归类，返回 {类别: [指标名]}
  /// 与 OCR 共用同一 OpenAI 兼容接口，纯文本对话
  Future<Map<String, List<String>>> classifyTags(List<String> names) async {
    const categories =
        '心血管、肝胆、肾脏、血糖、血脂、血常规、凝血功能、电解质、甲状腺、感染免疫、'
        '骨骼关节、消化、呼吸、泌尿生殖、肿瘤标志物、病理检查、维生素与代谢、基础体征、其他';
    final uri = Uri.parse('$baseUrl/chat/completions');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'user',
            'content': '以下是需要归类的医学检测指标名：\n'
                '${names.map((n) => '- $n').join('\n')}\n\n'
                '请把每个指标归入最贴切的类别，类别只能从这些里选：$categories。\n'
                '分类提示：PT/APTT/凝血酶/纤维蛋白原/D-二聚体/血栓弹力图(TEG,如 R/K/MA/Angle/LY30/CI/EPL 等前缀)属凝血功能；'
                '钾/钠/氯/钙/镁/磷属电解质；身高/体重/体温/心率/血氧属基础体征；'
                '肿块大小/送检组织/标本直径等手术病理所见属病理检查。\n'
                '只输出 JSON，格式：{"类别": ["指标名", ...]}，每个指标恰好出现一次。'
          }
        ],
        'temperature': 0.1,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    final body = jsonDecode(utf8.decode(resp.bodyBytes));
    var content = body['choices'][0]['message']['content'] as String;
    // 剥掉可能的 markdown 代码围栏
    content = content.replaceAll('```json', '').replaceAll('```', '').trim();
    final start = content.indexOf('{');
    final end = content.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const FormatException('AI 返回内容无法解析');
    }
    final parsed = jsonDecode(content.substring(start, end + 1)) as Map<String, dynamic>;
    final result = <String, List<String>>{};
    parsed.forEach((tag, list) {
      if (list is List) {
        result[tag] = list.map((e) => e.toString()).toList();
      }
    });
    return result;
  }

  /// 找出指向同一检查项的相似指标名组（OCR 识别同一项目常有中英文/写法/错字差异）。
  /// 纯文本对话，返回 keep + merge 别名列表；不相似的绝不能强行合并。
  Future<List<MetricMergeGroup>> mergeGroups(List<String> names) async {
    final uri = Uri.parse('$baseUrl/chat/completions');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'user',
            'content': '下面是一家人的健康追踪里积累的医学检测指标名（可能来自不同医院的报告，'
                '同一个检查项常因写法不同被存成多个条目）：\n'
                '${names.map((n) => '- $n').join('\n')}\n\n'
                '请找出其中指向**同一检查项**的相似名称组。判断标准：中英文互译（如 白蛋白/ALB）、'
                '全称与缩写（如 甘油三酯/TG）、写法或标点差异、明显的错别字。\n'
                '注意：单位或临床含义不同的项绝不能合并（如 血糖 与 糖化血红蛋白、'
                '收缩压 与 舒张压、白细胞 与 中性粒细胞 绝不是同一项）；\n'
                '拿不准的一律不要合并。keep 选最规范、最常用的中文全称。\n'
                '只输出 JSON 数组（没有相似组就输出 []），格式：'
                '[{"keep": "规范名", "merge": ["别名1", "别名2"]}]，'
                'keep 和 merge 里的名字必须原样取自上面的列表。'
          }
        ],
        'temperature': 0.1,
      }),
    ).timeout(const Duration(seconds: 60));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    final body = jsonDecode(utf8.decode(resp.bodyBytes));
    var content = body['choices'][0]['message']['content'] as String;
    content = content.replaceAll('```json', '').replaceAll('```', '').trim();
    final start = content.indexOf('[');
    final end = content.lastIndexOf(']');
    if (start < 0 || end <= start) return [];
    final parsed = jsonDecode(content.substring(start, end + 1)) as List;
    final groups = <MetricMergeGroup>[];
    for (final g in parsed) {
      if (g is! Map<String, dynamic>) continue;
      final keep = g['keep']?.toString() ?? '';
      final merge = (g['merge'] as List? ?? [])
          .map((e) => e.toString())
          .where((n) => n.isNotEmpty && n != keep)
          .toList();
      if (keep.isNotEmpty && merge.isNotEmpty) {
        groups.add(MetricMergeGroup(keep: keep, merge: merge));
      }
    }
    return groups;
  }

  /// 生成指标的医学解读：通俗解释 + 常用评判标准 + 成人参考上下限。
  /// 纯文本对话；refLow/refHigh 需与指标单位一致，无公认区间时为 null
  Future<MetricKnowledge> metricKnowledge({
    required String name,
    required String unit,
    List<double> recentValues = const [],
  }) async {
    final recent = recentValues.isEmpty
        ? ''
        : '\n最近的测量值：${recentValues.map((v) => v.toStringAsFixed(2)).join('、')}\n';
    final uri = Uri.parse('$baseUrl/chat/completions');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'user',
            'content': '你是面向家庭的医学科普助手。请介绍医学检验指标「$name」'
                '${unit.isEmpty ? '' : '（单位：$unit）'}。$recent\n'
                '1. explanation：这个指标是什么、反映什么身体状况、升高或降低常见于哪些情况，'
                '通俗易懂，2~4 句。\n'
                '2. criteria：临床常用的评判标准——参考区间以及偏低/正常/偏高如何界定，简洁分条。\n'
                '3. refLow、refHigh：成人最常用的参考区间下限与上限，纯数字，单位就用上面的单位；'
                '不同检测方法差异大、没有公认固定区间时填 null。\n'
                '只输出 JSON，不要任何其他文字：'
                '{"explanation": "...", "criteria": "...", "refLow": 数字或null, "refHigh": 数字或null}'
          }
        ],
        'temperature': 0.2,
      }),
    ).timeout(const Duration(seconds: 60));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    final body = jsonDecode(utf8.decode(resp.bodyBytes));
    var content = body['choices'][0]['message']['content'] as String;
    content = content.replaceAll('```json', '').replaceAll('```', '').trim();
    final start = content.indexOf('{');
    final end = content.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const FormatException('AI 返回内容无法解析');
    }
    final parsed = jsonDecode(content.substring(start, end + 1)) as Map<String, dynamic>;
    final (lo, _) = _numOf(parsed['refLow']);
    final (hi, _) = _numOf(parsed['refHigh']);
    return MetricKnowledge(
      explanation: (parsed['explanation'] ?? '').toString(),
      criteria: (parsed['criteria'] ?? '').toString(),
      refLow: lo,
      refHigh: hi,
    );
  }

  /// 从处方/医嘱/药品说明照片（可多张）提取用药信息，供人工核对入库。
  /// 一张处方常含多种药，返回草稿列表。

  /// 拍照识别中药/药用植物（初步判断，非专业鉴定）
  Future<HerbGuess> identifyHerb(Uint8List imageBytes) async {
    final b64 = base64Encode(imageBytes);
    final uri = Uri.parse('$baseUrl/chat/completions');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$b64'}
              },
              {
                'type': 'text',
                'text': '你是中药识别助手。请看这张照片（可能是中药材、中药饮片、'
                    '或活的药用植物），给出初步判断。只输出 JSON：'
                    '{"name": "最可能的中药/植物中文名（不确定时可写最接近的）", '
                    '"latin": "拉丁/学名或null", '
                    '"confidence": "高|中|低", '
                    '"features": "你依据的外观特征（颜色/形状/纹理等），1~3句", '
                    '"usage": "该药材的常见功效一句话", '
                    '"caution": "若有毒副作用或易混淆品种在此提醒，无则null"}'
                    '注意：照片模糊或非药材时 name 如实写"未能识别"并把 confidence 设为低。'
              }
            ]
          }
        ],
        'temperature': 0.1,
      }),
    ).timeout(const Duration(seconds: 60));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    final body = jsonDecode(utf8.decode(resp.bodyBytes));
    var txt = body['choices'][0]['message']['content'] as String;
    txt = txt.replaceAll('```json', '').replaceAll('```', '').trim();
    final start = txt.indexOf('{');
    final end = txt.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const FormatException('AI 返回内容无法解析');
    }
    final j =
        jsonDecode(txt.substring(start, end + 1)) as Map<String, dynamic>;
    return HerbGuess(
      name: (j['name'] ?? '未能识别').toString(),
      latin: _nullable(j['latin']),
      confidence: (j['confidence'] ?? '低').toString(),
      features: (j['features'] ?? '').toString(),
      usage: _nullable(j['usage']),
      caution: _nullable(j['caution']),
    );
  }

  /// 家庭小药箱：从药品包装/药盒/说明书的**多张**照片识别药品名称、
  /// 到期日期与用法用量。一张拍不全时（正面/背面/说明书分开拍）信息互补。
  /// 到期日写法多样（有效期至2027.03 / EXP 2027/03 / 生产日期+保质期等），
  /// 统一输出 YYYY-MM-DD（日缺失则 01），无法判断时置 null 由用户补填。
  Future<BoxMedDraft> recognizeBoxMedicine(List<Uint8List> images) async {
    final content = <Map<String, dynamic>>[
      for (final bytes in images)
        {
          'type': 'image_url',
          'image_url': {
            'url': 'data:image/jpeg;base64,${base64Encode(bytes)}'
          }
        },
      {
        'type': 'text',
        'text': '这些是家庭小药箱里**同一种药品**的多张照片（包装正面/背面/'
            '说明书局部，可能各有重点）。请综合所有照片识别药品信息，只输出 JSON，不要任何其他文字：\n'
            '{"name": "药品名（含剂型，如 阿莫西林胶囊；所有照片都看不清则 null）", '
            '"expire": "到期日期 YYYY-MM-DD（只到年月则 YYYY-MM-01；'
            '若只写生产日期和保质期请自行推算到期日；完全无法判断则 null）", '
            '"expire_raw": "有效期原文（如 有效期至2027.03/EXP 2027/03，没有则 null）", '
            '"usage": "用法用量与简要说明，如 口服。每次0.5g，每日3次，饭后服用；'
            '综合包装与说明书信息提炼为一两句话，完全没有则 null"}\n'
            '注意：①区分生产日期与到期日期，取更晚的作为到期日；②用法用量在说明书或'
            '包装背面，多张照片信息互相补充。'
      }
    ];
    final uri = Uri.parse('$baseUrl/chat/completions');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'user', 'content': content}
        ],
        'temperature': 0.1,
      }),
    ).timeout(const Duration(seconds: 120));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    final body = jsonDecode(utf8.decode(resp.bodyBytes));
    var txt = body['choices'][0]['message']['content'] as String;
    txt = txt.replaceAll('```json', '').replaceAll('```', '').trim();
    final start = txt.indexOf('{');
    final end = txt.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const FormatException('AI 返回内容无法解析');
    }
    final parsed = jsonDecode(txt.substring(start, end + 1)) as Map<String, dynamic>;
    String? name = _nullable(parsed['name']);
    if (name != null && (name.isEmpty || name == 'null')) name = null;
    String? raw = _nullable(parsed['expire_raw']);
    if (raw != null && (raw.isEmpty || raw == 'null')) raw = null;
    String? usage = _nullable(parsed['usage']);
    if (usage != null && (usage.isEmpty || usage == 'null')) usage = null;
    DateTime? expire;
    final es = _nullable(parsed['expire']);
    if (es != null) {
      final m = RegExp(r'^(\d{4})[-/.年](\d{1,2})(?:[-/.月](\d{1,2}))?').firstMatch(es);
      if (m != null) {
        expire = DateTime(int.parse(m.group(1)!), int.parse(m.group(2)!),
            int.parse(m.group(3) ?? '1'));
      }
    }
    return BoxMedDraft(
        name: name, expireDate: expire, rawExpire: raw ?? '', usage: usage);
  }

  /// 药箱 AI 找药：根据用户需求（如"有没有治感冒的药"）在药品清单里
  /// 挑出相关药品。清单每行 `编号|名称|用法用量|到期日`，AI 返回相关
  /// 编号数组；纯文本调用，不上传任何照片。
  Future<BoxMatchResult> matchBoxMedicines(
      String query, List<String> inventory) async {
    final uri = Uri.parse('$baseUrl/chat/completions');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'user',
            'content': '这是一个家庭小药箱的药品清单，每行格式：编号|药品名称|用法用量说明|到期日期：\n'
                '${inventory.isEmpty ? "（药箱是空的）" : inventory.join("\n")}\n\n'
                '用户需求：$query\n\n'
                '请根据药品名称与用法用量，从清单中挑出与该需求相关的药品'
                '（例如问"治感冒"时，感冒灵、退烧药、板蓝根颗粒等都相关；'
                '名称与说明都判断不出用途的不要猜）。只输出 JSON，不要任何其他文字：\n'
                '{"matches": [相关药品的编号], "reason": "一句话说明挑选依据"}\n'
                '没有相关药品时 matches 输出空数组。'
          }
        ],
        'temperature': 0.1,
      }),
    ).timeout(const Duration(seconds: 60));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    final body = jsonDecode(utf8.decode(resp.bodyBytes));
    var txt = body['choices'][0]['message']['content'] as String;
    txt = txt.replaceAll('```json', '').replaceAll('```', '').trim();
    final start = txt.indexOf('{');
    final end = txt.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const FormatException('AI 返回内容无法解析');
    }
    final parsed = jsonDecode(txt.substring(start, end + 1)) as Map<String, dynamic>;
    final matches = <int>[];
    if (parsed['matches'] is List) {
      for (final v in (parsed['matches'] as List)) {
        final i = int.tryParse(v.toString());
        if (i != null) matches.add(i);
      }
    }
    String? reason = _nullable(parsed['reason']);
    return BoxMatchResult(matches: matches, reason: reason ?? '');
  }

  Future<List<MedDraft>> extractMedications(List<Uint8List> images) async {
    final content = <Map<String, dynamic>>[
      for (final bytes in images)
        {
          'type': 'image_url',
          'image_url': {
            'url': 'data:image/jpeg;base64,${base64Encode(bytes)}'
          }
        },
      {
        'type': 'text',
        'text': '你是医疗文书数字化助手。请阅读这些医疗文书照片（处方、医嘱单、'
            '药品说明书等，可能多张属于同一次就诊），提取其中的**每一种药品**的用法信息。\n'
            '只输出 JSON，不要任何其他文字：\n'
            '{"medications": [{"name": "药品名（含剂型，如 阿莫西林胶囊）", '
            '"dosage": "单次剂量，如 0.5g/1粒，没有则 null", '
            '"mealRelation": "餐前|餐中|餐后|空腹|睡前 之一，未提及其他写 null", '
            '"times": ["08:00", "20:00"], '
            '"note": "频次与注意事项，如 每日两次，连服7天"}]}\n'
            'times 规则：有明确时间点（如 早8点、晚8点）按 24 小时制 HH:MM 输出；'
            '只写频次时按习惯时间给建议——每日一次 ["08:00"]、两次 ["08:00","20:00"]、'
            '三次 ["08:00","12:00","18:00"]，并在 note 里注明"时间按频次推定"；'
            '用法完全未写则 times 为空数组。只提取照片中确实出现的药品，最多 15 种。'
      }
    ];
    final uri = Uri.parse('$baseUrl/chat/completions');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'user', 'content': content}
        ],
        'temperature': 0.1,
      }),
    ).timeout(const Duration(seconds: 90));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    final body = jsonDecode(utf8.decode(resp.bodyBytes));
    var txt = body['choices'][0]['message']['content'] as String;
    txt = txt.replaceAll('```json', '').replaceAll('```', '').trim();
    final start = txt.indexOf('{');
    final end = txt.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const FormatException('AI 返回内容无法解析');
    }
    final parsed =
        jsonDecode(txt.substring(start, end + 1)) as Map<String, dynamic>;
    final meals = {'餐前', '餐中', '餐后', '空腹', '睡前'};
    final out = <MedDraft>[];
    for (final m in (parsed['medications'] as List? ?? [])) {
      if (m is! Map<String, dynamic>) continue;
      final name = (m['name'] ?? '').toString().trim();
      if (name.isEmpty || name == 'null') continue;
      final meal = m['mealRelation']?.toString();
      final times = (m['times'] as List? ?? [])
          .map((e) => e.toString())
          .where((t) => RegExp(r'^\d{1,2}:\d{2}$').hasMatch(t))
          .map((t) {
        final parts = t.split(':');
        return '${parts[0].padLeft(2, '0')}:${parts[1]}';
      }).toList();
      out.add(MedDraft(
        name: name,
        dosage: _nullable(m['dosage']),
        mealRelation: (meal != null && meals.contains(meal)) ? meal : null,
        times: times,
        note: _nullable(m['note']),
      ));
    }
    return out;
  }

  Future<OcrResult> extract(Uint8List imageBytes) async {
    final b64 = base64Encode(imageBytes);
    final uri = Uri.parse('$baseUrl/chat/completions');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$b64'}
              },
              {'type': 'text', 'text': _prompt},
            ]
          }
        ],
        'temperature': 0.1,
      }),
    ).timeout(const Duration(seconds: 60));

    if (resp.statusCode != 200) {
      throw Exception('识别接口返回 ${resp.statusCode}: ${resp.body}');
    }
    final body = jsonDecode(utf8.decode(resp.bodyBytes));
    final content = body['choices']?[0]?['message']?['content'];
    if (content is! String || content.isEmpty) {
      throw Exception('识别结果为空');
    }
    return _parse(content);
  }

  OcrResult _parse(String raw) {
    var s = raw.trim();
    // 剥离 ```json 围栏
    if (s.startsWith('```')) {
      s = s.replaceFirst(RegExp(r'^```(json)?\s*'), '');
      final end = s.lastIndexOf('```');
      if (end > 0) s = s.substring(0, end);
    }
    // 兜底：截取第一个 { 到最后一个 }
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start < 0 || end <= start) throw Exception('无法解析识别结果');
    final json = jsonDecode(s.substring(start, end + 1)) as Map<String, dynamic>;

    DateTime? date;
    final dateStr = json['date']?.toString();
    if (dateStr != null && dateStr != 'null') {
      date = DateTime.tryParse(dateStr) ??
          _tryParseCnDate(dateStr);
    }

    final metrics = <OcrMetric>[];
    if (json['metrics'] is List) {
      for (final m in (json['metrics'] as List)) {
        if (m is Map<String, dynamic> && m['name'] != null) {
          final (v1, tv) = _numOf(m['value']);
          final (v2, _) = _numOf(m['value2']);
          metrics.add(OcrMetric(
            name: m['name'].toString(),
            category: m['category']?.toString(),
            value: v1,
            value2: v2,
            unit: m['unit']?.toString(),
            textValue: tv,
          ));
        }
      }
    }

    return OcrResult(
      title: _nullable(json['title']),
      docType: _nullable(json['docType']),
      hospital: _nullable(json['hospital']),
      department: _nullable(json['department']),
      recordDate: date,
      summary: _nullable(json['summary']),
      metrics: metrics,
    );
  }

  String? _nullable(dynamic v) {
    final s = v?.toString();
    if (s == null || s.isEmpty || s == 'null') return null;
    return s;
  }

  DateTime? _tryParseCnDate(String s) {
    final m = RegExp(r'(\d{4})[年./-](\d{1,2})[月./-](\d{1,2})').firstMatch(s);
    if (m == null) return null;
    return DateTime.tryParse(
        '${m.group(1)}-${m.group(2)!.padLeft(2, '0')}-${m.group(3)!.padLeft(2, '0')}');
  }
}
