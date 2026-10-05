import 'dart:typed_data' show Uint8List;

import 'package:flutter_test/flutter_test.dart';

import 'package:lingshu/core/services/agent_service.dart';

/// AI 管家的趋势图离屏渲染：不依赖 widget 树，直接 dart:ui Canvas 出 PNG
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('渲染出血糖趋势 PNG（含参考区间带）', () async {
    final png = await renderTrendChart(
      title: '血糖 · 最近 7 天',
      unit: 'mmol/L',
      points: [
        for (var i = 0; i < 7; i++)
          (DateTime(2026, 9, 20 + i), 5.0 + i * 0.3),
      ],
      refLow: 3.9,
      refHigh: 6.1,
    );
    expect(png, isNotNull);
    final bytes = png as Uint8List;
    // PNG 魔数 + 非空内容
    expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    expect(bytes.lengthInBytes, greaterThan(1000));
  });

  test('无数据点返回 null', () async {
    final png = await renderTrendChart(
        title: '空', unit: '', points: const []);
    expect(png, isNull);
  });
}
