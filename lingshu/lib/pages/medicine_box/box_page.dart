import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/db.dart';
import '../../core/theme.dart';
import '../../providers.dart';

/// 家庭小药箱：选人组成小家庭，一家庭一药箱；
/// 拍照 AI 识别药品名与到期日；药柜格位式展示，点格拉开柜门看原图。
/// 到期前 6/3/1 个月与过期后每天发本地提醒。
class BoxPage extends ConsumerStatefulWidget {
  const BoxPage({super.key});

  @override
  ConsumerState<BoxPage> createState() => _BoxPageState();
}

class _BoxPageState extends ConsumerState<BoxPage> {
  List<FamilyRow> _families = [];
  Map<int, List<Profile>> _members = {}; // familyId -> profiles
  int? _currentFamily;
  List<BoxMedicine> _medicines = [];
  bool _loading = true;
  bool _sheetOpen = false; // 防止识别/权限等待期间重复点开多层表单
  Set<int>? _aiMatchIds; // AI 找药命中的药品 id；null = 未在筛选
  String? _aiReason; // 一句话筛选依据
  bool _aiBusy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final db = ref.read(dbProvider);
    final fams = await (db.select(db.families)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final profiles = await db.select(db.profiles).get();
    final profById = {for (final p in profiles) p.id: p};
    final members = <int, List<Profile>>{};
    for (final f in fams) {
      final links = await (db.select(db.familyMembers)
            ..where((t) => t.familyId.equals(f.id)))
          .get();
      members[f.id] = [
        for (final l in links)
          if (profById[l.profileId] != null) profById[l.profileId]!
      ];
    }
    List<BoxMedicine> meds = [];
    if (fams.isNotEmpty) {
      final cur = (_currentFamily != null &&
              fams.any((f) => f.id == _currentFamily))
          ? _currentFamily!
          : fams.first.id;
      _currentFamily = cur;
      meds = await (db.select(db.boxMedicines)
            ..where((t) => t.familyId.equals(cur))
            ..orderBy([(t) => OrderingTerm.asc(t.expireDate)]))
          .get();
    } else {
      _currentFamily = null;
    }
    if (!mounted) return;
    setState(() {
      _families = fams;
      _members = members;
      _medicines = meds;
      _loading = false;
    });
    // 到期提醒静默重排（保存时不排：权限弹窗/系统跳转会打断 await 链）
    _rescheduleReminders();
  }

  Future<void> _rescheduleReminders() async {
    try {
      final db = ref.read(dbProvider);
      final all = await db.select(db.boxMedicines).get();
      final notif = ref.read(notificationServiceProvider);
      for (final bm in all) {
        await notif.scheduleBoxMedicine(
            boxMedId: bm.id, name: bm.name, expireDate: bm.expireDate);
      }
    } catch (_) {
      // 排期失败不打扰用户；下次启动/进页会重试
    }
  }

