import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

// （applyWorkaroundToOpenSqlcipherOnOlderAndroidVersions / openCipherOnAndroid 来自 sqlcipher_flutter_libs）

part 'db.g.dart';

/// 家庭成员档案（含用户本人）
class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get gender => text()(); // male / female
  DateTimeColumn get birthday => dateTime().nullable()();
  TextColumn get idNumberEnc => text().nullable()(); // 身份证（库级加密后存储）
  TextColumn get bloodType => text().nullable()(); // A/B/O/AB
  TextColumn get rhType => text().nullable()(); // +/-
  TextColumn get allergies => text().nullable()(); // 过敏源
  TextColumn get chronicDisease => text().nullable()(); // 慢病史
  TextColumn get familyHistory => text().nullable()(); // 家族史
  TextColumn get emergencyName => text().nullable()();
  TextColumn get emergencyPhone => text().nullable()();
  TextColumn get emergencyRelation => text().nullable()(); // 紧急联系人与该成员的关系：本人/配偶/父母/爷孙…
  RealColumn get heightCm => real().nullable()();
  RealColumn get weightKg => real().nullable()();
  TextColumn get constitution => text().nullable()(); // 中医体质
  BoolColumn get isOwner => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 医疗档案（病历/报告）
class MedicalRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  TextColumn get title => text()();
  TextColumn get type => text()(); // 病历 / 检验报告 / 影像报告 / 处方 / 体检报告 / 其他
  DateTimeColumn get recordDate => dateTime()();
  TextColumn get hospital => text().nullable()();
  TextColumn get department => text().nullable()();
  TextColumn get tags => text().nullable()(); // 逗号分隔
  TextColumn get note => text().nullable()();
  TextColumn get filePath => text()(); // 原件路径（图片/PDF）
  TextColumn get fileType => text()(); // image / pdf
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  TextColumn get locationText => text().nullable()(); // 提交时地址/医院
  TextColumn get aiSummary => text().nullable()(); // AI 提取摘要
  TextColumn get fileHash => text().nullable()(); // 原件内容 MD5，重复导入去重用
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 健康指标定义
class Metrics extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  TextColumn get code => text()(); // 预设 code 或 custom
  TextColumn get name => text()();
  TextColumn get unit => text()();
  BoolColumn get dualValue => boolean().withDefault(const Constant(false))(); // 血压双值
  RealColumn get refLow => real().nullable()();
  RealColumn get refHigh => real().nullable()();
  RealColumn get refLow2 => real().nullable()(); // 双值指标第二参考
  RealColumn get refHigh2 => real().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  TextColumn get tag => text().nullable()(); // 归类标签：心血管/肝胆/血糖…
  TextColumn get aiInfo => text().nullable()(); // AI 医学解读（JSON：解释+评判标准）
  BoolColumn get followed => boolean().withDefault(const Constant(false))(); // 用户关注（⭐）
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 指标测量值
class MetricValues extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get metricId => integer()();
  RealColumn get value1 => real()();
  RealColumn get value2 => real().nullable()();
  DateTimeColumn get measuredAt => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get timeLabel => text().nullable()(); // 测量时点：空腹/早餐后/睡前…
  TextColumn get source => text().withDefault(const Constant('manual'))(); // manual / ai
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 药物
class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer()();
  TextColumn get name => text()();
  TextColumn get dosage => text().nullable()(); // 如 0.5g
  TextColumn get mealRelation => text().nullable()(); // 服用时间：早/午/晚餐前后、餐前/餐中/餐后/空腹/睡前
  TextColumn get timesOfDay => text()(); // JSON 数组 ["08:00","20:00"]
  TextColumn get daysOfWeek => text().nullable()(); // JSON 数组 [1..7]，空=每天
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get pausePeriods => text().nullable()(); // 暂停时段 JSON [{f:'yyyy-MM-dd', t:'yyyy-MM-dd'}]
  RealColumn get stock => real().nullable()(); // 剩余量
  TextColumn get stockUnit => text().nullable()();
  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get note => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 服药记录
class MedicationLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get medicationId => integer()();
  DateTimeColumn get scheduledAt => dateTime()();
  DateTimeColumn get takenAt => dateTime().nullable()();
  TextColumn get status => text()(); // taken / skipped / missed
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 家庭小药箱：小家庭（从成员中选人组成，一家庭一药箱）
/// 生成类名用 FamilyRow：避免与 riverpod 的 Family 概念重名冲突
@DataClassName('FamilyRow')
class Families extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 家庭组成员
class FamilyMembers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get familyId => integer()();
  IntColumn get profileId => integer()();
}

