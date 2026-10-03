import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../db.dart';
import 'herb_repo.dart';

// ── 导入预览：差异分析与用户决策的数据 ──

/// 单个成员的导入差异报告
class ImportPlanProfile {
  final String name;
  final bool isNew; // 本机是否尚无此姓名成员
  final List<String> fieldDiffs = []; // 档案字段差异（中文名，仅本机已有时有意义）
  int newRecords = 0, dupRecords = 0;
  int newValues = 0, dupValues = 0;
  int newMeds = 0, conflictMeds = 0;
  bool selected = true;
  ImportPlanProfile({required this.name, required this.isNew});
}

class ImportPlan {
  final DateTime? exportedAt;
  final List<ImportPlanProfile> profiles;
  ImportPlan({required this.exportedAt, required this.profiles});
}

/// 全量备份（zip：data.json + files/ 原件）与合并导入。
/// 导出为 JSON 而非加密库文件：导入时重新分配主键并重映射外键，
/// 可跨设备、跨加密实例迁移；同版本之间可随时回灌，不覆盖已有数据。
class BackupService {
  final AppDatabase db;
  final SharedPreferences? prefs; // 随包携带中药图鉴收藏进度

  // 档案字段差异比对表：json key → 中文标签 + 值归一化
  static const _profileFieldLabels = {
    'gender': '性别', 'birthday': '出生日期', 'bloodType': '血型', 'rhType': 'Rh',
    'allergies': '过敏源', 'chronicDisease': '慢病史', 'familyHistory': '家族史',
    'emergencyName': '紧急联系人', 'emergencyPhone': '紧急电话',
    'emergencyRelation': '联系人关系', 'heightCm': '身高', 'weightKg': '体重',
    'idNumberEnc': '身份证号',
  };

  /// 解析备份包并与本机比对，产出导入预览（只读，不改任何数据）
  Future<ImportPlan> analyze(File zipFile) async {
    final data =
        _readArchive(ZipDecoder().decodeBytes(zipFile.readAsBytesSync()));
    final localProfiles = await db.select(db.profiles).get();
    final localRecords = await db.select(db.medicalRecords).get();
    final localMetrics = await db.select(db.metrics).get();
    final localValues = await db.select(db.metricValues).get();
    final localMeds = await db.select(db.medications).get();

    final pkgProfiles =
        (data['profiles'] as List? ?? []).cast<Map<String, dynamic>>();
    final pkgRecords =
        (data['medicalRecords'] as List? ?? []).cast<Map<String, dynamic>>();
    final pkgMetrics =
        (data['metrics'] as List? ?? []).cast<Map<String, dynamic>>();
    final pkgValues =
        (data['metricValues'] as List? ?? []).cast<Map<String, dynamic>>();
    final pkgMeds =
        (data['medications'] as List? ?? []).cast<Map<String, dynamic>>();

    String? norm(Map<String, dynamic> j, String key) {
      final v = j[key];
      if (v == null) return null;
      final s = v.toString();
      if (s.isEmpty || s == 'null') return null;
      return s;
    }

    final plan = ImportPlan(
      exportedAt: DateTime.tryParse('${data['exportedAt'] ?? ''}'),
      profiles: [],
    );
    for (final j in pkgProfiles) {
      final name = (j['name'] ?? '') as String;
      final oldId = _i(j['id']);
      final local = localProfiles.where((e) => e.name == name).firstOrNull;
      final pp = ImportPlanProfile(name: name, isNew: local == null);
      final localId = local?.id;

      // 档案字段差异（包里有值且与本机不同才算）
      if (local != null) {
        for (final e in _profileFieldLabels.entries) {
          final pv = norm(j, e.key);
          if (pv == null) continue;
          final lv = switch (e.key) {
            'gender' => local.gender,
            'birthday' => local.birthday?.toIso8601String(),
            'bloodType' => local.bloodType,
            'rhType' => local.rhType,
            'allergies' => local.allergies,
            'chronicDisease' => local.chronicDisease,
            'familyHistory' => local.familyHistory,
            'emergencyName' => local.emergencyName,
            'emergencyPhone' => local.emergencyPhone,
            'emergencyRelation' => local.emergencyRelation,
            'heightCm' => local.heightCm?.toString(),
            'weightKg' => local.weightKg?.toString(),
            'idNumberEnc' => local.idNumberEnc,
            _ => null,
          };
          if (pv != lv) pp.fieldDiffs.add(e.value);
        }
      }

      // 病历：同哈希或同（标题+日期+类型）视为重复
      for (final r in pkgRecords.where((r) => _i(r['profileId']) == oldId)) {
        final hash = _s(r['fileHash']);
        final date = _dt(r['recordDate']);
        final title = _s(r['title']);
        final type = _s(r['type']);
        final dup = localId != null &&
            localRecords.any((e) =>
                e.profileId == localId &&
                ((hash != null && e.fileHash == hash) ||
                    (e.title == title &&
                        e.recordDate == date &&
                        e.type == type)));
        dup ? pp.dupRecords++ : pp.newRecords++;
      }

      // 指标测量值：同名指标下按（时刻+数值）判重
      for (final m in pkgMetrics.where((m) => _i(m['profileId']) == oldId)) {
        final mOldId = _i(m['id']);
        final mName = _s(m['name']) ?? '';
        final localMetric = localId == null
            ? null
            : localMetrics
                .where((e) => e.profileId == localId && e.name == mName)
                .firstOrNull;
        for (final v in pkgValues.where((v) => _i(v['metricId']) == mOldId)) {
          final at = _dt(v['measuredAt']);
          final v1 = _d(v['value1']);
          final dup = localMetric != null &&
              localValues.any((e) =>
                  e.metricId == localMetric.id &&
                  e.measuredAt == at &&
                  e.value1 == v1);
          dup ? pp.dupValues++ : pp.newValues++;
        }
      }

      // 用药：同名同剂量 → 比用法；否则算新增
      for (final med in pkgMeds.where((m) => _i(m['profileId']) == oldId)) {
        final name2 = _s(med['name']) ?? '';
        final dosage = _s(med['dosage']);
        final localMed = localId == null
            ? null
            : localMeds
                .where((e) =>
                    e.profileId == localId && e.name == name2 && e.dosage == dosage)
                .firstOrNull;
        if (localMed == null) {
          pp.newMeds++;
        } else if (_s(med['timesOfDay']) != localMed.timesOfDay ||
            _s(med['daysOfWeek']) != localMed.daysOfWeek ||
            _s(med['mealRelation']) != localMed.mealRelation) {
          pp.conflictMeds++;
        }
      }
      plan.profiles.add(pp);
    }
    return plan;
  }

