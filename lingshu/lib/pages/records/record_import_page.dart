import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/db.dart';
import '../../core/services/location_service.dart';
import '../../core/services/ocr_service.dart';
import '../../core/theme.dart';
import '../../providers.dart';
import 'record_detail_page.dart';
import 'records_page.dart';

/// 拍照/上传 → AI 识别 → 确认归档
class RecordImportPage extends ConsumerStatefulWidget {
  const RecordImportPage({super.key});

  @override
  ConsumerState<RecordImportPage> createState() => _RecordImportPageState();
}

class _RecordImportPageState extends ConsumerState<RecordImportPage> {
  final _title = TextEditingController();
  final _hospital = TextEditingController();
  final _department = TextEditingController();
  final _tags = TextEditingController();
  final _note = TextEditingController();
  final _locationCtrl = TextEditingController();

  String _type = '其他';
  DateTime _recordDate = DateTime.now();
  Uint8List? _imageBytes;
  String? _filePath; // 原始文件路径（图片或 PDF）
  String? _fileType;
  bool _aiRunning = false;
  OcrResult? _ai;
  final _selectedMetrics = <int, bool>{};

  // 批量模式：多选图片后建立队列，逐张走完"识别→核对→入库"
  final List<String> _queue = [];
  int _batchTotal = 0; // 0 = 非批量
  bool _saving = false;

