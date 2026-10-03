import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 经络
class Meridian {
  final String code;
  final String name;
  final String pinyin;
  final String category;
  final String? element;
  final String colorHex;
  final String? pairedWith;
  final String flowSummary;
  final ShichenInfo? shichen;

  Meridian({
    required this.code,
    required this.name,
    required this.pinyin,
    required this.category,
    this.element,
    required this.colorHex,
    this.pairedWith,
    required this.flowSummary,
    this.shichen,
  });

  factory Meridian.fromJson(Map<String, dynamic> j) => Meridian(
        code: j['code'],
        name: j['name'],
        pinyin: j['pinyin'],
        category: j['category'],
        element: j['element'],
        colorHex: j['color'],
        pairedWith: j['pairedWith'],
        flowSummary: j['flowSummary'] ?? '',
        shichen: j['shichen'] == null
            ? null
            : ShichenInfo.fromJson(j['shichen']),
      );
}

class ShichenInfo {
  final String branch;
  final String hours;
  final String tip;
  ShichenInfo({required this.branch, required this.hours, required this.tip});
  factory ShichenInfo.fromJson(Map<String, dynamic> j) => ShichenInfo(
        branch: j['branch'],
        hours: j['hours'],
        tip: j['tip'] ?? '',
      );
}

/// 穴位
class Acupoint {
  final String code;
  final String name;
  final String pinyin;
  final String meridian;
  final String location;
  final String effect;
  final String indications;
  final String method;
  final bool common;
  final List<double>? pos; // 模型坐标 [x,y,z]，米；左右对称穴取正 x

  Acupoint({
    required this.code,
    required this.name,
    required this.pinyin,
    required this.meridian,
    required this.location,
    required this.effect,
    required this.indications,
    required this.method,
    required this.common,
    this.pos,
  });

  factory Acupoint.fromJson(Map<String, dynamic> j) => Acupoint(
        code: j['code'],
        name: j['name'],
        pinyin: j['pinyin'],
        meridian: j['meridian'],
        location: j['location'] ?? '',
        effect: j['effect'] ?? '',
        indications: j['indications'] ?? '',
        method: j['method'] ?? '',
        common: j['common'] == true,
        pos: j['pos'] == null
            ? null
            : (j['pos'] as List).map((e) => (e as num).toDouble()).toList(),
      );
}

/// 急救场景
class FirstAidScenario {
  final String id;
  final String title;
  final String category;
  final bool emergency;
  final String summary;
  final List<String> steps;
  final List<String> warnings;

  FirstAidScenario({
    required this.id,
    required this.title,
    required this.category,
    required this.emergency,
    required this.summary,
    required this.steps,
    required this.warnings,
  });

  factory FirstAidScenario.fromJson(Map<String, dynamic> j) =>
      FirstAidScenario(
        id: j['id'],
        title: j['title'],
        category: j['category'],
        emergency: j['emergency'] == true,
        summary: j['summary'] ?? '',
        steps: (j['steps'] as List? ?? []).cast<String>(),
        warnings: (j['warnings'] as List? ?? []).cast<String>(),
      );
}

/// 预设指标
class MetricPreset {
  final String code;
  final String name;
  final String unit;
  final bool dualValue;
  final double? refLow, refHigh, refLow2, refHigh2;
  final String desc;

  MetricPreset({
    required this.code,
    required this.name,
    required this.unit,
    required this.dualValue,
    this.refLow,
    this.refHigh,
    this.refLow2,
    this.refHigh2,
    required this.desc,
  });

  factory MetricPreset.fromJson(Map<String, dynamic> j) => MetricPreset(
        code: j['code'],
        name: j['name'],
        unit: j['unit'],
        dualValue: j['dualValue'] == true,
        refLow: (j['refLow'] as num?)?.toDouble(),
        refHigh: (j['refHigh'] as num?)?.toDouble(),
        refLow2: (j['refLow2'] as num?)?.toDouble(),
        refHigh2: (j['refHigh2'] as num?)?.toDouble(),
        desc: j['desc'] ?? '',
      );
}

