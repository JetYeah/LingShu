import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db.dart';
import '../../core/services/content_loader.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../providers.dart';

/// 中医体质辨识（九种体质简化问卷）：一题一页向导式作答，
/// 结果按成员档案持久化（profiles.constitution），下次进入直接回显
class ConstitutionPage extends ConsumerStatefulWidget {
  const ConstitutionPage({super.key});

  @override
  ConsumerState<ConstitutionPage> createState() => _ConstitutionPageState();
}

class _ConstitutionPageState extends ConsumerState<ConstitutionPage> {
  int _step = 0; // 0=介绍, 1=答题, 2=结果
  int _cur = 0; // 当前题（扁平索引）
  List<(int, int)> _flat = const []; // (体质index, 题index) 作答顺序
  final _answers = <int, List<int>>{}; // constitutionIndex -> scores
  Constitution? _result;
  bool _fromSaved = false; // 当前结果来自上次保存而非本次作答
  bool _restoring = false; // 本次会话是否已触发过存档回读
  int? _loadedForProfile;

  static const _labels = ['没有', '很少', '有时', '经常', '总是'];

  List<(int, int)> _flatQuestions(List<Constitution> cs) => [
        for (var i = 0; i < cs.length; i++)
          for (var q = 0; q < cs[i].questions.length; q++) (i, q),
      ];

