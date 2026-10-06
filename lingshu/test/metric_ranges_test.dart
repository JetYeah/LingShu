import 'package:flutter_test/flutter_test.dart';

import 'package:lingshu/core/db.dart';
import 'package:lingshu/pages/metrics/metric_ranges.dart';

/// 指标参考区间与异常判定：血压双值分判、血糖按时点分判、其余指标 ref 兜底。
/// 指南锚：收缩压 90~139 / 舒张压 60~89 mmHg；空腹 3.9~6.1 / 餐后 3.9~7.8 mmol/L。
Metric _metric({
  bool dual = false,
  String code = 'custom',
  String name = '测试指标',
  double? refLow,
  double? refHigh,
  double? refLow2,
  double? refHigh2,
}) =>
    Metric(
      id: 1,
      profileId: 1,
      code: code,
      name: name,
      unit: '',
      dualValue: dual,
      refLow: refLow,
      refHigh: refHigh,
      refLow2: refLow2,
      refHigh2: refHigh2,
      isCustom: false,
      followed: false,
      createdAt: DateTime(2026, 1, 1),
    );

MetricValue _value(double v1, {double? v2, String? timeLabel}) =>
    MetricValue(
      id: 1,
      metricId: 1,
      value1: v1,
      value2: v2,
      measuredAt: DateTime(2026, 10, 6, 8),
      timeLabel: timeLabel,
      source: 'manual',
      createdAt: DateTime(2026, 10, 6, 8),
    );

void main() {
  group('血糖时点分组', () {
    test('空腹与各「前」归餐前系，各「后」归餐后系', () {
      expect(glucoseSlotOf('空腹'), GlucoseSlot.preprandial);
      expect(glucoseSlotOf('午餐前'), GlucoseSlot.preprandial);
      expect(glucoseSlotOf('晚餐前'), GlucoseSlot.preprandial);
      expect(glucoseSlotOf('早餐后'), GlucoseSlot.postprandial);
      expect(glucoseSlotOf('午餐后'), GlucoseSlot.postprandial);
      expect(glucoseSlotOf('晚餐后'), GlucoseSlot.postprandial);
    });

    test('睡前/随机/空标注归未标注（按空腹参考判定）', () {
      expect(glucoseSlotOf('睡前'), GlucoseSlot.unlabeled);
      expect(glucoseSlotOf('随机'), GlucoseSlot.unlabeled);
      expect(glucoseSlotOf(null), GlucoseSlot.unlabeled);
      expect(glucoseSlotOf(''), GlucoseSlot.unlabeled);
    });

    test('血糖类指标识别：code 或名称命中', () {
      expect(isGlucoseMetric(_metric(code: 'blood_sugar', name: '血糖')), isTrue);
      expect(isGlucoseMetric(_metric(name: '空腹血糖')), isTrue);
      expect(isGlucoseMetric(_metric(name: '尿酸')), isFalse);
    });
  });

  group('血压参考区间', () {
    test('未录 ref 回退指南值：收缩 90~139、舒张 60~89', () {
      final m = _metric(dual: true);
      expect(bpSystolicRef(m), (low: 90.0, high: 139.0));
      expect(bpDiastolicRef(m), (low: 60.0, high: 89.0));
    });

    test('指标自身 ref 优先（如医生给的个性化目标）', () {
      final m = _metric(dual: true, refLow: 65, refHigh: 85, refLow2: 100);
      expect(bpSystolicRef(m), (low: 100.0, high: 139.0));
      expect(bpDiastolicRef(m), (low: 65.0, high: 85.0));
    });
  });

  group('血糖参考区间', () {
    test('餐前/未标注用指标 ref（缺省 3.9~6.1），餐后固定 3.9~7.8', () {
      final m = _metric(code: 'blood_sugar', name: '血糖');
      expect(glucoseRef(m, GlucoseSlot.preprandial), (low: 3.9, high: 6.1));
      expect(glucoseRef(m, GlucoseSlot.unlabeled), (low: 3.9, high: 6.1));
      expect(glucoseRef(m, GlucoseSlot.postprandial), (low: 3.9, high: 7.8));
      // 指标录了空腹口径的个性化 ref：餐前跟随，餐后切点不被动它
      final custom = _metric(code: 'blood_sugar', name: '血糖',
          refLow: 4.4, refHigh: 7.0);
      expect(glucoseRef(custom, GlucoseSlot.preprandial), (low: 4.4, high: 7.0));
      expect(glucoseRef(custom, GlucoseSlot.postprandial), (low: 3.9, high: 7.8));
    });
  });

  group('异常判定 isAbnormal', () {
    test('血压：收缩/舒张各判各的；低压未录只判高压', () {
      final m = _metric(dual: true);
      expect(isAbnormal(m, _value(140, v2: 90)), isTrue, reason: '收缩 140≥高血压切点');
      expect(isAbnormal(m, _value(139, v2: 89)), isFalse, reason: '边界值内');
      expect(isAbnormal(m, _value(120, v2: 95)), isTrue, reason: '舒张 95 超上限');
      expect(isAbnormal(m, _value(85, v2: 50)), isTrue, reason: '双低同样异常');
      expect(isAbnormal(m, _value(120)), isFalse, reason: '只录收缩且正常');
      expect(isAbnormal(m, _value(160)), isTrue, reason: '只录收缩但超标');
    });

    test('血糖：同值不同时点判定不同（6.5 空腹超 / 餐后正常）', () {
      final m = _metric(code: 'blood_sugar', name: '血糖');
      expect(isAbnormal(m, _value(6.5, timeLabel: '空腹')), isTrue);
      expect(isAbnormal(m, _value(6.5, timeLabel: '早餐后')), isFalse);
      expect(isAbnormal(m, _value(9.0, timeLabel: '早餐后')), isTrue);
      expect(isAbnormal(m, _value(3.5, timeLabel: '空腹')), isTrue, reason: '低于下限');
      expect(isAbnormal(m, _value(6.5)), isTrue, reason: '未标注按空腹口径');
    });

    test('其余指标：用自身 ref，refs 为空视为正常', () {
      final m = _metric(refLow: 60, refHigh: 100);
      expect(isAbnormal(m, _value(59)), isTrue);
      expect(isAbnormal(m, _value(80)), isFalse);
      expect(isAbnormal(m, _value(101)), isTrue);
      expect(isAbnormal(m, _value(80)), isFalse);
      expect(isAbnormal(_metric(), _value(9999)), isFalse, reason: '无参考无从判定');
    });
  });
}
