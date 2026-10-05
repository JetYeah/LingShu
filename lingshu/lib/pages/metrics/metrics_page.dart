import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/db.dart';
import '../../core/services/asr_service.dart';
import '../../core/services/ocr_service.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../providers.dart';
import '../profile/hr_measure_sheet.dart';

/// AI 合并建议：sources 的名称与 target 指向同一检查项，
/// 确认后记录并入 target、删多余条目，必要时统一命名
class _MergeProposal {
  final Metric target;
  final List<Metric> sources;
  final String? renameTo; // target 与 AI 规范名不同时统一命名
  final int valueCount; // 将并入的记录条数
  bool selected = true;
  _MergeProposal({
    required this.target,
    required this.sources,
    required this.valueCount,
    this.renameTo,
  });
}

/// 健康指标列表：按归类标签分组，支持 AI 智能归类
class MetricsPage extends ConsumerStatefulWidget {
  const MetricsPage({super.key});

  @override
  ConsumerState<MetricsPage> createState() => _MetricsPageState();
}

class _MetricsPageState extends ConsumerState<MetricsPage> {
  bool _classifying = false;
  String? _classifyMsg;
  String? _tagFilter; // null = 全部分类；'⭐' = 仅看关注的指标

  static const _followedFilter = '⭐';

  // 常见类别固定排序，其余字母序
  static const _tagOrder = [
    '心血管', '血糖', '血脂', '血常规', '肝胆', '肾脏', '甲状腺',
    '感染免疫', '骨骼关节', '消化', '呼吸', '泌尿生殖', '肿瘤标志物',
    '维生素与代谢', '其他',
  ];

