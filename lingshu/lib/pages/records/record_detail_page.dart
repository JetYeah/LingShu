import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../providers.dart';
import 'records_page.dart';

class RecordDetailPage extends ConsumerStatefulWidget {
  final int recordId;
  const RecordDetailPage({super.key, required this.recordId});

  @override
  ConsumerState<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends ConsumerState<RecordDetailPage> {
  MedicalRecord? _record;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(dbProvider);
    final r = await (db.select(db.medicalRecords)
          ..where((x) => x.id.equals(widget.recordId)))
        .getSingleOrNull();
    if (mounted) setState(() => _record = r);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('删除档案'),
        content: const Text('删除后无法恢复（原件文件将保留），确定删除吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: WuXing.fire),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('删除')),
        ],
      ),
    );
    if (ok == true && _record != null) {
      await ref
          .read(dbProvider)
          .medicalRecords
          .deleteWhere((t) => t.id.equals(_record!.id));
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _editMeta() async {
    final r = _record!;
    final title = TextEditingController(text: r.title);
    final hospital = TextEditingController(text: r.hospital ?? '');
    final note = TextEditingController(text: r.note ?? '');
    var date = r.recordDate;
    final saved = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('编辑信息'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: '标题')),
            const SizedBox(height: 8),
            TextField(controller: hospital, decoration: const InputDecoration(labelText: '医院')),
            const SizedBox(height: 8),
            TextField(controller: note, decoration: const InputDecoration(labelText: '备注')),
            const SizedBox(height: 8),
            StatefulBuilder(builder: (context, setInner) => InkWell(
              onTap: () async {
                final d = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 1)));
                if (d != null) setInner(() => date = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: '日期'),
                child: Text(DateFormat('yyyy-MM-dd').format(date)),
              ),
            )),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('保存')),
        ],
      ),
    );
    if (saved == true) {
      final db = ref.read(dbProvider);
      await (db.update(db.medicalRecords)..where((t) => t.id.equals(r.id)))
          .write(MedicalRecordsCompanion(
        title: driftValue(title.text),
        hospital: driftValue(hospital.text),
        note: driftValue(note.text),
        recordDate: driftValue(date),
      ));
      _load();
    }
  }

  Value<T> driftValue<T>(T v) => Value<T>(v);

  @override
  Widget build(BuildContext context) {
    final r = _record;
    if (r == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final color = typeColor(r.type);
    return Scaffold(
      appBar: AppBar(
        title: const Text('档案详情'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _editMeta),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LSCard(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(r.type, style: TextStyle(fontSize: 12, color: color)),
                  ),
                  const Spacer(),
                  Text(DateFormat('yyyy-MM-dd').format(r.recordDate),
                      style: const TextStyle(color: LingShuColors.inkSoft)),
                ]),
                const SizedBox(height: 12),
                Text(r.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _kv('医院', r.hospital),
                _kv('科室', r.department),
                _kv('标签', r.tags),
                if (r.aiSummary?.isNotEmpty == true) _kv('AI 摘要', r.aiSummary),
                if (r.note?.isNotEmpty == true) _kv('备注', r.note),
                if (r.locationText?.isNotEmpty == true)
                  _kv('提交地址', r.locationText),
                if (r.lat != null && r.lng != null)
                  _kv('经纬度',
                      '${r.lat!.toStringAsFixed(5)}, ${r.lng!.toStringAsFixed(5)}'),
              ]),
          ),
          const SizedBox(height: 16),
          if (r.fileType == 'image')
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                maxScale: 4,
                child: Image.file(File(r.filePath), fit: BoxFit.contain),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LingShuColors.cardBorder),
              ),
              child: Column(children: [
                const Icon(Icons.picture_as_pdf_outlined, size: 40, color: WuXing.fire),
                const SizedBox(height: 8),
                Text('原件：${r.filePath}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11, color: LingShuColors.inkSoft)),
              ]),
            ),
          const SizedBox(height: 16),
          const Center(
            child: Text('本应用仅为健康记录工具，不能替代专业医疗诊断',
                style: TextStyle(fontSize: 11, color: LingShuColors.inkSoft)),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String? v) {
    if (v == null || v.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 64,
          child: Text(k,
              style: const TextStyle(
                  fontSize: 13, color: LingShuColors.inkSoft)),
        ),
        Expanded(child: Text(v, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }
}