  Future<void> _reloadMeds() async {
    if (_currentFamily == null) return;
    final db = ref.read(dbProvider);
    final meds = await (db.select(db.boxMedicines)
          ..where((t) => t.familyId.equals(_currentFamily!))
          ..orderBy([(t) => OrderingTerm.asc(t.expireDate)]))
        .get();
    if (!mounted) return;
    setState(() {
      _medicines = meds;
      // 清单变化（切家庭/增删药品）后 AI 筛选结果不再可信，直接复位
      _aiMatchIds = null;
      _aiReason = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('家庭小药箱'), actions: [
        if (_families.isNotEmpty)
          IconButton(
              tooltip: 'AI 找药：按需求在药箱里找药品',
              icon: const Icon(Icons.auto_awesome_outlined),
              onPressed: _aiQuery),
        if (_families.isNotEmpty)
          IconButton(
              tooltip: '家庭成员与家庭管理',
              icon: const Icon(Icons.group_outlined),
              onPressed: _manageFamilies),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _families.isEmpty
              ? _emptyGuide()
              : Column(children: [
                  _familyChips(),
                  if (_aiBusy || _aiMatchIds != null) _aiBanner(),
                  Expanded(child: _cabinet()),
                ]),
    );
  }

  Widget _emptyGuide() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.medication_liquid_outlined,
              size: 64, color: LingShuColors.gold.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          const Text('还没有小家庭',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('从家庭成员中选人组成一个小家庭，\n每个小家庭拥有一个独立药箱。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.6, color: LingShuColors.inkSoft)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _createFamilyFlow(),
            icon: const Icon(Icons.add_home_outlined),
            label: const Text('创建小家庭'),
          ),
        ]),
      ),
    );
  }

  Widget _familyChips() {
    return SizedBox(
      height: 52,
      child: Row(children: [
        Expanded(
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
            children: [
              for (final f in _families)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_members[f.id] == null
                        ? f.name
                        : '${f.name}（${_members[f.id]!.length}人）'),
                    selected: f.id == _currentFamily,
                    onSelected: (_) {
                      _currentFamily = f.id;
                      _reloadMeds();
                    },
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: '新建小家庭',
          icon: const Icon(Icons.add_home_outlined),
          onPressed: _createFamilyFlow,
        ),
      ]),
    );
  }

  Widget _cabinet() {
    final all = _medicines;
    final meds = _aiMatchIds == null
        ? all
        : all.where((m) => _aiMatchIds!.contains(m.id)).toList();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10,
          childAspectRatio: 0.82),
      itemCount: meds.length + 1,
      itemBuilder: (context, i) {
        if (i == meds.length) return _addCell();
        return _CabinetCell(
            medicine: meds[i],
            onTap: () => _openDrawer(meds[i]),
            onExpiredTap: () => _openDrawer(meds[i]));
      },
    );
  }

  Widget _addCell() {
    return InkWell(
      onTap: _addMedicine,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: LingShuColors.cardBorder,
              strokeAlign: BorderSide.strokeAlignInside),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_circle_outline,
              size: 30, color: LingShuColors.gold.withValues(alpha: 0.75)),
          const SizedBox(height: 6),
          const Text('放入药品',
              style: TextStyle(fontSize: 11.5, color: LingShuColors.inkSoft)),
        ]),
      ),
    );
  }

  // ---- AI 找药 ----

  /// 输入需求（如"有没有治感冒的药"）→ AI 在当前药箱清单里挑相关药品
  /// → 药柜只显示命中的格子，横幅里可一键清除筛选
  Future<void> _aiQuery() async {
    if (_sheetOpen || _currentFamily == null) return;
    _sheetOpen = true;
    final query = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AiQuerySheet(),
    );
    _sheetOpen = false;
    if (query == null || query.trim().isEmpty) return;
    final meds = _medicines;
    setState(() {
      _aiBusy = true;
      _aiMatchIds = null;
      _aiReason = null;
    });
    try {
      final ai = await ref.read(aiConfigProvider.future);
      final inv = <String>[
        for (var i = 0; i < meds.length; i++)
          '$i|${meds[i].name}|'
              '${(meds[i].usage == null || meds[i].usage!.isEmpty) ? '未填' : meds[i].usage}|'
              '${_dateText(meds[i].expireDate)}'
      ];
      final res = await ai.matchBoxMedicines(query.trim(), inv);
      if (!mounted) return;
      final hits = <int>{
        for (final idx in res.matches)
          if (idx >= 0 && idx < meds.length) meds[idx].id,
      };
      setState(() {
        _aiBusy = false;
        if (hits.isNotEmpty) {
          _aiMatchIds = hits;
          _aiReason = res.reason;
        }
      });
      if (hits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res.reason.isEmpty
                ? '药箱里没有找到与「${query.trim()}」相关的药品'
                : '没有找到相关药品：${res.reason}')));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _aiBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('AI 找药失败，请检查网络与 AI 设置（我的 → 设置）')));
    }
  }

  void _clearAiFilter() {
    setState(() {
      _aiMatchIds = null;
      _aiReason = null;
    });
  }

  static String _dateText(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _aiBanner() {
    final deco = BoxDecoration(
      color: LingShuColors.gold.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: LingShuColors.gold.withValues(alpha: 0.35)),
    );
    if (_aiBusy) {
      return Container(
        margin: const EdgeInsets.fromLTRB(14, 4, 14, 0),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: deco,
        child: const Row(children: [
          SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 10),
          Text('AI 正在药箱里找…',
              style: TextStyle(
                  fontSize: 12.5, color: LingShuColors.inkSoft)),
        ]),
      );
    }
    final ids = _aiMatchIds;
    if (ids == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 0),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: deco,
      child: Row(children: [
        const Icon(Icons.auto_awesome, size: 15, color: LingShuColors.gold),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'AI 找到 ${ids.length} 种相关药品'
            '${(_aiReason == null || _aiReason!.isEmpty) ? '' : '：$_aiReason'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12, height: 1.4, color: LingShuColors.ink),
          ),
        ),
        IconButton(
            tooltip: '清除筛选，显示全部药品',
            visualDensity: VisualDensity.compact,
            onPressed: _clearAiFilter,
            icon: const Icon(Icons.close, size: 18)),
      ]),
    );
  }

  // ---- 家庭组 ----

  Future<void> _createFamilyFlow() async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _FamilySetupSheet());
    _sheetOpen = false;
    if (ok == true) _reload();
  }

  Future<void> _manageFamilies() async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    try {
      await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => _FamilyManageSheet(families: _families));
    } finally {
      _sheetOpen = false;
    }
    _reload();
  }

  // ---- 药品 ----

  Future<void> _addMedicine() async {
    debugPrint('[box] add tap, sheetOpen=$_sheetOpen, family=$_currentFamily');
    if (_sheetOpen || _currentFamily == null) return;
    _sheetOpen = true;
    debugPrint('[box] add OPEN');
    try {
      await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => _MedEditSheet(familyId: _currentFamily!));
    } finally {
      _sheetOpen = false;
      debugPrint('[box] add CLOSED');
    }
    _reload();
  }

  Future<void> _openDrawer(BoxMedicine m) async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    try {
      await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _DrawerSheet(medicine: m));
    } finally {
      _sheetOpen = false;
    }
    _reloadMeds();
  }
}

