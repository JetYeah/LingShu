import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// AI 管家会话历史条目（纯数据，可 JSON 序列化）
class AiHistoryEntry {
  final bool user;
  final String text;
  final List<String> imagePaths; // 引用原路径，文件可能已被系统清理（加载时过滤）
  final String? chartPath; // 趋势图 PNG 落盘路径
  final String? chartTitle;

  const AiHistoryEntry({
    required this.user,
    this.text = '',
    this.imagePaths = const [],
    this.chartPath,
    this.chartTitle,
  });

  Map<String, dynamic> toJson() => {
        'user': user,
        if (text.isNotEmpty) 'text': text,
        if (imagePaths.isNotEmpty) 'images': imagePaths,
        if (chartPath != null) 'chart': chartPath,
        if (chartTitle != null) 'chartTitle': chartTitle,
      };

  factory AiHistoryEntry.fromJson(Map<String, dynamic> j) => AiHistoryEntry(
        user: j['user'] == true,
        text: (j['text'] ?? '').toString(),
        imagePaths: ((j['images'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        chartPath: j['chart'] as String?,
        chartTitle: j['chartTitle'] as String?,
      );
}

/// AI 管家会话历史落盘：`messages.json` + 趋势图 PNG 同目录。
/// 全量覆写式保存（个人会话量级小）；损坏/缺失一律当作无历史，
/// 绝不因读失败删用户数据。dir 可注入（单测用临时目录）。
class AiHistoryStore {
  final Future<Directory> Function() dir; // 历史根目录（不存在时由 save 创建）
  final int maxEntries; // 防无限膨胀上限

  AiHistoryStore({required this.dir, this.maxEntries = 300});

  File _file(Directory d) => File(p.join(d.path, 'messages.json'));

  /// 保存（最新在前；图片/图表只存路径）
  Future<void> save(List<AiHistoryEntry> entries) async {
    final d = await dir();
    if (!d.existsSync()) d.createSync(recursive: true);
    final kept = entries.take(maxEntries).toList();
    await _file(d).writeAsString(jsonEncode([for (final e in kept) e.toJson()]));
  }

  /// 加载（最新在前）。图片路径过滤掉已不存在的文件；图表文件存在才回读。
  /// JSON 损坏/读取失败返回空表并保留原文件（不静默清用户数据）。
  Future<List<AiHistoryEntry>> load() async {
    final d = await dir();
    final f = _file(d);
    if (!f.existsSync()) return const [];
    try {
      final list = jsonDecode(await f.readAsString()) as List;
      final out = <AiHistoryEntry>[];
      for (final e in list) {
        final en = AiHistoryEntry.fromJson(e as Map<String, dynamic>);
        final images =
            en.imagePaths.where((s) => File(s).existsSync()).toList();
        final chart = en.chartPath;
        out.add(AiHistoryEntry(
          user: en.user,
          text: en.text,
          imagePaths: images,
          chartPath: (chart != null && File(chart).existsSync()) ? chart : null,
          chartTitle: en.chartTitle,
        ));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// 清空：删除整个历史目录（含全部图表 PNG）。返回是否确有删除。
  Future<bool> clear() async {
    final d = await dir();
    if (!d.existsSync()) return false;
    await d.delete(recursive: true);
    return true;
  }

  /// 新图表落盘，返回文件路径；失败返回 null（图表不落盘只影响历史回看）
  Future<String?> saveChart(List<int> png) async {
    try {
      final d = await dir();
      if (!d.existsSync()) d.createSync(recursive: true);
      final f = File(p.join(
          d.path, 'chart_${DateTime.now().microsecondsSinceEpoch}.png'));
      await f.writeAsBytes(png);
      return f.path;
    } catch (_) {
      return null;
    }
  }
}
