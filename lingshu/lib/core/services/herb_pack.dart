import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 中药配图资源包：APK 不再内置 73MB 图片，改为可选下载包。
/// 安装后图片落在应用文档目录 herb_pack/ 下，目录结构与 assets 一致
/// （herb_images/、herb_images_zy/、herb_plants/），配 manifest.json 记版本。
class HerbPack {
  HerbPack._();
  static final instance = HerbPack._();

  static const version = 1;
  static const packSizeMB = '67';

  /// 下载地址依次尝试（资源基本不变，地址失效时可随版本更新）
  static const urls = <String>[
    // 国内备用（FlowUS CDN，较稳）
    'https://cdn2.flowus.cn/oss/d0db55fd-8590-4bc8-a618-38e25ff12ccb/herb_images_v1.zip',
    // 主渠道（GitHub Releases）
    'https://github.com/JetYeah/LingShu/releases/download/herb-images-v1/herb_images_v1.zip',
    // 测试覆盖：flutter build --dart-define=HERB_PACK_URL=http://...
    String.fromEnvironment('HERB_PACK_URL'),
  ];

  String? _dir; // 已安装包的根目录（缓存）
  int? _installedVersion;

  /// 安装/卸载后自增；已渲染的图片组件监听它重新解析文件
  final stateStamp = ValueNotifier<int>(0);

  Directory? _baseDir;

  Future<Directory> _root() async {
    _baseDir ??= Directory(
        p.join((await getApplicationDocumentsDirectory()).path, 'herb_pack'));
    return _baseDir!;
  }

  /// 已安装版本；未安装返回 null
  Future<int?> installedVersion() async {
    if (_installedVersion != null) return _installedVersion;
    final root = await _root();
    final mf = File(p.join(root.path, 'manifest.json'));
    if (!mf.existsSync()) return null;
    try {
      final j = jsonDecode(await mf.readAsString());
      final v = (j['version'] as num?)?.toInt() ?? 0;
      if (v >= version) {
        _dir = root.path;
        _installedVersion = v;
        return v;
      }
      return null; // 版本过旧视为未安装
    } catch (_) {
      return null;
    }
  }

  /// 把 asset 路径解析为本地文件；未安装/文件缺失返回 null（调用方回退占位）。
  /// [assetPath] 形如 assets/herb_images/B00339.jpg（可带或不带 .jpg）
  Future<String?> resolveFile(String assetPath) async {
    if (await installedVersion() == null) return null;
    final rel = assetPath.startsWith('assets/')
        ? assetPath.substring('assets/'.length)
        : assetPath;
    final f = File(p.join(_dir!, rel));
    return f.existsSync() ? f.path : null;
  }

  /// 下载并安装资源包；[onProgress] 回调 0.0~1.0
  Future<void> install(void Function(double progress, String phase) onProgress,
      {String? urlOverride}) async {
    final root = await _root();
    final candidates = [
      if (urlOverride != null) urlOverride,
      ...urls.where((u) => u.isNotEmpty),
    ];

    Object? lastError;
    for (final url in candidates) {
      try {
        onProgress(0, '连接服务器…');
        final client = http.Client();
        final req = http.Request('GET', Uri.parse(url));
        final resp = await client.send(req).timeout(const Duration(seconds: 20));
        if (resp.statusCode != 200) {
          throw Exception('HTTP ${resp.statusCode}');
        }
        final total = resp.contentLength ?? 0;
        final tmpZip = File(p.join(root.parent.path, 'herb_pack_download.zip'));
        final sink = tmpZip.openWrite();
        var received = 0;
        var lastPct = -1;
        await for (final chunk in resp.stream) {
          received += chunk.length;
          sink.add(chunk);
          if (total > 0) {
            final pct = (received * 100 ~/ total);
            if (pct != lastPct) {
              lastPct = pct;
              onProgress(received / total, '下载中 $pct%');
            }
          }
        }
        await sink.close();
        if (total > 0 && received < total) {
          throw Exception('下载不完整');
        }
        onProgress(0.98, '解压安装…');

        // 解压到临时目录，校验后原子替换
        final staging = Directory('${root.path}_staging');
        if (staging.existsSync()) staging.deleteSync(recursive: true);
        staging.createSync(recursive: true);
        final archive = ZipDecoder().decodeBytes(await tmpZip.readAsBytes());
        await extractArchiveToDisk(archive, staging.path);
        final mf = File(p.join(staging.path, 'manifest.json'));
        final j = jsonDecode(await mf.readAsString());
        if (((j['version'] as num?)?.toInt() ?? 0) < version) {
          throw Exception('资源包版本过旧');
        }
        if (root.existsSync()) root.deleteSync(recursive: true);
        staging.renameSync(root.path);
        tmpZip.deleteSync();

        _dir = root.path;
        _installedVersion = (j['version'] as num).toInt();
        stateStamp.value++;
        onProgress(1, '安装完成');
        return;
      } catch (e) {
        lastError = e;
        continue; // 换下一个地址
      }
    }
    throw Exception('资源包下载失败：$lastError');
  }

  Future<void> uninstall() async {
    final root = await _root();
    if (root.existsSync()) root.deleteSync(recursive: true);
    _dir = null;
    _installedVersion = null;
    stateStamp.value++;
  }

  // ---- 供测试/调试 ----
  /// 仅供测试：把已下载好的 zip 从本地路径安装（绕过网络）
  Future<void> installFromZipFile(String zipPath) async {
    final root = await _root();
    final staging = Directory('${root.path}_staging');
    if (staging.existsSync()) staging.deleteSync(recursive: true);
    staging.createSync(recursive: true);
    final archive =
        ZipDecoder().decodeBytes(await File(zipPath).readAsBytes());
    await extractArchiveToDisk(archive, staging.path);
    if (root.existsSync()) root.deleteSync(recursive: true);
    staging.renameSync(root.path);
    _dir = root.path;
    _installedVersion = version;
  }
}
