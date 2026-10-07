import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lingshu/core/db.dart';
import 'package:lingshu/core/services/agent_service.dart';
import 'package:lingshu/core/services/content_loader.dart';
import 'package:lingshu/core/services/ocr_service.dart';
import 'package:lingshu/pages/metrics/metrics_page.dart'
    show seedPresetMetricsIfEmpty;

/// AI 管家本地动作（不走大模型路由的部分）：口述记指标、用药增停查、
/// 档案查询、健康概览、体质、药箱、急救/中药/穴位百科、导航。
/// 通知服务传 null——单测环境无平台通道，跳过通知排期。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // rootBundle 读静态 JSON
  late AppDatabase db;
  late AgentService agent;
  final content = ContentRepo();

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    agent = AgentService(
      ocr: OcrService(baseUrl: 'https://example.invalid', apiKey: 'test'),
      content: content,
    );
    await db.into(db.profiles).insert(ProfilesCompanion.insert(
          name: '张三',
          gender: 'male',
          birthday: Value(DateTime(1984, 6, 1)),
        ));
  });

  tearDown(() async {
    await db.close();
  });

  Future<AgentReply> act(String action,
          {Map<String, dynamic> args = const {}, String message = ''}) =>
      agent.runAction(
          db: db, profileId: 1, action: action, args: args, message: message);

  group('record_metric 口述记指标', () {
    setUp(() async {
      await seedPresetMetricsIfEmpty(db, 1, content);
    });

    test('模型提取参数：血压双值+心率，自动建心率指标', () async {
      final r = await act('record_metric',
          args: {'metric': '血压', 'value': 130, 'value2': 85, 'hr': 76, 'timeLabel': '早上'});
      expect(r.text, contains('已记录'));
      expect(r.text, contains('130/85'));
      expect(r.text, contains('心率 76'));

      final metrics = await (db.select(db.metrics)
            ..where((m) => m.profileId.equals(1)))
          .get();
      final bp = metrics.firstWhere((m) => m.name == '血压');
      final hr = metrics.firstWhere((m) => m.name == '心率');
      final bpVals = await (db.select(db.metricValues)
            ..where((v) => v.metricId.equals(bp.id)))
          .get();
      final hrVals = await (db.select(db.metricValues)
            ..where((v) => v.metricId.equals(hr.id)))
          .get();
      expect(bpVals.single.value1, 130);
      expect(bpVals.single.value2, 85);
      expect(bpVals.single.timeLabel, '早上');
      expect(hrVals.single.value1, 76);
    });

    test('同日同时点同值去重，不重复入库', () async {
      await act('record_metric',
          args: {'metric': '血压', 'value': 130, 'value2': 85, 'hr': 76, 'timeLabel': '早上'});
      final r2 = await act('record_metric',
          args: {'metric': '血压', 'value': 130, 'value2': 85, 'timeLabel': '早上'});
      expect(r2.text, contains('未重复记录'));
      final count = await db.select(db.metricValues).get();
      expect(count.length, 2, reason: '血压+心率各一条，第二次不再插入');
    });

    test('模型没提数值时退回口述解析（中文数字+日期+时段）', () async {
      final r = await act('record_metric', message: '昨天早上 血压一百四/九十');
      expect(r.text, contains('140/90'));
      final metrics = await (db.select(db.metrics)
            ..where((m) => m.profileId.equals(1) & m.name.equals('血压')))
          .get();
      final vals = await (db.select(db.metricValues)
            ..where((v) => v.metricId.equals(metrics.single.id)))
          .get();
      final y = DateTime.now().subtract(const Duration(days: 1));
      expect(vals.single.value1, 140);
      expect(vals.single.value2, 90);
      expect(vals.single.measuredAt.day, y.day);
      expect(vals.single.timeLabel, '早上');
    });

    test('空腹血糖按口述解析并带时点', () async {
      final r = await act('record_metric', message: '空腹血糖六点八');
      expect(r.text, contains('血糖'));
      expect(r.text, contains('6.8'));
      final metrics = await (db.select(db.metrics)
            ..where((m) => m.profileId.equals(1) & m.name.equals('血糖')))
          .get();
      final vals = await (db.select(db.metricValues)
            ..where((v) => v.metricId.equals(metrics.single.id)))
          .get();
      expect(vals.single.value1, 6.8);
      expect(vals.single.timeLabel, '空腹');
    });
  });

  group('用药管理', () {
    test('创建提醒：口语时间归一为 24 小时制，每天=不存 daysOfWeek', () async {
      final r = await act('add_medication', args: {
        'name': '氨氯地平',
        'times': ['早', '晚'],
        'days': [1, 2, 3, 4, 5, 6, 7],
      });
      expect(r.text, contains('已创建用药提醒'));
      expect(r.text, contains('每天 08:00、20:00'));
      expect(r.route, '/medications');
      final med = (await db.select(db.medications).get()).single;
      expect(med.name, '氨氯地平');
      expect(med.timesOfDay, '["08:00","20:00"]');
      expect(med.daysOfWeek, isNull);
      expect(med.active, isTrue);
    });

    test('查询在用药物清单', () async {
      await act('add_medication', args: {
        'name': '氨氯地平',
        'times': ['08:00'],
      });
      final r = await act('list_medications');
      expect(r.text, contains('氨氯地平'));
      expect(r.text, contains('每天 08:00'));
    });

    test('停用：精确名命中，先落库后台再取消通知', () async {
      await act('add_medication', args: {'name': '阿司匹林', 'times': ['08:00']});
      final r = await act('stop_medication', args: {'name': '阿司匹林'});
      expect(r.text, contains('已停用'));
      final med = (await db.select(db.medications).get()).single;
      expect(med.active, isFalse);
    });

    test('停用：模糊命中多条时要求说全名，不动数据', () async {
      await act('add_medication', args: {'name': '阿莫西林胶囊', 'times': ['08:00']});
      await act('add_medication', args: {'name': '阿莫西林颗粒', 'times': ['20:00']});
      final r = await act('stop_medication', args: {'name': '阿莫西林'});
      expect(r.text, contains('说全名'));
      final meds = await db.select(db.medications).get();
      expect(meds.every((m) => m.active), isTrue);
    });
  });

  group('档案与概览', () {
    test('档案查询：关键词过滤 + 空库引导', () async {
      final empty = await act('query_records');
      expect(empty.text, contains('档案库还是空的'));

      await db.into(db.medicalRecords).insert(MedicalRecordsCompanion.insert(
            profileId: 1,
            title: '九院血常规报告',
            type: '检验报告',
            recordDate: DateTime(2026, 9, 30),
            filePath: '/x/a.jpg',
            fileType: 'image',
            hospital: const Value('上海九院'),
          ));
      final hit = await act('query_records', args: {'keyword': '血常规'});
      expect(hit.text, contains('九院血常规报告'));
      expect(hit.route, '/records');
      final miss = await act('query_records', args: {'keyword': 'CT'});
      expect(miss.text, contains('没有找到'));
    });

    test('健康概览：档案/指标/用药各就各位', () async {
      await seedPresetMetricsIfEmpty(db, 1, content);
      await act('add_medication', args: {'name': '氨氯地平', 'times': ['08:00']});
      await act('record_metric', args: {'metric': '血压', 'value': 128, 'value2': 82});
      final r = await act('health_summary');
      final birth = DateTime(1984, 6, 1);
      final now = DateTime.now();
      var age = now.year - birth.year;
      if (DateTime(now.year, birth.month, birth.day).isAfter(now)) age--;
      expect(r.text, contains('张三'));
      expect(r.text, contains('$age 岁'));
      expect(r.text, contains('档案库'));
      expect(r.text, contains('128/82'));
      expect(r.text, contains('氨氯地平'));
      expect(r.text, contains('体质：未辨识'));
    });
  });

  group('体质与药箱', () {
    test('未辨识 → 引导问卷并给入口', () async {
      final r = await act('constitution_query');
      expect(r.text, contains('体质辨识'));
      expect(r.route, '/constitution');
    });

    test('已辨识 → 给出调养建议', () async {
      await (db.update(db.profiles)..where((u) => u.id.equals(1)))
          .write(const ProfilesCompanion(constitution: Value('气虚质')));
      final r = await act('constitution_query');
      expect(r.text, contains('气虚质'));
      expect(r.text, contains('【调养建议】'));
      expect(r.text, contains('饮食'));
    });

    test('药箱盘点：过期与临期分档', () async {
      final famId = await db
          .into(db.families)
          .insert(FamiliesCompanion.insert(name: '我家'));
      await db.into(db.familyMembers).insert(
          FamilyMembersCompanion.insert(familyId: famId, profileId: 1));
      await db.into(db.boxMedicines).insert(BoxMedicinesCompanion.insert(
            familyId: famId,
            name: '布洛芬缓释胶囊',
            expireDate: DateTime(2026, 1, 1),
          ));
      await db.into(db.boxMedicines).insert(BoxMedicinesCompanion.insert(
            familyId: famId,
            name: '感冒灵颗粒',
            expireDate: DateTime(2027, 6, 30),
          ));
      final r = await act('box_status');
      expect(r.text, contains('布洛芬缓释胶囊'));
      expect(r.text, contains('已过期'));
      expect(r.text, contains('感冒灵颗粒'));
      expect(r.route, '/box');
    });
  });

  group('本地百科（权威数据源）', () {
    test('急救：烫伤命中场景，含步骤与 120 提醒', () async {
      final r = await act('firstaid', args: {'query': '烫伤'});
      expect(r.text, contains('烫伤'));
      expect(r.text, contains('【处理步骤】'));
      expect(r.route, contains('/firstaid/'));
    });

    test('急救：查不到场景时列全部类目', () async {
      final r = await act('firstaid', args: {'query': '不存在的场景xyz'});
      expect(r.text, contains('120'));
    });

    test('中药：黄芪命中，含性味归经与禁忌', () async {
      final r = await act('herb_lookup', args: {'name': '黄芪'});
      expect(r.text, contains('黄芪'));
      expect(r.text, contains('性味归经'));
      expect(r.text, contains('禁忌'));
    });

    test('穴位：合谷命中并标注经络', () async {
      final r = await act('acupoint_lookup', args: {'name': '合谷'});
      expect(r.text, contains('合谷'));
      expect(r.text, contains('手阳明大肠经'));
      expect(r.route, '/home');
    });

    test('节气：返回今日节气与农历', () async {
      final r = await act('solar_term');
      expect(r.text, contains('今日'));
      expect(r.text, contains('农历'));
    });
  });

  group('导航与能力问询', () {
    test('navigate 白名单页面带回跳转入口', () async {
      final r = await act('navigate', args: {'page': 'backup'});
      expect(r.route, '/backup');
      expect(r.routeLabel, '备份与恢复');
    });

    test('navigate 未知页面列出可打开项', () async {
      final r = await act('navigate', args: {'page': '不存在'});
      expect(r.text, contains('用药提醒'));
    });

    test('「你能做什么」本地直答：不配 Key 也返回能力列表', () async {
      final noKey = AgentService(
          ocr: OcrService(baseUrl: 'https://example.invalid', apiKey: ''),
          content: content);
      final r = await noKey.handle(
          db: db, profileId: 1, message: '你能帮我做什么');
      expect(r.capabilities.length, greaterThanOrEqualTo(13));
      expect(r.text, contains('点一项直接开始'));
    });

    test('本地兜底路由：概览/用药/药箱/体质/节气不请求模型直接执行', () async {
      await seedPresetMetricsIfEmpty(db, 1, content);
      final summary = await agent.handle(db: db, profileId: 1, message: '我的健康概览');
      expect(summary.text, contains('张三'));
      expect(summary.text, contains('健康概览'));

      final meds = await agent.handle(db: db, profileId: 1, message: '我在用什么药');
      expect(meds.text, contains('没有在用的药物'));

      final box = await agent.handle(db: db, profileId: 1, message: '药箱里有什么药');
      expect(box.text, contains('家庭药箱'));

      final term = await agent.handle(db: db, profileId: 1, message: '今天是什么节气');
      expect(term.text, contains('今日'));
    });

    test('兜底路由纯函数：不误收指标/中药等普通问句', () {
      expect(localActionFor('我的健康概览', AgentService.pageTable)?.$1,
          'health_summary');
      expect(localActionFor('打开备份', AgentService.pageTable)?.$1, 'navigate');
      // 以下应返回 null（交给模型路由）
      expect(localActionFor('看看最近7天的血糖', AgentService.pageTable), isNull);
      expect(localActionFor('黄芪的功效和禁忌', AgentService.pageTable), isNull);
      expect(localActionFor('记一下 血压130/85', AgentService.pageTable), isNull);
      expect(localActionFor('晚上睡不着怎么办', AgentService.pageTable), isNull);
    });
  });
}
