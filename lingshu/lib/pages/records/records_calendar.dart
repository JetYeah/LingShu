import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/db.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import 'records_page.dart';

/// 档案日历：双指缩放在 人生周期→年→月→日 四级视图间切换，
/// 有报告的年/月/日以类型色球标记，逐层下钻定位。打开默认停在人生周期。
/// 人生周期按《黄帝内经·上古天真论》"女七男八"分段：
/// 女性自出生每 7 年一段（一七～七七后延续 九七…十六七），男性每 8 年一段
/// （一八～八八后延续 九八…十四八），覆盖到 112 岁，每屏 3 段上下翻页。
class RecordsCalendarView extends StatefulWidget {
  final List<MedicalRecord> records;
  final void Function(MedicalRecord) onOpenRecord;
  final String gender; // male / female，决定周期段宽（女七男八）
  final int? birthYear; // 出生年；未知则取最早记录年
  const RecordsCalendarView({
    super.key,
    required this.records,
    required this.onOpenRecord,
    this.gender = 'male',
    this.birthYear,
  });

  @override
  State<RecordsCalendarView> createState() => _RecordsCalendarViewState();
}

enum _Zoom { lifespan, year, month, day }

class _RecordsCalendarViewState extends State<RecordsCalendarView> {
  _Zoom _zoom = _Zoom.lifespan; // 打开日历默认停在人生周期
  late int _year;
  late int _month;
  late int _day;
  final _ctrl = TransformationController();
  double _gestureScale = 1.0; // 本次捏合的累计缩放（相对手势开始）
  PageController? _lifespanCtrl; // 一生视图：竖向翻页，每页 3 段

  late final int _step = widget.gender == 'female' ? 7 : 8; // 女七男八
  // 段序号中文数字：八八之后继续 九八、十八、十一八 ……
  static const _cn = ['一', '二', '三', '四', '五', '六', '七', '八', '九', '十',
    '十一', '十二', '十三', '十四', '十五', '十六'];

  /// 一生视图覆盖到 112 岁：女 7×16 段 / 男 8×14 段，每屏 3 段
  int get _segCount => 112 ~/ _step;
  static const _perPage = 3;
  int get _pageCount => (_segCount + _perPage - 1) ~/ _perPage;

  int? get _birthYear {
    final b = widget.birthYear;
    if (b != null && b > 1900) return b;
    if (widget.records.isEmpty) return null;
    return widget.records
        .map((e) => e.recordDate.year)
        .reduce((a, b) => a < b ? a : b);
  }

  int _segOfYear(int y) {
    final birth = _birthYear!;
    return ((y - birth) ~/ _step).clamp(0, _segCount - 1);
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final latest = widget.records.isEmpty
        ? now
        : widget.records.map((e) => e.recordDate).reduce((a, b) => a.isAfter(b) ? a : b);
    _year = latest.year;
    _month = latest.month;
    _day = latest.day;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _lifespanCtrl?.dispose();
    super.dispose();
  }

  void _resetTransform() {
    _ctrl.value = Matrix4.identity();
  }

  void _zoomIn() {
    // 捏开放大：下钻 年→月→日
    if (_zoom == _Zoom.year) {
      setState(() => _zoom = _Zoom.month);
    } else if (_zoom == _Zoom.month) {
      setState(() => _zoom = _Zoom.day);
    }
    _resetTransform();
  }

  void _zoomOut() {
    if (_zoom == _Zoom.day) {
      setState(() => _zoom = _Zoom.month);
    } else if (_zoom == _Zoom.month) {
      setState(() => _zoom = _Zoom.year);
    } else if (_zoom == _Zoom.year) {
      _enterLifespan();
    }
    _resetTransform();
  }

