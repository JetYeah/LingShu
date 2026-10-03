import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db.dart';
import '../../core/theme.dart';
import '../../providers.dart';

/// 心率自测：15/30/60 秒倒计时数脉搏 → 输入计数 → 自动换算次/分
Future<void> showHrMeasureSheet(
    BuildContext context, WidgetRef ref, Metric metric) {
  int duration = 15; // 档位（秒）
  int remain = 0;
  bool counting = false;
  bool finished = false;
  Timer? ticker;
  final beats = TextEditingController();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (c) => StatefulBuilder(
      builder: (c, setSheet) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 18, 20, MediaQuery.of(c).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('自测心率',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          if (!counting && !finished) ...[
            const Text(
                '把两根手指搭在手腕内侧（拇指一侧）或颈侧感受脉搏，\n点开始后跟着倒计时数跳动次数，结束时会震动提醒。',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, height: 1.6, color: LingShuColors.inkSoft)),
            const SizedBox(height: 14),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 15, label: Text('15 秒')),
                ButtonSegment(value: 30, label: Text('30 秒')),
                ButtonSegment(value: 60, label: Text('60 秒')),
              ],
              selected: {duration},
              onSelectionChanged: (s) => setSheet(() => duration = s.first),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  setSheet(() {
                    counting = true;
                    remain = duration;
                  });
                  ticker = Timer.periodic(const Duration(seconds: 1), (t) {
                    if (remain <= 1) {
                      t.cancel();
                      HapticFeedback.heavyImpact();
                      setSheet(() {
                        counting = false;
                        finished = true;
                      });
                    } else {
                      setSheet(() => remain--);
                    }
                  });
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('开始倒计时', style: TextStyle(letterSpacing: 2)),
                ),
              ),
            ),
          ],
          if (counting) ...[
            const SizedBox(height: 6),
            Text('$remain',
                style: const TextStyle(
                    fontSize: 88,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    fontFamily: 'SerifSC',
                    color: WuXing.fire)),
            const Text('数脉搏…',
                style: TextStyle(
                    fontSize: 13, letterSpacing: 4, color: LingShuColors.inkSoft)),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                ticker?.cancel();
                Navigator.pop(c);
              },
              child: const Text('取消'),
            ),
          ],
          if (finished) ...[
            Text('倒计时结束',
                style: TextStyle(
                    fontSize: 12.5, color: WuXing.fire, letterSpacing: 2)),
            const SizedBox(height: 10),
            Text('数到了多少次脉搏？',
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: TextField(
                controller: beats,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  isDense: true,
                  suffixText: '次',
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(height: 10),
            Builder(builder: (c2) {
              final n = int.tryParse(beats.text);
              final bpm = n == null ? null : (n * 60 / duration).round();
              final abnormal = bpm != null && (bpm < 60 || bpm > 100);
              return Text(
                bpm == null ? '' : '≈ $bpm 次/分',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: abnormal ? WuXing.fire : WuXing.wood),
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final n = int.tryParse(beats.text);
                  if (n == null || n <= 0) return;
                  final bpm = (n * 60 / duration).round();
                  final db = ref.read(dbProvider);
                  await db.into(db.metricValues).insert(
                      MetricValuesCompanion.insert(
                        metricId: metric.id,
                        value1: bpm.toDouble(),
                        measuredAt: DateTime.now(),
                        note: Value('$duration 秒计数 $n 次'),
                      ));
                  if (c.mounted) Navigator.pop(c);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('保存', style: TextStyle(letterSpacing: 2)),
                ),
              ),
            ),
            TextButton(
              onPressed: () => setSheet(() {
                finished = false;
                beats.clear();
              }),
              child: const Text('再测一次'),
            ),
          ],
        ]),
      ),
    ),
  ).whenComplete(() => ticker?.cancel());
}