// ================= 药柜格子 =================


/// 解析药品的照片路径列表：v9 起为 JSON 数组；兼容 v0.1.27 的旧单路径字符串
List<String> _medicinePaths(BoxMedicine m) {
  final raw = (m.imagePaths != null && m.imagePaths!.isNotEmpty)
      ? m.imagePaths
      : m.imagePath;
  if (raw == null || raw.isEmpty) return const [];
  if (raw.startsWith('[')) {
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {}
  }
  return [raw];
}

class _CabinetCell extends StatelessWidget {
  final BoxMedicine medicine;
  final VoidCallback onTap;
  final VoidCallback onExpiredTap;
  const _CabinetCell(
      {required this.medicine,
      required this.onTap,
      required this.onExpiredTap});

  static const woodTop = Color(0xFF7A4E2D);
  static const woodBottom = Color(0xFF4E2F16);

  int get _daysLeft {
    final now = DateTime.now();
    final exp = DateTime(
        medicine.expireDate.year, medicine.expireDate.month, medicine.expireDate.day);
    return exp.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  Color get _expireColor {
    final d = _daysLeft;
    if (d < 0) return const Color(0xFFE05252);
    if (d <= 30) return const Color(0xFFE8734B);
    if (d <= 90) return const Color(0xFFE8B84B);
    if (d <= 180) return const Color(0xFFCFC08A);
    return const Color(0xFFF2E6C9);
  }

  String get _dateLabel {
    final e = medicine.expireDate;
    return '${e.year}.${e.month.toString().padLeft(2, '0')}.${e.day.toString().padLeft(2, '0')}';
  }

  String get _daysLabel {
    final d = _daysLeft;
    if (d < 0) return '已过期 ${-d} 天';
    if (d == 0) return '今日到期';
    return '剩 $d 天';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [woodTop, woodBottom]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A2310), width: 1.2),
          boxShadow: const [
            BoxShadow(color: Color(0x333A2310), blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(children: [
          // 把手
          Container(
            width: 34,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD9AE62).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const Spacer(),
          // 药名（竖排上限 2 列，超长截断）
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                medicine.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF6ECD7)),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 到期日与剩余天数分两行：格子窄，拼一行会被截断
          Text(_dateLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 9.5,
                  color: _expireColor.withValues(alpha: 0.85))),
          const SizedBox(height: 1),
          Text(_daysLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10.5,
                  color: _expireColor,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
        ]),
      ),
    );
  }
}