/// 体质
class Constitution {
  final String code;
  final String name;
  final String desc;
  final List<String> questions;
  final List<String> examples; // 与 questions 一一对应的判断举例
  final Map<String, String> advice;

  Constitution({
    required this.code,
    required this.name,
    required this.desc,
    required this.questions,
    this.examples = const [],
    required this.advice,
  });

  factory Constitution.fromJson(Map<String, dynamic> j) => Constitution(
        code: j['code'],
        name: j['name'],
        desc: j['desc'] ?? '',
        questions: (j['questions'] as List? ?? []).cast<String>(),
        examples: (j['examples'] as List? ?? []).cast<String>(),
        advice: (j['advice'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as String)),
      );
}

/// 节气
class SolarTerm {
  final String name;
  final String date;
  final String element;
  final String tip;
  SolarTerm(
      {required this.name,
      required this.date,
      required this.element,
      required this.tip});
  factory SolarTerm.fromJson(Map<String, dynamic> j) => SolarTerm(
        name: j['name'],
        date: j['date'],
        element: j['element'],
        tip: j['tip'],
      );
}

class Shichen {
  final String branch;
  final String hours;
  final String meridian;
  final String tip;
  Shichen(
      {required this.branch,
      required this.hours,
      required this.meridian,
      required this.tip});
  factory Shichen.fromJson(Map<String, dynamic> j) => Shichen(
        branch: j['branch'],
        hours: j['hours'],
        meridian: j['meridian'],
        tip: j['tip'],
      );
}

/// 静态内容仓库
class ContentRepo {
  List<Meridian> meridians = [];
  List<Acupoint> acupoints = [];
  Map<String, String> passages = {}; // 经脉代码 → 《灵枢》循行原文
  List<FirstAidScenario> firstAid = [];
  String firstAidSource = '';
  List<MetricPreset> presets = [];
  List<Constitution> constitutions = [];
  List<SolarTerm> terms = [];
  List<Shichen> shichen = [];
  bool loaded = false;

  Map<String, Meridian> get meridianMap =>
      {for (final m in meridians) m.code: m};

  Map<String, Meridian> get acupointMeridianMap => meridianMap;

  Future<void> load() async {
    if (loaded) return;
    final mJson =
        jsonDecode(await rootBundle.loadString('assets/data/meridians.json'));
    meridians = (mJson['meridians'] as List)
        .map((e) => Meridian.fromJson(e))
        .toList();

    acupoints = [];
    final v2 = jsonDecode(
        await rootBundle.loadString('assets/data/acupoints_v2.json'));
    acupoints = (v2['points'] as List)
        .map((e) => Acupoint.fromJson({
              ...e,
              'meridian': e['channel'],
            }))
        .toList();
    passages = (v2['passages'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v['passage'] as String?) ?? ''));

    final faJson =
        jsonDecode(await rootBundle.loadString('assets/data/firstaid.json'));
    firstAidSource = faJson['source'] ?? '';
    firstAid = (faJson['scenarios'] as List)
        .map((e) => FirstAidScenario.fromJson(e))
        .toList();

    final pJson =
        jsonDecode(await rootBundle.loadString('assets/data/presets.json'));
    presets =
        (pJson['presets'] as List).map((e) => MetricPreset.fromJson(e)).toList();

    final cJson = jsonDecode(
        await rootBundle.loadString('assets/data/constitution_quiz.json'));
    constitutions = (cJson['constitutions'] as List)
        .map((e) => Constitution.fromJson(e))
        .toList();

    final sJson = jsonDecode(
        await rootBundle.loadString('assets/data/solar_terms.json'));
    terms = (sJson['terms'] as List).map((e) => SolarTerm.fromJson(e)).toList();
    shichen = (sJson['shichen'] as List).map((e) => Shichen.fromJson(e)).toList();

    loaded = true;
  }
}