  Map<String, dynamic> _readArchive(Archive archive) {
    final dataFile = archive.findFile('data.json');
    if (dataFile == null) {
      throw const FormatException('不是有效的灵枢备份包（缺少 data.json）');
    }
    final data =
        jsonDecode(utf8.decode(dataFile.content as List<int>)) as Map<String, dynamic>;
    if (data['app'] != 'lingshu') throw const FormatException('备份包来源不对');
    final fmt = (data['formatVersion'] as num?)?.toInt() ?? 0;
    if (fmt > formatVersion) {
      throw const FormatException('备份包版本较新，请先升级 App');
    }
    return data;
  }

  BackupService(this.db) : prefs = null;
  BackupService.withPrefs(this.db, this.prefs);

  static const formatVersion = 1;

  // ── 导出 ──────────────────────────────────────────────
  /// [profileId] 为 null 导出全部成员；否则只导该成员（发给医生/家人的单人包）
  Future<File> exportAll({int? profileId, String? profileName}) async {
    final profiles = profileId == null
        ? await db.select(db.profiles).get()
        : await (db.select(db.profiles)
              ..where((t) => t.id.equals(profileId)))
            .get();
    final records = profileId == null
        ? await db.select(db.medicalRecords).get()
        : await (db.select(db.medicalRecords)
              ..where((t) => t.profileId.equals(profileId)))
            .get();
    final metrics = profileId == null
        ? await db.select(db.metrics).get()
        : await (db.select(db.metrics)
              ..where((t) => t.profileId.equals(profileId)))
            .get();
    final metricIds = metrics.map((m) => m.id).toSet();
    final metricValues = profileId == null
        ? await db.select(db.metricValues).get()
        : await (db.select(db.metricValues)
              ..where((t) => t.metricId.isIn(metricIds)))
            .get();
    final medications = profileId == null
        ? await db.select(db.medications).get()
        : await (db.select(db.medications)
              ..where((t) => t.profileId.equals(profileId)))
            .get();
    final medIds = medications.map((m) => m.id).toSet();
    final medicationLogs = profileId == null
        ? await db.select(db.medicationLogs).get()
        : await (db.select(db.medicationLogs)
              ..where((t) => t.medicationId.isIn(medIds)))
            .get();

    // 原件集中到临时目录打包，只存 basename
    final staging = await _recordsDir();
    final fileNames = <String, String>{}; // 本机绝对路径 -> 打包名
    for (final r in records) {
      final base = p.basename(r.filePath);
      fileNames[r.filePath] = base;
      final src = File(r.filePath);
      if (!src.existsSync()) continue;
      final dst = File(p.join(staging.path, base));
      if (!dst.existsSync()) src.copySync(dst.path);
    }

    final data = {
      'app': 'lingshu',
      'formatVersion': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'collectedHerbs': prefs?.getStringList(CollectedHerbs.key) ?? const [],
      'profiles': profiles.map(_profileJson).toList(),
      'medicalRecords':
          records.map((e) => _recordJson(e, fileNames[e.filePath])).toList(),
      'metrics': metrics.map(_metricJson).toList(),
      'metricValues': metricValues.map(_valueJson).toList(),
      'medications': medications.map(_medJson).toList(),
      'medicationLogs': medicationLogs.map(_logJson).toList(),
    };

    final archive = Archive()
      ..addFile(_txtEntry('data.json',
          const JsonEncoder.withIndent('  ').convert(data)));
    for (final base in fileNames.values.toSet()) {
      final f = File(p.join(staging.path, base));
      if (!f.existsSync()) continue;
      final bytes = f.readAsBytesSync();
      archive.addFile(ArchiveFile('files/$base', bytes.length, bytes));
    }

    final tmp = await getTemporaryDirectory();
    final t = DateTime.now();
    final tag = profileName == null ? '' : '_$profileName';
    final zipPath = p.join(tmp.path,
        'lingshu_backup$tag${t.year}${_p2(t.month)}${_p2(t.day)}_${_p2(t.hour)}${_p2(t.minute)}.zip');
    final out = File(zipPath);
    await out.writeAsBytes(ZipEncoder().encode(archive));
    return out;
  }