// ================= 拉开抽屉 =================

/// 点击药柜格：底部抽屉里"拉开柜门"——木门向左滑出，露出原始照片与操作
class _DrawerSheet extends StatefulWidget {
  final BoxMedicine medicine;
  const _DrawerSheet({required this.medicine});

  @override
  State<_DrawerSheet> createState() => _DrawerSheetState();
}

class _DrawerSheetState extends State<_DrawerSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650));
  bool _doorGone = false; // 拉开完成后柜门整个移出渲染树，杜绝残留遮盖

  @override
  void initState() {
    super.initState();
    _slide.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _doorGone = true);
      }
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _slide.forward();
    });
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.medicine;
    return Container(
      margin: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxHeight: 560),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2430),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(children: [
        // 抽屉内部：照片（多张可横滑）+ 信息 + 操作
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _DrawerPhotos(paths: _medicinePaths(m)),
            const SizedBox(height: 12),
            Text(m.name,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF2E6C9))),
            const SizedBox(height: 4),
            Text(
                '到期：${m.expireDate.year}.${m.expireDate.month.toString().padLeft(2, '0')}.${m.expireDate.day.toString().padLeft(2, '0')}',
                style: const TextStyle(
                    fontSize: 12.5, color: LingShuColors.inkSoft)),
            if ((m.usage ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(m.usage!,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.5,
                      color: LingShuColors.goldSoft)),
            ],
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => _MedEditSheet.edit(m));
                  },
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('编辑'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _delete,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE05252)),
                  icon: const Icon(Icons.delete_outline, size: 17),
                  label: const Text('删除'),
                ),
              ),
            ]),
          ]),
        ),
        // 柜门：向左拉开（完成后整个移出，杜绝 sub-pixel 残留遮盖）
        if (!_doorGone)
          Positioned.fill(
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: Offset.zero, end: const Offset(-1.05, 0))
                  .animate(CurvedAnimation(
                      parent: _slide, curve: Curves.easeOutCubic)),
              child: _CabinetDoor(medicine: m),
            ),
          ),
      ]),
    );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('取出药品'),
                content: Text('将「${widget.medicine.name}」从药箱删除？'
                    '到期提醒也会一并取消。'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('取消')),
                  FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFB03A2E)),
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('删除')),
                ]));
    if (ok != true || !mounted) return;
    final container = ProviderScope.containerOf(context);
    final db = container.read(dbProvider);
    for (final img in _medicinePaths(widget.medicine)) {
      try {
        final f = File(img);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
    await (db.delete(db.boxMedicines)
          ..where((t) => t.id.equals(widget.medicine.id)))
        .go();
    await container
        .read(notificationServiceProvider)
        .cancelBoxMedicine(widget.medicine.id);
    if (mounted) Navigator.pop(context);
  }
}

/// 抽屉照片区：多张可横滑，单张直接显示；页码点指示
class _DrawerPhotos extends StatefulWidget {
  final List<String> paths;
  const _DrawerPhotos({required this.paths});
  @override
  State<_DrawerPhotos> createState() => _DrawerPhotosState();
}

class _DrawerPhotosState extends State<_DrawerPhotos> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paths = widget.paths.where((p) => File(p).existsSync()).toList();
    if (paths.isEmpty) {
      return Container(
          height: 200,
          width: double.infinity,
          color: const Color(0xFF243240),
          alignment: Alignment.center,
          child: const Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.photo_outlined, size: 34, color: Colors.white24),
            SizedBox(height: 10),
            Text('无照片',
                style: TextStyle(fontSize: 13, color: Colors.white38)),
            SizedBox(height: 6),
            Text('这条药品保存于旧版本，点下方「编辑」补拍照片',
                style: TextStyle(fontSize: 11, color: Colors.white24)),
          ]));
    }
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 300,
          width: double.infinity,
          child: PageView.builder(
            controller: _controller,
            itemCount: paths.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) =>
                Image.file(File(paths[i]), fit: BoxFit.cover),
          ),
        ),
      ),
      if (paths.length > 1) ...[
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < paths.length; i++)
            Container(
              width: i == _page ? 18 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color:
                    i == _page ? LingShuColors.gold : Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ]),
      ],
    ]);
  }
}

