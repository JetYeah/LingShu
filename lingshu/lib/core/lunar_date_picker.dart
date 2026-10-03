import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';

import 'theme.dart';

/// 三列滚轮出生日期选择：左年 · 右月 · 右日
/// 顶部实时呈现公历年月日 + 干支纪年/农历 + 节气·传统节日标签
Future<DateTime?> showLunarDatePicker(
  BuildContext context, {
  DateTime? initial,
  required DateTime first,
  required DateTime last,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _LunarDatePickerSheet(
      initial: initial ?? DateTime(last.year - 30, 1, 1),
      first: first,
      last: last,
    ),
  );
}

class _LunarDatePickerSheet extends StatefulWidget {
  final DateTime initial;
  final DateTime first;
  final DateTime last;
  const _LunarDatePickerSheet({
    required this.initial,
    required this.first,
    required this.last,
  });

  @override
  State<_LunarDatePickerSheet> createState() => _LunarDatePickerSheetState();
}

class _LunarDatePickerSheetState extends State<_LunarDatePickerSheet> {
  late int _year;
  late int _month;
  late int _day;
  late final FixedExtentScrollController _yCtrl;
  late final FixedExtentScrollController _mCtrl;
  late final FixedExtentScrollController _dCtrl;

  @override
  void initState() {
    super.initState();
    final i = widget.initial.isBefore(widget.first)
        ? widget.first
        : (widget.initial.isAfter(widget.last) ? widget.last : widget.initial);
    _year = i.year;
    _month = i.month;
    _day = i.day;
    _yCtrl = FixedExtentScrollController(initialItem: _year - widget.first.year);
    _mCtrl = FixedExtentScrollController(initialItem: _month - 1);
    _dCtrl = FixedExtentScrollController(initialItem: _day - 1);
  }

  @override
  void dispose() {
    _yCtrl.dispose();
    _mCtrl.dispose();
    _dCtrl.dispose();
    super.dispose();
  }

  int get _daysInMonth {
    final n = DateTime(_year, _month + 1, 0).day;
    return n;
  }

  DateTime get _selected {
    final now = DateTime.now();
    var d = DateTime(_year, _month, _day);
    if (d.isBefore(widget.first)) d = widget.first;
    if (d.isAfter(widget.last)) d = DateTime(now.year, now.month, now.day);
    return d;
  }

  void _onYearMonthChanged() {
    // 年/月变化后，日超出当月天数则回拨
    if (_day > _daysInMonth) {
      _day = _daysInMonth;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _dCtrl.jumpToItem(_day - 1);
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sel = _selected;
    final lunar = Lunar.fromDate(sel);
    final ganzhi = '${lunar.getYearInGanZhi()}年（${lunar.getYearShengXiao()}）';
    final lunarText = lunar.getDayInChinese() == '初一'
        ? '${lunar.getMonthInChinese()}月'
        : '${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
    final jieqi = lunar.getJieQi();
    final festivals = lunar.getFestivals().where((f) =>
        f.contains('节') || f.contains('除夕') || f.contains('中秋') || f.contains('七夕'));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('选择出生日期',
                      style: TextStyle(
                          fontFamily: 'SerifSC',
                          fontSize: 15,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w700,
                          color: LingShuColors.ink)),
                  TextButton(
                    onPressed: () => Navigator.pop(context, sel),
                    child: const Text('确定'),
                  ),
                ],
              ),
              // ── 结果呈现：公历 + 干支纪年/农历 + 标签 ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F1E6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: LingShuColors.gold.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${sel.year}年${sel.month}月${sel.day}日',
                      style: TextStyle(
                          fontFamily: 'SerifSC',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: LingShuColors.ink),
                    ),
                    const SizedBox(height: 4),
                    Text('$ganzhi · 农历$lunarText',
                        style: TextStyle(
                            fontSize: 13, color: LingShuColors.inkSoft)),
                    if (jieqi.isNotEmpty || festivals.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (jieqi.isNotEmpty) _tag(jieqi, jieqi: true),
                            for (final f in festivals) _tag(f),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // ── 三列滚轮：年 | 月 | 日 ──
              SizedBox(
                height: 186,
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _wheel(
                        ctrl: _yCtrl,
                        count: widget.last.year - widget.first.year + 1,
                        label: (i) => '${widget.first.year + i}年',
                        onChanged: (i) {
                          _year = widget.first.year + i;
                          _onYearMonthChanged();
                        },
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _wheel(
                        ctrl: _mCtrl,
                        count: 12,
                        label: (i) => '${i + 1}月',
                        onChanged: (i) {
                          _month = i + 1;
                          _onYearMonthChanged();
                        },
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _wheel(
                        ctrl: _dCtrl,
                        count: _daysInMonth,
                        label: (i) => '${i + 1}日',
                        onChanged: (i) => setState(() => _day = i + 1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, {bool jieqi = false}) {
    final color = jieqi ? const Color(0xFF33506B) : const Color(0xFFB33A2E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11.5, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _wheel({
    required FixedExtentScrollController ctrl,
    required int count,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
  }) {
    return CupertinoPicker(
      scrollController: ctrl,
      itemExtent: 38,
      magnification: 1.08,
      squeeze: 1.15,
      useMagnifier: true,
      selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
        background: LingShuColors.gold.withValues(alpha: 0.18),
        capEndEdge: false,
        capStartEdge: false,
      ),
      looping: false,
      onSelectedItemChanged: onChanged,
      children: List.generate(
        count,
        (i) => Center(
          child: Text(label(i),
              style: TextStyle(
                  fontSize: 16.5, color: LingShuColors.ink, letterSpacing: 1)),
        ),
      ),
    );
  }
}