  int _tagCompare(String a, String b) {
    final ia = _tagOrder.indexOf(a), ib = _tagOrder.indexOf(b);
    if (ia >= 0 && ib >= 0) return ia - ib;
    if (ia >= 0) return -1;
    if (ib >= 0) return 1;
    if (a == '未分类') return -1;
    if (b == '未分类') return 1;
    return a.compareTo(b);
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ref.watch(metricsProvider).valueOrNull ?? const <Metric>[];
    // 「⭐」筛选：只看关注的指标
    final followedOnly = _tagFilter == _followedFilter;
    final shown = followedOnly
        ? metrics.where((m) => m.followed).toList()
        : metrics;
    final followedCount = metrics.where((m) => m.followed).length;

    // 按 tag 分组（保持原列表内顺序）
    final groups = <String, List<Metric>>{};
    for (final m in shown) {
      final tag = (m.tag == null || m.tag!.isEmpty) ? '未分类' : m.tag!;
      groups.putIfAbsent(tag, () => []).add(m);
    }
    final sortedTags = groups.keys.toList()..sort(_tagCompare);

    // 快速筛选：只看选中分类
    final visibleTags = followedOnly
        ? sortedTags
        : _tagFilter == null
            ? sortedTags
            : sortedTags.where((t) => t == _tagFilter).toList();
    final visibleGroups = {
      for (final t in visibleTags) t: groups[t]!,
    };
    final visibleMetrics = [for (final t in visibleTags) ...groups[t]!];

    return Scaffold(
      appBar: AppBar(
        title: const Text('健康追踪'),
        actions: [
          if (_classifying)
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
              tooltip: 'AI 整理：归类 + 合并相似项',
              icon: const Icon(Icons.auto_awesome_outlined),
              onPressed: metrics.isEmpty ? null : () => _aiTidy(ref, metrics),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_custom_metric',
        onPressed: () => _addCustomMetric(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('自定义指标'),
      ),
      body: Column(children: [
        // ── 分类标签快速筛选 ──
        if (sortedTags.isNotEmpty)
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _tagChip('全部', metrics.length,
                    selected: _tagFilter == null, onTap: () => setState(() => _tagFilter = null)),
                _tagChip('⭐ 关注', followedCount,
                    selected: followedOnly,
                    onTap: () => setState(() =>
                        _tagFilter = followedOnly ? null : _followedFilter)),
                for (final tag in sortedTags)
                  _tagChip(tag, groups[tag]!.length,
                      selected: _tagFilter == tag,
                      onTap: () => setState(
                          () => _tagFilter = _tagFilter == tag ? null : tag)),
              ],
            ),
          ),
        if (_classifyMsg != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: LingShuColors.gold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_classifyMsg!,
                style: const TextStyle(
                    fontSize: 12.5, color: LingShuColors.gold)),
          ),
        Expanded(
          child: metrics.isEmpty
              ? const Center(
                  child: Text('暂无指标',
                      style: TextStyle(color: LingShuColors.inkSoft)))
              : visibleMetrics.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.star_border_rounded,
                              size: 44, color: LingShuColors.cardBorder),
                          SizedBox(height: 10),
                          Text('还没有关注的指标',
                              style: TextStyle(
                                  fontSize: 13.5,
                                  color: LingShuColors.inkSoft)),
                          SizedBox(height: 6),
                          Text('点击指标卡片右侧的 ☆ 即可关注',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: LingShuColors.inkSoft)),
                        ],
                      ),
                    )
                  : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: visibleMetrics.length + visibleGroups.length,
                  itemBuilder: (context, i) {
                    int idx = 0;
                    for (final tag in visibleTags) {
                      if (i == idx) {
                        return _groupHeader(tag, visibleGroups[tag]!.length);
                      }
                      idx++;
                      final inner = idx + visibleGroups[tag]!.length;
                      if (i < inner) {
                        return _MetricCard(
                            metric: visibleGroups[tag]![i - idx]);
                      }
                      idx = inner;
                    }
                    return const SizedBox.shrink();
                  },
                ),
        ),
      ]),
    );
  }

  Widget _tagChip(String label, int count,
      {required bool selected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? LingShuColors.gold.withValues(alpha: 0.16)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: selected
                    ? LingShuColors.gold
                    : LingShuColors.cardBorder),
          ),
          child: Text('$label $count',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected
                      ? LingShuColors.gold
                      : LingShuColors.inkSoft)),
        ),
      ),
    );
  }

  Widget _groupHeader(String tag, int count) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: LingShuColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: LingShuColors.gold.withValues(alpha: 0.4)),
            ),
            child: Text('$tag · $count',
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: LingShuColors.gold)),
          ),
          const Expanded(
              child: Divider(indent: 10, color: LingShuColors.cardBorder)),
        ]),
      );

  /// ✦ AI 整理：①无标签/「其他」的指标自动归类（已有明确分类不动）；
  /// ②让 AI 找出指向同一检查项的相似名称（OCR 同一项目写法常不同），
  ///   弹窗确认后合并：记录并入保留条目、统一命名、同日同值去重，
  ///   详情页折线图即可看到完整趋势。
  Future<void> _aiTidy(WidgetRef ref, List<Metric> metrics) async {
    final db = ref.read(dbProvider);
    final untagged = metrics
        .where((m) =>
            m.tag == null || m.tag!.isEmpty || m.tag == '其他')
        .map((m) => m.name)
        .toList();
    if (untagged.isEmpty) {
      setState(() => _classifyMsg = '所有指标均已归类，开始查找相似项…');
    }
    setState(() {
      _classifying = true;
      if (untagged.isNotEmpty) _classifyMsg = null;
    });
    final msgParts = <String>[];
    try {
      final svc = await ref.read(aiConfigProvider.future);
      if (svc.apiKey.isEmpty) {
        throw Exception('请先在「我的 → 设置」配置 API Key');
      }

      // ── ① 归类 ──
      if (untagged.isNotEmpty) {
        final mapping = await svc.classifyTags(untagged);
        var updated = 0;
        final nameToTag = <String, String>{};
        mapping.forEach((tag, list) {
          for (final n in list) {
            nameToTag[n] = tag;
          }
        });
        for (final m in metrics.where((m) =>
            m.tag == null || m.tag!.isEmpty || m.tag == '其他')) {
          final tag = nameToTag[m.name];
          if (tag == null || tag.isEmpty || tag == '其他') continue;
          await (db.update(db.metrics)..where((t) => t.id.equals(m.id)))
              .write(MetricsCompanion(tag: Value(tag)));
          updated++;
        }
        msgParts.add('已归类 $updated/${untagged.length} 项');
      }

      // ── ② 相似项合并（失败不影响归类结果） ──
      try {
        final groups =
            await svc.mergeGroups(metrics.map((m) => m.name).toList());
        final proposals = await _resolveProposals(db, groups, metrics);
        if (proposals.isEmpty) {
          msgParts.add('未发现可合并的相似项');
        } else if (mounted) {
          final ok = await _confirmMerges(proposals);
          if (ok == true) {
            var groups0 = 0, moved = 0;
            for (final p in proposals.where((p) => p.selected)) {
              moved += await _applyMerge(db, p);
              groups0++;
            }
            if (groups0 > 0) {
              msgParts.add('合并 $groups0 组、并入 $moved 条记录');
            } else {
              msgParts.add('未选择要合并的组');
            }
          }
        }
      } catch (_) {
        msgParts.add('相似项检查失败');
      }

      if (mounted) {
        setState(() => _classifyMsg = msgParts.isEmpty ? '整理完成' : msgParts.join(' · '));
        Future.delayed(const Duration(seconds: 4),
            () => mounted ? setState(() => _classifyMsg = null) : null);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _classifyMsg = '整理失败：$e');
        Future.delayed(const Duration(seconds: 4),
            () => mounted ? setState(() => _classifyMsg = null) : null);
      }
    } finally {
      if (mounted) setState(() => _classifying = false);
    }
  }

  /// 把 AI 的分组落成可执行建议：名字对回现有指标（防 AI 改写），
  /// 目标取名为 keep 的，否则记录最多的；不足两条的组丢弃
  Future<List<_MergeProposal>> _resolveProposals(
      AppDatabase db, List<MetricMergeGroup> groups, List<Metric> metrics) async {
    final byName = {for (final m in metrics) m.name: m};
    final counts = await _valueCounts(db);
    final out = <_MergeProposal>[];
    for (final g in groups) {
      final members = <Metric>[];
      for (final n in [g.keep, ...g.merge]) {
        final m = byName[n];
        if (m != null && !members.any((x) => x.id == m.id)) members.add(m);
      }
      if (members.length < 2) continue;
      final target = members.firstWhere(
            (m) => m.name == g.keep,
            orElse: () => members.reduce((a, b) =>
                (counts[b.id] ?? 0) > (counts[a.id] ?? 0) ? b : a),
          );
      final sources = members.where((m) => m.id != target.id).toList();
      final moved = sources.fold<int>(0, (s, m) => s + (counts[m.id] ?? 0));
      out.add(_MergeProposal(
        target: target,
        sources: sources,
        valueCount: moved,
        renameTo: target.name == g.keep ? null : g.keep,
      ));
    }
    return out;
  }

  Future<Map<int, int>> _valueCounts(AppDatabase db) async {
    final cnt = db.metricValues.id.count();
    final q = db.selectOnly(db.metricValues)
      ..addColumns([db.metricValues.metricId, cnt])
      ..groupBy([db.metricValues.metricId]);
    final map = <int, int>{};
    for (final row in await q.get()) {
      final id = row.read(db.metricValues.metricId);
      if (id != null) map[id] = row.read(cnt) ?? 0;
    }
    return map;
  }

  Future<bool?> _confirmMerges(List<_MergeProposal> proposals) {
    // useRootNavigator：AI 整理耗时较长，用户常在等待期间切去别的标签页；
    // 默认弹在本分支 navigator 上时页面处于 Offstage，确认框会"消失"，
    // 整理流程也随之挂起。弹到根 navigator 保证任何页面下都立即可见。
    return showDialog<bool>(
      useRootNavigator: true,
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setD) => AlertDialog(
          title: const Text('发现相似指标'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(shrinkWrap: true, children: [
              const Text(
                  '以下名称疑似同一检查项（同一项目在不同报告里写法常不同）。'
                  '合并后记录会追加到保留条目，点开折线图即可看完整趋势：',
                  style: TextStyle(
                      fontSize: 12.5, color: LingShuColors.inkSoft)),
              const SizedBox(height: 4),
              for (final p in proposals)
                CheckboxListTile(
                  dense: true,
                  value: p.selected,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                      '${p.sources.map((m) => m.name).join('、')} → 「${p.renameTo ?? p.target.name}」',
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                      '${p.valueCount} 条记录将并入${p.renameTo != null ? '，统一命名为「${p.renameTo}」' : ''}',
                      style: const TextStyle(
                          fontSize: 11.5, color: LingShuColors.inkSoft)),
                  onChanged: (v) => setD(() => p.selected = v ?? false),
                ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('取消')),
            FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('合并所选')),
          ],
        ),
      ),
    );
  }

  /// 执行合并：记录改挂到目标、删多余条目、按需统一命名，
  /// 最后对目标做同日同值去重（同一报告被存两份的情况）
  Future<int> _applyMerge(AppDatabase db, _MergeProposal p) async {
    var moved = 0;
    for (final s in p.sources) {
      moved += await (db.update(db.metricValues)
            ..where((t) => t.metricId.equals(s.id)))
          .write(MetricValuesCompanion(metricId: Value(p.target.id)));
      await (db.delete(db.metrics)..where((t) => t.id.equals(s.id))).go();
    }
    if (p.renameTo != null && p.renameTo!.isNotEmpty) {
      await (db.update(db.metrics)..where((t) => t.id.equals(p.target.id)))
          .write(MetricsCompanion(name: Value(p.renameTo!)));
    }
    final tid = p.target.id;
    await db.customStatement('''
      DELETE FROM metric_values WHERE metric_id = ? AND id NOT IN (
        SELECT MIN(id) FROM metric_values WHERE metric_id = ?
        GROUP BY date(measured_at, 'unixepoch', 'localtime'), value1, ifnull(value2, -1e12)
      );
    ''', [tid, tid]);
    return moved;
  }

  Future<void> _addCustomMetric(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final unit = TextEditingController();
    final refLow = TextEditingController();
    final refHigh = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('自定义指标'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name,
              decoration: const InputDecoration(labelText: '指标名称（如 尿酸）')),
          const SizedBox(height: 8),
          TextField(controller: unit,
              decoration: const InputDecoration(labelText: '单位（如 μmol/L）')),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: refLow,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '参考下限'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: refHigh,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '参考上限'))),
          ]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('创建')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      final db = ref.read(dbProvider);
      final profileId = ref.read(currentProfileIdProvider);
      if (profileId == null) return;
      await db.into(db.metrics).insert(MetricsCompanion.insert(
            profileId: profileId,
            code: 'custom',
            name: name.text.trim(),
            unit: unit.text.trim(),
            refLow: Value(double.tryParse(refLow.text)),
            refHigh: Value(double.tryParse(refHigh.text)),
            isCustom: const Value(true),
          ));
    }
  }
}