/// 柜门：木纹 + 药名 + 到期日 + 把手（拉开动画的主体）
class _CabinetDoor extends StatelessWidget {
  final BoxMedicine medicine;
  const _CabinetDoor({required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7A4E2D), Color(0xFF4E2F16)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A2310), width: 1.5),
      ),
      child: Row(children: [
        // 左侧长把手
        Container(
          width: 14,
          margin: const EdgeInsets.symmetric(vertical: 60, horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFD9AE62),
            borderRadius: BorderRadius.circular(7),
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), blurRadius: 3),
            ],
          ),
        ),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Text(medicine.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF6ECD7))),
            const SizedBox(height: 10),
            Text(
                '到期 ${medicine.expireDate.year}.${medicine.expireDate.month.toString().padLeft(2, '0')}.${medicine.expireDate.day.toString().padLeft(2, '0')}',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFFD9AE62))),
          ]),
        ),
      ]),
    );
  }
}

// ================= 添加 / 编辑药品 =================

class _MedEditSheet extends ConsumerStatefulWidget {
  final int? familyId; // 新建模式
  final BoxMedicine? editing; // 编辑模式
  const _MedEditSheet({required this.familyId}) : editing = null;
  const _MedEditSheet.edit(BoxMedicine m)
      : familyId = null,
        editing = m;

  @override
  ConsumerState<_MedEditSheet> createState() => _MedEditSheetState();
}

class _MedEditSheetState extends ConsumerState<_MedEditSheet> {
  final _name = TextEditingController();
  final _usage = TextEditingController();
  DateTime? _expire;
  final _images = <Uint8List>[]; // 当前全部照片（含已落盘读回的）
  List<String> _oldPaths = const []; // 编辑模式落盘路径（保存时清理孤儿）
  bool _recognizing = false;
  String? _error;
  bool _saving = false;

  BoxMedicine? get _m => widget.editing;

