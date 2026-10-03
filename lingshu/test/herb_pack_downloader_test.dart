import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingshu/core/services/herb_pack_downloader.dart';

/// 断点续传下载器的异常路径覆盖：
/// 正常 200、中途断流→206 续传、停滞→看门狗→续传、忽略 Range→重下、
/// 416 越界分片重置、持续失败重试次数、expectedSize 不符。
void main() {
  late HttpServer server;
  late Uri url;
  late Mode mode;
  late Uint8List blob;
  late Directory tmp;
  final requests = <String?>[];

  setUpAll(() {
    final rng = Random(42);
    blob = Uint8List(300 * 1024);
    for (var i = 0; i < blob.length; i++) {
      blob[i] = rng.nextInt(256);
    }
  });

  setUp(() async {
    mode = Mode.ok;
    requests.clear();
    tmp = await Directory.systemTemp.createTemp('dl_test_');
    server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) async {
      final rangeHeader = req.headers.value(HttpHeaders.rangeHeader);
      requests.add(rangeHeader);
      // 第二个请求起恢复正常，模拟「服务端抽风一次」
      //（fail500/ignoreRange 例外：保持恒定行为）
      if (requests.length > 1 &&
          mode != Mode.ignoreRange &&
          mode != Mode.fail500) {
        mode = Mode.ok;
      }
      final serve = mode;
      final m = RegExp(r'bytes=(\d+)-').firstMatch(rangeHeader ?? '');
      final start = m != null ? int.parse(m.group(1)!) : 0;

      if (serve == Mode.fail500) {
        req.response.statusCode = 500;
        await req.response.close();
        return;
      }
      if (serve == Mode.tooLarge416 && start >= blob.length) {
        req.response.statusCode = 416;
        await req.response.close();
        return;
      }
      final ranged = m != null && serve != Mode.ignoreRange;
      // 真正「忽略 Range」的服务端会无视断点、从 0 回整个文件
      final effStart = ranged ? start : 0;
      if (ranged) req.response.statusCode = 206;
      req.response.headers.set(HttpHeaders.contentLengthHeader,
          (blob.length - effStart).toString());
      if (ranged) {
        req.response.headers.set(HttpHeaders.contentRangeHeader,
            'bytes $effStart-${blob.length - 1}/${blob.length}');
      }
      final broken = serve == Mode.abortMidway || serve == Mode.stallMidway;
      // 64KB：Dart 客户端对过小的在途数据不回调 onData（实测 <64KB 会
      // 攒着不交付，直到连接结束），用大块才能模拟「已收到 N 字节」
      final end = broken ? min(effStart + 64 * 1024, blob.length) : blob.length;
      req.response.add(blob.sublist(effStart, end));
      await req.response.flush();
      if (serve == Mode.abortMidway) {
        // 等客户端真正收下这段数据再断开，否则错误会抢先把在途数据丢掉
        await Future<void>.delayed(const Duration(milliseconds: 100));
        req.response.addError(const SocketException('server reset'));
        return;
      }
      if (serve == Mode.stallMidway) return; // 挂住连接，等客户端看门狗断开
      await req.response.close();
    });
    url = Uri.parse('http://127.0.0.1:${server.port}/file.bin');
  });

  tearDown(() async {
    await server.close(force: true);
    tmp.deleteSync(recursive: true);
  });

  Future<File> fetched(String path, {int? expectedSize, ResumableDownloader? dl}) async {
    final f = File(path);
    await (dl ?? ResumableDownloader()).download(url, f, expectedSize: expectedSize);
    return f;
  }

  test('正常 200 一次下完', () async {
    final f = await fetched('${tmp.path}/dl_ok.bin');
    expect(await f.readAsBytes(), blob);
    expect(requests, [null]);
  });

  test('中途断流后从断点 206 续传', () async {
    mode = Mode.abortMidway;
    final f = await fetched('${tmp.path}/dl_abort.bin');
    expect(await f.readAsBytes(), blob);
    expect(requests[0], isNull);
    expect(requests[1], 'bytes=65536-');
  });

  test('停滞触发看门狗后断开续传', () async {
    mode = Mode.stallMidway;
    final dl = ResumableDownloader(stallTimeout: const Duration(milliseconds: 400));
    final f = await fetched('${tmp.path}/dl_stall.bin', dl: dl);
    expect(await f.readAsBytes(), blob);
    expect(requests[1], 'bytes=65536-');
  });

  test('服务端忽略 Range 回 200 时丢弃旧分片重下', () async {
    final target = File('${tmp.path}/dl_norange.bin');
    await File('${target.path}.part').writeAsBytes(blob.sublist(0, 5000));
    mode = Mode.ignoreRange;
    await ResumableDownloader().download(url, target);
    expect(await target.readAsBytes(), blob);
    expect(requests[0], 'bytes=5000-'); // 客户端请求了续传，服务端没理会
  });

  test('416 越界分片重置后重新下全', () async {
    final target = File('${tmp.path}/dl_416.bin');
    await File('${target.path}.part').writeAsBytes(Uint8List(blob.length + 100));
    mode = Mode.tooLarge416;
    await ResumableDownloader().download(url, target);
    expect(await target.readAsBytes(), blob);
    expect(requests[0], 'bytes=${blob.length + 100}-');
    expect(requests[1], isNull);
  });

  test('持续失败按 maxAttempts 次数重试后抛出', () async {
    mode = Mode.fail500;
    final dl = ResumableDownloader(maxAttempts: 3);
    await expectLater(
        dl.download(url, File('${tmp.path}/dl_fail.bin')),
        throwsA(anything));
    expect(requests.length, 3);
  });

  test('expectedSize 与实际不符时按失败处理', () async {
    final dl = ResumableDownloader(maxAttempts: 2);
    await expectLater(
        fetched('${tmp.path}/dl_size.bin',
            expectedSize: blob.length + 1, dl: dl),
        throwsA(anything));
    expect(requests.length, 2);
  });
}

enum Mode { ok, abortMidway, stallMidway, ignoreRange, fail500, tooLarge416 }