  LocationResult? _loc;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    // 仅取最后已知位置（瞬时、无 GNSS 回调注册）；用户可点「重新定位」实时获取
    _locate();
  }

  Future<void> _locate({bool fresh = false}) async {
    setState(() => _locating = true);
    final loc = await ref.read(locationServiceProvider).locate(fresh: fresh);
    if (!mounted) return;
    setState(() {
      _locating = false;
      _loc = loc;
      if (loc != null && _locationCtrl.text.isEmpty) {
        _locationCtrl.text = loc.label;
      }
    });
  }

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
        source: source, maxWidth: 2400, imageQuality: 90);
    if (x == null) return;
    setState(() {
      _filePath = x.path;
      _fileType = 'image';
      _imageBytes = null;
      _ai = null;
    });
  }

  Future<void> _pickFile() async {
    final files = await FilePicker.pickFiles(type: FileType.any);
    if (files.isEmpty || files.single.path == null) return;
    final f = files.single;
    final ext = p.extension(f.path!).toLowerCase();
    setState(() {
      _filePath = f.path;
      _fileType = ext == '.pdf' ? 'pdf' : 'other';
      _imageBytes = null;
      _ai = null;
      if (_title.text.isEmpty && f.name.isNotEmpty) {
        _title.text = p.basenameWithoutExtension(f.name);
      }
    });
  }

  /// 批量模式：相册多选，逐张归档；按原件内容哈希去重（批内重复 & 与已有档案重复）
  Future<void> _pickBatch() async {
    final xs = await ImagePicker()
        .pickMultiImage(maxWidth: 2400, imageQuality: 90);
    if (xs.isEmpty) return;
    final db = ref.read(dbProvider);
    final profileId = ref.read(currentProfileIdProvider);
    final known = <String>{
      if (profileId != null)
        for (final r in await (db.select(db.medicalRecords)
              ..where((t) => t.profileId.equals(profileId)))
            .get())
          if (r.fileHash != null) r.fileHash!,
    };
    final kept = <String>[];
    var dupCount = 0;
    for (final x in xs) {
      try {
        final h = md5.convert(await File(x.path).readAsBytes()).toString();
        if (!known.add(h)) {
          dupCount++;
          continue;
        }
      } catch (_) {
        // 读不出内容的文件不拦，留到逐张核对时人工判断
      }
      kept.add(x.path);
    }
    if (kept.isEmpty) {
      _toast('所选 ${xs.length} 张均与已归档内容重复，无需再归');
      return;
    }
    setState(() {
      _queue.addAll(kept);
      _batchTotal = _queue.length;
    });
    _loadNext();
    _toast('已选 ${xs.length} 张${dupCount > 0 ? '，去重 $dupCount 张' : ''}，逐张核对归档');
  }

  /// 装载下一张：重置与单张相关的表单；医院/定位默认保留（同批常为同一次就诊）
  void _loadNext() {
    if (!mounted) return;
    if (_queue.isEmpty) {
      _finishBatch();
      return;
    }
    final next = _queue.removeAt(0);
    setState(() {
      _filePath = next;
      _fileType = 'image';
      _imageBytes = null;
      _ai = null;
      _selectedMetrics.clear();
      _title.clear();
      _department.clear();
      _tags.clear();
      _note.clear();
      _recordDate = DateTime.now();
    });
  }

  void _skipCurrent() {
    if (_batchTotal == 0) return;
    _loadNext();
  }

  void _finishBatch() {
    _toast('批量归档完成，共 $_batchTotal 张');
    Navigator.of(context).pop();
  }

  Future<Uint8List?> _loadAndCompress() async {
    if (_filePath == null || _fileType != 'image') return null;
    if (_imageBytes != null) return _imageBytes;
    final raw = await File(_filePath!).readAsBytes();
    final decoded = img.decodeImage(raw);
    if (decoded == null) return raw;
    final compressed = decoded.width > 1600
        ? img.copyResize(decoded, width: 1600)
        : decoded;
    final bytes = Uint8List.fromList(img.encodeJpg(compressed, quality: 85));
    _imageBytes = bytes;
    return bytes;
  }

  Future<void> _runAI() async {
    final bytes = await _loadAndCompress();
    if (bytes == null) {
      _toast('仅支持图片 AI 识别，其他格式请手动填写');
      return;
    }
    final ocr = await ref.read(aiConfigProvider.future);
    if (ocr.apiKey.isEmpty) {
      _toast('请先在「我的 → 设置」配置视觉模型 API Key');
      return;
    }
    setState(() => _aiRunning = true);
    try {
      final r = await ocr.extract(bytes);
      setState(() {
        _ai = r;
        _selectedMetrics.clear();
        for (var i = 0; i < r.metrics.length; i++) {
          _selectedMetrics[i] = true;
        }
        if (r.title != null && _title.text.isEmpty) _title.text = r.title!;
        if (r.docType != null && recordTypes.contains(r.docType)) {
          _type = r.docType!;
        }
        if (r.hospital != null && _hospital.text.isEmpty) {
          _hospital.text = r.hospital!;
        }
        if (r.department != null && _department.text.isEmpty) {
          _department.text = r.department!;
        }
        if (r.recordDate != null) _recordDate = r.recordDate!;
      });
      _toast('识别完成，请核对信息');
    } catch (e) {
      _toast('识别失败：$e');
    } finally {
      if (mounted) setState(() => _aiRunning = false);
    }
  }

  Future<void> _save() async {
    if (_filePath == null) {
      _toast('请先拍照或选择文件');
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final db = ref.read(dbProvider);
      final profileId = ref.read(currentProfileIdProvider);
      if (profileId == null) return;

      // 内容级去重：同一成员下已有相同原件（哈希一致）则不再入库
      final hash = md5.convert(await File(_filePath!).readAsBytes()).toString();
      await _backfillHashes(db, profileId);
      final dup = await (db.select(db.medicalRecords)
            ..where((t) => t.profileId.equals(profileId) & t.fileHash.equals(hash)))
          .getSingleOrNull();
      if (dup != null) {
        if (!mounted) return;
        _toast('与已归档的《${dup.title}》内容相同，已跳过');
        if (_batchTotal > 0) {
          if (_queue.isNotEmpty) {
            _loadNext();
          } else {
            _finishBatch();
          }
        }
        return;
      }

      // 定性指标（阴性/阳性等，无数值）并入病历备注
      final qualitative = <String>[];
      if (_ai != null) {
        for (var i = 0; i < _ai!.metrics.length; i++) {
          if (_selectedMetrics[i] != true) continue;
          final m = _ai!.metrics[i];
          if (m.value == null && m.textValue != null) {
            qualitative.add('${m.name}：${m.textValue}');
          }
        }
      }
      final noteText = [
        if (_note.text.trim().isNotEmpty) _note.text.trim(),
        if (qualitative.isNotEmpty) '定性结果：${qualitative.join('；')}',
      ].join('\n');

      // 拷贝原件到应用目录
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'records'));
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final ext = p.extension(_filePath!);
      final stored = p.join(dir.path, '${const Uuid().v4()}$ext');
      await File(_filePath!).copy(stored);

      final recordId = await db.into(db.medicalRecords).insert(
            MedicalRecordsCompanion.insert(
              profileId: profileId,
              title: _title.text.trim().isEmpty
                  ? '${_type} ${DateFormat('MMdd').format(_recordDate)}'
                  : _title.text.trim(),
              type: _type,
              recordDate: _recordDate,
              hospital: Value(_hospital.text.trim().isEmpty ? null : _hospital.text.trim()),
              department:
                  Value(_department.text.trim().isEmpty ? null : _department.text.trim()),
              tags: Value(_tags.text.trim().isEmpty ? null : _tags.text.trim()),
              note: Value(noteText.isEmpty ? null : noteText),
              filePath: stored,
              fileType: _fileType ?? 'other',
              fileHash: Value(hash),
              lat: Value(_loc?.lat),
              lng: Value(_loc?.lng),
              locationText: Value(_locationCtrl.text.trim().isEmpty
                  ? null
                  : _locationCtrl.text.trim()),
              aiSummary: Value(_ai?.summary),
            ),
          );

      // 保存 AI 识别的指标：单个指标入库失败不阻断归档与批量推进
      if (_ai != null) {
        for (final entry in _selectedMetrics.entries) {
          if (entry.value != true) continue;
          final m = _ai!.metrics[entry.key];
          if (m.value == null) continue;
          try {
            await _saveMetric(m);
          } catch (_) {}
        }
      }

      if (!mounted) return;
      if (_batchTotal > 0) {
        // 批量模式：入库后留在本页继续下一张
        if (_queue.isNotEmpty) {
          _toast('已归档 ${_batchTotal - _queue.length}/$_batchTotal');
          _loadNext();
        } else {
          _finishBatch();
        }
      } else {
        Navigator.of(context).pop();
        contextPushDetail(recordId);
      }
    } catch (e) {
      // 兜底报错：哈希/查询/入库任何一步异常都不能无声卡在当前张
      if (mounted) _toast('保存失败：$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 旧档案（v3 之前入库）没有哈希，渐进补算，让内容级去重对历史数据同样生效。
  /// 每次保存最多补 60 条：库大时首次保存也保持在秒级，剩余随后续保存逐步补齐。
  Future<void> _backfillHashes(AppDatabase db, int profileId,
      {int limit = 60}) async {
    final missing = await (db.select(db.medicalRecords)
          ..where((t) => t.profileId.equals(profileId) & t.fileHash.isNull())
          ..limit(limit))
        .get();
    for (final r in missing) {
      try {
        final f = File(r.filePath);
        if (!f.existsSync()) continue;
        final h = md5.convert(await f.readAsBytes()).toString();
        await (db.update(db.medicalRecords)..where((t) => t.id.equals(r.id)))
            .write(MedicalRecordsCompanion(fileHash: Value(h)));
      } catch (_) {
        // 原件可能已被清理，跳过不影响本次归档
      }
    }
  }

  Future<void> _saveMetric(OcrMetric m) async {
    // 定性结果无数值可入指标库，已在 _save 中并入病历备注
    if (m.value == null) return;
    final db = ref.read(dbProvider);
    final profileId = ref.read(currentProfileIdProvider)!;
    final isBp = m.value2 != null ||
        m.name.contains('收缩') ||
        m.name.contains('高压') ||
        m.name.toLowerCase() == 'bp';
    Metric? metric;
    // 精确同名优先；否则子串包含里取最短名（"血糖"挂"血糖"而非"空腹血糖"）。
    // 用 get() 而非 getSingleOrNull：LIKE 命中多行时后者会抛异常，
    // 中断 _save 的批量推进流程（病历已入库却不翻下一张）。
    final exact = await (db.select(db.metrics)
          ..where((t) => t.profileId.equals(profileId) & t.name.equals(m.name)))
        .get();
    if (exact.isNotEmpty) {
      metric = exact.first;
    } else {
      final like = await (db.select(db.metrics)
            ..where((t) =>
                t.profileId.equals(profileId) &
                t.name.like('%${m.name}%')))
          .get();
      if (like.isNotEmpty) {
        metric =
            like.reduce((a, b) => a.name.length <= b.name.length ? a : b);
      }
    }
    if (metric != null) {
      // 已有指标：仅在它还没有归类标签时，用本次 OCR 的类别补充
      if ((metric.tag == null || metric.tag!.isEmpty) &&
          (m.category != null && m.category!.isNotEmpty)) {
        await (db.update(db.metrics)..where((t) => t.id.equals(metric!.id)))
            .write(MetricsCompanion(tag: Value(m.category)));
      }
    } else {
      // 新建指标随路径种入指南参考限：血压收缩 90~139/舒张 60~89，
      // 血糖（餐前口径）3.9~6.1——趋势图与异常判定即时有据
      final isSugar = m.name.contains('血糖');
      metric = await db.into(db.metrics).insertReturning(
            MetricsCompanion.insert(
              profileId: profileId,
              code: isBp ? 'blood_pressure' : 'custom',
              name: m.name,
              unit: m.unit ?? '',
              dualValue: Value(isBp),
              tag: Value((m.category != null && m.category!.isNotEmpty)
                  ? m.category
                  : null),
              refLow: Value(isBp ? 60.0 : (isSugar ? 3.9 : null)),
              refHigh: Value(isBp ? 89.0 : (isSugar ? 6.1 : null)),
              refLow2: Value(isBp ? 90.0 : null),
              refHigh2: Value(isBp ? 139.0 : null),
            ),
          );
    }
    // 去重：同指标 + 同一自然日 + 同值视为重复导入，跳过
    final metricId = metric.id;
    final dayStart = DateTime(
        _recordDate.year, _recordDate.month, _recordDate.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final dup = await (db.select(db.metricValues)
          ..where((t) =>
              t.metricId.equals(metricId) &
              t.measuredAt.isBiggerOrEqualValue(dayStart) &
              t.measuredAt.isSmallerThanValue(dayEnd) &
              t.value1.equals(m.value!) &
              (m.value2 == null
                  ? t.value2.isNull()
                  : t.value2.equals(m.value2!))))
        .get();
    if (dup.isNotEmpty) return;
    await db.into(db.metricValues).insert(MetricValuesCompanion.insert(
          metricId: metric.id,
          value1: m.value!,
          value2: Value(m.value2),
          measuredAt: _recordDate,
          source: const Value('ai'),
        ));
  }

  void contextPushDetail(int id) => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RecordDetailPage(recordId: id),
      ));

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), width: 320));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('拍照归档')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _fileSection(),
          const SizedBox(height: 16),
          _formSection(),
          const SizedBox(height: 16),
          _locationSection(),
          const SizedBox(height: 16),
          if (_ai?.metrics.isNotEmpty == true) _metricsSection(),
          if (_ai?.metrics.isNotEmpty == true) const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                      _saving
                          ? '保存中…'
                          : _batchTotal > 0 && _queue.isNotEmpty
                              ? '保存并继续下一张'
                              : _batchTotal > 0
                                  ? '完成批量归档'
                                  : '保存归档',
                      style: const TextStyle(letterSpacing: 2)),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '原件仅保存在本机；上传识别前请确认不涉及隐私顾虑',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: LingShuColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fileSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('① 文件',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          // 批量模式进度条
          if (_batchTotal > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: LingShuColors.gold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: LingShuColors.gold.withValues(alpha: 0.35)),
              ),
              child: Row(children: [
                const Icon(Icons.photo_library_outlined,
                    size: 18, color: LingShuColors.gold),
                const SizedBox(width: 8),
                Text('批量 ${_batchTotal - _queue.length}/$_batchTotal',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: LingShuColors.ink)),
                const Spacer(),
                TextButton(
                  onPressed: _skipCurrent,
                  child: const Text('跳过此张'),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 8),
          if (_filePath == null)
            Column(children: [
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('拍照'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_outlined),
                    label: const Text('相册'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('文件'),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickBatch,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('批量选择图片 · 逐张归档'),
              ),
            ])
          else
            Column(children: [
              if (_fileType == 'image')
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FutureBuilder<Uint8List?>(
                    future: _loadAndCompress(),
                    builder: (c, s) => s.data != null
                        ? Image.memory(s.data!,
                            height: 200, width: double.infinity, fit: BoxFit.cover)
                        : Container(
                            height: 120,
                            color: LingShuColors.paperDeep,
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                  ),
                )
              else
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: LingShuColors.cardBorder),
                  ),
                  alignment: Alignment.center,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.picture_as_pdf_outlined,
                        color: WuXing.fire),
                    const SizedBox(width: 8),
                    Text(p.basename(_filePath!)),
                  ]),
                ),
              const SizedBox(height: 8),
              Row(children: [
                TextButton.icon(
                  onPressed: () =>
                      setState(() {
                        _filePath = null;
                        _ai = null;
                      }),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('重选'),
                ),
                const Spacer(),
                if (_fileType == 'image')
                  FilledButton.icon(
                    onPressed: _aiRunning ? null : _runAI,
                    icon: _aiRunning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: Text(_aiRunning ? '识别中…' : 'AI 识别'),
                  ),
              ]),
            ]),
        ],
      );

  Widget _formSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('② 信息核对',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(labelText: '标题'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: '类型'),
            items: recordTypes
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _type = v ?? '其他'),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _recordDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (d != null) setState(() => _recordDate = d);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                  labelText: '报告日期', suffixIcon: Icon(Icons.event_outlined)),
              child: Text(DateFormat('yyyy-MM-dd').format(_recordDate)),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _hospital,
                decoration: const InputDecoration(labelText: '医院'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _department,
                decoration: const InputDecoration(labelText: '科室'),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          TextFormField(
            controller: _tags,
            decoration: const InputDecoration(
                labelText: '标签（选填）', hintText: '如：复查,慢病'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _note,
            maxLines: 2,
            decoration: const InputDecoration(labelText: '备注（选填）'),
          ),
          if (_ai?.summary?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: WuXing.wood.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('AI 摘要：${_ai!.summary}',
                    style: const TextStyle(fontSize: 12, height: 1.5)),
              ),
            ),
        ],
      );

  Widget _locationSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('③ 提交地址',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const Spacer(),
            TextButton.icon(
              onPressed: _locating ? null : () => _locate(fresh: true),
              icon: _locating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location, size: 16),
              label: const Text('重新定位'),
            ),
          ]),
          const SizedBox(height: 4),
          TextFormField(
            controller: _locationCtrl,
            decoration: const InputDecoration(
                labelText: '地址 / 医院（可修改为更准确的名称）',
                prefixIcon: Icon(Icons.place_outlined)),
          ),
          if (_loc?.suggestions.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final s in _loc!.suggestions)
                    ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        _locationCtrl.text = s;
                        _hospital.text = s;
                      },
                    ),
                ],
              ),
            ),
        ],
      );

  Widget _metricsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('④ 识别到的指标（勾选后存入健康追踪）',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
            for (var i = 0; i < _ai!.metrics.length; i++)
              CheckboxListTile(
                dense: true,
                value: _selectedMetrics[i],
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(_ai!.metrics[i].name),
                subtitle: Text(
                  _ai!.metrics[i].value != null
                      ? '${_ai!.metrics[i].value}${_ai!.metrics[i].value2 != null ? '/${_ai!.metrics[i].value2}' : ''} ${_ai!.metrics[i].unit ?? ''}'
                      : (_ai!.metrics[i].textValue ?? ''),
                  style: const TextStyle(fontSize: 12)),
                onChanged: (v) =>
                    setState(() => _selectedMetrics[i] = v ?? false),
            ),
        ],
      );

  @override
  void dispose() {
    _title.dispose();
    _hospital.dispose();
    _department.dispose();
    _tags.dispose();
    _note.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }
}
