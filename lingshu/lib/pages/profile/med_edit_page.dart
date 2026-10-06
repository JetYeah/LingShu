import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../core/db.dart';
import '../../core/services/ocr_service.dart';
import '../../core/theme.dart';
import '../../providers.dart';

/// 新建/编辑药物
class MedEditPage extends ConsumerStatefulWidget {
  final int? medId;
  const MedEditPage({super.key, this.medId});

  @override
  ConsumerState<MedEditPage> createState() => _MedEditPageState();
}

class _MedEditPageState extends ConsumerState<MedEditPage> {
  static const _alarmChannel = MethodChannel('lingshu/alarm');
  final _name = TextEditingController();
  final _dosage = TextEditingController();
  final _note = TextEditingController();
  final _stock = TextEditingController();
  String _mealRelation = '餐后';
  List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  final Set<int> _days = {1, 2, 3, 4, 5, 6, 7}; // Dart weekday；全选=每天
  DateTime? _startDate; // 服用开始日（空=长期）
  DateTime? _endDate; // 服用结束日（空=长期）
  final List<(DateTime, DateTime)> _pauses = []; // 暂停时段

  // 处方/说明书拍照识别（仅新增模式）
  final List<String> _photos = [];
  bool _aiRunning = false;
  final List<MedDraft> _pending = []; // 多种药：逐种预填核对，保存后进下一种
  bool _saving = false; // 保存中：禁用按钮防重复提交，也给慢速重排一个可见反馈

