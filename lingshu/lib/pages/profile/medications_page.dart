import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/db.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../providers.dart';
import '../metrics/metrics_page.dart' show showMetricEntry;
import 'hr_measure_sheet.dart';

/// 用药提醒主页
class MedicationsPage extends ConsumerStatefulWidget {
  const MedicationsPage({super.key});

  @override
  ConsumerState<MedicationsPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends ConsumerState<MedicationsPage> {
  static const _prefMergedView = 'meds.merged_view';
  bool _merged = false; // 同一时间点的药合并成一张卡显示

  @override
  void initState() {
    super.initState();
    _merged =
        ref.read(sharedPreferencesProvider).getBool(_prefMergedView) ?? false;
    // 打开用药页时把全部在服药物的通知按新方案（周几重复）重排一遍：
    // 升级后清掉旧版"每天"通知，改用各药设置的重复日期
    _rescheduleAll();
  }

  void _toggleMerged() {
    setState(() => _merged = !_merged);
    ref.read(sharedPreferencesProvider).setBool(_prefMergedView, _merged);
  }

  Future<void> _rescheduleAll() async {
    final db = ref.read(dbProvider);
    final notif = ref.read(notificationServiceProvider);
    final meds = await (db.select(db.medications)
          ..where((t) => t.active.equals(true)))
        .get();
    for (final m in meds) {
      await notif.rescheduleMedication(
        medicationId: m.id,
        times: (jsonDecode(m.timesOfDay) as List).cast<String>(),
        days: (jsonDecode(m.daysOfWeek ?? '[1,2,3,4,5,6,7]') as List)
            .map((e) => int.parse(e.toString()))
            .toSet(),
        startDate: m.startDate,
        endDate: m.endDate,
        pauses: (jsonDecode(m.pausePeriods ?? '[]') as List)
            .map((e) => (DateTime.parse((e as Map)['f'] as String),
                DateTime.parse(e['t'] as String)))
            .toList(),
        title: '灵枢 · 用药提醒',
        body: '${m.name}${m.dosage?.isNotEmpty == true ? '（${m.dosage}）' : ''}'
            ' · ${m.mealRelation ?? ''}服用',
      );
    }
  }

  /// 日常记录：快速录入血糖/血压/体重等居家数据，进入健康追踪趋势图，
  /// 与医院检验报告（拍照归档识别）分开，居家自测与院检在图上合并看趋势
  Future<void> _quickRecord(String name, String unit,
      {bool dual = false, String code = 'custom', String tag = '基础体征'}) async {
    final metric = await _ensureMetric(name, unit,
        dual: dual, code: code, tag: tag);
    if (metric == null || !mounted) return;
    await showMetricEntry(context, ref, metric);
  }

  Future<Metric?> _ensureMetric(String name, String unit,
      {bool dual = false,
      String code = 'custom',
      String tag = '基础体征',
      double? refLow,
      double? refHigh}) async {
    final db = ref.read(dbProvider);
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId == null) return null;
    final hit = await (db.select(db.metrics)
          ..where((t) => t.profileId.equals(profileId) & t.name.equals(name)))
        .get();
    if (hit.isNotEmpty) return hit.first;
    return db.into(db.metrics).insertReturning(MetricsCompanion.insert(
      profileId: profileId,
      code: code,
      name: name,
      unit: unit,
      dualValue: Value(dual),
      tag: Value(tag),
      refLow: Value(refLow),
      refHigh: Value(refHigh),
    ));
  }

  /// 心率自测：15/30/60 秒倒计时数脉搏，自动换算次/分
  Future<void> _measureHr() async {
    final metric = await _ensureMetric('心率', '次/分', refLow: 60, refHigh: 100);
    if (metric == null || !mounted) return;
    await showHrMeasureSheet(context, ref, metric);
  }

