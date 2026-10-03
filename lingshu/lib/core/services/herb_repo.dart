import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// 中药条目（数据源：中医中药网 zhongyoo.com 公开整理集，879 味）
class Herb {
  final String name;
  final String pinyin;
  final List<String> py; // 逐字带声调拼音（注音用）
  final String alias;
  final String latin;
  final String type; // 性味归经
  final String effect; // 功效
  final String usage; // 用法与主治
  final String intro; // 一句话简介
  final List<String> formulas; // 验方配伍（多含著作出处）
  final String constituent;
  final String pharmacology;
  final String taboo; // 禁忌
  final String part; // 基原
  final String distribution;
  final String processing;
  final String? img; // 药材照片（HKBU 中药材图像数据库）
  final String? plantImg; // 原植物照片（HKBU 药用植物图像数据库）

  /// 显示用拼音：优先逐字带调（py），回退无调连写（pinyin）
  String get pinyinDisplay => py.isEmpty ? pinyin : py.join(' ');

  const Herb({
    required this.name,
    required this.pinyin,
    this.py = const [],
    required this.alias,
    required this.latin,
    required this.type,
    required this.effect,
    required this.usage,
    required this.intro,
    required this.formulas,
    required this.constituent,
    required this.pharmacology,
    required this.taboo,
    required this.part,
    required this.distribution,
    required this.processing,
    this.img,
    this.plantImg,
  });

  factory Herb.fromJson(Map<String, dynamic> j) => Herb(
        name: j['name'] ?? '',
        pinyin: j['pinyin'] ?? '',
        py: (j['py'] as List? ?? []).map((e) => e.toString()).toList(),
        alias: j['alias'] ?? '',
        latin: j['latin'] ?? '',
        type: j['type'] ?? '',
        effect: j['effect'] ?? '',
        usage: j['usage'] ?? '',
        intro: j['intro'] ?? '',
        formulas: (j['formulas'] as List? ?? []).map((e) => e.toString()).toList(),
        constituent: j['constituent'] ?? '',
        pharmacology: j['pharmacology'] ?? '',
        taboo: j['taboo'] ?? '',
        part: j['part'] ?? '',
        distribution: j['distribution'] ?? '',
        processing: j['processing'] ?? '',
        img: j['img'] as String?,
        plantImg: j['plantImg'] as String?,
      );
}

/// 中药库：懒加载 herbs.json；每日一味按日期确定性抽取（同一天稳定不变）
class HerbRepo {
  List<Herb>? _all;

  Future<List<Herb>> all() async {
    if (_all != null) return _all!;
    final s = await rootBundle.loadString('assets/data/herbs.json');
    final list = jsonDecode(s) as List;
    _all = [for (final j in list) Herb.fromJson(j as Map<String, dynamic>)];
    return _all!;
  }

  /// 今日一味：只在未收藏的池子里抽（日期做种子取模，跨天自动换）；
  /// 全部收集完返回 null（图鉴集齐状态）
  Future<Herb?> today(Set<String> collected) async {
    final list = await all();
    final pool =
        collected.isEmpty ? list : list.where((h) => !collected.contains(h.name)).toList();
    if (pool.isEmpty) return null;
    final now = DateTime.now();
    final key = now.year * 10000 + now.month * 100 + now.day;
    return pool[key % pool.length];
  }
}

/// 收藏集（图鉴进度）：SharedPreferences 持久化，随备份包导出/导入
class CollectedHerbs {
  static const key = 'lingshu.collected_herbs';
  final SharedPreferences prefs;
  CollectedHerbs(this.prefs);

  Set<String> get names => (prefs.getStringList(key) ?? const []).toSet();
  bool contains(String name) => names.contains(name);

  Future<void> add(String name) async {
    final s = names..add(name);
    await prefs.setStringList(key, s.toList());
  }

  Future<void> remove(String name) async {
    final s = names..remove(name);
    await prefs.setStringList(key, s.toList());
  }

  /// 清空全部收藏（重置图鉴进度）
  Future<void> clear() async {
    await prefs.setStringList(key, []);
  }

  /// 备份导入时合并
  Future<void> merge(List<String> incoming) async {
    final s = names..addAll(incoming);
    await prefs.setStringList(key, s.toList());
  }
}
