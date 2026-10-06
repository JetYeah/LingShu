import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'herb_pack_downloader.dart';

/// changelog 行类型（Release body 的轻量 markdown 解析结果）
enum ChangelogLineKind { heading, bullet, paragraph }

class ChangelogLine {
  const ChangelogLine(this.kind, this.text);
  final ChangelogLineKind kind;
  final String text;
}

/// 一次「检查更新」的结果
class UpdateCheck {
  const UpdateCheck({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseTitle,
    required this.changelog,
    required this.apkUrl,
    required this.apkName,
    required this.apkSize,
    this.apkSha256,
  });

  final String currentVersion; // 本机版本，如 0.1.43
  final String latestVersion; // 已去掉 v 前缀
  final String releaseTitle; // Release 标题，如「灵枢 v0.1.43 · 语音记录升级」
  final List<ChangelogLine> changelog;
  final String apkUrl;
  final String apkName;
  final int apkSize;
  final String? apkSha256; // GitHub asset digest（2025 起提供），缺省为 null

  bool get hasUpdate => UpdateService.compareVersions(latestVersion, currentVersion) > 0;
}

/// 应用内自动更新：GitHub Releases 为唯一权威源。
/// 检查 → 确认（展示更新记录）→ 断点续传下载 → 校验 → 拉起系统安装器覆盖安装。
class UpdateService {
  UpdateService({Uri? apiBase, this.currentVersionOverride})
      : apiBase =
            apiBase ?? Uri.parse('https://api.github.com/repos/$repo/releases/latest');

  /// GitHub API 入口，测试注入本地 HttpServer
  final Uri apiBase;

  /// 测试/联调注入的本机版本
  final String? currentVersionOverride;

  static const repo = 'JetYeah/LingShu';
  static const _channel = MethodChannel('lingshu/updater');

  Future<String> currentVersion() async {
    if (currentVersionOverride != null) return currentVersionOverride!;
    // 真机联调：debug 构建可 --dart-define=UPDATE_FAKE_VERSION=0.1.40 模拟旧版，
    // 走完整更新链路（弹窗/下载/安装）；release 不受影响
    final fake = const String.fromEnvironment('UPDATE_FAKE_VERSION');
    if (kDebugMode && fake.isNotEmpty) return fake;
    return (await PackageInfo.fromPlatform()).version;
  }

  /// 拉取 GitHub 最新 Release 并与本机版本比较
  Future<UpdateCheck> checkLatest() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    final String body;
    final int status;
    try {
      final req = await client.getUrl(apiBase);
      req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final resp = await req.close().timeout(const Duration(seconds: 30));
      status = resp.statusCode;
      body = await resp.transform(utf8.decoder).join();
    } finally {
      client.close();
    }
    if (status != 200) {
      throw Exception('GitHub API HTTP $status');
    }
    final j = jsonDecode(body) as Map<String, dynamic>;
    final tag = (j['tag_name'] as String?)?.replaceFirst(RegExp(r'^v'), '') ?? '';
    if (tag.isEmpty) throw Exception('Release 缺少 tag_name');

    Map<String, dynamic>? asset;
    for (final a in (j['assets'] as List? ?? const [])) {
      final m = (a as Map).cast<String, dynamic>();
      if ((m['name'] as String? ?? '').endsWith('.apk')) {
        asset = m;
        break;
      }
    }
    if (asset == null) throw Exception('最新 Release 未附 APK（arm64 专版）');

    final digest = asset['digest'] as String?;
    return UpdateCheck(
      currentVersion: await currentVersion(),
      latestVersion: tag,
      releaseTitle: (j['name'] as String?) ?? 'v$tag',
      changelog: parseChangelog(j['body'] as String? ?? ''),
      apkUrl: asset['browser_download_url'] as String,
      apkName: asset['name'] as String,
      apkSize: (asset['size'] as num).toInt(),
      apkSha256:
          (digest != null && digest.startsWith('sha256:')) ? digest.substring(7) : null,
    );
  }

  /// 解析 Release body 为轻量结构：`## ` 标题 / `- ` 列表 / 其余段落。
  /// 行内 `**加粗**` 由展示层处理，这里只剥离 markdown 语法壳。
  static List<ChangelogLine> parseChangelog(String body) {
    final lines = <ChangelogLine>[];
    for (final raw in const LineSplitter().convert(body)) {
      final s = raw.trim();
      if (s.isEmpty) continue;
      if (s.startsWith('## ')) {
        lines.add(ChangelogLine(ChangelogLineKind.heading, s.substring(3).trim()));
      } else if (s.startsWith('- ')) {
        lines.add(ChangelogLine(ChangelogLineKind.bullet, s.substring(2).trim()));
      } else {
        lines.add(ChangelogLine(ChangelogLineKind.paragraph, s));
      }
    }
    return lines;
  }

  /// 比较点分版本号（容忍 v 前缀；+build 为构建元数据，不参与比较），>0 表示 a 更新
  static int compareVersions(String a, String b) {
    List<int> parse(String v) => v
        .trim()
        .toLowerCase()
        .split('+')
        .first
        .replaceFirst(RegExp(r'^v'), '')
        .split(RegExp(r'[.\-]'))
        .map((s) => int.tryParse(s) ?? 0)
        .toList();
    final pa = parse(a);
    final pb = parse(b);
    final n = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < n; i++) {
      final d = (i < pa.length ? pa[i] : 0) - (i < pb.length ? pb[i] : 0);
      if (d != 0) return d;
    }
    return 0;
  }

  /// 下载更新 APK 到应用专属外部目录（…/Android/data/`<pkg>`/files/update/），
  /// 完整性双校验（大小 + GitHub digest 的 sha256，若提供），成功返回文件路径。
  /// 断点续传：中断留下的 .part 下次调用继续用，不归零。
  Future<String> downloadApk(UpdateCheck u,
      {void Function(int received, int total)? onProgress}) async {
    final dir = await getExternalStorageDirectory();
    if (dir == null) throw Exception('应用外部存储目录不可用');
    final folder = Directory(p.join(dir.path, 'update'));
    await folder.create(recursive: true);
    final target = File(p.join(folder.path, u.apkName));

    await ResumableDownloader().download(
      Uri.parse(u.apkUrl),
      target,
      expectedSize: u.apkSize,
      onProgress: (received, total) => onProgress?.call(received, total ?? u.apkSize),
    );

    final len = await target.length();
    if (len != u.apkSize) {
      target.deleteSync();
      throw Exception('APK 大小不符（$len ≠ ${u.apkSize}），已删除请重试');
    }
    if (u.apkSha256 != null) {
      final digest = await crypto.sha256.bind(target.openRead()).first;
      if (digest.toString() != u.apkSha256) {
        target.deleteSync();
        throw Exception('APK 校验和不符，已删除请重试');
      }
    }
    // 顺手清掉旧版本残留的安装包
    for (final e in folder.listSync()) {
      if (e is File && e.path.endsWith('.apk') && e.path != target.path) {
        e.deleteSync();
      }
    }
    return target.path;
  }

  /// 拉起系统安装器。返回 'opened'（已拉起）或 'needsPermission'
  /// （缺少「安装未知应用」授权，已带去授权页，授权后需再次调用）。
  Future<String> installApk(String path) async {
    final r = await _channel.invokeMethod<String>('installApk', {'path': path});
    return r ?? 'opened';
  }
}