  @override
  Widget build(BuildContext context) {
    final meds = ref.watch(medicationsProvider).valueOrNull ?? const [];
    final db = ref.watch(dbProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('用药提醒'),
        actions: [
          IconButton(
            tooltip: _merged ? '切换为按药物显示' : '同一时间的药合并显示',
            icon: Icon(_merged ? Icons.merge_type : Icons.view_agenda_outlined,
                color: _merged ? WuXing.water : null),
            onPressed: _toggleMerged,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_med',
        onPressed: () => context.push('/medications/edit'),
        icon: const Icon(Icons.add),
        label: const Text('添加药物'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: [
          _dailyRecordCard(),
          const SizedBox(height: 10),
          if (meds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(children: [
                Icon(Icons.medication_liquid_outlined,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                const Text('还没有添加药物',
                    style: TextStyle(color: LingShuColors.inkSoft)),
              ]),
            )
          else ...[
            _todayHeader(db, meds),
            const SizedBox(height: 8),
            if (_merged)
              ..._mergedCards(meds)
            else
              for (final m in meds) _MedCard(med: m),
          ],
        ],
      ),
    );
  }

  Widget _dailyRecordCard() {
    return LSCard(
      color: WuXing.wood.withValues(alpha: 0.05),
      border: Border.all(color: WuXing.wood.withValues(alpha: 0.22)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.monitor_heart_outlined, color: WuXing.wood, size: 19),
            const SizedBox(width: 8),
            const Text('日常记录',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('居家自测 · 趋势图',
                style: TextStyle(
                    fontSize: 10.5, color: LingShuColors.inkSoft)),
          ]),
          const SizedBox(height: 4),
          Text('在家量的数据随手记，进入健康追踪趋势图；与医院检验报告分开管理',
              style: TextStyle(
                  fontSize: 11, height: 1.4, color: LingShuColors.inkSoft)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.favorite_border, size: 15),
                label: const Text('血压'),
                onPressed: () =>
                    _quickRecord('血压', 'mmHg', dual: true, code: 'blood_pressure'),
              ),
              ActionChip(
                avatar: const Icon(Icons.water_drop_outlined, size: 15),
                label: const Text('血糖'),
                onPressed: () => _quickRecord('血糖', 'mmol/L', tag: '血糖'),
              ),
              ActionChip(
                avatar: const Icon(Icons.monitor_weight_outlined, size: 15),
                label: const Text('体重'),
                onPressed: () => _quickRecord('体重', 'kg'),
              ),
              ActionChip(
                avatar: const Icon(Icons.timer_outlined, size: 15),
                label: const Text('心率'),
                onPressed: _measureHr,
              ),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _todayHeader(AppDatabase db, List<Medication> meds) {
    return LSCard(
      color: WuXing.water.withValues(alpha: 0.06),
      border: Border.all(color: WuXing.water.withValues(alpha: 0.22)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: StreamBuilder<List<MedicationLog>>(
          stream: _todayLogs(db, meds),
          builder: (context, snap) {
            final logs = snap.data ?? const [];
            final taken = logs.where((l) => l.status == 'taken').length;
            return Row(children: [
              const Icon(Icons.alarm, color: WuXing.water),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '今日服药 $taken / ${logs.isEmpty ? 0 : logs.length} 次',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                DateFormat('M月d日 EEEE', 'zh_CN').format(DateTime.now()),
                style: const TextStyle(
                    fontSize: 12, color: LingShuColors.inkSoft),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Stream<List<MedicationLog>> _todayLogs(
      AppDatabase db, List<Medication> meds) {
    if (meds.isEmpty) return Stream.value(const []);
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return (db.select(db.medicationLogs)
          ..where((l) =>
              l.scheduledAt.isBiggerOrEqualValue(dayStart) &
              l.scheduledAt.isSmallerThanValue(dayEnd)))
        .watch();
  }

  /// 合并视图：今天在服的药按时间点分组，同一 HH:mm 的多种药合为一张卡；
  /// 今日不用服的药（未开始/已结束/暂停/休药）单独列在下方
  List<Widget> _mergedCards(List<Medication> meds) {
    final active = <Medication>[];
    final inactive = <(Medication, String)>[];
    for (final m in meds) {
      final (ok, status) = medTodayStatus(m);
      if (ok) {
        active.add(m);
      } else {
        inactive.add((m, status ?? '今日休药'));
      }
    }
    final groups = <String, List<Medication>>{};
    for (final m in active) {
      for (final t in (jsonDecode(m.timesOfDay) as List).cast<String>()) {
        groups.putIfAbsent(t, () => []).add(m);
      }
    }
    int mins(String t) =>
        int.parse(t.split(':')[0]) * 60 + int.parse(t.split(':')[1]);
    final times = groups.keys.toList()
      ..sort((a, b) => mins(a).compareTo(mins(b)));
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text('同一时间服的药已合并为一张卡 · 点药名可编辑，底部按钮一键打卡（长按跳过）',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: LingShuColors.inkSoft)),
      ),
      for (final t in times) _MergedTimeCard(time: t, meds: groups[t]!),
      if (inactive.isNotEmpty) ...[
        const Padding(
          padding: EdgeInsets.only(top: 4, bottom: 8),
          child: Text('今日不提醒',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: LingShuColors.inkSoft)),
        ),
        for (final (m, status) in inactive)
          LSCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            onTap: () => context.push('/medications/edit?id=${m.id}'),
            child: Row(children: [
              const Icon(Icons.block_flipped,
                  size: 15, color: LingShuColors.inkSoft),
              const SizedBox(width: 8),
              Expanded(
                child: Text(m.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13.5)),
              ),
              Text('今日 $status',
                  style: const TextStyle(
                      fontSize: 11.5, color: LingShuColors.inkSoft)),
            ]),
          ),
      ],
    ];
  }
}

class _MedCard extends ConsumerWidget {
  final Medication med;
  const _MedCard({required this.med});

  List<String> get _times =>
      (jsonDecode(med.timesOfDay) as List).cast<String>();

  static const _weekLabels = ['一', '二', '三', '四', '五', '六', '日'];

  String get _repeatLabel {
    final days = (jsonDecode(med.daysOfWeek ?? '[1,2,3,4,5,6,7]') as List)
        .map((e) => int.parse(e.toString()))
        .toSet();
    if (days.length == 7 || days.isEmpty) return '每天';
    final sorted = days.toList()..sort();
    return sorted.map((d) => '周${_weekLabels[d - 1]}').join();
  }

  List<(DateTime, DateTime)> get _pauses => medPauses(med);

  /// 区间/暂停摘要行（无内容返回空串）
  String get _periodLabel {
    final parts = <String>[];
    String d2(DateTime d) =>
        '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    if (med.startDate != null || med.endDate != null) {
      parts.add('${med.startDate != null ? d2(med.startDate!) : '起'}'
          '~${med.endDate != null ? d2(med.endDate!) : '止'}');
    }
    if (_pauses.isNotEmpty) {
      parts.add('暂停 ${_pauses.map((pg) => '${d2(pg.$1)}~${d2(pg.$2)}').join('、')}');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    final now = DateTime.now();
    return LSCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: WuXing.wood.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.medication, color: WuXing.wood, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(med.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(
                      [
                        if (med.dosage?.isNotEmpty == true) med.dosage!,
                        if (med.mealRelation?.isNotEmpty == true)
                          med.mealRelation!,
                        '每日 ${_times.length} 次',
                        _repeatLabel,
                        if (_periodLabel.isNotEmpty) _periodLabel,
                      ].join(' · '),
                      style: const TextStyle(
                          fontSize: 12, color: LingShuColors.inkSoft),
                    ),
                  ]),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => context.push('/medications/edit?id=${med.id}'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('停用药物'),
                    content: Text('确定停用「${med.name}」并取消提醒吗？'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('取消')),
                      FilledButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('停用')),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref
                      .read(notificationServiceProvider)
                      .cancelForMedication(med.id);
                  await (db.update(db.medications)
                        ..where((t) => t.id.equals(med.id)))
                      .write(const MedicationsCompanion(active: Value(false)));
                }
              },
            ),
          ]),
          const SizedBox(height: 10),
          Builder(builder: (context) {
            final (active, status) = medTodayStatus(med);
            if (!active) {
              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: LingShuColors.paperDeep.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.block_flipped,
                      size: 15, color: LingShuColors.inkSoft),
                  const SizedBox(width: 6),
                  Text('今日 $status · 不用服药',
                      style: const TextStyle(
                          fontSize: 12, color: LingShuColors.inkSoft)),
                ]),
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in _times) _timeChip(db, t, now),
              ],
            );
          }),
        ]),
    );
  }

  Widget _timeChip(AppDatabase db, String time, DateTime now) {
    final scheduled = DateTime(now.year, now.month, now.day,
        int.parse(time.split(':')[0]), int.parse(time.split(':')[1]));
    return StreamBuilder<List<MedicationLog>>(
      stream: watchMedLogsForDay(db, med.id, scheduled),
      builder: (context, snap) {
        final logs = snap.data ?? const <MedicationLog>[];
        final taken = logs.any((l) => l.status == 'taken');
        final skipped = !taken && logs.any((l) => l.status == 'skipped');
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: taken
              ? null
              : () => markMedTaken(db, med.id, scheduled, taken: true),
          onLongPress:
              taken ? null : () => markMedTaken(db, med.id, scheduled, taken: false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: taken
                  ? WuXing.wood.withValues(alpha: 0.14)
                  : skipped
                      ? LingShuColors.paperDeep
                      : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: taken
                    ? WuXing.wood
                    : skipped
                        ? LingShuColors.cardBorder
                        : WuXing.water.withValues(alpha: 0.5),
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                taken ? Icons.check_circle : skipped ? Icons.close : Icons.alarm,
                size: 15,
                color: taken
                    ? WuXing.wood
                    : skipped
                        ? LingShuColors.inkSoft
                        : WuXing.water,
              ),
              const SizedBox(width: 6),
              Text(time,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: skipped ? LingShuColors.inkSoft : null,
                      decoration:
                          skipped ? TextDecoration.lineThrough : null)),
            ]),
          ),
        );
      },
    );
  }
}

