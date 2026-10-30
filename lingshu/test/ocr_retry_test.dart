import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lingshu/core/services/ocr_service.dart';

/// OcrService 大模型请求的瞬时故障重试：多图归档时单张请求被
/// 网络中断/限流/5xx 打断不应直接丢一张（回归 v0.1.53 真机反馈）
void main() {
  final content = jsonEncode({
    'title': '血常规检验报告',
    'docType': '检验报告',
    'hospital': null,
    'date': '2026-10-01',
    'summary': '大致正常',
    'metrics': [
      {'name': '白细胞', 'category': '血常规', 'value': 6.2, 'value2': null, 'unit': '10^9/L'},
    ],
  });
  String okBody() => jsonEncode({
        'choices': [
          {'message': {'content': content}},
        ],
      });

  // 含中文的响应体必须走 bytes+utf8（Response(String) 默认 latin1 会抛错）
  http.Response okResp() =>
      http.Response.bytes(utf8.encode(okBody()), 200);

  test('连接被中断 → 自动重试后成功', () async {
    var calls = 0;
    final svc = OcrService(
      baseUrl: 'https://x.invalid',
      apiKey: 'k',
      retryDelay: Duration.zero,
      client: MockClient((req) async {
        calls++;
        if (calls == 1) {
          throw http.ClientException(
              'Software caused connection abort', req.url);
        }
        return okResp();
      }),
    );
    final r = await svc.extract(Uint8List.fromList([1, 2, 3]));
    expect(calls, 2);
    expect(r.title, '血常规检验报告');
    expect(r.metrics.single.name, '白细胞');
  });

  test('5xx / 429 → 重试后成功；重试耗尽返回最后的非 200 由调用方报错', () async {
    var calls = 0;
    final svc = OcrService(
      baseUrl: 'https://x.invalid',
      apiKey: 'k',
      retryDelay: Duration.zero,
      client: MockClient((req) async {
        calls++;
        if (calls == 1) return http.Response('bad gateway', 502);
        if (calls == 2) return http.Response('too many', 429);
        return okResp();
      }),
    );
    final r = await svc.extract(Uint8List.fromList([1]));
    expect(calls, 3);
    expect(r.title, '血常规检验报告');

    var calls2 = 0;
    final svc2 = OcrService(
      baseUrl: 'https://x.invalid',
      apiKey: 'k',
      retryDelay: Duration.zero,
      client: MockClient((req) async {
        calls2++;
        return http.Response('server error', 500);
      }),
    );
    await expectLater(
        svc2.extract(Uint8List.fromList([1])), throwsException);
    expect(calls2, 3);
  });

  test('4xx 客户端错误（Key 错等）不重试直接失败', () async {
    var calls = 0;
    final svc = OcrService(
      baseUrl: 'https://x.invalid',
      apiKey: 'k',
      retryDelay: Duration.zero,
      client: MockClient((req) async {
        calls++;
        return http.Response('unauthorized', 401);
      }),
    );
    await expectLater(
        svc.extract(Uint8List.fromList([1])), throwsException);
    expect(calls, 1);
  });

  test('网络错误重试 3 次耗尽后原样抛出', () async {
    var calls = 0;
    final svc = OcrService(
      baseUrl: 'https://x.invalid',
      apiKey: 'k',
      retryDelay: Duration.zero,
      client: MockClient((req) async {
        calls++;
        throw http.ClientException('connection aborted', req.url);
      }),
    );
    await expectLater(
        svc.extract(Uint8List.fromList([1])),
        throwsA(isA<http.ClientException>()));
    expect(calls, 3);
  });
}
