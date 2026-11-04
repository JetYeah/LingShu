import 'package:flutter_test/flutter_test.dart';

import 'package:lingshu/pages/metrics/metrics_page.dart';

/// 健康追踪模糊搜索：子串 / 按序子序列 / 大小写 / 空格 / 分类单位编码命中
void main() {
  // 空腹血糖 GLU · 血糖类 · mmol/L · code glu_fast
  hit(String query) => metricFuzzyHit(
      '空腹血糖 GLU', '血糖', 'mmol/L', 'glu_fast', query);

  test('子串命中：名称/分类/单位/编码任一', () {
    expect(hit('血糖'), isTrue);
    expect(hit('空腹血糖'), isTrue);
    expect(hit('GLU'), isTrue);
    expect(hit('mmol'), isTrue);
    expect(metricFuzzyHit('糖化血红蛋白 HbA1c', '血糖', '%', 'hba1c', '血红'), isTrue);
    // 分类命中（名称里没有「血糖」二字也行）
    expect(metricFuzzyHit('糖化血红蛋白 HbA1c', '血糖', '%', 'hba1c', '血糖'), isTrue);
    // 编码命中
    expect(metricFuzzyHit('HbA1c', '', '%', 'hba1c', 'hba1c'), isTrue);
  });

  test('按序子序列命中：「空糖」→ 空[腹血]糖', () {
    expect(hit('空糖'), isTrue);
    expect(hit('腹糖'), isTrue);
    expect(hit('gu'), isTrue); // [G]LU 之后的 U
    expect(hit('ft'), isTrue); // F…las[T] 按序
  });

  test('顺序不对不命中', () {
    expect(hit('糖空'), isFalse);
  });

  test('忽略大小写与空格', () {
    expect(hit('glu'), isTrue);
    expect(hit('GLU'), isTrue);
    expect(hit('空 腹'), isTrue); // 空格剥除后为子串
  });

  test('空查询 = 全部命中', () {
    expect(hit(''), isTrue);
    expect(hit('   '), isTrue);
  });

  test('完全不相关不命中', () {
    expect(hit('甲状腺'), isFalse);
    expect(hit('体重'), isFalse);
  });
}
