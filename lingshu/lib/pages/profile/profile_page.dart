import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/branding.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../providers.dart';

/// 我的：成员切换、档案管理、入口聚合
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final profiles = ref.watch(profilesProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 当前成员卡
          LSCard(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: (profile?.gender == 'female'
                          ? WuXing.fire
                          : WuXing.water)
                      .withValues(alpha: 0.14),
                  child: Text(
                    (profile?.name.isNotEmpty == true
                            ? profile!.name.characters.first
                            : '?')
                        .toString(),
                    style: TextStyle(
                        fontSize: 22,
                        color: profile?.gender == 'female'
                            ? WuXing.fire
                            : WuXing.water,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile?.name ?? '',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (profile?.gender == 'female') '女',
                          if (profile?.gender == 'male') '男',
                          if (profile?.birthday != null)
                            '${DateTime.now().year - profile!.birthday!.year}岁',
                          if (profile?.bloodType != null)
                            '血型 ${profile!.bloodType}${profile.rhType == null ? '' : profile.rhType! == '+' ? '·阳' : '·阴'}',
                          if (profile?.constitution != null)
                            '${profile!.constitution}',
                        ].join(' · '),
                        style: const TextStyle(
                            fontSize: 12, color: LingShuColors.inkSoft),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: profile == null
                      ? null
                      : () => context.push('/family/edit?id=${profile.id}'),
                ),
              ]),
          ),
          const SizedBox(height: 16),
          if (profiles.length > 1)
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in profiles)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p.name),
                        selected: p.id == profile?.id,
                        selectedColor: LingShuColors.primary,
                        labelStyle: TextStyle(
                            color: p.id == profile?.id
                                ? Colors.white
                                : LingShuColors.ink),
                        showCheckmark: false,
                        onSelected: (_) => ref
                            .read(currentProfileIdProvider.notifier)
                            .state = p.id,
                      ),
                    ),
                ],
              ),
            ),
          if (profiles.length > 1) const SizedBox(height: 8),
          _section(context, '家庭与档案', [
            _item(Icons.family_restroom, '家庭成员管理',
                '为家人建立健康档案', () => context.push('/family')),
            _item(Icons.folder_copy_outlined, '健康档案库',
                '病历报告归档', () => context.go('/records')),
            _item(Icons.show_chart, '健康指标追踪', null,
                () => context.go('/metrics')),
          ]),
          const SizedBox(height: 12),
          _section(context, '养生与用药', [
            _item(Icons.medication_outlined, '用药提醒', '按时服药打卡',
                () => context.push('/medications')),
            _item(Icons.medication_liquid_outlined, '家庭小药箱',
                '药柜式管理 · 拍照识别 · 到期提醒',
                () => context.push('/box')),
            _item(Icons.spa_outlined, '中医体质辨识', '九种体质测试与养生建议',
                () => context.push('/constitution')),
          ]),
          const SizedBox(height: 12),
          _section(context, '安全与设置', [
            _item(Icons.backup_outlined, '数据备份与迁移', '导出 / 导入全量数据',
                () => context.push('/backup')),
            _item(Icons.lock_outline, '隐私与安全', 'PIN 码 / 生物识别',
                () => context.push('/settings')),
            _item(Icons.settings_outlined, '设置', 'AI 识别配置 / 数据管理',
                () => context.push('/settings')),
          ]),
          const SizedBox(height: 24),
          const Center(
            child: AppFooter(
              note: '数据仅存本机 · 本应用不能替代专业医疗建议',
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> items) =>
      Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(title,
                  style: TextStyle(
                      fontSize: 12,
                      color: LingShuColors.inkSoft,
                      fontWeight: FontWeight.w600)),
            ),
            ...items,
          ],
        ),
      );

  Widget _item(IconData icon, String title, String? subtitle, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon, color: LingShuColors.primary),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
      );
}
