/// 指标参考区间与异常判定：血压双值、血糖分时点，列表卡片与趋势图共用。
///
/// 指南默认值（指标自身 ref* 字段优先，为空时回退——旧指标/报告识别建的
/// 指标没录参考限也能直接显示正常区间）：
/// · 血压（中国高血压防治指南）：收缩压 90~139 mmHg、舒张压 60~89 mmHg，
///   ≥140/90 为高血压。收缩压存 value1（参考 refLow2~refHigh2），
///   舒张压存 value2（参考 refLow~refHigh）。
/// · 血糖（中国 2 型糖尿病防治指南，mmol/L）：餐前/空腹 3.9~6.1
///   （≥7.0 为糖尿病切点）、餐后 2h 3.9~7.8（7.8~11.1 为糖耐量异常），
///   时点存 metric_values.timeLabel。
library;

import '../../core/db.dart';

/// 血压指南区间（mmHg）：收缩压 / 舒张压
const bpSystolicDefault = (low: 90.0, high: 139.0);
const bpDiastolicDefault = (low: 60.0, high: 89.0);

/// 血糖指南区间（mmol/L）：餐前（空腹）/ 餐后 2h
const glucosePreDefault = (low: 3.9, high: 6.1);
const glucosePostDefault = (low: 3.9, high: 7.8);

/// 血糖类指标（预设 code 或名称含「血糖」）
bool isGlucoseMetric(Metric m) =>
    m.code == 'blood_sugar' || m.name.contains('血糖');

/// 血糖时点分组：餐前系（空腹/*前）/餐后系（*后）/未标注（睡前、随机、空）
enum GlucoseSlot { preprandial, postprandial, unlabeled }

GlucoseSlot glucoseSlotOf(String? timeLabel) {
  final t = timeLabel ?? '';
  if (t.contains('后')) return GlucoseSlot.postprandial;
  // 「睡前」也以「前」结尾，但它不是餐前时点，归未标注
  if (t == '空腹' || (t.endsWith('前') && t != '睡前')) {
    return GlucoseSlot.preprandial;
  }
  return GlucoseSlot.unlabeled;
}

/// 收缩压参考（refLow2~refHigh2，缺省回退指南 90~139）
({double low, double high}) bpSystolicRef(Metric m) => (
      low: m.refLow2 ?? bpSystolicDefault.low,
      high: m.refHigh2 ?? bpSystolicDefault.high,
    );

/// 舒张压参考（refLow~refHigh，缺省回退指南 60~89）
({double low, double high}) bpDiastolicRef(Metric m) => (
      low: m.refLow ?? bpDiastolicDefault.low,
      high: m.refHigh ?? bpDiastolicDefault.high,
    );

/// 血糖指定时点的参考区间：餐前/未标注用指标自身 ref（缺省回退空腹
/// 区间——未标注时点按空腹判定是更保守的常规做法），餐后固定指南值
/// （餐后切点与空腹不同，不复用指标上那条空腹参考）。
({double low, double high}) glucoseRef(Metric m, GlucoseSlot slot) {
  switch (slot) {
    case GlucoseSlot.preprandial:
    case GlucoseSlot.unlabeled:
      return (
        low: m.refLow ?? glucosePreDefault.low,
        high: m.refHigh ?? glucosePreDefault.high,
      );
    case GlucoseSlot.postprandial:
      return glucosePostDefault;
  }
}

/// 单条记录是否超出参考区间：
/// · 血压双值各判各的（低压未录则只判高压，不视为异常）；
/// · 血糖按测量时点选区间（餐前/餐后切点不同）；
/// · 其余指标用自身 refLow/refHigh（都为空则无从判定，视为正常）。
bool isAbnormal(Metric m, MetricValue v) {
  if (m.dualValue) {
    final s = bpSystolicRef(m);
    if (v.value1 < s.low || v.value1 > s.high) return true;
    if (v.value2 == null) return false;
    final d = bpDiastolicRef(m);
    return v.value2! < d.low || v.value2! > d.high;
  }
  if (isGlucoseMetric(m)) {
    final r = glucoseRef(m, glucoseSlotOf(v.timeLabel));
    return v.value1 < r.low || v.value1 > r.high;
  }
  return (m.refHigh != null && v.value1 > m.refHigh!) ||
      (m.refLow != null && v.value1 < m.refLow!);
}
