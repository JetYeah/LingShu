import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers.dart';
import 'herb_detail_page.dart';
import 'herb_identify_page.dart';

/// 百草图鉴：已收集中药列表 + 集齐进度（收集游戏）
class HerbCollectionPage extends ConsumerWidget {
  const HerbCollectionPage({super.key});

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final count = ref.read(collectedHerbsProvider).names.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('清空收藏'),
        content: Text(count == 0
            ? '当前没有收藏任何中药。'
            : '将清空全部 $count 味收藏，图鉴进度归零、每日一味从 879 味重新抽取。'
              '此操作不影响档案、病历等其他数据。确定吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('取消')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: WuXing.fire),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('清空')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(collectedHerbsProvider).clear();
      ref.read(collectedVersionProvider.notifier).state++;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 收藏/清空改的是 prefs 数据，collectedHerbsProvider 实例不变，
    // 必须靠 version bump 触发本页重建（清空/详情页收藏/识别页收藏都走这里）
    ref.watch(collectedVersionProvider);
    final collected = ref.watch(collectedHerbsProvider).names;
    return Scaffold(
      appBar: AppBar(
        title: const Text('百草图鉴'),
        actions: [
          IconButton(
            tooltip: '清空收藏（重新开始收集）',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => _confirmClear(context, ref),
          ),
          IconButton(
            tooltip: '拍照识药',
            icon: const Icon(Icons.photo_camera_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const HerbIdentifyPage())),
          ),
        ],
      ),
      body: ref.watch(allHerbsProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('加载失败：${e.toString()}')),
          data: (all) {
          final total = all.length;
          final got = all.where((h) => collected.contains(h.name)).toList();
          final progress = total == 0 ? 0.0 : got.length / total;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.auto_awesome,
                          size: 15, color: LingShuColors.gold),
                      const SizedBox(width: 6),
                      Text(
                        got.length == total
                            ? '🎉 已集齐全部 $total 味！'
                            : '已收集 ${got.length} / $total 味',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor:
                            LingShuColors.cardBorder.withValues(alpha: 0.4),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            LingShuColors.gold),
                      ),
                    ),
                  ]),
            ),
            Expanded(
              child: got.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.star_border_rounded,
                              size: 46, color: LingShuColors.cardBorder),
                          SizedBox(height: 10),
                          Text('还没有收藏',
                              style: TextStyle(
                                  fontSize: 13.5,
                                  color: LingShuColors.inkSoft)),
                          SizedBox(height: 6),
                          Text('每天的首页会展示一味中药，点开后用 ☆ 收入图鉴',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: LingShuColors.inkSoft)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: got.length,
                      itemBuilder: (context, i) {
                        final h = got[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                                color: LingShuColors.cardBorder),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: (h.img ?? h.plantImg) == null
                                ? CircleAvatar(
                                    backgroundColor: LingShuColors.gold
                                        .withValues(alpha: 0.14),
                                    child: Text(h.name.characters.first,
                                        style: const TextStyle(
                                            color: LingShuColors.gold,
                                            fontWeight: FontWeight.bold)),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      h.img != null
                                          ? '${h.img}.jpg'
                                          : 'assets/herb_plants/${h.plantImg}.jpg',
                                      width: 46,
                                      height: 46,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          CircleAvatar(
                                              backgroundColor: LingShuColors
                                                  .gold
                                                  .withValues(alpha: 0.14),
                                              child: Text(
                                                  h.name.characters.first)),
                                    ),
                                  ),
                            title: Text('${h.name}'
                                '${h.pinyinDisplay.isEmpty ? '' : '  ${h.pinyinDisplay}'}'),
                            subtitle: Text(h.intro,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    color: LingShuColors.inkSoft)),
                            trailing: const Icon(Icons.chevron_right,
                                size: 18, color: LingShuColors.inkSoft),
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => HerbDetailPage(herb: h))),
                          ),
                        );
                      },
                    ),
            ),
          ]);
          }
        ),
    );
  }
}
