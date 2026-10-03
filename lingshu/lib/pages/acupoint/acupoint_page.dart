import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lunar/lunar.dart';

import '../../core/services/content_loader.dart';
import '../../core/services/herb_repo.dart';
import '../../core/services/weather_service.dart';
import '../herb/herb_collection_page.dart';
import '../herb/herb_detail_page.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../providers.dart';
import 'body_chart.dart';

/// 首页：三视图经穴挂图（正面 / 背面 / 侧面）
class AcupointPage extends ConsumerStatefulWidget {
  const AcupointPage({super.key});

  @override
  ConsumerState<AcupointPage> createState() => _AcupointPageState();
}

class _AcupointPageState extends ConsumerState<AcupointPage> {
  String _meridianFilter = 'COMMON'; // COMMON=常用, ALL=全部, 或经络 code
  String _viewTab = 'front'; // front / back / side
  final GlobalKey<BodyChartViewState> _chartKey = GlobalKey();
  Acupoint? _spotlightAp; // 搜索定位态：图上高亮闪烁的目标穴位

  WeatherInfo? _weather;
  bool _weatherTried = false;
  Herb? _herb; // 今日一味

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _rollHerb();
  }

  /// 每日一味：只在未收藏的池子里抽；收藏变化后重抽（立即换下一味）
  void _rollHerb() {
    HerbRepo()
        .today(ref.read(collectedHerbsProvider).names)
        .then((h) {
      if (mounted) setState(() => _herb = h);
    });
  }

  /// 天气：定位（最后已知位置）→ Open-Meteo；失败静默，卡片仍显示日历。
  /// 点卡片可重试（定位权限刚授予时首次常失败）
  Future<void> _loadWeather() async {
    try {
      final loc = await ref.read(locationServiceProvider).locate();
      if (loc != null) {
        final w = await WeatherService.fetch(loc.lat, loc.lng);
        if (mounted) setState(() => _weather = w);
      }
    } catch (_) {}
  }

  void _retryWeather() => _loadWeather();

  void _openHerb() {
    final h = _herb;
    if (h == null) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => HerbDetailPage(herb: h))).then((_) {
      // 详情页可能刚收藏了这味：池子变化，立即重抽下一味
      if (_herb?.name != null &&
          ref.read(collectedHerbsProvider).contains(_herb!.name)) {
        _rollHerb();
      }
    });
  }

  void _openCollection() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HerbCollectionPage()));
  }

  List<Acupoint> get _allPoints => ref.read(contentProvider).acupoints;

  void _showDetail(Acupoint ap) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AcupointDetailSheet(ap: ap),
    ).whenComplete(() => _chartKey.currentState?.clearSelection());
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(contentProvider);
    if (!content.loaded) {
      content.load().then((_) => mounted ? setState(() {}) : null);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('灵枢 · 经穴挂图'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _openSearch),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(content),
          _buildViewTabs(),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: LingShuColors.gold.withValues(alpha: 0.28),
                      width: 0.8),
                  boxShadow: const [
                    BoxShadow(
                        color: LingShuColors.cardShadow,
                        blurRadius: 18,
                        offset: Offset(0, 8)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(children: [
                    Positioned.fill(
                      child: BodyChartView(
                        key: _chartKey,
                        acupoints: _allPoints,
                        view: _viewTab,
                        filter: _meridianFilter,
                        onPointTap: _showDetail,
                        spotlight: _spotlightAp?.code,
                        onSpotlightDismiss: () =>
                            setState(() => _spotlightAp = null),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      top: 12,
                      child: Text(
                        _meridianFilter == 'COMMON'
                            ? '常用要穴'
                            : _meridianFilter == 'ALL'
                                ? '周身要穴'
                                : content.meridianMap[_meridianFilter]?.name ??
                                    '',
                        style: TextStyle(
                          fontFamily: 'SerifSC',
                          fontSize: 13,
                          letterSpacing: 4,
                          color: LingShuColors.goldSoft.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    if (_spotlightAp != null)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 10,
                        child: _spotlightBanner(_spotlightAp!),
                      ),
                  ]),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 2),
            child: Text('点击穴位 · 查看定位 功效 主治 · 双指缩放',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: LingShuColors.inkSoft, letterSpacing: 2)),
          ),
          Expanded(flex: 2, child: _buildQuickCards()),
        ],
      ),
    );
  }

  Widget _buildViewTabs() {
    Widget tab(String value, String label) {
      final selected = _viewTab == value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: () => setState(() => _viewTab = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? LingShuColors.gold.withValues(alpha: 0.18)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color:
                      selected ? LingShuColors.gold : LingShuColors.cardBorder),
            ),
            child: Text(label,
                style: TextStyle(
                    fontFamily: 'SerifSC',
                    fontSize: 12.5,
                    letterSpacing: 2,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? LingShuColors.gold : LingShuColors.ink)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(children: [
        tab('front', '正面'),
        tab('back', '背面'),
        tab('side', '侧面'),
        const Spacer(),
      ]),
    );
  }

  Widget _buildFilterBar(ContentRepo content) {
    Widget chip(String value, String label, Color? dotColor) {
      final selected = _meridianFilter == value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: () => setState(() => _meridianFilter = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? LingShuColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                  color: selected
                      ? LingShuColors.primary
                      : LingShuColors.cardBorder),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                          color: LingShuColors.cardShadow,
                          blurRadius: 10,
                          offset: Offset(0, 4)),
                    ]
                  : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (dotColor != null && !selected) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
              ],
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1,
                      color: selected ? Colors.white : LingShuColors.ink)),
            ]),
          ),
        ),
      );
    }

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        children: [
          chip('COMMON', '常用', null),
          chip('ALL', '全部', null),
          for (final m in content.meridians)
            chip(m.code, shortName(m.name), WuXing.fromElement(m.element)),
        ],
      ),
    );
  }

  static String shortName(String name) {
    if (name.endsWith('经') && name.length >= 5) {
      return '${name.characters.elementAt(name.characters.length - 2)}经';
    }
    return name;
  }

  Widget _buildQuickCards() {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      children: [
        _dateWeatherCard(),
        _quickCard(
          icon: Icons.photo_camera,
          color: WuXing.earth,
          title: '拍照归档',
          subtitle: '病历 / 报告 自动归档',
          onTap: () => context.push('/records/import'),
        ),
        _quickCard(
          icon: Icons.medication,
          color: WuXing.water,
          title: '用药提醒',
          subtitle: '管理药物与服药打卡',
          onTap: () => context.push('/medications'),
        ),
        _quickCard(
          icon: Icons.emergency,
          color: WuXing.fire,
          title: '一键呼救',
          subtitle: '拨打120 + 发送定位',
          onTap: () => context.push('/firstaid'),
        ),
      ],
    );
  }

  /// 首卡：公历 + 农历 + 当日天气
  Widget _dateWeatherCard() {
    final now = DateTime.now();
    final lunar = Lunar.fromDate(now);
    final lunarDay = lunar.getDayInChinese() == '初一'
        ? '${lunar.getMonthInChinese()}月'
        : '${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
    final w = _weather;
    final h = _herb;
    ref.watch(collectedVersionProvider); // 收藏变化时刷新卡片
    return GestureDetector(
      onTap: h == null ? _openCollection : _openHerb,
      child: LSCard(
      margin: const EdgeInsets.only(right: 10, bottom: 6, top: 4),
      padding: const EdgeInsets.all(13),
      child: SizedBox(
        width: 164,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: LingShuColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.today_outlined,
                    color: LingShuColors.gold, size: 17),
              ),
              const Spacer(),
              // 天气区：无天气时点此重试（其余区域点按开中药详情）
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: w == null ? _retryWeather : null,
                child: w == null
                    ? const Row(children: [
                        Icon(Icons.refresh, size: 14, color: LingShuColors.inkSoft),
                        SizedBox(width: 3),
                        Text('天气',
                            style: TextStyle(
                                fontSize: 10.5, color: LingShuColors.inkSoft)),
                      ])
                    : Row(children: [
                        Icon(w.icon, color: w.color, size: 18),
                        const SizedBox(width: 3),
                        Text('${w.temp.round()}°',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                      ]),
              ),
            ]),
            // 今日一味：填充卡片中部（全部集齐则显示图鉴入口态）
            Expanded(
              child: h == null
                  ? const Center(
                      child: Text('🎉 百草图鉴已集齐，点击查看',
                          style: TextStyle(
                              fontSize: 11.5,
                              color: LingShuColors.gold,
                              letterSpacing: 1)),
                    )
                  : Row(children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(children: [
                              for (var i = 0;
                                  i < h.name.characters.length;
                                  i++)
                                Padding(
                                  padding: const EdgeInsets.only(right: 3),
                                  child: Column(children: [
                                    Text(i < h.py.length ? h.py[i] : '',
                                        style: const TextStyle(
                                            fontSize: 7.5,
                                            height: 1.1,
                                            color: LingShuColors.inkSoft)),
                                    Text(h.name.characters.elementAt(i),
                                        style: const TextStyle(
                                            fontFamily: 'SerifSC',
                                            fontSize: 15.5,
                                            height: 1.15,
                                            fontWeight: FontWeight.w700)),
                                  ]),
                                ),
                            ]),
                            const SizedBox(height: 3),
                            Text(
                              h.intro,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10.5,
                                  color: LingShuColors.inkSoft,
                                  letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                      // 图鉴入口
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _openCollection,
                        child: const Icon(Icons.collections_bookmark_rounded,
                            size: 17, color: LingShuColors.gold),
                      ),
                    ]),
            ),
            Text(
                '${DateFormat('M月d日 · EEEE', 'zh_CN').format(now)}'
                ' · ${lunar.getYearInGanZhi()}年',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: 'SerifSC',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.5)),
            const SizedBox(height: 3),
            Text(
              w != null
                  ? '农历$lunarDay · ${w.desc} ${w.range}'
                  : '农历$lunarDay${_weatherTried ? ' · 天气未获取' : ''}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: LingShuColors.inkSoft),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _quickCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: LSCard(
        margin: const EdgeInsets.only(right: 10, bottom: 6, top: 4),
        padding: const EdgeInsets.all(13),
        child: SizedBox(
          width: 164,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: color, size: 17),
                ),
              ]),
              const Spacer(),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: 'SerifSC',
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      letterSpacing: 1)),
              const SizedBox(height: 3),
              Text(subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: LingShuColors.inkSoft)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSearch() async {
    final result = await showDialog<Acupoint>(
      context: context,
      builder: (context) => AcupointSearchDialog(all: _allPoints),
    );
    if (result != null && mounted) {
      final v = _chartKey.currentState?.focus(result.code);
      if (v != null) setState(() => _viewTab = v);
      // 进入定位态：目标穴高亮闪烁、其余灰掉；不直接弹详情抽屉（会挡住挂图）
      setState(() => _spotlightAp = result);
    }
  }

  /// 定位态信息浮层：穴位名 + 经络 + 查看详情/退出定位
  Widget _spotlightBanner(Acupoint ap) {
    final content = ref.read(contentProvider);
    final m = content.meridianMap[ap.meridian];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D131C).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: LingShuColors.gold.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Text(ap.name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF2E6C9))),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(m?.name ?? ap.meridian,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11,
                            color: LingShuColors.goldSoft)),
                  ),
                ]),
                const SizedBox(height: 2),
                const Text('已定位 · 点击其他区域退出',
                    style: TextStyle(
                        fontSize: 10.5, color: LingShuColors.inkSoft)),
              ]),
        ),
        TextButton(
          onPressed: () => _showDetail(ap),
          style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: LingShuColors.gold),
          child: const Text('详情'),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close, size: 18, color: LingShuColors.inkSoft),
          onPressed: () => setState(() => _spotlightAp = null),
        ),
      ]),
    );
  }
}