  // ── 导入（合并，不删除/覆盖本机已有数据） ──────────────
  /// [onlyNames] 只导入勾选的成员；[preferBackup] 冲突时以备份为准
  /// （档案差异字段、药物用法被备份覆盖；病历与测量值始终增量去重）
  Future<ImportStats> importAll(File zipFile,
      {Set<String>? onlyNames, bool preferBackup = false}) async {
    final archive =
        ZipDecoder().decodeBytes(zipFile.readAsBytesSync());
    final data = _readArchive(archive);

    final stats = ImportStats();
    final filesDir = await _recordsDir();

    await db.transaction(() async {
      // ── 成员：按姓名合并到已有，无则新建 ──
      final profileMap = <int, int>{};
      final localProfiles = await db.select(db.profiles).get();
      for (final j
          in (data['profiles'] as List? ?? []).cast<Map<String, dynamic>>()) {
        final oldId = _i(j['id']);
        if (onlyNames != null && !onlyNames.contains(j['name'])) {
          continue; // 用户未勾选该成员：其名下数据整体跳过
        }
        final local =
            localProfiles.where((e) => e.name == j['name']).firstOrNull;
        if (local != null) {
          profileMap[oldId] = local.id;
          // 冲突策略「以备份为准」：包里有值的档案字段覆盖本机
          if (preferBackup) {
            await (db.update(db.profiles)
                  ..where((t) => t.id.equals(local.id)))
                .write(ProfilesCompanion(
              gender: Value(_s(j['gender']) ?? local.gender),
              birthday: Value(_dt(j['birthday']) ?? local.birthday),
              idNumberEnc: Value(_s(j['idNumberEnc']) ?? local.idNumberEnc),
              bloodType: Value(_s(j['bloodType']) ?? local.bloodType),
              rhType: Value(_s(j['rhType']) ?? local.rhType),
              allergies: Value(_s(j['allergies']) ?? local.allergies),
              chronicDisease:
                  Value(_s(j['chronicDisease']) ?? local.chronicDisease),
              familyHistory:
                  Value(_s(j['familyHistory']) ?? local.familyHistory),
              emergencyName:
                  Value(_s(j['emergencyName']) ?? local.emergencyName),
              emergencyPhone:
                  Value(_s(j['emergencyPhone']) ?? local.emergencyPhone),
              emergencyRelation:
                  Value(_s(j['emergencyRelation']) ?? local.emergencyRelation),
              heightCm: Value(_d(j['heightCm']) ?? local.heightCm),
              weightKg: Value(_d(j['weightKg']) ?? local.weightKg),
              constitution: Value(_s(j['constitution']) ?? local.constitution),
            ));
          }
          continue;
        }
        final newId = await db.into(db.profiles).insert(
              ProfilesCompanion.insert(
                name: j['name'] as String,
                gender: _s(j['gender']) ?? 'male',
                birthday: Value(_dt(j['birthday'])),
                idNumberEnc: Value(_s(j['idNumberEnc'])),
                bloodType: Value(_s(j['bloodType'])),
                rhType: Value(_s(j['rhType'])),
                allergies: Value(_s(j['allergies'])),
                chronicDisease: Value(_s(j['chronicDisease'])),
                familyHistory: Value(_s(j['familyHistory'])),
                emergencyName: Value(_s(j['emergencyName'])),
                emergencyPhone: Value(_s(j['emergencyPhone'])),
                emergencyRelation: Value(_s(j['emergencyRelation'])),
                heightCm: Value(_d(j['heightCm'])),
                weightKg: Value(_d(j['weightKg'])),
                constitution: Value(_s(j['constitution'])),
                isOwner: Value(j['isOwner'] == true),
              ),
            );
        profileMap[oldId] = newId;
        stats.profiles++;
      }

      // ── 病历：按原件哈希跳过库里已有的相同内容，其余全部新增；原件从包内解出重存 ──
      for (final j in (data['medicalRecords'] as List? ?? [])
          .cast<Map<String, dynamic>>()) {
        if (!profileMap.containsKey(_i(j['profileId']))) continue;
        final base = _s(j['file']) ?? p.basename(_s(j['filePath']) ?? '');
        final src = base.isEmpty ? null : archive.findFile('files/$base');
        final hash = _s(j['fileHash']);
        if (hash != null &&
            await (db.select(db.medicalRecords)
                  ..where((t) => t.profileId
                          .equals(profileMap[_i(j['profileId'])] ?? 0) &
                      t.fileHash.equals(hash)))
                .getSingleOrNull() !=
                null) {
          continue; // 目标库里已有相同内容，不重复导入
        }
        final storedName =
            '${const Uuid().v4()}${base.isEmpty ? '' : p.extension(base)}';
        final storedPath = p.join(filesDir.path, storedName);
        if (src != null) {
          await File(storedPath)
              .writeAsBytes(src.content as List<int>, flush: true);
        }
        await db.into(db.medicalRecords).insert(
              MedicalRecordsCompanion.insert(
                profileId: profileMap[_i(j['profileId'])] ?? 0,
                title: _s(j['title']) ?? '导入病历',
                type: _s(j['type']) ?? '其他',
                recordDate:
                    _dt(j['recordDate']) ?? DateTime.now(),
                hospital: Value(_s(j['hospital'])),
                department: Value(_s(j['department'])),
                tags: Value(_s(j['tags'])),
                note: Value(_s(j['note'])),
                filePath: storedPath,
                fileType: _s(j['fileType']) ?? 'image',
                fileHash: Value(hash),
                lat: Value(_d(j['lat'])),
                lng: Value(_d(j['lng'])),
                locationText: Value(_s(j['locationText'])),
                aiSummary: Value(_s(j['aiSummary'])),
              ),
            );
        stats.records++;
      }

      // ── 指标定义：按（成员, 指标名）合并 ──
      final metricMap = <int, int>{};
      final localMetrics = await db.select(db.metrics).get();
      for (final j in (data['metrics'] as List? ?? [])
          .cast<Map<String, dynamic>>()) {
        final oldId = _i(j['id']);
        if (!profileMap.containsKey(_i(j['profileId']))) continue;
        final pid = profileMap[_i(j['profileId'])] ?? 0;
        final name = _s(j['name']) ?? '';
        final local = localMetrics
            .where((e) => e.profileId == pid && e.name == name)
            .firstOrNull;
        if (local != null) {
          metricMap[oldId] = local.id;
          continue;
        }
        final newId = await db.into(db.metrics).insert(
              MetricsCompanion.insert(
                profileId: pid,
                code: _s(j['code']) ?? 'custom',
                name: name,
                unit: _s(j['unit']) ?? '',
                dualValue: Value(j['dualValue'] == true),
                refLow: Value(_d(j['refLow'])),
                refHigh: Value(_d(j['refHigh'])),
                refLow2: Value(_d(j['refLow2'])),
                refHigh2: Value(_d(j['refHigh2'])),
                isCustom: Value(j['isCustom'] == true),
              ),
            );
        metricMap[oldId] = newId;
        stats.metrics++;
      }

      // ── 测量值：同指标+同时间+同数值 视为重复跳过 ──
      final localValues = await db.select(db.metricValues).get();
      for (final j in (data['metricValues'] as List? ?? [])
          .cast<Map<String, dynamic>>()) {
        final mid = metricMap[_i(j['metricId'])];
        if (mid == null) continue;
        final at = _dt(j['measuredAt']);
        final v1 = _d(j['value1']);
        if (localValues.any((e) =>
            e.metricId == mid && e.measuredAt == at && e.value1 == v1)) {
          continue;
        }
        await db.into(db.metricValues).insert(
              MetricValuesCompanion.insert(
                metricId: mid,
                value1: v1 ?? 0,
                value2: Value(_d(j['value2'])),
                measuredAt: at ?? DateTime.now(),
                note: Value(_s(j['note'])),
                timeLabel: Value(_s(j['timeLabel'])),
                source: Value(_s(j['source']) ?? 'manual'),
              ),
            );
        stats.metricValues++;
      }

      // ── 用药：同成员+同名+同剂量 视为重复跳过 ──
      final medMap = <int, int>{};
      final localMeds = await db.select(db.medications).get();
      for (final j in (data['medications'] as List? ?? [])
          .cast<Map<String, dynamic>>()) {
        final oldId = _i(j['id']);
        if (!profileMap.containsKey(_i(j['profileId']))) continue;
        final pid = profileMap[_i(j['profileId'])] ?? 0;
        final name = _s(j['name']) ?? '';
        final dosage = _s(j['dosage']);
        final local = localMeds
            .where((e) =>
                e.profileId == pid && e.name == name && e.dosage == dosage)
            .firstOrNull;
        if (local != null) {
          medMap[oldId] = local.id;
          // 冲突策略「以备份为准」：用法（时间/重复日/餐前餐后）被备份覆盖
          if (preferBackup) {
            await (db.update(db.medications)
                  ..where((t) => t.id.equals(local.id)))
                .write(MedicationsCompanion(
              mealRelation: Value(_s(j['mealRelation']) ?? local.mealRelation),
              timesOfDay: Value(_s(j['timesOfDay']) ?? local.timesOfDay),
              daysOfWeek: Value(_s(j['daysOfWeek']) ?? local.daysOfWeek),
              startDate: Value(_dt(j['startDate']) ?? local.startDate),
              endDate: Value(_dt(j['endDate']) ?? local.endDate),
              pausePeriods: Value(_s(j['pausePeriods']) ?? local.pausePeriods),
              stock: Value(_d(j['stock']) ?? local.stock),
              note: Value(_s(j['note']) ?? local.note),
            ));
          }
          continue;
        }
        final newId = await db.into(db.medications).insert(
              MedicationsCompanion.insert(
                profileId: pid,
                name: name,
                dosage: Value(dosage),
                mealRelation: Value(_s(j['mealRelation'])),
                timesOfDay: _s(j['timesOfDay']) ?? '[]',
                daysOfWeek: Value(_s(j['daysOfWeek'])),
                pausePeriods: Value(_s(j['pausePeriods'])),
                startDate: Value(_dt(j['startDate'])),
                endDate: Value(_dt(j['endDate'])),
                stock: Value(_d(j['stock'])),
                stockUnit: Value(_s(j['stockUnit'])),
                reminderEnabled: Value(j['reminderEnabled'] != false),
                note: Value(_s(j['note'])),
                active: Value(j['active'] != false),
              ),
            );
        medMap[oldId] = newId;
        stats.medications++;
      }

      // ── 打卡记录：同药+同计划时间+同状态 视为重复跳过 ──
      final localLogs = await db.select(db.medicationLogs).get();
      for (final j in (data['medicationLogs'] as List? ?? [])
          .cast<Map<String, dynamic>>()) {
        final mid = medMap[_i(j['medicationId'])];
        if (mid == null) continue;
        final at = _dt(j['scheduledAt']);
        final status = _s(j['status']) ?? 'taken';
        if (localLogs.any((e) =>
            e.medicationId == mid && e.scheduledAt == at && e.status == status)) {
          continue;
        }
        await db.into(db.medicationLogs).insert(
              MedicationLogsCompanion.insert(
                medicationId: mid,
                scheduledAt: at ?? DateTime.now(),
                takenAt: Value(_dt(j['takenAt'])),
                status: status,
              ),
            );
        stats.medicationLogs++;
      }
    });

    // 中药图鉴收藏进度合并（如有）
    final collected = data['collectedHerbs'];
    if (prefs != null && collected is List && collected.isNotEmpty) {
      await CollectedHerbs(prefs!).merge(
          collected.map((e) => e.toString()).toList());
    }
    return stats;
  }