class _MetricCard extends ConsumerWidget {
  final Metric metric;
  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    return LSCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: StreamBuilder<List<MetricValue>>(
        stream: watchMetricValues(db, metric.id),
        builder: (context, snap) {
          final values = snap.data ?? const <MetricValue>[];
          final latest = values.isNotEmpty ? values.first : null;
          final color = WuXing.wood;
                  return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push('/metrics/${metric.id}'),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                SizedBox(
                  width: 72,
                  height: 44,
                  child: values.length < 2
                      ? const SizedBox()
                      : LineChart(_spark(values, color)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(metric.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        latest == null
                            ? '暂无记录，点击添加'
                            : '${DateFormat('MM-dd HH:mm').format(latest.measuredAt)} · '
                                '${latest.value1}${latest.value2 != null ? '/${latest.value2}' : ''} ${metric.unit}',
                        style: const TextStyle(
                            fontSize: 12, color: LingShuColors.inkSoft),
                      ),
                    ],
                  ),
                ),
                // 关注开关：⭐ 金色为已关注
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 34, minHeight: 34),
                  icon: Icon(
                    metric.followed
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 23,
                    color: metric.followed
                        ? LingShuColors.gold
                        : LingShuColors.inkSoft.withValues(alpha: 0.55),
                  ),
                  onPressed: () => _toggleFollow(ref, metric),
                ),
                latest == null
                    ? const SizedBox.shrink()
                    : _abnormalBadge(latest),
                const Icon(Icons.chevron_right, color: LingShuColors.inkSoft),
              ]),
            ),
          );
        },
      ),
    );
  }

  /// 关注/取消关注
  Future<void> _toggleFollow(WidgetRef ref, Metric metric) async {
    final db = ref.read(dbProvider);
    await (db.update(db.metrics)..where((t) => t.id.equals(metric.id)))
        .write(MetricsCompanion(followed: Value(!metric.followed)));
  }

  bool _isAbnormal(MetricValue v) {
    if (metric.dualValue) {
      final sysOk = metric.refLow == null || v.value1 >= metric.refLow!;
      final sysHi = metric.refHigh2 == null || v.value1 <= metric.refHigh2!;
      final diaOk = metric.refLow == null || (v.value2 ?? 0) >= metric.refLow!;
      final diaHi = metric.refHigh == null || (v.value2 ?? 0) <= metric.refHigh!;
      return !(sysOk && sysHi && diaOk && diaHi);
    }
    final lo = metric.refLow == null || v.value1 >= metric.refLow!;
    final hi = metric.refHigh == null || v.value1 <= metric.refHigh!;
    return !(lo && hi);
  }

  Widget _abnormalBadge(MetricValue v) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _isAbnormal(v)
              ? WuXing.fire.withValues(alpha: 0.12)
              : WuXing.wood.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(_isAbnormal(v) ? '偏高/异常' : '正常',
            style: TextStyle(
                fontSize: 10,
                color: _isAbnormal(v) ? WuXing.fire : WuXing.wood)),
      );

  LineChartData _spark(List<MetricValue> values, Color color) {
    final spots = <FlSpot>[];
    for (var i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[values.length - 1 - i].value1));
    }
    return LineChartData(
      lineTouchData: const LineTouchData(enabled: false),
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (spots.length - 1).toDouble().clamp(1, double.infinity),
      minY: _minY(spots),
      maxY: _maxY(spots),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          dotData: const FlDotData(show: false),
          barWidth: 2,
          color: color,
        ),
      ],
    );
  }

  double _minY(List<FlSpot> s) =>
      s.map((e) => e.y).reduce((a, b) => a < b ? a : b) * 0.98;
  double _maxY(List<FlSpot> s) =>
      s.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.02;
}