/// 穴位搜索
class AcupointSearchDialog extends StatefulWidget {
  final List<Acupoint> all;
  const AcupointSearchDialog({super.key, required this.all});

  /// 拼音匹配规范化：数据里 pinyin 带声调（Zúsānlǐ），用户输入通常无调
  /// （zusanli / zu san li）——去声调符号、去空格、统一小写后再比对
  static String _norm(String s) {
    const tone = {
      'ā': 'a', 'á': 'a', 'ǎ': 'a', 'à': 'a',
      'ē': 'e', 'é': 'e', 'ě': 'e', 'è': 'e',
      'ī': 'i', 'í': 'i', 'ǐ': 'i', 'ì': 'i',
      'ō': 'o', 'ó': 'o', 'ǒ': 'o', 'ò': 'o',
      'ū': 'u', 'ú': 'u', 'ǔ': 'u', 'ù': 'u',
      'ǖ': 'v', 'ǘ': 'v', 'ǚ': 'v', 'ǜ': 'v',
      'ü': 'v',
    };
    final sb = StringBuffer();
    for (final ch in s.toLowerCase().runes) {
      final c = String.fromCharCode(ch);
      sb.write(tone[c] ?? c);
    }
    return sb.toString().replaceAll(' ', '');
  }

  @override
  State<AcupointSearchDialog> createState() => _AcupointSearchDialogState();
}

