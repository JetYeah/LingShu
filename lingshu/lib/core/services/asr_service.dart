import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// 语音转写（OpenAI 兼容 /audio/transcriptions）。
/// 配置留空时复用 AI 病历识别的 base_url / api_key（见 asrConfigProvider）。
class AsrService {
  static const defaultModel = 'glm-asr';

  final String baseUrl;
  final String apiKey;
  final String model;

  AsrService({
    required this.baseUrl,
    required this.apiKey,
    this.model = defaultModel,
  });

  /// 音频转文字。audio 为 wav 文件字节（record 包 AudioEncoder.wav 产出）。
  Future<String> transcribe(Uint8List audio,
      {String filename = 'speech.wav'}) async {
    final uri = Uri.parse('$baseUrl/audio/transcriptions');
    final req = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = model
      ..files.add(http.MultipartFile.fromBytes('file', audio,
          filename: filename));
    final resp = await req.send().timeout(const Duration(seconds: 60));
    final body = await resp.stream.bytesToString();
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: $body');
    }
    final parsed = jsonDecode(body);
    final text = parsed['text']?.toString().trim();
    if (text == null || text.isEmpty) {
      throw const FormatException('未识别到语音内容');
    }
    return text;
  }
}

/// 口述血压/心率的解析结果（数值已按字段归位）
class SpeechVitals {
  final double sys; // 高压（收缩压）
  final double? dia; // 低压（舒张压）
  final double? hr; // 心率
  final DateTime? date; // 「今天/昨天/前天」「10月3号」等口述日期
  final String? period; // 测量时段：早上/中午/晚上
  SpeechVitals(
      {required this.sys, this.dia, this.hr, this.date, this.period});
}

/// 从语音转写文本中解析 高压/低压/心率（可选附带日期与早/中/晚时段），
/// 血糖口述（preferSugar 或明说「血糖/空腹」）则解析为 血糖值 + 空腹/餐后时点。
/// 支持两种说法：
/// - 带关键词：「昨天早上 高压一百四，低压九十，心率八十」「收缩压140 舒张压90 脉搏80」
/// - 纯报数（按习惯顺序）：「140 90 80」→ 高压/低压/心率；「140 90」→ 高压/低压
SpeechVitals? parseVitalsFromSpeech(String raw, {bool preferSugar = false}) {
  // 中文数字归一为阿拉伯，便于统一提取（一百四 → 140）
  var text = _normalizeZhNumbers(raw);

  // 日期先提取并从文本中移除：避免「10月3号」的 10、3 混进纯报数的数值序列
  final date = _parseSpokenDate(text);
  text = text
      .replaceAll(RegExp(r'\d{2,4}年\d{1,2}月\d{1,2}[日号]'), ' ')
      .replaceAll(RegExp(r'\d{1,2}月\d{1,2}[日号]'), ' ')
      .replaceAll(RegExp('今天|昨天|前天'), ' ');

  // 血糖路径：对话框就是血糖（preferSugar），或口述里明说了血糖/空腹且没提血压系词
  // （「血糖5.8 血压130 85」这类混合句仍按血压归位）
  final hasBpWords =
      RegExp('血压|高压|低压|收缩|舒张|心率|脉搏|脉率|心跳').hasMatch(text);
  if (preferSugar || ((text.contains('血糖') || text.contains('空腹')) && !hasBpWords)) {
    final val = _sugarValue(text);
    if (val != null && val > 0) {
      return SpeechVitals(
          sys: val, date: date, period: _sugarLabel(text));
    }
    // 数值都没解析出来则继续走血压路径兜底
  }

  // 测量时段：早/中/晚的口语说法归并为三档
  String? period;
  if (RegExp('早上|早晨|清晨|上午|早饭').hasMatch(text)) {
    period = '早上';
  } else if (RegExp('中午|午间|午后|午饭').hasMatch(text)) {
    period = '中午';
  } else if (RegExp('晚上|今晚|傍晚|夜间|夜里|晚饭').hasMatch(text)) {
    period = '晚上';
  }

  const zh = '零一二两三四五六七八九十百';
  final num = '([0-9]+(?:\\.[0-9]+)?|[$zh]+)';
  const sep = '[\\s，,、。．:：的是为有约个当前后度之／/\\.\\-]*';

  // 关键词必须整体加非捕获分组：否则 sep*num 只会拼到交替的最后一个词上
  double? matchAfter(String kws) =>
      _toNum(RegExp('(?:$kws)$sep$num').firstMatch(text)?.group(1));

  final sys = matchAfter('高压|收缩压|大压|上压|血压');
  final dia = matchAfter('低压|舒张压|小压|下压');
  final hr = matchAfter('心率|心跳|脉搏|脉率');
  final all = RegExp(num)
      .allMatches(text)
      .map((m) => _toNum(m.group(1)))
      .whereType<double>()
      .where((n) => n > 0)
      .toList();

  if (sys != null && sys > 0) {
    var d = dia;
    var h = hr;
    if (d == null || h == null) {
      // 关键词没认领的数字，按「高压之后」的顺序补位：先低压、再心率
      // （覆盖「血压130/85」「高压140 90 80」这类只报开头关键词的说法）
      final claimed = <double>[sys, ?d, ?h];
      final i = all.indexOf(sys);
      final rest = all
          .skip(i < 0 ? 0 : i + 1)
          .where((n) => !claimed.contains(n))
          .toList();
      d ??= rest.isNotEmpty ? rest.removeAt(0) : null;
      h ??= rest.isNotEmpty ? rest.first : null;
    }
    return SpeechVitals(sys: sys, dia: d, hr: h, date: date, period: period);
  }

  // 无关键词：按报数顺序取前三个数
  if (all.length >= 3) {
    return SpeechVitals(
        sys: all[0], dia: all[1], hr: all[2], date: date, period: period);
  }
  if (all.length == 2) {
    return SpeechVitals(sys: all[0], dia: all[1], date: date, period: period);
  }
  return null;
}

