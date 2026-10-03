import 'dart:async';
import 'dart:io';

/// 断点续传下载器：.part 增量续传 + 停滞看门狗 + 每地址有限重试。
/// 纯 dart:io 实现，flutter test 可用本地 HttpServer 覆盖各异常路径。
class ResumableDownloader {
  ResumableDownloader({
    this.stallTimeout = const Duration(seconds: 15),
    this.maxAttempts = 3,
    this.connectTimeout = const Duration(seconds: 20),
  });

  /// 连接建立后持续不吐数据超过该时长即主动断开，下次尝试从断点续传
  final Duration stallTimeout;

  /// 同一地址的最大尝试次数（尝试之间续传，不从头来）
  final int maxAttempts;
  final Duration connectTimeout;

  /// 下载 [url] 到 [target]。[target].part 已存在时从已收字节续传
  /// （服务端回 206；回 200 说明其忽略 Range，丢弃旧分片重下）。
  /// [expectedSize] 已知时用于严格判定完整性。成功后 .part 原子改名；
  /// 失败抛异常且保留 .part，供下次续传。
  Future<void> download(
    Uri url,
    File target, {
    void Function(int received, int? total)? onProgress,
    int? expectedSize,
  }) async {
    final part = File('${target.path}.part');
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        if (await _attempt(url, part, onProgress, expectedSize)) {
          final size = await part.length();
          if (expectedSize != null && size != expectedSize) {
            // 源上内容与预期不一致（如 CDN 缓存串包）：该地址按失败处理
            lastError = Exception('分片大小与预期不符（$size ≠ $expectedSize）');
          } else {
            lastError = null;
            break;
          }
          continue;
        }
        lastError = Exception('连接提前结束，分片不完整');
      } catch (e) {
        lastError = e;
      }
    }
    if (lastError != null) {
      throw Exception('下载失败（尝试 $maxAttempts 次）：$lastError');
    }
    if (target.existsSync()) target.deleteSync();
    await _renameWithRetry(part, target);
  }

  /// Windows 上杀毒/索引器可能短暂锁住刚写完的文件，重试几次再放弃
  static Future<void> _renameWithRetry(File from, File to) async {
    for (var i = 0; ; i++) {
      try {
        from.renameSync(to.path);
        return;
      } catch (_) {
        if (i >= 4) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }
  }

  /// 单次尝试。返回 true = 完整收完；false = 服务端提前断流，可续传重试
  Future<bool> _attempt(Uri url, File part,
      void Function(int, int?)? onProgress, int? expectedSize) async {
    final offset = part.existsSync() ? await part.length() : 0;
    final client = HttpClient()..connectionTimeout = connectTimeout;
    late final HttpClientResponse resp;
    try {
      final req = await client.getUrl(url);
      if (offset > 0) {
        req.headers.set(HttpHeaders.rangeHeader, 'bytes=$offset-');
      }
      // 响应头阶段也可能挂死（CDN 排队/丢包），同样计超时
      resp = await req.close().timeout(connectTimeout);
    } catch (_) {
      client.close(force: true);
      rethrow;
    }

    if (resp.statusCode == 416) {
      // 残留 .part 越过文件末尾（坏分片），删掉由外层重试从头下
      client.close();
      await part.delete();
      throw Exception('Range 416：本地分片越界，已重置');
    }
    if (resp.statusCode != 200 && resp.statusCode != 206) {
      client.close(force: true);
      throw Exception('HTTP ${resp.statusCode}');
    }

    // 续传起点与总长以服务端 Content-Range 为准
    var from = 0;
    int? total;
    var ranged = resp.statusCode == 206;
    if (ranged) {
      final m = RegExp(r'bytes (\d+)-\d+/(\d+)').firstMatch(
          resp.headers.value(HttpHeaders.contentRangeHeader) ?? '');
      if (m == null) {
        client.close(force: true);
        throw Exception('206 响应缺 Content-Range');
      }
      from = int.parse(m.group(1)!);
      total = int.parse(m.group(2)!);
    } else if (resp.contentLength > 0) {
      total = resp.contentLength;
    }

    IOSink? sink;
    try {
      if (ranged && from > 0 && from <= offset) {
        sink = part.openWrite(mode: FileMode.append);
      } else {
        // 服务端忽略 Range（回 200）或续传点对不上：丢弃旧分片重下
        from = 0;
        ranged = false;
        if (part.existsSync()) await part.delete();
        sink = part.openWrite(mode: FileMode.write);
      }
      onProgress?.call(from, total ?? expectedSize);

      var received = from;
      var lastData = DateTime.now();
      final done = Completer<void>();
      late final StreamSubscription<List<int>> sub;
      Timer? watchdog;
      void bail(Object e) {
        if (!done.isCompleted) done.completeError(e);
      }

      sub = resp.listen((chunk) {
        sink!.add(chunk);
        received += chunk.length;
        lastData = DateTime.now();
        onProgress?.call(received, total ?? expectedSize);
      }, onError: bail, onDone: () {
        if (!done.isCompleted) done.complete();
      });
      watchdog = Timer.periodic(stallTimeout ~/ 3, (_) {
        if (DateTime.now().difference(lastData) > stallTimeout) {
          sub.cancel();
          bail(TimeoutException('连接停滞超过 ${stallTimeout.inSeconds}s，断开以便续传'));
        }
      });
      try {
        await done.future;
      } finally {
        watchdog.cancel();
      }
      await sink.flush();
      await sink.close();
      sink = null;
      client.close();

      if (total != null && received < total) return false;
      if (!ranged && expectedSize != null && received > expectedSize) {
        throw Exception('收到的数据超出预期大小');
      }
      return true;
    } catch (_) {
      client.close(force: true);
      rethrow;
    } finally {
      try {
        await sink?.close();
      } catch (_) {}
    }
  }
}