  /// 进入一生视图：翻到 _year 所在页。
  /// 该视图是竖向 PageView（自身可滚动），不再包在 InteractiveViewer 里，
  /// 所以进入时不走捏合手势，翻页靠滑动、进入年视图靠点击。
  void _enterLifespan() {
    if (_birthYear == null) return;
    setState(() => _zoom = _Zoom.lifespan);
    _resetTransform();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _lifespanCtrl;
      if (c == null || !c.hasClients) return;
      final target = _segOfYear(_year) ~/ _perPage;
      if ((c.page ?? target) != target) c.jumpToPage(target);
    });
  }

  List<MedicalRecord> _recordsOf(DateTime from, DateTime to) => widget.records
      .where((r) => !r.recordDate.isBefore(from) && r.recordDate.isBefore(to))
      .toList();

  List<String> _ballsOf(List<MedicalRecord> list) {
    // 该时段报告类型色球（去重，最多 3 个）
    final types = <String>[];
    for (final r in list) {
      if (!types.contains(r.type)) types.add(r.type);
      if (types.length >= 3) break;
    }
    return types;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _header(),
      Expanded(
        // 一生视图自带竖向翻页，不进 InteractiveViewer；
        // 年/月/日必须无纵向滚动（否则滚动手势抢走捏合，缩放不生效）
        child: _zoom == _Zoom.lifespan
            ? _lifespanPager()
            : InteractiveViewer(
                transformationController: _ctrl,
                minScale: 0.6,
                maxScale: 3.4,
                onInteractionStart: (_) => _gestureScale = 1.0,
                onInteractionUpdate: (d) => _gestureScale = d.scale,
                onInteractionEnd: (_) {
                  if (_gestureScale > 1.9 && _zoom != _Zoom.day) _zoomIn();
                  // 缩小：日→月→年→一生（一生视图已不在 InteractiveViewer 内）
                  if (_gestureScale < 0.55) _zoomOut();
                },
                child: switch (_zoom) {
                  _Zoom.year => _yearGrid(),
                  _Zoom.month => _monthGrid(),
                  _Zoom.day => _dayList(),
                  _ => const SizedBox.shrink(),
                },
              ),
      ),
      _hint(),
    ]);
  }

  String get _zoomLabel => switch (_zoom) {
        _Zoom.lifespan => '人生周期 · 上下翻页查看各段 · 点击卡片或年份进入年视图',
        _Zoom.year => '年视图 · 捏合放大进入月份 · 捏合缩小查看一生',
        _Zoom.month => '月视图 · 捏合放大查看某日',
        _Zoom.day => '日视图 · 捏合缩小返回',
      };

  Widget _hint() => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(_zoomLabel,
            style: const TextStyle(
                fontSize: 11, color: LingShuColors.inkSoft, letterSpacing: 1)),
      );

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
        child: Row(children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: _zoom == _Zoom.lifespan ? null : () {
              setState(() {
                if (_zoom == _Zoom.year) _year--;
                if (_zoom == _Zoom.month) {
                  if (_month == 1) { _year--; _month = 12; } else { _month--; }
                }
                if (_zoom == _Zoom.day) {
                  final d = DateTime(_year, _month, _day).subtract(const Duration(days: 1));
                  _year = d.year; _month = d.month; _day = d.day;
                }
              });
            },
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _zoom == _Zoom.year && _birthYear != null
                  ? _enterLifespan
                  : null,
              child: Text(_title(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'SerifSC',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2)),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: _zoom == _Zoom.lifespan ? null : () {
              setState(() {
                if (_zoom == _Zoom.year) _year++;
                if (_zoom == _Zoom.month) {
                  if (_month == 12) { _year++; _month = 1; } else { _month++; }
                }
                if (_zoom == _Zoom.day) {
                  final d = DateTime(_year, _month, _day + 1);
                  _year = d.year; _month = d.month; _day = d.day;
                }
              });
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ]),
      );

  String _title() => switch (_zoom) {
        _Zoom.lifespan => widget.gender == 'female' ? '女七 · 人生周期' : '男八 · 人生周期',
        _Zoom.year => '$_year 年',
        _Zoom.month => '$_year 年 $_month 月',
        _Zoom.day => '$_year 年 $_month 月 $_day 日',
      };

  // ── 人生周期视图：按《上古天真论》女七男八分段，每页 3 段，上下翻页到 112 岁 ──
  Widget _lifespanPager() {
    final birth = _birthYear;
    if (birth == null) {
      return const Center(
          child: Text('填写出生日期后即可查看人生周期',
              style: TextStyle(fontSize: 13, color: LingShuColors.inkSoft)));
    }
    _lifespanCtrl ??= PageController(
        initialPage: _segOfYear(_year) ~/ _perPage, viewportFraction: 0.97);
    final thisYear = DateTime.now().year;
    return PageView.builder(
      scrollDirection: Axis.vertical,
      controller: _lifespanCtrl,
      itemCount: _pageCount,
      itemBuilder: (context, page) => _lifespanPage(page, birth, thisYear),
    );
  }

  Widget _lifespanPage(int page, int birth, int thisYear) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 8),
      child: Column(children: [
        for (var i = 0; i < _perPage; i++)
          Expanded(
            child: page * _perPage + i < _segCount
                ? _segmentCard(page * _perPage + i, birth, thisYear)
                : const SizedBox(),
          ),
      ]),
    );
  }

  Widget _segmentCard(int k, int birth, int thisYear) {
    final yearFrom = birth + _step * k;
    final yearTo = birth + _step * (k + 1);
    final ageFrom = _step * k + 1; // 虚岁
    final ageTo = _step * (k + 1);
    final list = _recordsOf(DateTime(yearFrom, 1, 1), DateTime(yearTo, 1, 1));
    final isCurrent = thisYear >= yearFrom && thisYear < yearTo;
    final segTitle = '${_cn[k]}${widget.gender == 'female' ? '七' : '八'}';
    final years = [for (var y = yearFrom; y < yearTo; y++) y];
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          _year = yearFrom > thisYear ? thisYear : yearFrom;
          _zoom = _Zoom.year;
        });
        _resetTransform();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(13, 9, 13, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isCurrent
                  ? LingShuColors.gold
                  : list.isEmpty
                      ? LingShuColors.cardBorder
                      : LingShuColors.gold.withValues(alpha: 0.5),
              width: isCurrent ? 1.6 : 1),
        ),
        child: Column(children: [
          Row(children: [
            Text(segTitle,
                style: TextStyle(
                    fontFamily: 'SerifSC',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: list.isEmpty
                        ? LingShuColors.inkSoft
                        : LingShuColors.gold)),
            const SizedBox(width: 9),
            if (isCurrent) _currentBadge,
            const Spacer(),
            Text('虚岁 $ageFrom–$ageTo · ${list.isEmpty ? '—' : '${list.length} 份'}',
                style: const TextStyle(
                    fontSize: 11.5, color: LingShuColors.inkSoft)),
          ]),
          const SizedBox(height: 3),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('$yearFrom–${yearTo - 1} 年',
                style: const TextStyle(
                    fontSize: 11.5, color: LingShuColors.inkSoft)),
          ),
          const SizedBox(height: 6),
          // 段内年份 4 列铺开，写全年份，有报告的高亮可点；
          // 行/格都用 Expanded 撑满卡片剩余高度，不因屏矮而溢出
          Expanded(
            child: Column(children: [
              for (var row = 0; row < (years.length + 3) ~/ 4; row++) ...[
                if (row > 0) const SizedBox(height: 7),
                Expanded(
                  child: Row(children: [
                    for (var col = 0; col < 4; col++)
                      (row * 4 + col) < years.length
                          ? Expanded(
                              child: _yearCell(years[row * 4 + col], list))
                          : const Expanded(child: SizedBox()),
                  ]),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget get _currentBadge => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: LingShuColors.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: LingShuColors.gold.withValues(alpha: 0.4)),
        ),
        child: const Text('当前阶段',
            style: TextStyle(fontSize: 10.5, color: LingShuColors.gold)),
      );

  Widget _yearCell(int y, List<MedicalRecord> segList) {
    final count = segList.where((r) => r.recordDate.year == y).length;
    final has = count > 0;
    final color = has
        ? typeColor(segList.firstWhere((r) => r.recordDate.year == y).type)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.5),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: has
            ? () {
                setState(() {
                  _year = y;
                  _zoom = _Zoom.year;
                });
                _resetTransform();
              }
            : null,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: has
                ? color!.withValues(alpha: 0.16)
                : LingShuColors.paperDeep.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: has
                    ? color!
                    : LingShuColors.cardBorder.withValues(alpha: 0.4),
                width: has ? 1 : 0.8),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$y',
                style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: has ? FontWeight.w700 : FontWeight.w400,
                    color: has
                        ? LingShuColors.ink
                        : LingShuColors.inkSoft.withValues(alpha: 0.55))),
            if (count > 1)
              Text('$count 份',
                  style: const TextStyle(
                      fontSize: 9.5, color: LingShuColors.inkSoft)),
          ]),
        ),
      ),
    );
  }

  // ── 年视图：12 个月格，4 行 flex 铺满（无滚动，捏合手势才不会被滚动手势抢走） ──
  Widget _yearGrid() {
    const monthNames = ['一月', '二月', '三月', '四月', '五月', '六月',
      '七月', '八月', '九月', '十月', '十一月', '十二月'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 20),
      child: Column(children: [
        for (var row = 0; row < 4; row++)
          Expanded(
            child: Row(children: [
              for (var col = 0; col < 3; col++)
                Expanded(
                    child: _monthCell(row * 3 + col + 1, monthNames[row * 3 + col])),
            ]),
          ),
      ]),
    );
  }

  Widget _monthCell(int m, String name) {
    final list = _recordsOf(DateTime(_year, m), DateTime(_year, m + 1));
    final balls = _ballsOf(list);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() {
          _month = m;
          _zoom = _Zoom.month;
        });
        _resetTransform();
      },
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: list.isEmpty ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: list.isEmpty
                  ? LingShuColors.cardBorder
                  : LingShuColors.gold.withValues(alpha: 0.5),
              width: list.isEmpty ? 0.8 : 1.2),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(name,
              style: const TextStyle(
                  fontFamily: 'SerifSC', fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          if (list.isEmpty)
            const Text('—',
                style: TextStyle(fontSize: 11, color: LingShuColors.inkSoft))
          else ...[
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final t in balls)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                      color: typeColor(t), shape: BoxShape.circle),
                ),
            ]),
            const SizedBox(height: 3),
            Text('${list.length} 份',
                style:
                    const TextStyle(fontSize: 10, color: LingShuColors.inkSoft)),
          ],
        ]),
      ),
    );
  }

  // ── 月视图：日格 ──
  Widget _monthGrid() {
    final first = DateTime(_year, _month, 1);
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final lead = (first.weekday - 1) % 7; // 周一为首
    const weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 20),
      child: Column(children: [
        Row(children: [
          for (final w in weekdayNames)
            Expanded(
              child: Center(
                  child: Text(w,
                      style: const TextStyle(
                          fontSize: 11, color: LingShuColors.inkSoft))),
            ),
        ]),
        const SizedBox(height: 4),
        Expanded(
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            childAspectRatio: 0.78,
            children: [
              for (var i = 0; i < lead; i++) const SizedBox(),
              for (var d = 1; d <= daysInMonth; d++) _dayCell(d),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _dayCell(int d) {
    final list = _recordsOf(
        DateTime(_year, _month, d), DateTime(_year, _month, d + 1));
    final balls = _ballsOf(list);
    final isToday = DateTime.now().year == _year &&
        DateTime.now().month == _month &&
        DateTime.now().day == d;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: list.isEmpty
          ? null
          : () {
              setState(() {
                _day = d;
                _zoom = _Zoom.day;
              });
              _resetTransform();
            },
      child: Container(
        margin: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: list.isEmpty
              ? Colors.white
              : LingShuColors.gold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isToday
                  ? LingShuColors.gold
                  : list.isEmpty
                      ? LingShuColors.cardBorder.withValues(alpha: 0.5)
                      : LingShuColors.gold.withValues(alpha: 0.4),
              width: isToday ? 1.4 : 0.8),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$d',
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isToday || list.isNotEmpty
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: list.isEmpty ? LingShuColors.inkSoft : LingShuColors.ink)),
          if (balls.isNotEmpty)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final t in balls)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                      color: typeColor(t), shape: BoxShape.circle),
                ),
            ]),
          if (list.length > 1)
            Text('×${list.length}',
                style: const TextStyle(
                    fontSize: 8.5, color: LingShuColors.inkSoft)),
        ]),
      ),
    );
  }

  // ── 日视图：当日记录列表 ──
  Widget _dayList() {
    final list = _recordsOf(
        DateTime(_year, _month, _day), DateTime(_year, _month, _day + 1));
    if (list.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.event_busy_outlined,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text('这一天没有报告',
              style: TextStyle(fontSize: 13, color: LingShuColors.inkSoft)),
          const SizedBox(height: 8),
          Text('捏合缩小返回月视图',
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade400)),
        ]),
      );
    }
    // 一天通常只有一两份报告：内容放得下就禁止滚动，捏合缩放手势更可靠
    return ListView.builder(
      physics: list.length < 4 ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 20),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final r = list[i];
        final color = typeColor(r.type);
        return LSCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          onTap: () => widget.onOpenRecord(r),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(typeIcons[r.type] ?? Icons.folder_outlined,
                  color: color, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('HH:mm').format(r.recordDate) +
                          ((r.hospital?.isNotEmpty == true)
                              ? ' · ${r.hospital}'
                              : ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11.5, color: LingShuColors.inkSoft),
                    ),
                  ]),
            ),
            const Icon(Icons.chevron_right, size: 18, color: LingShuColors.inkSoft),
          ]),
        );
      },
    );
  }
}