class _AcupointSearchDialogState extends State<AcupointSearchDialog> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final q = AcupointSearchDialog._norm(_q);
    final list = widget.all.where((a) {
      if (q.isEmpty) return a.common;
      return a.name.contains(_q) ||
          AcupointSearchDialog._norm(a.pinyin).contains(q) ||
          a.code.toLowerCase().contains(_q.toLowerCase());
    }).toList();
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 480, maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜索穴位：名称 / 拼音 / 编码（空=常用穴）',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _q = v.trim()),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final a = list[i];
                    return ListTile(
                      dense: true,
                      title: Text('${a.name}  ${a.pinyin}'),
                      subtitle: Text(a.code, style: const TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.chevron_right, size: 16),
                      onTap: () => Navigator.pop(context, a),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 穴位详情底部抽屉
class AcupointDetailSheet extends ConsumerWidget {
  final Acupoint ap;
  const AcupointDetailSheet({super.key, required this.ap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.read(contentProvider);
    final m = content.meridianMap[ap.meridian];
    final color = WuXing.fromElement(m?.element);
    final passage = content.passages[ap.meridian];
    return Container(
      margin: const EdgeInsets.all(10),
      constraints: const BoxConstraints(maxHeight: 580),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
              color: Color(0x3326282E), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: color.withValues(alpha: 0.35), width: 0.8),
                    ),
                    child: Text(m?.name ?? ap.meridian,
                        style: TextStyle(
                            fontSize: 12, letterSpacing: 1, color: color)),
                  ),
                  const Spacer(),
                  Text(ap.code,
                      style: const TextStyle(
                          fontSize: 12,
                          letterSpacing: 1,
                          color: LingShuColors.inkSoft)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(ap.name,
                      style: const TextStyle(
                          fontFamily: 'SerifSC',
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 6)),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(ap.pinyin,
                        style: const TextStyle(
                            fontSize: 13.5,
                            letterSpacing: 1,
                            color: LingShuColors.inkSoft)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Row(children: [
                Container(width: 34, height: 2.5, color: LingShuColors.gold),
                const SizedBox(width: 4),
                Container(width: 8, height: 2.5, color: LingShuColors.goldSoft),
                const SizedBox(width: 4),
                Container(width: 3, height: 2.5, color: LingShuColors.goldSoft),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _info('定位', ap.location),
                  _info('功效', ap.effect),
                  _info('主治', ap.indications),
                  _info('按摩 / 刺灸', ap.method),
                  if (passage?.isNotEmpty == true)
                    _info('经络循行 · 《灵枢》原文', passage!)
                  else if (m?.flowSummary.isNotEmpty == true)
                    _info('经络循行', m!.flowSummary),
                  const SizedBox(height: 4),
                  Text('穴位定位依 GB/T 12346-2021 / GB/T 40997-2021（几何示意移植自 meridian-atlas 项目，AGPL；部分定位与主治文案引自 Acupuncture-Assistant 项目，GPL-3.0），循行原文出自《黄帝内经·灵枢》。仅供养生学习参考，针刺请在专业医师指导下进行。',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: LingShuColors.inkSoft)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(String title, String body) {
    if (body.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 76,
              child: Text(title,
                  style: const TextStyle(
                      fontFamily: 'SerifSC',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 2,
                      color: LingShuColors.primary)),
            ),
            Container(width: 0.8, color: LingShuColors.cardBorder),
            const SizedBox(width: 10),
            Expanded(
              child:
                  Text(body, style: const TextStyle(fontSize: 13, height: 1.55)),
            ),
          ],
        ),
      ),
    );
  }
}