/// 指标录入对话框（双值指标即血压：附带可选心率，与血压同一时刻入表）
Future<void> showMetricEntry(
    BuildContext context, WidgetRef ref, Metric metric) async {
  final v1 = TextEditingController();
  final v2 = TextEditingController();
  final hr = TextEditingController(); // 仅双值（血压）指标显示
  final note = TextEditingController();
  var date = DateTime.now();
  var timeLabel =
      (metric.code == 'blood_sugar' || metric.name.contains('血糖'))
          ? _defaultTimeLabel(DateTime.now())
          : null;
  const labels = ['空腹', '早餐后', '午餐前', '午餐后', '晚餐前', '晚餐后', '睡前', '随机'];
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (c) => StatefulBuilder(
      builder: (c, setSheet) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(c).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('记录${metric.name}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: TextField(
                controller: v1,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                ],
                decoration: InputDecoration(
                  labelText: metric.dualValue ? '收缩压(高压)' : '数值 (${metric.unit})',
                ),
              ),
            ),
            if (metric.dualValue) ...[
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: v2,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                  ],
                  decoration: const InputDecoration(labelText: '舒张压(低压)'),
                ),
              ),
            ],
          ]),
          if (metric.dualValue) ...[
            const SizedBox(height: 12),
            TextField(
              controller: hr,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: InputDecoration(
                labelText: '心率（选填，次/分）',
                suffixIcon: IconButton(
                  tooltip: '数脉搏自测换算',
                  icon: const Icon(Icons.timer_outlined, size: 20),
                  onPressed: () async {
                    final r = await showHrMeasureSheet(c);
                    if (r != null) setSheet(() => hr.text = '${r.$1}');
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            _SpeechVitalsButton(onFilled: (sys, dia, hrV) {
              setSheet(() {
                v1.text = _fmtNum(sys);
                if (dia != null) v2.text = _fmtNum(dia);
                if (hrV != null) hr.text = _fmtNum(hrV);
              });
            }),
          ],
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                  context: c,
                  initialDate: date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 1)));
              if (d != null) setSheet(() => date = d);
            },
            child: InputDecorator(
              decoration:
                  const InputDecoration(labelText: '测量日期'),
              child: Text(DateFormat('yyyy-MM-dd').format(date)),
            ),
          ),
          const SizedBox(height: 12),
          // 测量时点仅对血糖类指标有意义（空腹/餐后对照参考区间），
          // 血压/体重等显示"晚餐前"只会造成困惑
          if (metric.code == 'blood_sugar' || metric.name.contains('血糖'))
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final lb in labels)
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                        label: Text(lb,
                            style: TextStyle(
                                fontSize: 12,
                                color: timeLabel == lb
                                    ? Colors.white
                                    : LingShuColors.ink)),
                        selected: timeLabel == lb,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) => setSheet(() => timeLabel = lb),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          TextField(controller: note,
              decoration: const InputDecoration(labelText: '备注（选填）')),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final val = double.tryParse(v1.text);
                final hrVal =
                    metric.dualValue ? double.tryParse(hr.text) : null;
                // 血压或心率至少填一项即可保存（只测心率时血压可留空）
                if (val == null && hrVal == null) return;
                Navigator.pop(c, true);
                _saveEntry(metric, val, double.tryParse(v2.text), hrVal, date,
                    note.text, ref,
                    timeLabel: timeLabel);
              },
              child: const Text('保存'),
            ),
          ),
        ]),
      ),
    ),
  );
  if (ok == true) {}
}

