import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/herb_repo.dart';
import '../../core/theme.dart';
import '../../providers.dart';

/// 中药详情：性味归经 / 功效主治 / 验方配伍（含出处） / 成分药理 / 禁忌
class HerbDetailPage extends ConsumerWidget {
  final Herb herb;
  const HerbDetailPage({super.key, required this.herb});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(collectedVersionProvider);
    final isCollected = ref
        .read(collectedHerbsProvider)
        .contains(herb.name);
    return Scaffold(
      appBar: AppBar(
        title: Text(herb.name),
        actions: [
          IconButton(
            tooltip: isCollected ? '取消收藏' : '收入图鉴',
            icon: Icon(
              isCollected ? Icons.star_rounded : Icons.star_border_rounded,
              color: isCollected ? LingShuColors.gold : null,
            ),
            onPressed: () async {
              final c = ref.read(collectedHerbsProvider);
              if (isCollected) {
                await c.remove(herb.name);
              } else {
                await c.add(herb.name);
              }
              ref.read(collectedVersionProvider.notifier).state++;
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          if (herb.img != null)
            _banner('${herb.img}.jpg', '药材'),
          if (herb.plantImg != null)
            _banner('assets/herb_plants/${herb.plantImg}.jpg', '原植物'),
          // 药名逐字注音（拼音标在字头上方）
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < herb.name.characters.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Column(children: [
                  Text(i < herb.py.length ? herb.py[i] : '',
                      style: const TextStyle(
                          fontSize: 10.5,
                          height: 1.1,
                          letterSpacing: 0.5,
                          color: LingShuColors.inkSoft)),
                  Text(herb.name.characters.elementAt(i),
                      style: const TextStyle(
                          fontFamily: 'SerifSC',
                          fontSize: 30,
                          height: 1.15,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
          ]),
          if (herb.alias.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('别名：${herb.alias}',
                  style: const TextStyle(
                      fontSize: 12, color: LingShuColors.inkSoft)),
            ),
          if (herb.latin.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(herb.latin,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: LingShuColors.inkSoft.withValues(alpha: 0.8))),
            ),
          const SizedBox(height: 10),
          Row(children: [
            Container(width: 34, height: 2.5, color: LingShuColors.gold),
            const SizedBox(width: 4),
            Container(width: 8, height: 2.5, color: LingShuColors.goldSoft),
            const SizedBox(width: 4),
            Container(width: 3, height: 2.5, color: LingShuColors.goldSoft),
          ]),
          const SizedBox(height: 14),
          _info('性味归经', herb.type),
          _info('功效', herb.effect),
          _info('用法与主治', herb.usage),
          if (herb.formulas.isNotEmpty)
            _infoList('验方与配伍', herb.formulas),
          _info('成分', herb.constituent),
          _info('药理', herb.pharmacology),
          if (herb.taboo.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: WuXing.fire.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: WuXing.fire.withValues(alpha: 0.35), width: 0.8),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 17, color: WuXing.fire),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('禁忌',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: WuXing.fire)),
                    const SizedBox(height: 3),
                    Text(herb.taboo,
                        style:
                            const TextStyle(fontSize: 13, height: 1.55)),
                  ]),
                ),
              ]),
            ),
          _info('基原', herb.part),
          _info('产地分布', herb.distribution),
          _info('采收加工', herb.processing),
          const SizedBox(height: 8),
          Text(
            '文字整理自中医中药网（zhongyoo.com）公开资料；药材与原植物照片来自香港浸会大学中药材/药用植物图像数据库（仅供个人学习）；验方出处以原文标注著作为准。内容仅供养生学习参考，用药请遵医嘱。',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: LingShuColors.inkSoft, height: 1.5),
          ),
        ],
      ),
    );
  }

  /// 顶部横幅图（右下角带"药材/原植物"角标）
  Widget _banner(String asset, String tag) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            asset,
            height: 165,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, e, __) => Container(
              height: 165,
              width: double.infinity,
              color: LingShuColors.paperDeep,
              alignment: Alignment.center,
              child: Text('图片未能加载：$asset',
                  style: const TextStyle(
                      fontSize: 11, color: LingShuColors.inkSoft)),
            ),
          ),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(tag,
                style: const TextStyle(fontSize: 10.5, color: Colors.white)),
          ),
        ),
      ]),
    );
  }

  Widget _info(String title, String body) {
    if (body.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
            child: Text(body,
                style: const TextStyle(fontSize: 13, height: 1.6)),
          ),
        ]),
      ),
    );
  }

  Widget _infoList(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('${i + 1}. ${items[i]}',
                        style: const TextStyle(fontSize: 13, height: 1.6)),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
