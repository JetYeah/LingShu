import 'package:flutter/material.dart';

/// 灵枢品牌标识：维特鲁威人 × 北斗七星（天人合一）
/// 图片资产由 .setup/compose_logo.py 生成（AI 线稿 + J2000 真实星图叠加）
class LingShuLogo extends StatelessWidget {
  final double size;
  final Color? background;
  final bool showBackground;
  const LingShuLogo({
    super.key,
    this.size = 80,
    this.background,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final img = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.18),
      child: Image.asset('assets/images/logo_main.png',
          width: size, height: size, fit: BoxFit.cover),
    );
    if (!showBackground) return img;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.18),
        boxShadow: const [
          BoxShadow(color: Color(0x3326282E), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: img,
    );
  }
}