  @override
  void initState() {
    super.initState();
    // 提前请求通知与精确闹钟权限：若留到保存时请求，跳系统设置的往返
    // 会打断到期提醒的排期链路
    ref.read(notificationServiceProvider).init();
    final m = _m;
    if (m != null) {
      _name.text = m.name;
      _expire = m.expireDate;
      _usage.text = m.usage ?? '';
      () async {
        final loaded = <Uint8List>[];
        for (final path in _medicinePaths(m)) {
          try {
            if (File(path).existsSync()) loaded.add(await File(path).readAsBytes());
          } catch (_) {}
        }
        if (loaded.isNotEmpty && mounted) setState(() => _images.addAll(loaded));
      }();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _usage.dispose();
    super.dispose();
  }

  /// 拍照 = 追加一张；相册 = 可多选追加。追加后自动对全部照片重新识别。
  Future<void> _pickPhoto(ImageSource src) async {
    try {
      List<XFile> picked = [];
      if (src == ImageSource.gallery) {
        picked = await ImagePicker().pickMultiImage(
            maxWidth: 1600, imageQuality: 85);
      } else {
        final x = await ImagePicker().pickImage(
            source: src, maxWidth: 1600, imageQuality: 85);
        if (x != null) picked = [x];
      }
      if (picked.isEmpty) return;
      final bytesList = [for (final x in picked) await x.readAsBytes()];
      if (!mounted) return;
      setState(() {
        _images.addAll(bytesList);
        _error = null;
      });
    } catch (_) {}
  }

  Widget _addTile(ImageSource src, IconData icon, String label) {
    return InkWell(
      onTap: () => _pickPhoto(src),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LingShuColors.cardBorder),
        ),
        alignment: Alignment.center,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 26, color: LingShuColors.gold),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 10.5, color: LingShuColors.inkSoft)),
        ]),
      ),
    );
  }

  /// 手动触发 AI 识别（照片加完后统一分析）
  Future<void> _startRecognize() async {
    if (_images.isEmpty || _recognizing) return;
    setState(() => _recognizing = true);
    await _recognize();
  }

  Future<void> _recognize() async {
    if (_images.isEmpty) return;
    try {
      final ai = await ref.read(aiConfigProvider.future);
      final draft = await ai.recognizeBoxMedicine(_images);
      if (!mounted) return;
      setState(() {
        _recognizing = false;
        if (draft.name != null && _name.text.isEmpty) _name.text = draft.name!;
        if (draft.expireDate != null) _expire = draft.expireDate;
        if (draft.usage != null && _usage.text.isEmpty) {
          _usage.text = draft.usage!;
        }
        if (draft.rawExpire.isNotEmpty) {
          _error = '识别到有效期原文：${draft.rawExpire}，请核对';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recognizing = false;
        _error = 'AI 识别失败，请手动填写名称、到期日与用法';
      });
    }
  }

  /// 把当前全部照片写盘（先清掉该药的旧图，防孤儿），返回路径列表
  Future<List<String>> _savePhotos(int medId) async {
    final dir = await getApplicationDocumentsDirectory();
    final dirBox = Directory('${dir.path}/box_photos');
    if (!dirBox.existsSync()) dirBox.createSync(recursive: true);
    for (final old in _oldPaths) {
      try {
        final f = File(old);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    final paths = <String>[];
    for (var i = 0; i < _images.length; i++) {
      final path = '${dirBox.path}/med_${medId}_${ts}_$i.jpg';
      await File(path).writeAsBytes(_images[i]);
      paths.add(path);
    }
    return paths;
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final expire = _expire;
    final usage = _usage.text.trim();
    if (name.isEmpty || expire == null || _saving) return;
    setState(() => _saving = true);
    try {
      final db = ref.read(dbProvider);

      if (_m == null) {
        final id = await db
            .into(db.boxMedicines)
            .insert(BoxMedicinesCompanion.insert(
                familyId: widget.familyId!,
                name: name,
                expireDate: expire,
                note: const Value(null)));
        final paths = await _savePhotos(id);
        await (db.update(db.boxMedicines)..where((t) => t.id.equals(id)))
            .write(BoxMedicinesCompanion(
                imagePaths: Value(jsonEncode(paths)),
                usage: Value(usage.isEmpty ? null : usage)));
      } else {
        final paths = await _savePhotos(_m!.id);
        await (db.update(db.boxMedicines)..where((t) => t.id.equals(_m!.id)))
            .write(BoxMedicinesCompanion(
                name: Value(name),
                expireDate: Value(expire),
                imagePaths: Value(jsonEncode(paths)),
                usage: Value(usage.isEmpty ? null : usage),
                note: const Value(null)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '保存失败：$e';
      });
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickExpire() async {
    final now = DateTime.now();
    final d = await showDatePicker(
        context: context,
        initialDate: _expire ?? now.add(const Duration(days: 365)),
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 20));
    if (d != null) setState(() => _expire = d);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = _m == null;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        constraints: const BoxConstraints(maxHeight: 640),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isNew ? '放入药品' : '编辑药品',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
                isNew
                    ? '拍下药品包装，AI 自动识别名称与到期日；也可直接手动填写。'
                    : '修改后到期提醒会自动按新日期重排。',
                style: const TextStyle(
                    fontSize: 11.5, color: LingShuColors.inkSoft)),
            const SizedBox(height: 14),
            if (_images.isEmpty)
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined,
                            size: 18),
                        label: const Text('拍照'))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_outlined, size: 18),
                        label: const Text('相册'))),
              ])
            else ...[
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length + 2,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    if (i == _images.length) {
                      return _addTile(ImageSource.camera,
                          Icons.photo_camera_outlined, '拍照');
                    }
                    if (i == _images.length + 1) {
                      return _addTile(ImageSource.gallery,
                          Icons.photo_outlined, '相册');
                    }
                    return Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_images[i],
                            width: 120,
                            height: 150,
                            fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: InkWell(
                          onTap: () => setState(() => _images.removeAt(i)),
                          child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: Color(0x99000000),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  size: 15, color: Colors.white)),
                        ),
                      ),
                    ]);
                  },
                ),
              ),
            ],
            if (_images.isNotEmpty && !_recognizing) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: _startRecognize,
                  style: FilledButton.styleFrom(
                      backgroundColor: WuXing.wood.withValues(alpha: 0.12),
                      foregroundColor: WuXing.wood),
                  child: const Text('开始 AI 识别（名称 / 到期日 / 用法）',
                      style: TextStyle(letterSpacing: 1)),
                ),
              ),
            ],
            if (_recognizing)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Row(children: [
                  SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('AI 识别中…',
                      style: TextStyle(
                          fontSize: 11.5, color: LingShuColors.inkSoft)),
                ]),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(
                      fontSize: 11.5, color: LingShuColors.gold)),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _name,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                  labelText: '药品名称', prefixIcon: Icon(Icons.medication_outlined)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usage,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: '用法用量 / 说明（可留空）',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.receipt_long_outlined)),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickExpire,
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: '到期日期', prefixIcon: Icon(Icons.event_outlined)),
                child: Text(
                    _expire == null
                        ? '请选择'
                        : '${_expire!.year}.${_expire!.month.toString().padLeft(2, '0')}.${_expire!.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                        fontSize: 15,
                        color: _expire == null
                            ? LingShuColors.inkSoft
                            : LingShuColors.ink)),
              ),
            ),
            const SizedBox(height: 8),
            const Text('到期前 6 个月、3 个月、1 个月会自动提醒；过期后每天提醒一次。',
                style: TextStyle(fontSize: 11, color: LingShuColors.inkSoft)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    (_name.text.trim().isEmpty || _expire == null || _saving)
                        ? null
                        : _save,
                child: Text(_saving ? '保存中…' : '保存放入药箱'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ================= AI 找药输入 =================

/// 一句话需求输入；提交时 Navigator.pop(context, query) 交回调用方
class _AiQuerySheet extends StatefulWidget {
  const _AiQuerySheet();

  @override
  State<_AiQuerySheet> createState() => _AiQuerySheetState();
}

class _AiQuerySheetState extends State<_AiQuerySheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.auto_awesome, size: 18, color: LingShuColors.gold),
            SizedBox(width: 6),
            Text('AI 找药',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          const Text(
              '用一句话说需求，AI 在当前药箱里帮你找；只上传药品名称与用法用量，不上传照片。',
              style: TextStyle(fontSize: 11.5, color: LingShuColors.inkSoft)),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            autofocus: true,
            minLines: 1,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
                hintText: '如：有没有治感冒的药',
                prefixIcon: Icon(Icons.search)),
          ),
          const SizedBox(height: 14),
          SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: _ctrl.text.trim().isEmpty
                      ? null
                      : () => Navigator.pop(context, _ctrl.text.trim()),
                  child: const Text('在药箱里找一找'))),
        ]),
      ),
    );
  }
}

