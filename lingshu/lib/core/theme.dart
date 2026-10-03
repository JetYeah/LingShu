import 'package:flutter/material.dart';

/// 五行五色体系（低饱和传统色）+ 宣纸底
class WuXing {
  static const wood = Color(0xFF3D7A5E); // 木 · 青
  static const fire = Color(0xFFB03A2E); // 火 · 赤
  static const earth = Color(0xFFB98A2F); // 土 · 黄
  static const metal = Color(0xFF8C9BAB); // 金 · 白(银)
  static const water = Color(0xFF33506B); // 水 · 玄(深青)

  static Color fromElement(String? element) {
    switch (element) {
      case '木':
        return wood;
      case '火':
      case '相火':
        return fire;
      case '土':
        return earth;
      case '金':
        return metal;
      case '水':
        return water;
      default:
        return const Color(0xFF7A5C3E);
    }
  }

  static const elementGlyphs = ['木', '火', '土', '金', '水'];
}

class LingShuColors {
  static const paper = Color(0xFFF8F4EB); // 宣纸米白
  static const paperDeep = Color(0xFFF0E9D9);
  static const ink = Color(0xFF26282E); // 墨色
  static const inkSoft = Color(0xFF847C6D); // 淡墨
  static const primary = WuXing.water; // 主色玄青
  static const gold = Color(0xFFB08D57); // 鎏金
  static const goldSoft = Color(0xFFD9C9A7);
  static const cinnabar = Color(0xFFB03A2E); // 朱砂
  static const cardBorder = Color(0xFFEAE2D0);
  static const cardShadow = Color(0x141F2127); // 8% 墨影
  static const success = WuXing.wood;
  static const danger = WuXing.fire;
  static const warning = WuXing.earth;
  // 玄色舞台（3D 铜人区专用）
  static const stageTop = Color(0xFF202B38);
  static const stageBottom = Color(0xFF0D131C);
}

ThemeData buildLingShuTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: LingShuColors.primary,
      brightness: Brightness.light,
      primary: LingShuColors.primary,
      secondary: WuXing.wood,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: LingShuColors.paper,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: LingShuColors.ink).copyWith(
          // 标题族使用思源宋体，正文保持无衬线
          titleLarge: const TextStyle(
              fontFamily: 'SerifSC',
              fontWeight: FontWeight.w700,
              color: LingShuColors.ink),
          titleMedium: const TextStyle(
              fontFamily: 'SerifSC',
              fontWeight: FontWeight.w500,
              color: LingShuColors.ink),
          headlineSmall: const TextStyle(
              fontFamily: 'SerifSC',
              fontWeight: FontWeight.w700,
              color: LingShuColors.ink),
          headlineMedium: const TextStyle(
              fontFamily: 'SerifSC',
              fontWeight: FontWeight.w700,
              color: LingShuColors.ink),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: LingShuColors.paper,
      foregroundColor: LingShuColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'SerifSC',
        color: LingShuColors.ink,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: 5,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: LingShuColors.cardBorder),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LingShuColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LingShuColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LingShuColors.primary, width: 1.3),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LingShuColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, letterSpacing: 4),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LingShuColors.primary,
        side: const BorderSide(color: LingShuColors.primary, width: 0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      side: const BorderSide(color: LingShuColors.cardBorder),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      height: 66,
      indicatorColor: LingShuColors.paperDeep,
      surfaceTintColor: Colors.white,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, color: LingShuColors.ink, height: 1.4),
      ),
    ),
    dividerTheme: const DividerThemeData(color: LingShuColors.cardBorder),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dialogTheme: DialogThemeData(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}