Stream<List<MedicationLog>> watchMedLogsForDay(
    AppDatabase db, int medId, DateTime scheduled) {
  final start = scheduled.subtract(const Duration(minutes: 30));
  final end = scheduled.add(const Duration(minutes: 30));
  return (db.select(db.medicationLogs)
        ..where((l) =>
            l.medicationId.equals(medId) &
            l.scheduledAt.isBiggerOrEqualValue(start) &
            l.scheduledAt.isSmallerOrEqualValue(end)))
      .watch();
}

/// 合并卡用：一次 watch 同一时间点多种药的打卡记录（±30 分钟窗口，
/// 与 watchMedLogsForDay 的判定窗口保持一致）
Stream<List<MedicationLog>> watchMedLogsForGroup(
    AppDatabase db, List<int> medIds, DateTime scheduled) {
  final start = scheduled.subtract(const Duration(minutes: 30));
  final end = scheduled.add(const Duration(minutes: 30));
  return (db.select(db.medicationLogs)
        ..where((l) =>
            l.medicationId.isIn(medIds) &
            l.scheduledAt.isBiggerOrEqualValue(start) &
            l.scheduledAt.isSmallerOrEqualValue(end)))
      .watch();
}

/// 解析药物暂停时段 [(from, to)]（合并卡与单药卡共用）
List<(DateTime, DateTime)> medPauses(Medication med) =>
    (jsonDecode(med.pausePeriods ?? '[]') as List)
        .map((e) => (DateTime.parse((e as Map)['f'] as String),
            DateTime.parse(e['t'] as String)))
        .toList();