// ================= 家庭组管理 =================

/// 创建小家庭：家庭名 + 从成员中勾选
class _FamilySetupSheet extends ConsumerStatefulWidget {
  const _FamilySetupSheet();

  @override
  ConsumerState<_FamilySetupSheet> createState() => _FamilySetupSheetState();
}

class _FamilySetupSheetState extends ConsumerState<_FamilySetupSheet> {
  final _name = TextEditingController();
  final _picked = <int>{};
  List<Profile> _profiles = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    () async {
      final db = ref.read(dbProvider);
      final ps = await db.select(db.profiles).get();
      if (mounted) setState(() => _profiles = ps);
    }();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    final db = ref.read(dbProvider);
    final fid = await db
        .into(db.families)
        .insert(FamiliesCompanion.insert(name: name));
    for (final pid in _picked) {
      await db.into(db.familyMembers).insert(
          FamilyMembersCompanion.insert(familyId: fid, profileId: pid));
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('创建小家庭',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
              controller: _name,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                  labelText: '家庭名称（如：我们家 / 爸妈家）',
                  prefixIcon: Icon(Icons.home_outlined))),
          const SizedBox(height: 8),
          const Text('选择加入这个家庭的成员：',
              style: TextStyle(fontSize: 12.5, color: LingShuColors.inkSoft)),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final p in _profiles)
                  CheckboxListTile(
                      dense: true,
                      value: _picked.contains(p.id),
                      title: Text(p.name),
                      secondary: CircleAvatar(
                          radius: 14,
                          child: Text(p.name.characters.first,
                              style: const TextStyle(fontSize: 12))),
                      onChanged: (v) => setState(() {
                            v == true
                                ? _picked.add(p.id)
                                : _picked.remove(p.id);
                          })),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
                onPressed: (_name.text.trim().isEmpty || _saving) ? null : _save,
                child: Text(_saving ? '创建中…' : '创建并进入药箱')),
          ),
        ]),
      ),
    );
  }
}

