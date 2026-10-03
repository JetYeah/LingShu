import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:drift/drift.dart' show OrderingTerm;

import '../../core/db.dart';
import '../../core/services/backup_service.dart';
import '../../core/theme.dart';
import '../../providers.dart';

/// 数据备份与迁移：导出全量 zip / 从 zip 合并导入
class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _busy = false;
  String _log = '';
  int? _exportProfileId; // null = 全部成员
  List<Profile> _profiles = const [];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final db = ref.read(dbProvider);
    final list = await (db.select(db.profiles)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    if (mounted) setState(() => _profiles = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据备份与迁移')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: LingShuColors.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: LingShuColors.gold.withValues(alpha: 0.3)),
            ),
            child: const Text(
              '正常升级 App 不会丢失任何数据（数据保存在应用私有目录，覆盖安装原样保留）。'
              '但卸载重装或清除应用数据会全部丢失——建议定期导出备份。\n\n'
              '导出包为 zip 格式，可通过微信等方式发送；可以导出全部成员，也可以只导某一位（如发给医生或家人）。\n'
              '导入为合并模式：不覆盖、不删除本机已有数据，同一成员按姓名合并。',
              style: TextStyle(fontSize: 12.5, height: 1.6),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _exportProfileId,
            decoration: const InputDecoration(
                labelText: '导出范围', prefixIcon: Icon(Icons.family_restroom)),
            items: [
              const DropdownMenuItem<int>(
                  value: null, child: Text('全部成员')),
              for (final p in _profiles)
                DropdownMenuItem(value: p.id, child: Text(p.name)),
            ],
            onChanged: _busy
                ? null
                : (v) => setState(() => _exportProfileId = v),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.ios_share),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                  _exportProfileId == null
                      ? '导出全部数据'
                      : '导出「${_selectedName ?? ''}」的数据',
                  style: const TextStyle(letterSpacing: 2)),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _import,
            icon: const Icon(Icons.download),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('从备份包导入', style: TextStyle(letterSpacing: 2)),
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_log.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LingShuColors.cardBorder),
              ),
              child: Text(_log,
                  style: const TextStyle(
                      fontSize: 12.5, height: 1.5, fontFamily: 'monospace')),
            ),
          ],
        ],
      ),
    );
  }

  String? get _selectedName =>
      _profiles.where((p) => p.id == _exportProfileId).firstOrNull?.name;

  Future<void> _export() async {
    setState(() {
      _busy = true;
      _log = '';
    });
    try {
      final file = await BackupService.withPrefs(
              ref.read(dbProvider), ref.read(sharedPreferencesProvider))
          .exportAll(profileId: _exportProfileId, profileName: _selectedName);
      setState(() {
        _log = '已生成备份：${file.uri.pathSegments.last}\n正在调起分享…';
      });
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        subject: '灵枢数据备份',
        text: '灵枢健康数据备份包（可在对方 App 的「数据备份与迁移」中一键导入）',
      ));
      if (mounted) setState(() => _log = '已生成备份：${file.uri.pathSegments.last}');
    } catch (e) {
      setState(() => _log = '导出失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final files = await FilePicker.pickFiles(type: FileType.any);
    if (files.isEmpty || files.single.path == null) return;
    if (!mounted) return;
    final svc = BackupService.withPrefs(
        ref.read(dbProvider), ref.read(sharedPreferencesProvider));
    final zip = File(files.single.path!);

    // ── 分析差异（只读） ──
    setState(() {
      _busy = true;
      _log = '分析备份包差异…';
    });
    ImportPlan plan;
    try {
      plan = await svc.analyze(zip);
    } catch (e) {
      setState(() => _log = '无法读取备份包：$e');
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    // ── 预览与决策 ──
    var preferBackup = false;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (c) => StatefulBuilder(
        builder: (c, setSheet) => DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.82,
          initialChildSize: 0.6,
          builder: (c, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Row(children: [
                const Icon(Icons.difference_outlined,
                    color: LingShuColors.gold, size: 20),
                const SizedBox(width: 8),
                const Text('导入预览',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
                const Spacer(),
                Text(
                    plan.exportedAt == null
                        ? ''
                        : '导出于 ${plan.exportedAt!.year}-${plan.exportedAt!.month.toString().padLeft(2, '0')}-${plan.exportedAt!.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        fontSize: 11, color: LingShuColors.inkSoft)),
              ]),
              const SizedBox(height: 12),
              for (final pp in plan.profiles)
                CheckboxListTile(
                  value: pp.selected,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Row(children: [
                    Text(pp.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: (pp.isNew ? WuXing.wood : LingShuColors.gold)
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(pp.isNew ? '新成员' : '已存在',
                          style: TextStyle(
                              fontSize: 10,
                              color: pp.isNew
                                  ? WuXing.wood
                                  : LingShuColors.gold)),
                    ),
                  ]),
                  subtitle: Text(
                    [
                      if (!pp.isNew && pp.fieldDiffs.isNotEmpty)
                        '档案差异 ${pp.fieldDiffs.length} 项（${pp.fieldDiffs.join('、')}）',
                      '病历 新增 ${pp.newRecords} · 重复 ${pp.dupRecords}',
                      '指标值 新增 ${pp.newValues} · 重复 ${pp.dupValues}',
                      if (pp.newMeds > 0 || pp.conflictMeds > 0)
                        '药物 新增 ${pp.newMeds} · 用法冲突 ${pp.conflictMeds}',
                    ].join('\n'),
                    style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.5,
                        color: LingShuColors.inkSoft),
                  ),
                  onChanged: (v) =>
                      setSheet(() => pp.selected = v ?? false),
                ),
              const Divider(height: 24),
              const Text('冲突时以谁为准？',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              const SizedBox(height: 4),
              Text(
                  '档案差异字段与用法冲突的药物按此策略处理；病历和测量值不受影响——始终只新增本机没有的，不会重复、不会删除。',
                  style: const TextStyle(
                      fontSize: 11, height: 1.4, color: LingShuColors.inkSoft)),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                      value: false,
                      icon: Icon(Icons.shield_outlined),
                      label: Text('保留本机')),
                  ButtonSegment(
                      value: true,
                      icon: Icon(Icons.backup_outlined),
                      label: Text('以备份为准')),
                ],
                selected: {preferBackup},
                onSelectionChanged: (s) =>
                    setSheet(() => preferBackup = s.first),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: plan.profiles.any((p) => p.selected)
                    ? () => Navigator.pop(c, true)
                    : null,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('开始导入', style: TextStyle(letterSpacing: 2)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('取消'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;

    setState(() {
      _busy = true;
      _log = '导入中…';
    });
    try {
      final stats = await svc.importAll(
        zip,
        onlyNames: {
          for (final p in plan.profiles.where((p) => p.selected)) p.name
        },
        preferBackup: preferBackup,
      );
      setState(() => _log = '导入完成：\n$stats');
    } catch (e) {
      setState(() => _log = '导入失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
