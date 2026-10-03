import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/db.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../providers.dart';
import 'records_calendar.dart';

const recordTypes = ['病历', '检验报告', '影像报告', '处方', '体检报告', '其他'];

const typeIcons = {
  '病历': Icons.description_outlined,
  '检验报告': Icons.science_outlined,
  '影像报告': Icons.image_outlined,
  '处方': Icons.receipt_long_outlined,
  '体检报告': Icons.health_and_safety_outlined,
  '其他': Icons.folder_outlined,
};

Color typeColor(String type) {
  switch (type) {
    case '检验报告':
      return WuXing.wood;
    case '影像报告':
      return WuXing.water;
    case '处方':
      return WuXing.fire;
    case '体检报告':
      return WuXing.earth;
    case '病历':
      return WuXing.metal;
    default:
      return LingShuColors.inkSoft;
  }
}

/// 健康档案库：按年月时间线归档
class RecordsPage extends ConsumerStatefulWidget {
  const RecordsPage({super.key});

  @override
  ConsumerState<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends ConsumerState<RecordsPage> {
  String _query = '';
  String? _typeFilter; // null = 全部类型
  String? _hospitalFilter; // null = 全部医院
  bool _calendarMode = false;

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(recordsProvider).valueOrNull ?? const [];
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    // 该成员所有出现过的医院（筛选下拉）
    final hospitals = <String>{};
    for (final r in records) {
      final h = r.hospital?.trim() ?? '';
      if (h.isNotEmpty) hospitals.add(h);
    }

    bool pass(MedicalRecord r) {
      if (_typeFilter != null && r.type != _typeFilter) return false;
      if (_hospitalFilter != null && (r.hospital?.trim() ?? '') != _hospitalFilter) {
        return false;
      }
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return r.title.toLowerCase().contains(q) ||
          (r.hospital ?? '').toLowerCase().contains(q) ||
          (r.tags ?? '').toLowerCase().contains(q) ||
          (r.note ?? '').toLowerCase().contains(q);
    }

    final filtered = records.where(pass).toList();

    // 按 年-月 分组
    final groups = <String, List<MedicalRecord>>{};
    final df = DateFormat('yyyy年M月');
    for (final r in filtered) {
      groups.putIfAbsent(df.format(r.recordDate), () => []).add(r);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('健康档案 · ${profile?.name ?? ''}'),
        actions: [
          IconButton(
            tooltip: _calendarMode ? '列表视图' : '日历视图',
            icon: Icon(_calendarMode ? Icons.view_list : Icons.calendar_month),
            onPressed: () => setState(() => _calendarMode = !_calendarMode),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final q = await showSearch<String?>(
                context: context,
                delegate: _RecordSearchDelegate(),
              );
              if (q != null) setState(() => _query = q);
            },
          ),
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _query = ''),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'import_record',
        onPressed: () => context.push('/records/import'),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('拍照归档'),
      ),
      body: Column(children: [
        _filterBar(hospitals.toList()..sort()),
        Expanded(
          child: _calendarMode
              ? RecordsCalendarView(
                  records: filtered,
                  onOpenRecord: (r) => context.push('/records/${r.id}'),
                  gender: profile?.gender ?? 'male',
                  birthYear: profile?.birthday?.year,
                )
              : filtered.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      itemCount: filtered.length + groups.keys.length,
                      itemBuilder: (context, i) {
                        // 展开分组：先组头，再组内条目
                        int idx = 0;
                        for (final entry in groups.entries) {
                          if (i == idx) {
                            return _groupHeader(entry.key, entry.value.length);
                          }
                          idx++;
                          final inner = idx + entry.value.length;
                          if (i < inner) {
                            final record = entry.value[i - idx];
                            return _recordCard(record);
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

  // ── 筛选行：报告类型 chips + 医院 ──
  Widget _filterBar(List<String> hospitals) {
    final types = ['全部', ...recordTypes];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final t in types)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _chip(
                    t,
                    selected: t == '全部'
                        ? _typeFilter == null
                        : _typeFilter == t,
                    color: t == '全部' ? WuXing.metal : typeColor(t),
                    onTap: () => setState(
                        () => _typeFilter = t == '全部' ? null : t),
                  ),
                ),
            ],
          ),
        ),
        if (hospitals.isNotEmpty) ...[
          const SizedBox(height: 4),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip('全部医院',
                    selected: _hospitalFilter == null,
                    color: WuXing.water,
                    onTap: () => setState(() => _hospitalFilter = null)),
                for (final h in hospitals)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _chip(
                      h,
                      selected: _hospitalFilter == h,
                      color: WuXing.water,
                      onTap: () => setState(() => _hospitalFilter =
                          _hospitalFilter == h ? null : h),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ]),
    );
  }

  Widget _chip(String label,
      {required bool selected, required Color color, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
              color: selected ? color : LingShuColors.cardBorder),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? color : LingShuColors.inkSoft)),
      ),
    );
  }

  Widget _groupHeader(String label, int count) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Row(children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
                color: WuXing.earth, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(width: 6),
          Text('$count 份',
              style:
                  const TextStyle(fontSize: 12, color: LingShuColors.inkSoft)),
          const Expanded(
              child: Divider(indent: 10, color: LingShuColors.cardBorder)),
        ]),
      );

  Widget _recordCard(MedicalRecord r) {
    final color = typeColor(r.type);
    return LSCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => context.push('/records/${r.id}'),
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcons[r.type] ?? Icons.folder_outlined,
                color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 3),
                Text(
                  [
                    DateFormat('yyyy-MM-dd').format(r.recordDate),
                    if (r.hospital?.isNotEmpty == true) r.hospital!,
                    if (r.department?.isNotEmpty == true) r.department!,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: LingShuColors.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (r.locationText?.isNotEmpty == true)
            Tooltip(
              message: r.locationText!,
              child: const Icon(Icons.place_outlined,
                  size: 16, color: WuXing.earth),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: LingShuColors.inkSoft),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_special_outlined,
                size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('还没有健康档案',
                style: TextStyle(fontSize: 16, color: LingShuColors.inkSoft)),
            const SizedBox(height: 6),
            const Text('拍照或上传病历报告，灵枢帮你按日期归档',
                style: TextStyle(fontSize: 12, color: LingShuColors.inkSoft)),
          ],
        ),
      );
}

class _RecordSearchDelegate extends SearchDelegate<String?> {
  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => query = ''),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) {
    close(context, query.trim());
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) => const SizedBox.shrink();
}
