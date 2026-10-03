import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../providers.dart';

class FirstAidDetailPage extends ConsumerWidget {
  final String scenarioId;
  const FirstAidDetailPage({super.key, required this.scenarioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider);
    if (!content.loaded) {
      content.load().then((_) {});
    }
    final s = content.firstAid.where((x) => x.id == scenarioId).firstOrNull;
    if (s == null) {
      return const Scaffold(body: Center(child: Text('内容未找到')));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(s.title, style: const TextStyle(fontSize: 16)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16,
            MediaQuery.of(context).viewPadding.bottom + 28),
        children: [
          if (s.emergency)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: WuXing.fire.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: WuXing.fire.withValues(alpha: 0.4)),
              ),
              child: const Row(children: [
                Icon(Icons.emergency, color: WuXing.fire),
                SizedBox(width: 10),
                Expanded(
                  child: Text('危急场景！如情况严重请立即拨打 120',
                      style: TextStyle(
                          color: WuXing.fire,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              ]),
            ),
          if (s.emergency) const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: WuXing.fire),
              onPressed: () => launchUrl(Uri.parse('tel:120')),
              icon: const Icon(Icons.phone_in_talk),
              label: const Text('拨打 120'),
            ),
          ),
          const SizedBox(height: 16),
          Text(s.summary,
              style: const TextStyle(fontSize: 13.5, height: 1.6)),
          const SizedBox(height: 16),
          const Text('处置步骤',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (var i = 0; i < s.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: const BoxDecoration(
                      color: WuXing.water, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(s.steps[i],
                      style:
                          const TextStyle(fontSize: 13.5, height: 1.55)),
                ),
              ]),
            ),
          if (s.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: WuXing.earth.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.warning_amber_rounded,
                        color: WuXing.earth, size: 18),
                    SizedBox(width: 6),
                    Text('千万不要',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: WuXing.earth,
                            fontSize: 14)),
                  ]),
                  const SizedBox(height: 8),
                  for (final w in s.warnings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('✕  $w',
                          style: const TextStyle(
                              fontSize: 12.5, height: 1.5)),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(content.firstAidSource,
              style: const TextStyle(
                  fontSize: 10, color: LingShuColors.inkSoft)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
