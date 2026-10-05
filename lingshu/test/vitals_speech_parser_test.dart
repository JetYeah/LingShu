import 'package:flutter_test/flutter_test.dart';

import 'package:lingshu/core/services/asr_service.dart';

/// 口述血压/心率解析：关键词、中文数字、纯报数三种说法
void main() {
  void expectVitals(String text, double sys, double? dia, double? hr) {
    final v = parseVitalsFromSpeech(text);
    expect(v, isNotNull, reason: '「$text」应解析成功');
    expect(v!.sys, sys, reason: '「$text」高压');
    expect(v.dia, dia, reason: '「$text」低压');
    expect(v.hr, hr, reason: '「$text」心率');
  }

  test('阿拉伯数字 + 关键词', () {
    expectVitals('高压140 低压90 心率80', 140, 90, 80);
    expectVitals('收缩压120，舒张压85，脉搏76', 120, 85, 76);
    expectVitals('高压135 心率78 低压88', 135, 88, 78);
  });

  test('中文数字 + 关键词', () {
    expectVitals('高压一百四，低压九十，心率八十', 140, 90, 80);
    expectVitals('收缩压一百二十 舒张压八十 脉搏七十五', 120, 80, 75);
    expectVitals('高压一百零五，低压七十', 105, 70, null);
  });

  test('纯报数按顺序', () {
    expectVitals('140 90 80', 140, 90, 80);
    expectVitals('140，90', 140, 90, null);
    expectVitals('一百四十 九十 八十', 140, 90, 80);
  });

  test('只报开头关键词，后续数字按序补位', () {
    expectVitals('血压130/85', 130, 85, null);
    expectVitals('血压130 85 76', 130, 85, 76);
    expectVitals('高压140，90，80', 140, 90, 80);
  });

  test('前置无关数字不干扰', () {
    expectVitals('血糖5.8 血压130 85', 130, 85, null);
  });

  test('解析不出数值返回 null', () {
    expect(parseVitalsFromSpeech('今天天气不错'), isNull);
    expect(parseVitalsFromSpeech(''), isNull);
    expect(parseVitalsFromSpeech('血压有点高'), isNull);
  });
}