  // 旧值（餐前/餐中/餐后/空腹/睡前）保留在尾部：历史数据仍在用，删除会导致下拉框回显失败
  static const _mealRelations = [
    '早餐前', '早餐后', '午餐前', '午餐后', '晚餐前', '晚餐后',
    '餐前', '餐中', '餐后', '空腹', '睡前',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.medId != null) _load();
  }

  Future<void> _load() async {
    final db = ref.read(dbProvider);
    final m = await (db.select(db.medications)
          ..where((t) => t.id.equals(widget.medId!)))
        .getSingleOrNull();
    if (m == null) return;
    _name.text = m.name;
    _dosage.text = m.dosage ?? '';
    _note.text = m.note ?? '';
    _stock.text = m.stock?.toString() ?? '';
    _mealRelation = m.mealRelation ?? '餐后';
    _times = ((jsonDecode(m.timesOfDay) as List).cast<String>())
        .map((t) => TimeOfDay(
            hour: int.parse(t.split(':')[0]),
            minute: int.parse(t.split(':')[1])))
        .toList();
    _days
      ..clear()
      ..addAll((jsonDecode(m.daysOfWeek ?? '[1,2,3,4,5,6,7]') as List)
          .map((e) => int.parse(e.toString())));
    _startDate = m.startDate;
    _endDate = m.endDate;
    _pauses
      ..clear()
      ..addAll((jsonDecode(m.pausePeriods ?? '[]') as List).map((e) => (
            DateTime.parse((e as Map)['f'] as String),
            DateTime.parse(e['t'] as String),
          )));
    if (mounted) setState(() {});
  }

  Future<void> _addTime() async {
    final t = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 20, minute: 0));
    if (t != null) setState(() => _times.add(t));
  }

  static const _weekLabels = ['一', '二', '三', '四', '五', '六', '日'];
  String _weekLabel(int d) => _weekLabels[d - 1];

  static String _dstr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<DateTime?> _pickDate(DateTime? current, {DateTime? first}) async {
    return showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: first ?? DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
  }

  Future<void> _addPause() async {
    final f = await _pickDate(DateTime.now());
    if (f == null || !mounted) return;
    final t = await _pickDate(f, first: f);
    if (t == null) return;
    setState(() => _pauses.add((f, t)));
  }

  /// 把当前时间点写入系统时钟 app（真正的闹钟，响铃不受通知限制）。
  /// 依赖厂商实现：原生/多数系统静默创建，个别系统会弹确认——都算成功。
  Future<void> _syncToClock() async {
    if (_name.text.trim().isEmpty) {
      _toast('请先填写药物名称');
      return;
    }
    final msg = '灵枢·${_name.text.trim()}'
        '${_dosage.text.isNotEmpty ? '（${_dosage.text}）' : ''}'
        ' ${_mealRelation}服用';
    final days = _days.length == 7 ? null : _days.toList();
    var ok = 0;
    for (final t in _times) {
      try {
        final r = await _alarmChannel.invokeMethod<bool>('setAlarm', {
          'name': msg,
          'hour': t.hour,
          'minute': t.minute,
          'days': days,
        });
        if (r == true) ok++;
      } on PlatformException {
        // 设备不支持时逐个跳过
      }
    }
    _toast(ok > 0
        ? '已请求创建 $ok 个系统闹钟（可在时钟 app 查看）'
        : '本机不支持一键建闹钟，请在时钟 app 手动添加');
  }

  Future<void> _save() async {
    // 空名称早退必须有提示——静默 return 在用户看来就是「点了保存没反应、不退回」
    if (_saving) return;
    if (_name.text.trim().isEmpty) {
      _toast('请先填写药物名称');
      return;
    }
    setState(() => _saving = true);
    try {
      final db = ref.read(dbProvider);
      final profileId = ref.read(currentProfileIdProvider)!;
      final notif = ref.read(notificationServiceProvider);
      final times = _times.map((t) =>
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').toList();
      final daysJson = _days.length == 7
          ? null // 每天
          : jsonEncode(_days.toList()..sort());
      final daysSet = _days.toSet();
      String? pausesJson = _pauses.isEmpty
          ? null
          : jsonEncode([
              for (final pg in _pauses)
                {'f': _dstr(pg.$1), 't': _dstr(pg.$2)}
            ]);

      int medId;
      if (widget.medId == null) {
        medId = await db.into(db.medications).insert(MedicationsCompanion.insert(
              profileId: profileId,
              name: _name.text.trim(),
              dosage: Value(_dosage.text.trim().isEmpty ? null : _dosage.text.trim()),
              mealRelation: Value(_mealRelation),
              timesOfDay: jsonEncode(times),
              daysOfWeek: Value(daysJson),
              startDate: Value(_startDate),
              endDate: Value(_endDate),
              pausePeriods: Value(pausesJson),
              stock: Value(double.tryParse(_stock.text)),
              note: Value(_note.text.trim().isEmpty ? null : _note.text.trim()),
            ));
      } else {
        medId = widget.medId!;
        await notif.cancelForMedication(medId);
        await (db.update(db.medications)..where((t) => t.id.equals(medId)))
            .write(MedicationsCompanion(
          name: Value(_name.text.trim()),
          dosage: Value(_dosage.text.trim().isEmpty ? null : _dosage.text.trim()),
          mealRelation: Value(_mealRelation),
          timesOfDay: Value(jsonEncode(times)),
          daysOfWeek: Value(daysJson),
          startDate: Value(_startDate),
          endDate: Value(_endDate),
          pausePeriods: Value(pausesJson),
          stock: Value(double.tryParse(_stock.text)),
          note: Value(_note.text.trim().isEmpty ? null : _note.text.trim()),
        ));
      }

      // 窗口式重排：周几 ∩ 服用区间 ∩ 非暂停。
      // 重排失败绝不能卡住保存——部分 ROM 精确闹钟权限被收回时
      // zonedSchedule 会抛异常，不接住的话 Navigator.pop 永远到不了，
      // 页面就停在编辑页（数据其实已落库）。兜底：App 启动/回本页时会
      // 对全部在用药物整体重排，错过这次也会补上。
      try {
        await notif.rescheduleMedication(
          medicationId: medId,
          times: times,
          days: daysSet,
          startDate: _startDate,
          endDate: _endDate,
          pauses: _pauses,
          title: '灵枢 · 用药提醒',
          body: '${_name.text.trim()}${_dosage.text.isNotEmpty ? '（${_dosage.text}）' : ''} · ${_mealRelation}服用',
        );
      } catch (e) {
        debugPrint('[med] reschedule failed: $e');
        _toast('已保存，但提醒重排未完成：$e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    // 处方多药模式：保存当前这种后，预填下一种继续核对
    if (widget.medId == null && _pending.isNotEmpty) {
      _fillFromDraft(_pending.removeAt(0));
      setState(() {});
      _toast('已保存「${_name.text}」');
      return;
    }
    Navigator.of(context).pop();
  }

  // ── 处方/说明书拍照识别 ──

  Future<void> _pickPhotos() async {
    final xs = await ImagePicker()
        .pickMultiImage(maxWidth: 2400, imageQuality: 90);
    if (xs.isEmpty) return;
    setState(() => _photos.addAll(xs.map((e) => e.path)));
  }

  Future<void> _shoot() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.camera, maxWidth: 2400, imageQuality: 90);
    if (x == null) return;
    setState(() => _photos.add(x.path));
  }

  Future<Uint8List> _compress(String path) async {
    final raw = await File(path).readAsBytes();
    final decoded = img.decodeImage(raw);
    if (decoded == null) return raw;
    final c = decoded.width > 1600 ? img.copyResize(decoded, width: 1600) : decoded;
    return Uint8List.fromList(img.encodeJpg(c, quality: 85));
  }

  Future<void> _runAi() async {
    if (_photos.isEmpty) {
      _toast('请先拍照或选择处方/说明书照片');
      return;
    }
    final cfg = await ref.read(aiConfigProvider.future);
    if (cfg.apiKey.isEmpty) {
      _toast('请先在「我的 → 设置」配置视觉模型 API Key');
      return;
    }
    setState(() => _aiRunning = true);
    try {
      final images = [for (final p in _photos) await _compress(p)];
      final drafts = await cfg.extractMedications(images);
      if (drafts.isEmpty) {
        _toast('未识别到药品信息');
        return;
      }
      if (drafts.length == 1) {
        _fillFromDraft(drafts.first);
        setState(() {});
        _toast('识别完成，请核对后保存');
        return;
      }
      if (!mounted) return;
      // 多种药：勾选要录入的，逐种核对保存
      final selected = [...drafts];
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => StatefulBuilder(
          builder: (c, setD) => AlertDialog(
            title: Text('识别到 ${drafts.length} 种药品'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(shrinkWrap: true, children: [
                for (final d in drafts)
                  CheckboxListTile(
                    dense: true,
                    value: selected.contains(d),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text(d.name,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      [
                        if (d.dosage != null) d.dosage!,
                        if (d.mealRelation != null) '${d.mealRelation}服用',
                        if (d.times.isNotEmpty) d.times.join(' / '),
                      ].join(' · '),
                      style: const TextStyle(
                          fontSize: 11.5, color: LingShuColors.inkSoft),
                    ),
                    onChanged: (v) =>
                        setD(() => v == true ? selected.add(d) : selected.remove(d)),
                  ),
              ]),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('取消')),
              FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.pop(c, true),
                  child: Text('录入所选 ${selected.length} 种')),
            ],
          ),
        ),
      );
      if (ok == true && selected.isNotEmpty) {
        _pending
          ..clear()
          ..addAll(selected.skip(1));
        _fillFromDraft(selected.first);
        setState(() {});
        _toast('共 ${selected.length} 种，逐种核对保存');
      }
    } catch (e) {
      _toast('识别失败：$e');
    } finally {
      if (mounted) setState(() => _aiRunning = false);
    }
  }

  /// 用 AI 草稿预填表单（空字段保持原值/默认值），等待人工核对
  void _fillFromDraft(MedDraft d) {
    _name.text = d.name;
    _dosage.text = d.dosage ?? '';
    if (d.mealRelation != null) _mealRelation = d.mealRelation!;
    if (d.times.isNotEmpty) {
      _times = d.times.map((t) {
        final p = t.split(':');
        return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      }).toList();
    }
    _note.text = d.note ?? '';
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), width: 320));
  }

  Widget _photoSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('处方 / 说明书识别（选填）',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Text('拍照或多选照片，AI 自动提取药品与用法，核对后保存',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: LingShuColors.inkSoft)),
          const SizedBox(height: 8),
          if (_photos.isNotEmpty)
            SizedBox(
              height: 76,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in _photos)
                    Stack(children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: LingShuColors.cardBorder),
                          image: DecorationImage(
                              image: FileImage(File(p)), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _photos.remove(p)),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ]),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(children: [
            OutlinedButton.icon(
              onPressed: _shoot,
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: const Text('拍照'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _pickPhotos,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('相册（可多选）'),
            ),
            const Spacer(),
            if (_aiRunning)
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else
              FilledButton.tonal(
                onPressed: _photos.isEmpty ? null : _runAi,
                child: const Text('AI 提取'),
              ),
          ]),
          const Divider(height: 28),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.medId == null ? '添加药物' : '编辑药物')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    _pending.isNotEmpty ? '保存并核对下一种' : '保 存',
                    style: const TextStyle(letterSpacing: 4),
                  ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.medId == null) ...[
            _photoSection(),
            const SizedBox(height: 4),
          ],
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(
                labelText: '药物名称 *', hintText: '如：阿司匹林肠溶片'),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _dosage,
                decoration: const InputDecoration(
                    labelText: '剂量', hintText: '如：100mg / 1片'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _mealRelation,
                decoration: const InputDecoration(labelText: '服用时间'),
                items: _mealRelations
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _mealRelation = v ?? '餐后'),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          const Text('服药时间点',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _times)
                InputChip(
                  label: Text(t.format(context)),
                  onDeleted: _times.length > 1
                      ? () => setState(() => _times.remove(t))
                      : null,
                  onPressed: () async {
                    final nt = await showTimePicker(
                        context: context, initialTime: t);
                    if (nt != null) {
                      setState(
                          () => _times[_times.indexOf(t)] = nt);
                    }
                  },
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('添加时间'),
                onPressed: _addTime,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('重复日期',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Text('取消某天即那天跳过服药提醒；全选即每天',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: LingShuColors.inkSoft)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  label: Text('周${_weekLabel(d)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: _days.contains(d)
                              ? Colors.white
                              : LingShuColors.ink)),
                  selected: _days.contains(d),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  onSelected: (v) =>
                      setState(() => v ? _days.add(d) : _days.remove(d)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('服用区间',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Text('留空即长期服用；到结束日后自动不再提醒',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: LingShuColors.inkSoft)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final d = await _pickDate(_startDate);
                  if (d != null) setState(() => _startDate = d);
                },
                child: InputDecorator(
                  decoration:
                      const InputDecoration(labelText: '开始日期', isDense: true),
                  child: Text(_startDate == null ? '长期' : _dstr(_startDate!)),
                ),
              ),
            ),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8), child: Text('至')),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final d = await _pickDate(_endDate, first: _startDate);
                  if (d != null) setState(() => _endDate = d);
                },
                child: InputDecorator(
                  decoration:
                      const InputDecoration(labelText: '结束日期', isDense: true),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(child: Text(
                        _endDate == null ? '长期' : _dstr(_endDate!),
                        overflow: TextOverflow.ellipsis)),
                    if (_endDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _endDate = null),
                        child: const Icon(Icons.close,
                            size: 15, color: LingShuColors.inkSoft),
                      ),
                  ]),
                ),
              ),
            ),
          ]),
          if (_startDate != null)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => setState(() => _startDate = null),
                child: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('清除开始日期',
                      style: TextStyle(
                          fontSize: 11, color: LingShuColors.inkSoft)),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(children: [
            const Text('暂停时段',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            TextButton.icon(
              onPressed: _addPause,
              icon: const Icon(Icons.block, size: 16),
              label: const Text('添加'),
            ),
          ]),
          if (_pauses.isEmpty)
            Text('旅行/停药观察等期间可加暂停，暂停期内不提醒',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: LingShuColors.inkSoft)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final pg in _pauses)
                InputChip(
                  label: Text('${_dstr(pg.$1)} ~ ${_dstr(pg.$2)}'),
                  onDeleted: () => setState(() => _pauses.remove(pg)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _syncToClock,
            icon: const Icon(Icons.alarm_add_outlined, size: 18),
            label: const Text('同步到系统闹钟（闹钟 app 内响铃）'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _stock,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: '当前库存（选填）', hintText: '如：30'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _note,
            decoration: const InputDecoration(labelText: '备注（选填）'),
          ),
          const SizedBox(height: 8),
          Text(
            '开启提醒后将按时间点每日通知（通知权限请保持开启）。',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: LingShuColors.inkSoft),
          ),
        ],
      ),
    );
  }
}
