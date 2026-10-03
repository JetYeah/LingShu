import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/content_loader.dart';
import '../../core/services/location_service.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../providers.dart';

/// 急救指南
class FirstAidPage extends ConsumerStatefulWidget {
  const FirstAidPage({super.key});

  @override
  ConsumerState<FirstAidPage> createState() => _FirstAidPageState();
}

class _FirstAidPageState extends ConsumerState<FirstAidPage> {
  String _category = '全部';
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(contentProvider);
    if (!content.loaded) {
      content.load().then((_) => mounted ? setState(() {}) : null);
    }
    final categories = ['全部', '心脑急症', '创伤出血', '环境伤害', '中毒与咬蜇伤', '其他急症'];
    var list = content.firstAid.where((s) =>
        (_category == '全部' || s.category == _category) &&
        (_q.isEmpty || s.title.contains(_q) || s.summary.contains(_q))).toList()
      ..sort((a, b) => b.emergency == a.emergency ? 0 : (b.emergency ? 1 : -1));

    return Scaffold(
      appBar: AppBar(title: const Text('急救指南')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'sos',
        backgroundColor: WuXing.fire,
        foregroundColor: Colors.white,
        onPressed: () => _sos(context, ref),
        icon: const Icon(Icons.emergency),
        label: const Text('SOS 一键呼救'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索急救场景：如 烫伤、异物、CPR',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _q.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _q = ''),
                      ),
              ),
              onChanged: (v) => setState(() => _q = v.trim()),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(c,
                          style: TextStyle(
                              fontSize: 12,
                              color: _category == c
                                  ? Colors.white
                                  : LingShuColors.ink)),
                      selected: _category == c,
                      selectedColor: WuXing.fire,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: content.firstAid.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: list.length + 1,
                    itemBuilder: (context, i) {
                      // 末尾：资料来源随列表滚动（固定底条会被 SOS 浮钮遮挡）
                      if (i == list.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            content.firstAidSource,
                            style: const TextStyle(
                                fontSize: 10, color: LingShuColors.inkSoft),
                          ),
                        );
                      }
                      final s = list[i];
                      return LSCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        border: Border.all(
                          color: s.emergency
                              ? WuXing.fire.withValues(alpha: 0.55)
                              : LingShuColors.cardBorder,
                          width: s.emergency ? 1.1 : 1,
                        ),
                        onTap: () => context.push('/firstaid/${s.id}'),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          leading: s.emergency
                              ? const Icon(Icons.emergency, color: WuXing.fire)
                              : const Icon(Icons.medical_services_outlined,
                                  color: WuXing.wood),
                          title: Text(s.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          subtitle: Text(s.summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: LingShuColors.inkSoft)),
                          trailing:
                              const Icon(Icons.chevron_right, size: 18),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _sos(BuildContext context, WidgetRef ref) async {
    final loc = await ref.read(locationServiceProvider).locate();
    if (!mounted) return;
    final mapUrl = loc != null
        ? 'https://maps.google.com/?q=${loc.lat},${loc.lng}'
        : '定位失败，请口述位置';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.emergency, color: WuXing.fire),
          SizedBox(width: 8),
          Text('紧急呼救'),
        ]),
        content: Text(
            '即将拨打 120 急救电话。\n\n当前定位：${loc?.label ?? '未获取'}\n$mapUrl\n\n请保持冷静，说清：地点、病情、人数、联系方式。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: WuXing.fire),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('拨打 120')),
        ],
      ),
    );
    if (confirmed == true) {
      await launchUrl(Uri.parse('tel:120'));
    }
  }
}