/// 今天是否处于服药状态（区间内、非暂停、周几命中）；不命中时返回原因
(bool, String?) medTodayStatus(Medication med) {
  final now = DateTime.now();
  final d = DateTime(now.year, now.month, now.day);
  if (med.startDate != null &&
      d.isBefore(DateTime(
          med.startDate!.year, med.startDate!.month, med.startDate!.day))) {
    return (false, '未开始');
  }
  if (med.endDate != null) {
    final end = DateTime(med.endDate!.year, med.endDate!.month, med.endDate!.day);
    if (d.isAfter(end)) return (false, '已结束');
  }
  for (final pg in medPauses(med)) {
    final f = DateTime(pg.$1.year, pg.$1.month, pg.$1.day);
    final t = DateTime(pg.$2.year, pg.$2.month, pg.$2.day);
    if (!d.isBefore(f) && !d.isAfter(t)) return (false, '暂停中');
  }
  final days = (jsonDecode(med.daysOfWeek ?? '[1,2,3,4,5,6,7]') as List)
      .map((e) => int.parse(e.toString()))
      .toSet();
  if (days.isNotEmpty && !days.contains(now.weekday)) {
    return (false, '今日休药');
  }
  return (true, null);
}

/// 打一条服药记录（taken=true 服用 / false 跳过）
Future<void> markMedTaken(AppDatabase db, int medId, DateTime scheduled,
    {required bool taken}) async {
  await db.into(db.medicationLogs).insert(MedicationLogsCompanion.insert(
        medicationId: medId,
        scheduledAt: scheduled,
        status: taken ? 'taken' : 'skipped',
        takenAt: Value(taken ? DateTime.now() : null),
      ));
}

