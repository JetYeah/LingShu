import 'package:flutter/material.dart';

import 'theme.dart';

/// 灵枢标准卡片：宣纸白 + 发丝边 + 柔和墨影
class LSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? shadows;

  const LSCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.onTap,
    this.color,
    this.border,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: border ?? Border.all(color: LingShuColors.cardBorder),
      boxShadow: shadows ??
          const [
            BoxShadow(
              color: LingShuColors.cardShadow,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
    );
    final body = padding == null ? child : Padding(padding: padding!, child: child);
    if (onTap == null) {
      return Container(margin: margin, decoration: decoration, child: body);
    }
    return Container(
      margin: margin,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: body,
        ),
      ),
    );
  }
}

/// 区块小标题：金色竖线 + 宋体
class LSSectionTitle extends StatelessWidget {
  final String text;
  const LSSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 3,
        height: 15,
        decoration: BoxDecoration(
          color: LingShuColors.gold,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(text,
          style: const TextStyle(
              fontFamily: 'SerifSC',
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: LingShuColors.ink)),
    ]);
  }
}