/// 口述血糖值：优先取「血糖/葡萄糖」后面的数；否则剥掉时点词后取
/// 唯一（或唯一落在 1~35 合理区间的）数值。「六点八」的「点」转小数点。
double? _sugarValue(String raw) {
  final t =
      raw.replaceAllMapped(RegExp(r'(\d)点(\d)'), (m) => '${m[1]}.${m[2]}');
  const zh = '零一二两三四五六七八九十百';
  final num = '([0-9]+(?:\\.[0-9]+)?|[$zh]+)';
  const sep = '[\\s，,、。．:：的是为有约个当前后度之／/\\.\\-]*';
  final kw = RegExp('(?:血糖|葡萄糖)$sep$num').firstMatch(t);
  final kwVal = _toNum(kw?.group(1));
  if (kwVal != null && kwVal > 0) return kwVal;
  final cleaned = t.replaceAll(
      RegExp('空腹|早餐后|早饭后|早餐前|早饭前|午餐前|午饭前|午餐后|午饭后|'
          '晚餐前|晚饭前|晚餐后|晚饭后|睡前|餐前|餐后|血糖|葡萄糖'),
      ' ');
  final nums = RegExp(num)
      .allMatches(cleaned)
      .map((m) => _toNum(m.group(1)))
      .whereType<double>()
      .where((n) => n > 0)
      .toList();
  if (nums.length == 1) return nums.first;
  final plausible = nums.where((n) => n >= 1 && n <= 35).toList();
  if (plausible.length == 1) return plausible.first;
  return nums.isEmpty ? null : nums.first;
}

/// 口述血糖时点 → 规范标签（与血糖录入的时点选项一致）；没说返回 null
String? _sugarLabel(String text) {
  if (text.contains('空腹')) return '空腹';
  if (text.contains('早餐后') || text.contains('早饭后')) return '早餐后';
  if (text.contains('早餐前') || text.contains('早饭前')) return '早餐前';
  if (text.contains('午餐前') || text.contains('午饭前')) return '午餐前';
  if (text.contains('午餐后') || text.contains('午饭后')) return '午餐后';
  if (text.contains('晚餐前') || text.contains('晚饭前')) return '晚餐前';
  if (text.contains('晚餐后') || text.contains('晚饭后')) return '晚餐后';
  if (text.contains('睡前')) return '睡前';
  return null;
}

/// 口述日期 → DateTime（只到日）。支持：今天/昨天/前天、（yyyy年）M月D日/号。
/// 无日期返回 null；月份口误超界也返回 null（由用户手填兜底）。
DateTime? _parseSpokenDate(String text) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (text.contains('前天')) return today.subtract(const Duration(days: 2));
  if (text.contains('昨天')) return today.subtract(const Duration(days: 1));
  if (text.contains('今天')) return today;
  final full = RegExp(r'(\d{2,4})年(\d{1,2})月(\d{1,2})[日号]').firstMatch(text);
  final md = RegExp(r'(\d{1,2})月(\d{1,2})[日号]').firstMatch(text);
  int y, m, d;
  if (full != null) {
    y = int.parse(full.group(1)!);
    if (y < 100) y += 2000;
    m = int.parse(full.group(2)!);
    d = int.parse(full.group(3)!);
  } else if (md != null) {
    y = now.year;
    m = int.parse(md.group(1)!);
    d = int.parse(md.group(2)!);
  } else {
    return null;
  }
  final parsed = DateTime(y, m, d);
  if (parsed.month != m || parsed.day != d) return null; // 口误（13月/32号）
  // 未说年份却指向未来（如 1 月说「12月30号」）→ 理解为去年
  if (full == null && parsed.isAfter(today)) {
    return DateTime(y - 1, m, d);
  }
  return parsed;
}

double? _toNum(String? s) {
  if (s == null || s.isEmpty) return null;
  return double.tryParse(s);
}

/// 把「一百四十」「八十五」等中文数字统一改写成阿拉伯数字再拼接回去，
/// 后续统一用数字正则提取。无法解析的片段原样保留。
String _normalizeZhNumbers(String raw) {
  const zh = '零一二两三四五六七八九十百';
  final re = RegExp('[$zh]+');
  return raw.replaceAllMapped(re, (m) {
    final v = _zhToInt(m.group(0)!);
    return v == null ? m.group(0)! : '$v';
  });
}

/// 中文数字 → 整数；仅支持口语常见的 百/十 两位量级写法。
/// 「一百四」= 140（省略「十」的口语）；「一百零五」= 105；非数字返回 null。
int? _zhToInt(String s) {
  const d = {'零': 0, '一': 1, '二': 2, '两': 2, '三': 3, '四': 4, '五': 5,
    '六': 6, '七': 7, '八': 8, '九': 9};
  var total = 0;
  var section = 0; // 当前量级内的数字
  var lastUnit = 0; // 最近出现的单位（10/100）
  for (final ch in s.split('')) {
    if (d.containsKey(ch)) {
      section = d[ch]!;
    } else if (ch == '十' || ch == '百') {
      final u = ch == '十' ? 10 : 100;
      total += (section == 0 ? 1 : section) * u;
      lastUnit = u;
      section = 0;
    } else {
      return null;
    }
  }
  if (section > 0) {
    // 「一百四」结尾无「十」且无「零」→ 省略十位的口语，尾数 ×10
    if (lastUnit >= 100 && !s.contains('十') && !s.contains('零')) {
      total += section * 10;
    } else {
      total += section;
    }
  }
  return total;
}
