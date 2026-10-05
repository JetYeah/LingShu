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
  SpeechVitals({required this.sys, this.dia, this.hr});
}

/// 从语音转写文本中解析 高压/低压/心率。
/// 支持两种说法：
/// - 带关键词：「高压一百四，低压九十，心率八十」「收缩压140 舒张压90 脉搏80」
/// - 纯报数（按习惯顺序）：「140 90 80」→ 高压/低压/心率；「140 90」→ 高压/低压
SpeechVitals? parseVitalsFromSpeech(String raw) {
  // 中文数字归一为阿拉伯，便于统一提取（一百四 → 140）
  final text = _normalizeZhNumbers(raw);
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
    return SpeechVitals(sys: sys, dia: d, hr: h);
  }

  // 无关键词：按报数顺序取前三个数
  if (all.length >= 3) {
    return SpeechVitals(sys: all[0], dia: all[1], hr: all[2]);
  }
  if (all.length == 2) {
    return SpeechVitals(sys: all[0], dia: all[1]);
  }
  return null;
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