  void _resetAnswers(List<Constitution> cs) {
    _answers.clear();
    for (var i = 0; i < cs.length; i++) {
      _answers[i] = List.filled(cs[i].questions.length, 0);
    }
    _cur = 0;
    _flat = _flatQuestions(cs);
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(contentProvider);
    if (!content.loaded) {
      content.load().then((_) => mounted ? setState(() {}) : null);
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 每个成员各自记住上次结果：进入页面（或切换档案）时读回 profiles.constitution
    final profileId = ref.watch(currentProfileIdProvider);
    if (_loadedForProfile != profileId) {
      _loadedForProfile = profileId;
      _restoring = false;
      _result = null;
      _fromSaved = false;
      _step = 0;
    }
    if (!_restoring && profileId != null) {
      _restoring = true;
      _restoreSaved(profileId, content);
    }

    return Scaffold(
      appBar: AppBar(title: Text(_step == 2 ? '辨识结果' : '中医体质辨识')),
      body: switch (_step) {
        0 => _intro(content),
        1 => _quiz(content),
        _ => _resultView(content),
      },
    );
  }

  Future<void> _restoreSaved(int profileId, ContentRepo content) async {
    final db = ref.read(dbProvider);
    final row = await ((db.select(db.profiles)
              ..where((t) => t.id.equals(profileId)))
            .getSingleOrNull());
    final name = row?.constitution;
    if (name == null || name.isEmpty) return;
    Constitution? match;
    for (final c in content.constitutions) {
      if (c.name == name) match = c;
    }
    if (match == null || !mounted) return;
    setState(() {
      _result = match;
      _step = 2;
      _fromSaved = true;
    });
  }

  Widget _intro(ContentRepo content) {
    final total = _flatQuestions(content.constitutions).length;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WuXing.earth.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '「王琦九种体质量表」简化版\n\n'
              '体质是身心相对稳定的特质。辨识体质，可以更好地指导饮食起居与养生方向。\n'
              '问卷共 $total 题，一次一题，每题都附有生活化的例子帮助判断，约 3 分钟。',
              style: const TextStyle(fontSize: 13.5, height: 1.7),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => setState(() {
                _resetAnswers(content.constitutions);
                _step = 1;
              }),
              child: const Text('开始答题', style: TextStyle(letterSpacing: 2)),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('结果仅供参考，不能替代中医师面诊',
                style: TextStyle(fontSize: 11, color: LingShuColors.inkSoft)),
          ),
        ],
      ),
    );
  }

  Widget _quiz(ContentRepo content) {
    final cs = content.constitutions;
    if (_flat.isEmpty) {
      _flat = _flatQuestions(cs);
      for (var i = 0; i < cs.length; i++) {
        _answers.putIfAbsent(i, () => List.filled(cs[i].questions.length, 0));
      }
    }
    final total = _flat.length;
    final (ci, qi) = _flat[_cur];
    final c = cs[ci];
    final question = c.questions[qi].replaceAll('（反向计分）', '');
    final example = qi < c.examples.length ? c.examples[qi] : '';
    final picked = _answers[ci]![qi];
    final answered = _answeredCount(cs);
    final last = _cur == total - 1;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('第 ${_cur + 1} / $total 题',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: LingShuColors.inkSoft)),
            const Spacer(),
            Text('${c.name}倾向',
                style: const TextStyle(
                    fontSize: 12, color: LingShuColors.gold)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: answered / total,
              minHeight: 5,
              backgroundColor: LingShuColors.paperDeep,
              valueColor: const AlwaysStoppedAnimation<Color>(WuXing.wood),
            ),
          ),
        ]),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          children: [
            Text(question,
                style: const TextStyle(
                    fontSize: 17, height: 1.5, fontWeight: FontWeight.w700)),
            if (example.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: WuXing.earth.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          size: 15, color: LingShuColors.gold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('例如：$example',
                            style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.6,
                                color: LingShuColors.inkSoft)),
                      ),
                    ]),
              ),
            ],
            const SizedBox(height: 18),
            for (var s = 1; s <= 5; s++) _optionTile(ci, qi, s),
            if (last) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: answered == total ? _finish : null,
                child: const Text('提交并查看结果',
                    style: TextStyle(letterSpacing: 2)),
              ),
            ],
          ],
        ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(children: [
            if (_cur > 0)
              OutlinedButton(
                  onPressed: () => setState(() => _cur--),
                  child: const Text('上一题')),
            const Spacer(),
            if (!last)
              TextButton(
                  onPressed: picked > 0 ? () => setState(() => _cur++) : null,
                  child: const Text('下一题')),
          ]),
        ),
      ),
    ]);
  }

  int _answeredCount(List<Constitution> cs) {
    var n = 0;
    for (var i = 0; i < cs.length; i++) {
      n += _answers[i]!.where((v) => v > 0).length;
    }
    return n;
  }

  void _pick(int ci, int qi, int s) {
    setState(() => _answers[ci]![qi] = s);
    final from = _cur;
    if (from < _flat.length - 1) {
      // 给选中态留出可视反馈后自动进入下一题；手动导航会改变 _cur 使本次延迟失效
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _cur == from) setState(() => _cur = from + 1);
      });
    }
  }

  Widget _optionTile(int ci, int qi, int s) {
    final selected = _answers[ci]![qi] == s;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _pick(ci, qi, s),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? WuXing.wood : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? WuXing.wood : LingShuColors.cardBorder),
          ),
          child: Row(children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 17,
              color: selected ? Colors.white : LingShuColors.inkSoft,
            ),
            const SizedBox(width: 10),
            Text(_labels[s - 1],
                style: TextStyle(
                    fontSize: 13.5,
                    color: selected ? Colors.white : LingShuColors.ink,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w400)),
          ]),
        ),
      ),
    );
  }

  void _finish() {
    final content = ref.read(contentProvider);
    final cs = content.constitutions;
    // 每种体质平均分；标注「反向计分」的题按 6-s 反转后再计
    double avg(int ci) {
      var sum = 0;
      for (var q = 0; q < cs[ci].questions.length; q++) {
        var v = _answers[ci]![q];
        if (cs[ci].questions[q].contains('反向计分')) v = 6 - v;
        sum += v;
      }
      return sum / cs[ci].questions.length;
    }

    final scores = <int, double>{for (var i = 0; i < cs.length; i++) i: avg(i)};
    Constitution? best;
    double bestScore = 0;
    for (var i = 0; i < cs.length; i++) {
      if (cs[i].code == 'pinghe') continue;
      if (scores[i]! > bestScore) {
        bestScore = scores[i]!;
        best = cs[i];
      }
    }
    best ??= cs.firstWhere((c) => c.code == 'pinghe');
    setState(() {
      _result = best;
      _fromSaved = false;
      _step = 2;
    });

    // 保存到当前成员档案
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId != null) {
      final db = ref.read(dbProvider);
      (db.update(db.profiles)..where((t) => t.id.equals(profileId)))
          .write(ProfilesCompanion(
              constitution: Value(best.name)));
    }
  }

  Widget _resultView(ContentRepo content) {
    final c = _result!;
    final color = WuXing.wood;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LSCard(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
              const Text('您的体质倾向为',
                  style: TextStyle(fontSize: 12, color: LingShuColors.inkSoft)),
              const SizedBox(height: 10),
              Text(c.name,
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 6)),
              const SizedBox(height: 10),
              Text(c.desc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, height: 1.6)),
              if (_fromSaved) ...[
                const SizedBox(height: 10),
                const Text('以上为上次测试结果，重新作答可更新',
                    style:
                        TextStyle(fontSize: 11, color: LingShuColors.inkSoft)),
              ],
            ]),
          ),
        const SizedBox(height: 16),
        const Text('养生建议',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final entry in c.advice.entries)
          LSCard(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(_adviceIcon(entry.key), color: color),
              title: Text(entry.key,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text(entry.value,
                  style: const TextStyle(fontSize: 12.5, height: 1.5)),
            ),
          ),
        const SizedBox(height: 12),
        const Text('结果依据简化量表计算，仅供养生参考；如需准确辨证请咨询专业中医师。',
            style: TextStyle(fontSize: 11, color: LingShuColors.inkSoft)),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => setState(() {
            _resetAnswers(content.constitutions);
            _result = null;
            _fromSaved = false;
            _step = 1;
          }),
          child: const Text('重新测试'),
        ),
      ],
    );
  }

  IconData _adviceIcon(String key) => switch (key) {
        '饮食' => Icons.restaurant_outlined,
        '起居' => Icons.bedtime_outlined,
        '运动' => Icons.directions_run_outlined,
        '穴位' => Icons.healing_outlined,
        _ => Icons.spa_outlined,
      };
}
