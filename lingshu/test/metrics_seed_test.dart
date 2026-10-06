import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lingshu/core/db.dart';
import 'package:lingshu/core/services/content_loader.dart';
import 'package:lingshu/pages/metrics/metrics_page.dart';

/// 空档案自动播种预设指标：成员档案/老版本建档不走 onboarding 播种，
/// 进入健康追踪页时补齐全套（BMI 除外）；非空档案不动。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // rootBundle 读 presets.json 需要
  late AppDatabase db;
  final content = ContentRepo();

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('空档案播种 7 项预设（BMI 除外），血糖/血压带指南参考限', () async {
    final n = await seedPresetMetricsIfEmpty(db, 7, content);
    expect(n, 7, reason: '8 项预设去 BMI 后 7 项');
    final rows = await db.select(db.metrics).get();
    expect(rows.map((m) => m.name), containsAll(
        ['血压', '血糖', '心率', '体重', '身高', '体温', '血氧饱和度']));
    expect(rows.map((m) => m.name), isNot(contains('BMI')),
        reason: 'BMI 由身高体重推导，不入表');

    final sugar = rows.firstWhere((m) => m.name == '血糖');
    expect(sugar.refLow, 3.9);
    expect(sugar.refHigh, 6.1);
    final bp = rows.firstWhere((m) => m.name == '血压');
    expect(bp.dualValue, isTrue);
    expect(bp.refLow2, 90.0);
    expect(bp.refHigh2, 139.0);
    expect(bp.refLow, 60.0);
    expect(bp.refHigh, 89.0);
  });

  test('非空档案不播种（返回 0，尊重用户删除预设的自由）', () async {
    await db.into(db.metrics).insert(MetricsCompanion.insert(
          profileId: 7,
          code: 'custom',
          name: '尿酸',
          unit: 'μmol/L',
        ));
    final n = await seedPresetMetricsIfEmpty(db, 7, content);
    expect(n, 0);
    final rows = await db.select(db.metrics).get();
    expect(rows.length, 1);
    expect(rows.single.name, '尿酸');
  });

  test('播种只作用于目标档案，其他档案不受影响', () async {
    await db.into(db.metrics).insert(MetricsCompanion.insert(
          profileId: 8, // 另一档案已有指标
          code: 'custom',
          name: '尿酸',
          unit: 'μmol/L',
        ));
    final n = await seedPresetMetricsIfEmpty(db, 7, content);
    expect(n, 7);
    final of8 = await (db.select(db.metrics)
          ..where((m) => m.profileId.equals(8)))
        .get();
    expect(of8.length, 1, reason: '档案 8 不应被补种');
  });
}