/// 合并卡：同一时间点的多种药合为一张卡，一起显示、一键打卡；
/// 点药名进编辑，底部按钮点按=全部服用、长按=全部跳过
class _MergedTimeCard extends ConsumerWidget {
  final String time;
  final List<Medication> meds;
  const _MergedTimeCard({required this.time, required this.meds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    final now = DateTime.now();
    final scheduled = DateTime(now.year, now.month, now.day,
        int.parse(time.split(':')[0]), int.parse(time.split(':')[1]));
    return LSCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: StreamBuilder<List<MedicationLog>>(
        stream: watchMedLogsForGroup(
            db, [for (final m in meds) m.id], scheduled),
        builder: (context, snap) {
          final logs = snap.data ?? const <MedicationLog>[];
          bool takenOf(int medId) =>
              logs.any((l) => l.medicationId == medId && l.status == 'taken');
          bool skippedOf(int medId) =>
              !takenOf(medId) &&
              logs.any((l) => l.medicationId == medId && l.status == 'skipped');
          final takenCount = meds.where((m) => takenOf(m.id)).length;
          final allTaken = takenCount == meds.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: WuXing.water.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.alarm, color: WuXing.water, size: 20),
                ),
                const SizedBox(width: 10),
                Text(time,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 17)),
                const SizedBox(width: 8),
                Text('${meds.length} 种药',
                    style: const TextStyle(
                        fontSize: 12, color: LingShuColors.inkSoft)),
                const Spacer(),
                Text(
                    allTaken ? '已完成' : '已服 $takenCount/${meds.length}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: allTaken ? WuXing.wood : LingShuColors.inkSoft)),
              ]),
              const Divider(height: 18),
              for (final m in meds)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.push('/medications/edit?id=${m.id}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      Icon(
                        takenOf(m.id)
                            ? Icons.check_circle
                            : skippedOf(m.id)
                                ? Icons.close
                                : Icons.medication,
                        size: 16,
                        color: takenOf(m.id)
                            ? WuXing.wood
                            : skippedOf(m.id)
                                ? LingShuColors.inkSoft
                                : WuXing.wood.withValues(alpha: 0.55),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          [
                            m.name,
                            if (m.dosage?.isNotEmpty == true) '（${m.dosage}）',
                          ].join(),
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color:
                                  skippedOf(m.id) ? LingShuColors.inkSoft : null,
                              decoration: skippedOf(m.id)
                                  ? TextDecoration.lineThrough
                                  : null),
                        ),
                      ),
                      if (m.mealRelation?.isNotEmpty == true)
                        Text(m.mealRelation!,
                            style: const TextStyle(
                                fontSize: 11.5,
                                color: LingShuColors.inkSoft)),
                    ]),
                  ),
                ),
              const SizedBox(height: 8),
              if (allTaken)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: WuXing.wood.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.done_all, size: 15, color: WuXing.wood),
                      const SizedBox(width: 6),
                      Text('这一时间的药已全部服用',
                          style: const TextStyle(
                              fontSize: 12.5, color: WuXing.wood)),
                    ],
                  ),
                )
            else
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _markGroup(
                    db, scheduled, meds.where((m) => !takenOf(m.id)),
                    taken: true),
                onLongPress: () => _markGroup(
                    db, scheduled,
                    meds.where(
                        (m) => !takenOf(m.id) && !skippedOf(m.id)),
                    taken: false),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: WuXing.water.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.done_all,
                          size: 15, color: WuXing.water),
                      const SizedBox(width: 6),
                      Text(
                          takenCount > 0
                              ? '打卡其余 ${meds.length - takenCount} 种'
                              : '一键打卡 ${meds.length} 种',
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: WuXing.water)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _markGroup(AppDatabase db, DateTime scheduled,
      Iterable<Medication> targets, {required bool taken}) async {
    for (final m in targets) {
      await markMedTaken(db, m.id, scheduled, taken: taken);
    }
  }
}
