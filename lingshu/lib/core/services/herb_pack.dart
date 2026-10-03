import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'herb_pack_downloader.dart';

/// 下载完成但内容与编译期固定的大小/校验和不符：
/// 说明该源的内容错了，需丢弃本地缓存数据换下一个源
class PackVerifyException implements Exception {
  PackVerifyException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 中药配图资源包：APK 不再内置 73MB 图片，改为可选下载包。
/// 安装后图片落在应用文档目录 herb_pack/ 下，目录结构与 assets 一致
/// （herb_images/、herb_images_zy/、herb_plants/），配 manifest.json 记版本。
class HerbPack {
  HerbPack._();
  static final instance = HerbPack._();

  static const version = 1;
  static const packSizeMB = '67';
  static const zipBytes = 70778765;
  static const zipSha256 =
      '9a380478b43ed55f30705f75b9b158b3900c4a44ba38843d2a3c14ba8fbdb5b0';

  /// 主源：jsDelivr 分卷。jsDelivr 是 GitHub 仓库内容的公益 CDN，但
  /// 2026-10 实测主域与 fastly 域对 /gh/ 一律 301 甩给
  /// raw.githubusercontent.com（国内不可达），仅 testingcf 域仍在直出
  /// 内容（支持 206 断点续传，速度较慢但配合续传总能磨完）。
  /// 单文件 20MB 上限，故整包拆 4 段提交在仓库 packs/ 下，按段下载、
  /// 本地拼合。段内容不可变：升级只新增文件不改旧文件，并固定在 git
  /// tag 上，避免 CDN 缓存指向新内容。
  static const _volumeTag = 'herb-pack-v1';
  static const _volumeBases = <String>[
    // 国内多数地区直连可用（实测 206）
    'https://testingcf.jsdelivr.net/gh/JetYeah/LingShu@$_volumeTag/packs',
    // 国外/部分网络：301 跟随到 raw.githubusercontent.com 也能下完
    'https://cdn.jsdelivr.net/gh/JetYeah/LingShu@$_volumeTag/packs',
  ];
  static const volumeSizes = <int>[17694692, 17694692, 17694692, 17694689];

