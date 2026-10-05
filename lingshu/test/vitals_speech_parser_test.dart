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

  test('血糖口述：数值 + 空腹/餐后时点 + 日期', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime oct3() {
      var d = DateTime(now.year, 10, 3);
      if (d.isAfter(today)) d = DateTime(now.year - 1, 10, 3);
      return d;
    }

    final s1 = parseVitalsFromSpeech('空腹血糖6.8', preferSugar: true)!;
    expect(s1.sys, 6.8);
    expect(s1.period, '空腹');

    // 「六点八」的小数口述
    final s2 = parseVitalsFromSpeech('血糖六点八', preferSugar: true)!;
    expect(s2.sys, 6.8);

    final s3 = parseVitalsFromSpeech('昨天早餐后 9.2', preferSugar: true)!;
    final yst = today.subtract(const Duration(days: 1));
    expect(s3.sys, 9.2);
    expect(s3.period, '早餐后');
    expect(s3.date, yst);

    // 「晚饭后」映射到「晚餐后」；日期含数字不混入取值
    final s4 = parseVitalsFromSpeech('10月3号晚饭后血糖7.4', preferSugar: true)!;
    expect(s4.date, oct3());
    expect(s4.period, '晚餐后');
    expect(s4.sys, 7.4);

    // 明说血糖（即使不在血糖对话框）也走血糖解析
    final s5 = parseVitalsFromSpeech('空腹血糖5.9')!;
    expect(s5.sys, 5.9);
    expect(s5.period, '空腹');

    // 混合句「血糖…血压…」仍按血压归位（血糖数值作为前置无关数字跳过）
    final v = parseVitalsFromSpeech('血糖5.8 血压130 85')!;
    expect(v.sys, 130);
    expect(v.dia, 85);
    expect(v.period, isNull);
  });

  test('日期与时段一并解析', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 「10月3号」的期望年份与实现同规则：未说年份且指向未来按去年理解
    DateTime oct3() {
      var d = DateTime(now.year, 10, 3);
      if (d.isAfter(today)) d = DateTime(now.year - 1, 10, 3);
      return d;
    }

    final v = parseVitalsFromSpeech('昨天早上 高压140 低压90 心率80')!;
    final yst = today.subtract(const Duration(days: 1));
    expect(v.date, yst);
    expect(v.period, '早上');
    expect(v.sys, 140);
    expect(v.dia, 90);
    expect(v.hr, 80);

    final v2 = parseVitalsFromSpeech('10月3号晚上 血压130 85')!;
    expect(v2.date, oct3());
    expect(v2.period, '晚上');
    expect(v2.sys, 130);
    expect(v2.dia, 85);

    final v3 = parseVitalsFromSpeech('十月三号 早晨 高压一百三')!;
    expect(v3.date, oct3());
    expect(v3.period, '早上');
    expect(v3.sys, 130);

    final v4 = parseVitalsFromSpeech('前天中午 140 90')!;
    final qqt = today.subtract(const Duration(days: 2));
    expect(v4.date, qqt);
    expect(v4.period, '中午');

    // 日期里的数字不能混进数值序列
    final v5 = parseVitalsFromSpeech('10月3号 140 90 80')!;
    expect(v5.date, oct3());
    expect(v5.sys, 140);
    expect(v5.dia, 90);
    expect(v5.hr, 80);

    // 没说日期时段时不误报
    final v6 = parseVitalsFromSpeech('高压140 低压90')!;
    expect(v6.date, isNull);
    expect(v6.period, isNull);
  });
}