String _fmtNum(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

/// 取「心率」指标（按名称匹配，兼容旧数据），没有则创建——
/// 血压对话框里顺带记的心率与自测心率共用同一条趋势
Future<Metric> _ensureHrMetric(AppDatabase db, int profileId) async {
  final hit = await (db.select(db.metrics)
        ..where((t) => t.profileId.equals(profileId) & t.name.equals('心率')))
      .get();
  if (hit.isNotEmpty) return hit.first;
  return db.into(db.metrics).insertReturning(MetricsCompanion.insert(
        profileId: profileId,
        code: 'heart_rate',
        name: '心率',
        unit: '次/分',
        tag: const Value('基础体征'),
        refLow: const Value(60),
        refHigh: const Value(100),
      ));
}

/// 录入落库：血压（可留空）+ 心率（可留空），两者同一时刻
Future<void> _saveEntry(Metric metric, double? v1, double? v2, double? hrVal,
    DateTime date, String note, WidgetRef ref,
    {String? timeLabel}) async {
  if (v1 != null) {
    await _save(metric, v1, v2, date, note, ref, timeLabel: timeLabel);
  }
  if (hrVal != null) {
    final db = ref.read(dbProvider);
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId == null) return;
    final hrMetric = await _ensureHrMetric(db, profileId);
    await _save(hrMetric, hrVal, null, date,
        note.isEmpty ? (v1 != null ? '与血压同测' : '') : note, ref);
  }
}