  // ── 序列化 ────────────────────────────────────────────
  Map<String, dynamic> _profileJson(Profile e) => {
        'id': e.id,
        'name': e.name,
        'gender': e.gender,
        'birthday': e.birthday?.toIso8601String(),
        'idNumberEnc': e.idNumberEnc,
        'bloodType': e.bloodType,
        'rhType': e.rhType,
        'allergies': e.allergies,
        'chronicDisease': e.chronicDisease,
        'familyHistory': e.familyHistory,
        'emergencyName': e.emergencyName,
        'emergencyPhone': e.emergencyPhone,
        'emergencyRelation': e.emergencyRelation,
        'heightCm': e.heightCm,
        'weightKg': e.weightKg,
        'constitution': e.constitution,
        'isOwner': e.isOwner,
      };

  Map<String, dynamic> _recordJson(MedicalRecord e, String? file) => {
        'id': e.id,
        'profileId': e.profileId,
        'title': e.title,
        'type': e.type,
        'recordDate': e.recordDate.toIso8601String(),
        'hospital': e.hospital,
        'department': e.department,
        'tags': e.tags,
        'note': e.note,
        'file': file,
        'fileType': e.fileType,
        'fileHash': e.fileHash,
        'lat': e.lat,
        'lng': e.lng,
        'locationText': e.locationText,
        'aiSummary': e.aiSummary,
      };