  /// 备用源：单文件整包，按序尝试（分卷全部失败才走到）
  static const fallbackUrls = <String>[
    // GitHub Releases（速度慢，但配合断点续传总能磨完）
    'https://github.com/JetYeah/LingShu/releases/download/herb-images-v1/herb_images_v1.zip',
    // FlowUS CDN（2026-10 起对直链回 403，仅作残存兜底）
    'https://cdn2.flowus.cn/oss/d0db55fd-8590-4bc8-a618-38e25ff12ccb/herb_images_v1.zip',
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

  /// 下载并安装资源包；[onProgress] 回调 0.0~1.0 与阶段文案。
  /// 下载矩阵：jsDelivr 分卷（每段独立断点续传）→ FlowUS CDN → GitHub，
  /// 每地址最多 3 次尝试、15s 停滞看门狗；中途失败留下的分段可在
  /// 下次点「下载」时接着用，不会归零。
  Future<void> install(void Function(double progress, String phase) onProgress,
      {String? urlOverride}) async {
    final root = await _root();
    final scratch = root.parent.path;
    final zip = File(p.join(scratch, 'herb_pack_download.zip'));
    try {
      await _obtainZip(zip, onProgress, urlOverride, scratch);
      onProgress(0.98, '校验并解压…');
      await _installZip(zip, root);
      _clearVolumeParts(scratch); // 安装成功，分段缓存不再需要
      onProgress(1, '安装完成');
    } finally {
      // 整包文件校验不过或安装失败都视为可疑，删掉；分段 .part 保留供续传
      if (zip.existsSync()) zip.deleteSync();
    }
  }

  /// 按「分卷 → 单文件备用源」矩阵把资源包弄到 [zip]
  Future<void> _obtainZip(File zip, void Function(double, String) onProgress,
      String? urlOverride, String scratch) async {
    final dl = ResumableDownloader();
    final envOverride = const String.fromEnvironment('HERB_PACK_URL');
    final failures = <String>[];

    if (urlOverride != null || envOverride.isNotEmpty) {
      // 测试覆盖：只走指定地址（--dart-define=HERB_PACK_URL=...）
      await _downloadSingle(
          dl, Uri.parse(urlOverride ?? envOverride), zip, onProgress);
      return;
    }

    try {
      onProgress(0, '连接分段服务器…');
      await _downloadVolumes(dl, _volumeBases.first, zip, onProgress, scratch);
      return;
    } on PackVerifyException catch (e) {
      failures.add('${_volumeBases.first}：$e');
      _clearVolumeParts(scratch); // 拼合后校验不过 → 某段静默损坏，清掉重来
    } catch (e) {
      // 网络类失败：分段保留，换下一个源（或下次点下载）接着传
      failures.add('${_volumeBases.first}：$e');
    }
    for (final base in _volumeBases.skip(1)) {
      try {
        onProgress(0, '连接分段服务器…');
        await _downloadVolumes(dl, base, zip, onProgress, scratch);
        return;
      } on PackVerifyException catch (e) {
        failures.add('$base：$e');
        _clearVolumeParts(scratch);
      } catch (e) {
        failures.add('$base：$e');
      }
    }
    for (final url in fallbackUrls) {
      try {
        await _downloadSingle(dl, Uri.parse(url), zip, onProgress);
        return;
      } catch (e) {
        failures.add('$url：$e');
      }
    }
    throw Exception('所有下载源均失败：${failures.join('；')}');
  }

  static String _partName(int i) => 'herb_images_v1.part${i + 1}.zip';

  void _clearVolumeParts(String scratch) {
    for (var i = 0; i < volumeSizes.length; i++) {
      final f = File(p.join(scratch, _partName(i)));
      if (f.existsSync()) f.deleteSync();
    }
  }

  /// jsDelivr 分卷：逐段下载（各自断点续传）→ 顺序拼合 → 整包校验
  Future<void> _downloadVolumes(ResumableDownloader dl, String base,
      File zip, void Function(double, String) onProgress, String scratch) async {
    final totalBytes = volumeSizes.fold<int>(0, (a, b) => a + b);
    var doneBytes = 0;
    for (var i = 0; i < volumeSizes.length; i++) {
      final base0 = doneBytes;
      await dl.download(
        Uri.parse('$base/${_partName(i)}'),
        File(p.join(scratch, _partName(i))),
        expectedSize: volumeSizes[i],
        onProgress: (received, _) {
          final overall = (base0 + received) / totalBytes;
          final pct = (overall * 100).floor();
          onProgress(overall * 0.97,
              '下载分段 ${i + 1}/${volumeSizes.length}（断点续传）$pct%');
        },
      );
      doneBytes += volumeSizes[i];
    }
    final sink = zip.openWrite(mode: FileMode.write);
    try {
      for (var i = 0; i < volumeSizes.length; i++) {
        await sink
            .addStream(File(p.join(scratch, _partName(i))).openRead());
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    final len = await zip.length();
    if (len != zipBytes) {
      throw PackVerifyException('拼合后大小不符（$len ≠ $zipBytes）');
    }
    final digest = await crypto.sha256.bind(zip.openRead()).first;
    if (digest.toString() != zipSha256) {
      throw PackVerifyException('拼合后校验和不符');
    }
  }

  Future<void> _downloadSingle(ResumableDownloader dl, Uri url, File zip,
      void Function(double, String) onProgress) async {
    await dl.download(url, zip,
        expectedSize: zipBytes,
        onProgress: (received, total) {
          final t = total ?? zipBytes;
          final pct = (received * 100 ~/ t).clamp(0, 100);
          onProgress(received / t * 0.97, '下载中 $pct%（断点续传）');
        });
    await _verifyZip(zip);
  }

  Future<void> _verifyZip(File zip) async {
    final len = await zip.length();
    if (len != zipBytes) {
      throw PackVerifyException('包大小不符（$len ≠ $zipBytes）');
    }
    final digest = await crypto.sha256.bind(zip.openRead()).first;
    if (digest.toString() != zipSha256) {
      throw PackVerifyException('包校验和不符');
    }
  }

  Future<void> _installZip(File zip, Directory root) async {
    // 解压到临时目录，校验后原子替换
    final staging = Directory('${root.path}_staging');
    if (staging.existsSync()) staging.deleteSync(recursive: true);
    staging.createSync(recursive: true);
    final archive = ZipDecoder().decodeBytes(await zip.readAsBytes());
    await extractArchiveToDisk(archive, staging.path);
    final mf = File(p.join(staging.path, 'manifest.json'));
    final j = jsonDecode(await mf.readAsString());
    if (((j['version'] as num?)?.toInt() ?? 0) < version) {
      throw Exception('资源包版本过旧');
    }
    if (root.existsSync()) root.deleteSync(recursive: true);
    staging.renameSync(root.path);

    _dir = root.path;
    _installedVersion = (j['version'] as num).toInt();
    stateStamp.value++;
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
    await _installZip(File(zipPath), root);
  }
}
