import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../providers.dart';
import 'metrics_page.dart';

/// 指标趋势图
class MetricChartPage extends ConsumerStatefulWidget {
  final int metricId;
  const MetricChartPage({super.key, required this.metricId});

  @override
  ConsumerState<MetricChartPage> createState() => _MetricChartPageState();
}

class _MetricChartPageState extends ConsumerState<MetricChartPage> {
  bool _aiRunning = false;

  /// AI 医学解读：生成通俗解释与评判标准，并把参考上下限写入指标，
  /// 趋势图上的参考带随之出现。结果存 metrics.aiInfo，再次点击可重新生成。
  Future<void> _generateAiInfo(Metric metric, List<MetricValue> values) async {
    if (_aiRunning) return;
    setState(() => _aiRunning = true);
    try {
      final svc = await ref.read(aiConfigProvider.future);
      if (svc.apiKey.isEmpty) {
        throw Exception('请先在「我的 → 设置」配置 API Key');
      }
      final db = ref.read(dbProvider);
      final k = await svc.metricKnowledge(
        name: metric.name,
        unit: metric.unit,
        recentValues: values.length <= 5
            ? values.map((v) => v.value1).toList()
            : values.sublist(values.length - 5).map((v) => v.value1).toList(),
      );
      await (db.update(db.metrics)..where((m) => m.id.equals(metric.id))).write(
        MetricsCompanion(
          aiInfo: Value(jsonEncode({
            'explanation': k.explanation,
            'criteria': k.criteria,
          })),
          // 参考上下限写入指标 → 趋势图参考带；血压等双值指标不套用
          refLow: (!metric.dualValue && k.refLow != null)
              ? Value(k.refLow!)
              : const Value.absent(),
          refHigh: (!metric.dualValue && k.refHigh != null)
              ? Value(k.refHigh!)
              : const Value.absent(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('AI 解读已生成，参考上下限已标到趋势图'),
            width: 320));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('生成失败：$e'), width: 320));
      }
    } finally {
      if (mounted) setState(() => _aiRunning = false);
    }
  }

  /// aiInfo 存的是 JSON（解释+评判标准）；解析失败按纯文本兜底显示
  Widget _aiInfoCard(Metric metric) {
    String explanation = metric.aiInfo ?? '';
    String criteria = '';
    try {
      final j = jsonDecode(metric.aiInfo!) as Map<String, dynamic>;
      explanation = (j['explanation'] ?? '').toString();
      criteria = (j['criteria'] ?? '').toString();
    } catch (_) {}
    return LSCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.auto_awesome, size: 16, color: LingShuColors.gold),
          const SizedBox(width: 6),
          const Text('AI 医学解读',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: LingShuColors.gold)),
          const Spacer(),
          Text('由 AI 生成，仅供参考',
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500)),
        ]),
        const SizedBox(height: 10),
        Text(explanation,
            style: const TextStyle(fontSize: 13.5, height: 1.5)),
        if (criteria.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('常见评判标准',
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(criteria,
              style: const TextStyle(fontSize: 13, height: 1.5)),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    return StreamBuilder<Metric?>(
      stream: (db.select(db.metrics)..where((m) => m.id.equals(widget.metricId)))
          .watchSingleOrNull(),
      builder: (context, metaSnap) {
        final metric = metaSnap.data;
        if (metric == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(metric.name),
            actions: [
              if (_aiRunning)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))),
                )
              else
                IconButton(
                  tooltip: 'AI 医学解读：生成解释与评判标准，参考限标到趋势图',
                  icon: const Icon(Icons.auto_awesome_outlined),
                  onPressed: () async {
                    final values = await (db.select(db.metricValues)
                          ..where((t) => t.metricId.equals(widget.metricId)))
                        .get();
                    if (!mounted) return;
                    values.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
                    _generateAiInfo(metric, values);
                  },
                ),
            ],
          ),
          body: StreamBuilder<List<MetricValue>>(
            stream: watchMetricValues(db, widget.metricId),
            builder: (context, snap) {
              final values = (snap.data ?? const <MetricValue>[])
                  .toList()
                ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
              if (values.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('暂无测量记录',
                          style: TextStyle(color: LingShuColors.inkSoft)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () =>
                            showMetricEntry(context, ref, metric),
                        child: const Text('记录第一次'),
                      ),
                    ],
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _statsCard(metric, values),
                  const SizedBox(height: 16),
                  _chartCard(metric, values),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => showMetricEntry(context, ref, metric),
                    child: const Text('添加记录'),
                  ),
                  const SizedBox(height: 8),
                  ...values.reversed.map((v) => _valueTile(ref, metric, v)),
                  if (metric.aiInfo != null) ...[
                    const SizedBox(height: 16),
                    _aiInfoCard(metric),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  bool _abnormal(Metric metric, MetricValue v) {
    if (metric.dualValue) {
      return (metric.refHigh2 != null && v.value1 > metric.refHigh2!) ||
          (metric.refLow != null && v.value1 < metric.refLow!) ||
          (metric.refHigh != null && (v.value2 ?? 0) > metric.refHigh!);
    }
    return (metric.refHigh != null && v.value1 > metric.refHigh!) ||
        (metric.refLow != null && v.value1 < metric.refLow!);
  }

  Widget _statsCard(Metric metric, List<MetricValue> values) {
    final all = values.map((v) => v.value1).toList();
    final latest = values.last;
    String fmt(double d) =>
        d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toStringAsFixed(1);
    return LSCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('最新',
                style: TextStyle(
                    fontSize: 12, color: WuXing.fromElement(null))),
            const SizedBox(width: 8),
            Text(
              '${fmt(latest.value1)}${latest.value2 != null ? ' / ${fmt(latest.value2!)}' : ''} ${metric.unit}',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _abnormal(metric, latest) ? WuXing.fire : WuXing.wood),
            ),
            const Spacer(),
            if (metric.dualValue)
              Text('mmHg', style: const TextStyle(fontSize: 11, color: LingShuColors.inkSoft)),
          ]),
          if (metric.dualValue)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '参考区间：收缩压 ${metric.refLow2 != null ? fmt(metric.refLow2!) : '—'} ~ ${metric.refHigh2 != null ? fmt(metric.refHigh2!) : '—'} · 舒张压 ${metric.refLow != null ? fmt(metric.refLow!) : '—'} ~ ${metric.refHigh != null ? fmt(metric.refHigh!) : '—'} mmHg',
                style: const TextStyle(
                    fontSize: 12, color: LingShuColors.inkSoft),
              ),
            )
          else if (metric.refLow != null || metric.refHigh != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '参考区间：${metric.refLow != null ? fmt(metric.refLow!) : '—'} ~ ${metric.refHigh != null ? fmt(metric.refHigh!) : '—'} ${metric.unit}',
                style: const TextStyle(
                    fontSize: 12, color: LingShuColors.inkSoft),
              ),
            ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat('记录数', '${values.length}'),
              _stat('平均', fmt(all.reduce((a, b) => a + b) / all.length)),
              _stat('最高', fmt(all.reduce((a, b) => a > b ? a : b))),
              _stat('最低', fmt(all.reduce((a, b) => a < b ? a : b))),
            ],
          ),
        ]),
    );
  }

  Widget _stat(String label, String value) => Column(children: [
        Text(value,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: LingShuColors.inkSoft)),
      ]);

  Widget _chartCard(Metric metric, List<MetricValue> values) {
    final fmt = DateFormat('MM-dd');
    final n = values.length;
    // x 轴用索引（第几次记录）而不是真实时间：
    // 时间轴在记录间隔悬殊时会产生刻度标签重叠、平滑曲线过冲出钩子等问题，
    // 索引轴每个刻度恰好对应一条记录的日期，首尾必有标签且不会互相挤。
    final spots = <FlSpot>[
      for (var i = 0; i < n; i++) FlSpot(i.toDouble(), values[i].value1),
    ];
    double minX = 0;
    double maxX = (n - 1).toDouble();
    if (maxX <= minX) maxX = minX + 1; // 单点时也给出一小段轴
    final ys = spots.map((s) => s.y).toList()
      ..addAll([
        if (metric.refHigh != null) metric.refHigh!,
        if (metric.refLow != null) metric.refLow!,
      ]);
    double minY = ys.reduce((a, b) => a < b ? a : b);
    double maxY = ys.reduce((a, b) => a > b ? a : b);
    final padY = (maxY - minY) * 0.15 + 0.5;
    minY -= padY;
    maxY += padY;

    // x 轴最多显示 5 个刻度（首尾必有），标签取对应记录的日期；
    // 相邻刻度日期相同（同一天多条记录）时只显示一个
    final xInterval = n <= 5 ? 1.0 : (n - 1) / 4;
    final labelIdx = <int>{};
    if (n <= 5) {
      labelIdx.addAll(List.generate(n, (i) => i));
    } else {
      for (var k = 0; k <= 4; k++) {
        labelIdx.add((k * (n - 1) / 4).round());
      }
    }
    final keptIdx = <int>[];
    String? prevDate;
    for (final i in labelIdx.toList()..sort()) {
      final d = fmt.format(values[i].measuredAt);
      if (d != prevDate) {
        keptIdx.add(i);
        prevDate = d;
      }
    }

    // y 轴间隔取"漂亮数"（1/2/2.5/5×10ⁿ），标签不再互相挤
    double niceInterval(double raw) {
      double mag = 1;
      while (mag * 10 <= raw) {
        mag *= 10;
      }
      while (mag > raw) {
        mag /= 10;
      }
      final norm = raw / mag;
      final nice = norm <= 1
          ? 1.0
          : norm <= 2
              ? 2.0
              : norm <= 2.5
                  ? 2.5
                  : norm <= 5
                      ? 5.0
                      : 10.0;
      return nice * mag;
    }

    final hInterval = niceInterval((maxY - minY) / 4);

    return LSCard(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                  metric.dualValue
                      ? '收缩压趋势 (mmHg)'
                      : metric.unit.isEmpty
                          ? '趋势'
                          : '趋势 (${metric.unit})',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: hInterval,
                    getDrawingHorizontalLine: (v) => const FlLine(
                        color: LingShuColors.cardBorder,
                        strokeWidth: 0.6,
                        dashArray: [4, 4]),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 38,
                          // 不显示 min/max 边界标签：与最近刻度挨得太近会互相叠字
                          minIncluded: false,
                          maxIncluded: false,
                          getTitlesWidget: _yLabel),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: xInterval,
                        getTitlesWidget: (v, meta) {
                          final i = (v.round().clamp(0, n - 1));
                          if (!keptIdx.contains(i)) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              fmt.format(values[i].measuredAt),
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: LingShuColors.inkSoft),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: minX,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  betweenBarsData: metric.refHigh != null &&
                          metric.refLow != null &&
                          !metric.dualValue
                      ? [
                          BetweenBarsData(
                            fromIndex: 1,
                            toIndex: 2,
                            color: WuXing.wood.withValues(alpha: 0.10),
                          ),
                        ]
                      : [],
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false, // 真折线：两点间直线，不用平滑弧
                      barWidth: 2.5,
                      color: WuXing.wood,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (s, p, b, i) =>
                            FlDotCirclePainter(radius: 3, color: WuXing.wood),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: WuXing.wood.withValues(alpha: 0.06),
                      ),
                    ),
                    if (metric.refHigh != null && !metric.dualValue)
                      LineChartBarData(
                        spots: [
                          FlSpot(minX, metric.refHigh!),
                          FlSpot(maxX, metric.refHigh!),
                        ],
                        barWidth: 1,
                        color: WuXing.fire.withValues(alpha: 0.5),
                        dotData: const FlDotData(show: false),
                      ),
                    if (metric.refLow != null && !metric.dualValue)
                      LineChartBarData(
                        spots: [
                          FlSpot(minX, metric.refLow!),
                          FlSpot(maxX, metric.refLow!),
                        ],
                        barWidth: 1,
                        color: WuXing.water.withValues(alpha: 0.5),
                        dotData: const FlDotData(show: false),
                      ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots
                          .map((s) => LineTooltipItem(
                                '${s.y.toStringAsFixed(s.y == s.y.roundToDouble() ? 0 : 1)} ${metric.unit}\n'
                                '${fmt.format(DateTime.fromMillisecondsSinceEpoch((s.x * 86400000).round()))}',
                                const TextStyle(
                                    fontSize: 11, color: Colors.white),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  static Widget _yLabel(double v, TitleMeta meta) => Text(
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1),
        style: const TextStyle(fontSize: 10, color: LingShuColors.inkSoft),
      );

  Widget _valueTile(WidgetRef ref, Metric metric, MetricValue v) {
    final abnormal = _abnormal(metric, v);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        abnormal ? Icons.warning_amber_rounded : Icons.check_circle_outline,
        color: abnormal ? WuXing.fire : WuXing.wood,
        size: 20,
      ),
      title: Text(
        '${v.value1}${v.value2 != null ? ' / ${v.value2}' : ''} ${metric.unit}',
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        '${(v.timeLabel == null
                    ? DateFormat('MM-dd HH:mm').format(v.measuredAt)
                    : '${DateFormat('MM-dd').format(v.measuredAt)} ${v.timeLabel}')}'
        '${v.note?.isNotEmpty == true ? ' · ${v.note}' : ''}'
        '${v.source == 'ai' ? ' · 来自报告识别' : ''}',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        onPressed: () async {
          final db = ref.read(dbProvider);
          await db.metricValues.deleteWhere((t) => t.id.equals(v.id));
        },
      ),
    );
  }
}