  Map<String, dynamic> _metricJson(Metric e) => {
        'id': e.id,
        'profileId': e.profileId,
        'code': e.code,
        'name': e.name,
        'unit': e.unit,
        'dualValue': e.dualValue,
        'refLow': e.refLow,
        'refHigh': e.refHigh,
        'refLow2': e.refLow2,
        'refHigh2': e.refHigh2,
        'isCustom': e.isCustom,
      };

  Map<String, dynamic> _valueJson(MetricValue e) => {
        'timeLabel': e.timeLabel,
        'id': e.id,
        'metricId': e.metricId,
        'value1': e.value1,
        'value2': e.value2,
        'measuredAt': e.measuredAt.toIso8601String(),
        'note': e.note,
        'source': e.source,
      };

  Map<String, dynamic> _medJson(Medication e) => {
        'pausePeriods': e.pausePeriods,
        'id': e.id,
        'profileId': e.profileId,
        'name': e.name,
        'dosage': e.dosage,
        'mealRelation': e.mealRelation,
        'timesOfDay': e.timesOfDay,
        'daysOfWeek': e.daysOfWeek,
        'startDate': e.startDate?.toIso8601String(),
        'endDate': e.endDate?.toIso8601String(),
        'stock': e.stock,
        'stockUnit': e.stockUnit,
        'reminderEnabled': e.reminderEnabled,
        'note': e.note,
        'active': e.active,
      };

