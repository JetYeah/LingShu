import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';

/// 底部五 Tab：灵枢（穴位）/ 档案 / 健康 / 急救 / 我的
class HomeShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const HomeShell({super.key, required this.shell});

  static const _items = [
    (icon: Icons.accessibility_new, label: '灵枢', color: WuXing.water),
    (icon: Icons.folder_copy_outlined, label: '档案', color: WuXing.earth),
    (icon: Icons.show_chart, label: '健康', color: WuXing.wood),
    (icon: Icons.emergency, label: '急救', color: WuXing.fire),
    (icon: Icons.person_outline, label: '我的', color: WuXing.metal),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        height: 64,
        destinations: [
          for (final (i, item) in _items.indexed)
            NavigationDestination(
              icon: Icon(item.icon,
                  color: shell.currentIndex == i
                      ? item.color
                      : LingShuColors.inkSoft),
              selectedIcon: Icon(item.icon, color: item.color),
              label: item.label,
            ),
        ],
        onDestinationSelected: (i) => shell.goBranch(
          i,
          initialLocation: i == shell.currentIndex,
        ),
      ),
    );
  }
}