/// 药箱药品（拍照 AI 识别入库，格位式展示）
class BoxMedicines extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get familyId => integer()();
  TextColumn get name => text()();
  DateTimeColumn get expireDate => dateTime()(); // 到期日（含之日）
  TextColumn get imagePath => text().nullable()(); // 旧版单图路径（v9 起弃用，读 imagePaths）
  TextColumn get imagePaths => text().nullable()(); // 多张原始照片，JSON 数组
  TextColumn get usage => text().nullable()(); // 用法用量/说明
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [
  Profiles,
  MedicalRecords,
  Metrics,
  MetricValues,
  Medications,
  MedicationLogs,
  Families,
  FamilyMembers,
  BoxMedicines,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor}) : super(executor ?? _open());

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(metrics, metrics.tag);
        }
        if (from < 3) {
          await m.addColumn(medicalRecords, medicalRecords.fileHash);
          await _dedupeMetricData();
        }
        if (from < 4) {
          await m.addColumn(metrics, metrics.aiInfo);
        }
        if (from < 5) {
          await m.addColumn(metrics, metrics.followed);
        }
        if (from < 6) {
          await m.addColumn(profiles, profiles.emergencyRelation);
        }
        if (from < 7) {
          await m.addColumn(medications, medications.pausePeriods);
          await m.addColumn(metricValues, metricValues.timeLabel);
        }
        if (from < 8) {
          await m.createTable(families);
          await m.createTable(familyMembers);
          await m.createTable(boxMedicines);
        }
        if (from < 9) {
          // addColumn 包防御：v0.1.29 短暂发布过 user_version=8 但表已含新列的
          // 组合，此类库重复 addColumn 会抛 duplicate column，吞掉即可（列已在）
          try {
            await m.addColumn(boxMedicines, boxMedicines.imagePaths);
          } catch (_) {}
          try {
            await m.addColumn(boxMedicines, boxMedicines.usage);
          } catch (_) {}
          // 旧单图迁到多图 JSON 数组（JSON1 缺失时跳过——旧路径仍有兼容读取，不阻塞升级）
          try {
            await customStatement(
                "UPDATE box_medicines SET image_paths = json_array(image_path) "
                "WHERE image_path IS NOT NULL AND (image_paths IS NULL OR image_paths = '')");
          } catch (_) {}
        }
      });

  /// 去重历史脏数据（v3 一次性清理）：
  /// ① 指标定义按（成员, 名称）合并——值改挂到最小 id，删多余定义；
  /// ② 测量值按（指标, 同一自然日, 数值, 双值）判重，保留最早入库的一条。
  /// drift 的 DateTime 存的是 unix 秒，转本地日期按天判重。
  Future<void> _dedupeMetricData() async {
    await customStatement('''
      UPDATE metric_values SET metric_id = (
        SELECT MIN(m.id) FROM metrics m
        WHERE m.profile_id = (SELECT t.profile_id FROM metrics t WHERE t.id = metric_values.metric_id)
          AND m.name = (SELECT t.name FROM metrics t WHERE t.id = metric_values.metric_id)
      )
      WHERE metric_id IN (
        SELECT id FROM metrics
        WHERE id NOT IN (SELECT MIN(id) FROM metrics GROUP BY profile_id, name)
      );
    ''');
    await customStatement(
        'DELETE FROM metrics WHERE id NOT IN (SELECT MIN(id) FROM metrics GROUP BY profile_id, name);');
    await customStatement('''
      DELETE FROM metric_values WHERE id NOT IN (
        SELECT MIN(id) FROM metric_values
        GROUP BY metric_id, date(measured_at, 'unixepoch', 'localtime'), value1, ifnull(value2, -1e12)
      );
    ''');
  }

  static QueryExecutor _open() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final keyFile = File(p.join(dir.path, '.dbkey'));
      if (!keyFile.existsSync()) {
        keyFile.writeAsStringSync(
            DateTime.now().microsecondsSinceEpoch.toRadixString(16));
      }
      final key = keyFile.readAsStringSync().trim();
      final file = File(p.join(dir.path, 'lingshu.db'));
      await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
      return NativeDatabase.createInBackground(
        file,
        // 后台 isolate 的静态状态与主 isolate 隔离，
        // 必须在 isolateSetup 里把动态库指向 libsqlcipher.so
        isolateSetup: () {
          open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
        },
        setup: (raw) {
          raw.execute("PRAGMA key = '$key';");
          raw.execute('PRAGMA foreign_keys = ON;');
        },
      );
    });
  }
}

/// 便捷扩展：按成员查询
extension ProfileQueries on AppDatabase {
  Stream<List<Profile>> watchProfiles() =>
      (select(profiles)..orderBy([(u) => OrderingTerm.asc(u.id)])).watch();

  Future<Profile?> getProfile(int id) =>
      (select(profiles)..where((u) => u.id.equals(id))).getSingleOrNull();
}