  Map<String, dynamic> _logJson(MedicationLog e) => {
        'id': e.id,
        'medicationId': e.medicationId,
        'scheduledAt': e.scheduledAt.toIso8601String(),
        'takenAt': e.takenAt?.toIso8601String(),
        'status': e.status,
      };

  Future<Directory> _recordsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'records'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  static ArchiveFile _txtEntry(String name, String content) {
    final bytes = utf8.encode(content);
    return ArchiveFile(name, bytes.length, bytes);
  }

  static String? _s(dynamic v) => v?.toString();
  static double? _d(dynamic v) => (v as num?)?.toDouble();
  static int _i(dynamic v) => (v as num).toInt();
  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.tryParse(v as String);
  static String _p2(int n) => n.toString().padLeft(2, '0');
}

class ImportStats {
  int profiles = 0;
  int records = 0;
  int metrics = 0;
  int metricValues = 0;
  int medications = 0;
  int medicationLogs = 0;

  bool get isEmpty =>
      profiles == 0 &&
      records == 0 &&
      metrics == 0 &&
      metricValues == 0 &&
      medications == 0 &&
      medicationLogs == 0;

  @override
  String toString() =>
      '新增成员 $profiles · 病历 $records · 指标定义 $metrics · 测量值 $metricValues · 用药 $medications · 打卡 $medicationLogs';
}