Future<void> _save(Metric metric, double v1, double? v2, DateTime date,
    String note, WidgetRef ref,
    {String? timeLabel}) async {
  final db = ref.read(dbProvider);
  // 去重：同指标 + 同一自然日 + 同时点 + 同值视为重复录入
  final dayStart = DateTime(date.year, date.month, date.day);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final dup = await (db.select(db.metricValues)
        ..where((t) =>
            t.metricId.equals(metric.id) &
            t.measuredAt.isBiggerOrEqualValue(dayStart) &
            t.measuredAt.isSmallerThanValue(dayEnd) &
            t.value1.equals(v1) &
            (v2 == null ? t.value2.isNull() : t.value2.equals(v2)) &
            (timeLabel == null
                ? t.timeLabel.isNull()
                : t.timeLabel.equals(timeLabel))))
      .get();
  if (dup.isNotEmpty) {
    if (ref.context.mounted) {
      ScaffoldMessenger.of(ref.context).showSnackBar(const SnackBar(
          content: Text('当天该时点已有相同数值，未重复记录'), width: 300));
    }
    return;
  }
  await db.into(db.metricValues).insert(MetricValuesCompanion.insert(
        metricId: metric.id,
        value1: v1,
        value2: Value(v2),
        measuredAt: date,
        note: Value(note.isEmpty ? null : note),
        timeLabel: Value(timeLabel),
      ));
}