/// 管理家庭：成员增减 / 新建 / 删除家庭
class _FamilyManageSheet extends ConsumerStatefulWidget {
  final List<FamilyRow> families;
  const _FamilyManageSheet({required this.families});

  @override
  ConsumerState<_FamilyManageSheet> createState() =>
      _FamilyManageSheetState();
}

class _FamilyManageSheetState extends ConsumerState<_FamilyManageSheet> {
  FamilyRow? _current;
  List<Profile> _profiles = [];
  Set<int> _memberIds = {};

  @override
  void initState() {
    super.initState();
    _current = widget.families.first;
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(dbProvider);
    final ps = await db.select(db.profiles).get();
    final links = await (db.select(db.familyMembers)
          ..where((t) => t.familyId.equals(_current!.id)))
        .get();
    if (!mounted) return;
    setState(() {
      _profiles = ps;
      _memberIds = links.map((l) => l.profileId).toSet();
    });
  }

  Future<void> _toggle(int profileId, bool join) async {
    final db = ref.read(dbProvider);
    if (join) {
      await db.into(db.familyMembers).insert(
          FamilyMembersCompanion.insert(
              familyId: _current!.id, profileId: profileId));
    } else {
      await (db.delete(db.familyMembers)
            ..where((t) => t.familyId.equals(_current!.id))
            ..where((t) => t.profileId.equals(profileId)))
          .go();
    }
    await _load();
  }

  Future<void> _deleteFamily() async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: Text('删除「${_current!.name}」'),
                content: const Text('家庭药箱里的全部药品与提醒将一并删除。'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('取消')),
                  FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFB03A2E)),
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('删除')),
                ]));
    if (ok != true || !mounted) return;
    final container = ProviderScope.containerOf(context);
    final db = container.read(dbProvider);
    final meds = await (db.select(db.boxMedicines)
          ..where((t) => t.familyId.equals(_current!.id)))
        .get();
    final notif = container.read(notificationServiceProvider);
    for (final m in meds) {
      await notif.cancelBoxMedicine(m.id);
      if (m.imagePath != null && File(m.imagePath!).existsSync()) {
        try {
          File(m.imagePath!).deleteSync();
        } catch (_) {}
      }
    }
    await (db.delete(db.boxMedicines)
          ..where((t) => t.familyId.equals(_current!.id)))
        .go();
    await (db.delete(db.familyMembers)
          ..where((t) => t.familyId.equals(_current!.id)))
        .go();
    await (db.delete(db.families)..where((t) => t.id.equals(_current!.id)))
        .go();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      constraints: const BoxConstraints(maxHeight: 620),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('管理小家庭',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
            spacing: 8,
            children: [
              for (final f in widget.families)
                ChoiceChip(
                    label: Text(f.name),
                    selected: _current?.id == f.id,
                    onSelected: (_) {
                      _current = f;
                      _load();
                    }),
            ]),
        if (_current != null) ...[
          const SizedBox(height: 8),
          Text('「${_current!.name}」的成员（勾选 = 在这个家庭）：',
              style:
                  const TextStyle(fontSize: 12.5, color: LingShuColors.inkSoft)),
          Flexible(
            child: ListView(shrinkWrap: true, children: [
              for (final p in _profiles)
                CheckboxListTile(
                    dense: true,
                    value: _memberIds.contains(p.id),
                    title: Text(p.name),
                    onChanged: (v) => _toggle(p.id, v == true)),
            ]),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
                onPressed: _deleteFamily,
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB03A2E)),
                icon: const Icon(Icons.delete_outline, size: 17),
                label: const Text('删除这个家庭')),
          ),
        ],
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('完成')),
        ),
      ]),
    );
  }
}
