import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'theme.dart';

/// 应用版本号（读安装包真实版本，如 0.1.8）
Future<String> appVersion() async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
}

/// 个人品牌钤记：磨沙客 · MOSAIC（中英文名，出品品牌，应用名仍为灵枢）
class MosaicBranding extends StatelessWidget {
  final double size; // 中文行字号，英文行按比例缩小
  const MosaicBranding({super.key, this.size = 13});

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFFB08D57);
    return Column(children: [
      Container(
        width: 46,
        height: 0.8,
        color: color.withValues(alpha: 0.45),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 6, 3, 3),
        child: Text(
          '磨 沙 客',
          style: TextStyle(
            fontFamily: 'SerifSC',
            fontSize: size,
            fontWeight: FontWeight.w600,
            letterSpacing: 6,
            height: 1,
            color: color,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          'M O S A I C',
          style: TextStyle(
            fontSize: size * 0.62,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.6,
            height: 1,
            color: color.withValues(alpha: 0.85),
          ),
        ),
      ),
      Container(
        width: 46,
        height: 0.8,
        color: color.withValues(alpha: 0.45),
      ),
    ]);
  }
}

/// 页脚：品牌 + 动态版本号
class AppFooter extends StatelessWidget {
  final String? note; // 额外说明行（如免责声明）
  const AppFooter({super.key, this.note});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      MosaicBranding(),
      const SizedBox(height: 10),
      FutureBuilder<String>(
        future: appVersion(),
        builder: (c, s) => Text(
          '灵枢 LíngShū v${s.data ?? '…'}',
          style: const TextStyle(
              fontSize: 11,
              color: LingShuColors.inkSoft,
              letterSpacing: 2),
        ),
      ),
      if (note != null) ...[
        const SizedBox(height: 4),
        Text(note!,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 11, color: LingShuColors.inkSoft)),
      ],
    ]);
  }
}