/// 按当前时刻智能预选时点：免手动点选，多数情况直接保存即可
String _defaultTimeLabel(DateTime now) {
  final h = now.hour;
  if (h < 9) return '空腹';
  if (h < 11) return '早餐后';
  if (h < 13) return '午餐前';
  if (h < 16) return '午餐后';
  if (h < 19) return '晚餐前';
  if (h < 22) return '晚餐后';
  return '睡前';
}

/// 语音录入按钮：点按开始录音，说完再点按结束 → 转写 → 解析回填高压/低压/心率。
/// 例句「高压一百四，低压九十，心率八十」或直接报数「140 90 80」
class _SpeechVitalsButton extends ConsumerStatefulWidget {
  final void Function(double sys, double? dia, double? hr) onFilled;
  const _SpeechVitalsButton({required this.onFilled});

  @override
  ConsumerState<_SpeechVitalsButton> createState() =>
      _SpeechVitalsButtonState();
}

class _SpeechVitalsButtonState extends ConsumerState<_SpeechVitalsButton> {
  final _recorder = AudioRecorder();
  bool _recording = false;
  bool _busy = false; // 停止后的转写/解析阶段

  @override
  void dispose() {
    // 对话框中途关闭时丢弃未停止的录音
    _recorder.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), width: 340));
  }

  Future<void> _toggle() async {
    if (_busy) return;
    if (!_recording) {
      try {
        if (!await _recorder.hasPermission()) {
          _toast('未获得麦克风权限，无法语音录入');
          return;
        }
        final dir = await getTemporaryDirectory();
        await _recorder.start(
          const RecordConfig(
              encoder: AudioEncoder.wav, numChannels: 1, sampleRate: 16000),
          path: '${dir.path}${Platform.pathSeparator}ls_speech.wav',
        );
        setState(() => _recording = true);
      } catch (e) {
        _toast('无法开始录音：$e');
      }
      return;
    }
    setState(() {
      _recording = false;
      _busy = true;
    });
    try {
      final path = await _recorder.stop();
      final asr = await ref.read(asrConfigProvider.future);
      if (asr.apiKey.isEmpty) {
        _toast('未配置语音识别：请到「我的 → 设置」填写 API Key（可复用 AI 识别的 Key）');
        return;
      }
      if (path == null) {
        _toast('录音失败，请重试');
        return;
      }
      final bytes = await File(path).readAsBytes();
      if (bytes.length < 2000) {
        _toast('录音太短，请说完再点结束');
        return;
      }
      final text = await asr.transcribe(bytes);
      final v = parseVitalsFromSpeech(text);
      if (v == null) {
        _toast('听到「$text」，未解析出数值，请手动填写');
      } else {
        widget.onFilled(v.sys, v.dia, v.hr);
        _toast('已填入：${_fmtNum(v.sys)}'
            '${v.dia != null ? '/${_fmtNum(v.dia!)}' : ''}'
            '${v.hr != null ? ' · 心率 ${_fmtNum(v.hr!)}' : ''}');
      }
    } catch (e) {
      _toast('语音识别失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const SizedBox(
            width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        label: const Text('识别中…'),
      );
    }
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: _recording ? WuXing.fire : WuXing.wood,
        side: BorderSide(
            color:
                _recording ? WuXing.fire : WuXing.wood.withValues(alpha: 0.45)),
      ),
      onPressed: _toggle,
      icon: Icon(_recording ? Icons.stop_circle_outlined : Icons.mic_none,
          size: 20),
      label: Text(_recording ? '正在录音…说完点击结束' : '语音录入（说：高压140 低压90 心率80）'),
    );
  }
}
